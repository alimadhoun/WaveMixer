//
//  TransportController.swift
//  WaveMixer
//
//  Created by Ali Madhoun on 22/03/2026.
//

import Foundation
import AVFoundation

/// Controls playback transport (play, pause, stop, seek) across all tracks.
/// Ensures synchronized playback using a master clock.
internal final class TransportController {

    // MARK: - Properties

    private let engineManager: AudioEngineManager
    private let masterClock: MasterClock
    private let scheduler: Scheduler
    private var tracks: [Track] = []

    private(set) var isPlaying: Bool = false
    private(set) var isPaused: Bool = false

    // MARK: - Initialization

    init(
        engineManager: AudioEngineManager,
        masterClock: MasterClock,
        scheduler: Scheduler
    ) {
        self.engineManager = engineManager
        self.masterClock = masterClock
        self.scheduler = scheduler
    }

    // MARK: - Track Management

    func setTracks(_ tracks: [Track]) {
        self.tracks = tracks
    }

    // MARK: - Transport Control

    /// Starts playback from the current position
    func play() throws {
        // Ensure engine is running
        try engineManager.start()

        if isPaused {
            // Resume from pause
            resumePlayback()
        } else {
            // Start fresh playback
            try startPlayback()
        }

        isPlaying = true
        isPaused = false
    }

    /// Pauses playback at the current position
    func pause() {
        guard isPlaying else { return }

        for track in tracks {
            track.playerNode.pause()
        }

        masterClock.pausePlayback()
        isPlaying = false
        isPaused = true
    }

    /// Stops playback and resets to the beginning
    func stop() {
        for track in tracks {
            scheduler.stopTrack(track)
        }

        masterClock.stopPlayback()
        isPlaying = false
        isPaused = false
    }

    /// Seeks to a specific time in the timeline
    /// - Parameter time: The target time in seconds
    func seek(to time: TimeInterval) throws {
        let wasPlaying = isPlaying

        // Stop current playback
        stop()

        // Update clock
        masterClock.seek(to: time)

        // If we were playing, restart playback from the new position
        if wasPlaying {
            try play()
        }
    }

    /// Skips forward by a specified amount
    /// - Parameter seconds: The number of seconds to skip
    func skipForward(_ seconds: TimeInterval) throws {
        let newTime = masterClock.currentTime + seconds
        try seek(to: newTime)
    }

    /// Skips backward by a specified amount
    /// - Parameter seconds: The number of seconds to skip
    func skipBackward(_ seconds: TimeInterval) throws {
        let newTime = max(0, masterClock.currentTime - seconds)
        try seek(to: newTime)
    }

    // MARK: - Private Helpers

    /// Starts playback from the current clock position
    private func startPlayback() throws {
        let currentTime = masterClock.currentTime

        // Calculate the schedule time for synchronized playback
        // Schedule slightly in the future to allow for processing
        let scheduleTime = AVAudioTime(
            sampleTime: AVAudioFramePosition(engineManager.sampleRate * 0.01), // 10ms ahead
            atRate: engineManager.sampleRate
        )

        // Schedule all tracks from the current time
        for track in tracks {
            try scheduler.scheduleTrack(track, from: currentTime, at: scheduleTime)
        }

        // Start all player nodes at the same time
        for track in tracks {
            track.playerNode.play(at: scheduleTime)
        }

        masterClock.startPlayback()
    }

    /// Resumes playback after pause
    private func resumePlayback() {
        for track in tracks {
            track.playerNode.play()
        }
        masterClock.startPlayback()
    }
}
