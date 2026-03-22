//
//  PlayerViewModel.swift
//  WaveMixerExample
//
//  Created by Ali Madhoun on 22/03/2026.
//


import Foundation
import Combine
import WaveMixer
import AVFoundation

/// ViewModel for managing multi-track audio playback
@MainActor
final class PlayerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isPlaying: Bool = false
    @Published var tracks: [TrackInfo] = []
    @Published var shouldRepeat: Bool = false

    // MARK: - Properties

    private let player = MultiTrackPlayer()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Track Info

    struct TrackInfo: Identifiable {
        let id: UUID
        let name: String
        var volume: Float
    }

    // MARK: - Initialization

    init() {
        setupTimeObserver()
        loadBundledTracks()
    }

    // MARK: - Setup

    private func setupTimeObserver() {
        player.currentTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.currentTime = time
            }
            .store(in: &cancellables)

        player.completionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                // Update UI state when playback completes
                if self.player.completionStrategy == .stopAndSeekToStart {
                    self.isPlaying = false
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Track Management

    /// Loads bundled audio tracks from the Assets folder
    private func loadBundledTracks() {
        let audioFiles = ["vocals", "drums", "bass", "other"]
        var urls: [URL] = []

        // Get URLs for bundled audio files
        for fileName in audioFiles {
            if let url = Bundle.main.url(forResource: fileName, withExtension: "wav") {
                urls.append(url)
            } else {
                print("⚠️ Could not find \(fileName) in bundle")
            }
        }

        guard !urls.isEmpty else {
            print("❌ No audio files found in bundle")
            return
        }

        loadDemoTracks(urls: urls)
    }

    /// Loads demo tracks with sample audio files
    func loadDemoTracks(urls: [URL]) {
        // Clear existing tracks
        player.removeAllTracks()
        tracks.removeAll()

        // Create tracks from provided URLs
        for url in urls {
            let trackID = UUID()

            // Get actual duration from audio file
            let audioDuration = getAudioDuration(from: url)

            // Create a simple track with one segment spanning the file
            let segment = AudioSegment(
                fileURL: url,
                startTime: 0,
                duration: audioDuration
            )

            let track = Track(id: trackID, segments: [segment])
            track.volume = 1.0

            player.addTrack(track)

            // Use friendly names
            let fileName = url.deletingPathExtension().lastPathComponent
            let displayName = fileName.capitalized

            tracks.append(TrackInfo(
                id: trackID,
                name: displayName,
                volume: 1.0
            ))
        }

        duration = player.duration
    }

    /// Gets the actual duration of an audio file
    private func getAudioDuration(from url: URL) -> TimeInterval {
        let asset = AVAsset(url: url)
        return asset.duration.seconds
    }

    // MARK: - Playback Control

    func play() {
        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func stop() {
        player.stop()
        isPlaying = false
        currentTime = 0
    }

    // MARK: - Seeking

    func seek(to time: TimeInterval) {
        player.seek(to: time)
    }

    func skipForward() {
        player.skipForward(10)
    }

    func skipBackward() {
        player.skipBackward(10)
    }

    // MARK: - Volume Control

    func setVolume(_ volume: Float, for trackID: UUID) {
        player.setVolume(volume, for: trackID)

        if let index = tracks.firstIndex(where: { $0.id == trackID }) {
            tracks[index].volume = volume
        }
    }

    // MARK: - Completion Strategy

    func toggleRepeatMode(_ enabled: Bool) {
        shouldRepeat = enabled
        player.completionStrategy = enabled ? .repeatFromStart : .stopAndSeekToStart
    }

    // MARK: - Formatting

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
