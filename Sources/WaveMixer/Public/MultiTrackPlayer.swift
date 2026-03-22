//
//  MultiTrackPlayer.swift
//  WaveMixer
//
//  Created by Ali Madhoun on 22/03/2026.
//

import Foundation
import AVFoundation
import Combine

/// The main entry point for multi-track audio playback.
/// Provides a clean, high-level API for managing tracks and controlling playback.
public final class MultiTrackPlayer {

    // MARK: - Types

    /// Defines what happens when playback reaches the end
    public enum CompletionStrategy {
        /// Stop playback and seek to the beginning
        case stopAndSeekToStart
        /// Repeat playback from the beginning
        case repeatFromStart
    }

    // MARK: - Properties

    private let engineManager: AudioEngineManager
    private let masterClock: MasterClock
    private let scheduler: Scheduler
    private let transportController: TransportController

    private var tracks: [UUID: Track] = [:]
    private var timeObserverTimer: Timer?
    private let currentTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let completionSubject = PassthroughSubject<Void, Never>()
    private var hasCompletedPlayback = false

    /// The strategy to use when playback completes
    public var completionStrategy: CompletionStrategy = .stopAndSeekToStart

    // MARK: - Public Properties

    /// Publisher for observing current playback time
    public var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
        return currentTimeSubject.eraseToAnyPublisher()
    }

    /// Publisher that fires when playback completes
    public var completionPublisher: AnyPublisher<Void, Never> {
        return completionSubject.eraseToAnyPublisher()
    }

    /// The current playback time in seconds (clamped to duration)
    public var currentTime: TimeInterval {
        let time = masterClock.currentTime
        return min(time, duration)
    }

    /// The total duration of all tracks
    public var duration: TimeInterval {
        return tracks.values.map { $0.duration }.max() ?? 0
    }

    /// Whether playback is currently active
    public var isPlaying: Bool {
        return transportController.isPlaying
    }

    // MARK: - Initialization

    public init() {
        self.engineManager = AudioEngineManager()
        self.masterClock = MasterClock(engineManager: engineManager)
        self.scheduler = Scheduler(engineManager: engineManager)
        self.transportController = TransportController(
            engineManager: engineManager,
            masterClock: masterClock,
            scheduler: scheduler
        )

        setupTimeObserver()
    }

    deinit {
        timeObserverTimer?.invalidate()
    }

    // MARK: - Track Management

    /// Adds a track to the player
    /// - Parameter track: The track to add
    public func addTrack(_ track: Track) {
        guard tracks[track.id] == nil else { return }

        tracks[track.id] = track
        engineManager.attachTrack(track)
        updateTransportTracks()
    }

    /// Removes a track from the player
    /// - Parameter id: The UUID of the track to remove
    public func removeTrack(id: UUID) {
        guard let track = tracks.removeValue(forKey: id) else { return }

        engineManager.detachTrack(track)
        updateTransportTracks()
    }

    /// Removes all tracks
    public func removeAllTracks() {
        for track in tracks.values {
            engineManager.detachTrack(track)
        }
        tracks.removeAll()
        updateTransportTracks()
    }

    // MARK: - Playback Control

    /// Starts or resumes playback
    public func play() {
        do {
            hasCompletedPlayback = false
            try transportController.play()
        } catch {
            print("Failed to start playback: \(error)")
        }
    }

    /// Pauses playback at the current position
    public func pause() {
        transportController.pause()
    }

    /// Stops playback and returns to the beginning
    public func stop() {
        transportController.stop()
        currentTimeSubject.send(0)
    }

    // MARK: - Seeking

    /// Seeks to a specific time in the timeline
    /// - Parameter time: The target time in seconds
    public func seek(to time: TimeInterval) {
        do {
            let clampedTime = max(0, min(time, duration))
            hasCompletedPlayback = false
            try transportController.seek(to: clampedTime)
            currentTimeSubject.send(clampedTime)
        } catch {
            print("Failed to seek: \(error)")
        }
    }

    /// Skips forward by a specified amount
    /// - Parameter seconds: The number of seconds to skip (default: 10)
    public func skipForward(_ seconds: TimeInterval = 10) {
        do {
            try transportController.skipForward(seconds)
        } catch {
            print("Failed to skip forward: \(error)")
        }
    }

    /// Skips backward by a specified amount
    /// - Parameter seconds: The number of seconds to skip (default: 10)
    public func skipBackward(_ seconds: TimeInterval = 10) {
        do {
            try transportController.skipBackward(seconds)
        } catch {
            print("Failed to skip backward: \(error)")
        }
    }

    // MARK: - Volume Control

    /// Sets the volume for a specific track
    /// - Parameters:
    ///   - value: The volume level (0.0 to 1.0)
    ///   - trackID: The UUID of the track
    public func setVolume(_ value: Float, for trackID: UUID) {
        guard let track = tracks[trackID] else { return }
        track.volume = value
    }

    /// Gets the volume for a specific track
    /// - Parameter trackID: The UUID of the track
    /// - Returns: The volume level (0.0 to 1.0), or nil if track not found
    public func getVolume(for trackID: UUID) -> Float? {
        return tracks[trackID]?.volume
    }

    // MARK: - Private Helpers

    /// Updates the transport controller with current tracks
    private func updateTransportTracks() {
        let trackArray = Array(tracks.values)
        transportController.setTracks(trackArray)
    }

    /// Sets up periodic time observation
    private func setupTimeObserver() {
        timeObserverTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1, // Update 10 times per second
            repeats: true
        ) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }

            let currentTime = self.currentTime
            let duration = self.duration

            // Send current time update
            self.currentTimeSubject.send(currentTime)

            // Check if playback has completed
            if currentTime >= duration && duration > 0 && !self.hasCompletedPlayback {
                self.hasCompletedPlayback = true
                self.handlePlaybackCompletion()
            }
        }
    }

    /// Handles playback completion based on the completion strategy
    private func handlePlaybackCompletion() {
        // Notify observers
        completionSubject.send()

        // Execute completion strategy
        switch completionStrategy {
        case .stopAndSeekToStart:
            stop()

        case .repeatFromStart:
            do {
                try transportController.seek(to: 0)
                hasCompletedPlayback = false
            } catch {
                print("Failed to repeat playback: \(error)")
                stop()
            }
        }
    }
}
