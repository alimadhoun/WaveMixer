//
//  Scheduler.swift
//  WaveMixer
//
//  Created by Ali Madhoun on 22/03/2026.
//

import Foundation
import AVFoundation

/// Handles scheduling of audio segments for gapless playback.
/// Ensures sample-accurate synchronization across all tracks.
internal final class Scheduler {

    // MARK: - Properties

    private let engineManager: AudioEngineManager
    private var audioFiles: [URL: AVAudioFile] = [:]

    // MARK: - Initialization

    init(engineManager: AudioEngineManager) {
        self.engineManager = engineManager
    }

    // MARK: - Scheduling

    /// Schedules all segments for a track starting from a specific time
    /// - Parameters:
    ///   - track: The track to schedule
    ///   - startTime: The time to start scheduling from
    ///   - scheduleTime: The AVAudioTime to schedule at (for synchronization)
    func scheduleTrack(
        _ track: Track,
        from startTime: TimeInterval,
        at scheduleTime: AVAudioTime?
    ) throws {
        // Find segments that should be playing at or after startTime
        let relevantSegments = track.segments.filter { segment in
            segment.endTime > startTime
        }

        guard !relevantSegments.isEmpty else { return }

        var currentScheduleTime = scheduleTime

        for segment in relevantSegments {
            try scheduleSegment(
                segment,
                on: track.playerNode,
                startingFrom: startTime,
                at: currentScheduleTime
            )

            // For subsequent segments, schedule immediately after (nil = append to queue)
            currentScheduleTime = nil
        }
    }

    /// Schedules a single audio segment
    /// - Parameters:
    ///   - segment: The segment to schedule
    ///   - playerNode: The player node to schedule on
    ///   - playbackStartTime: The global playback start time
    ///   - scheduleTime: When to schedule this segment (nil = immediately after previous)
    private func scheduleSegment(
        _ segment: AudioSegment,
        on playerNode: AVAudioPlayerNode,
        startingFrom playbackStartTime: TimeInterval,
        at scheduleTime: AVAudioTime?
    ) throws {
        // Load audio file
        let audioFile = try getAudioFile(for: segment.fileURL)

        let sampleRate = audioFile.processingFormat.sampleRate
        let totalFrames = audioFile.length

        // Calculate offset within the segment if we're seeking into it
        var frameOffset: AVAudioFramePosition = 0
        var frameCount = totalFrames

        if playbackStartTime > segment.startTime {
            // We're starting in the middle of this segment
            let offsetIntoSegment = playbackStartTime - segment.startTime
            frameOffset = TimeConverter.secondsToSamples(offsetIntoSegment, sampleRate: sampleRate)
            frameCount = totalFrames - frameOffset
        }

        // Ensure we don't exceed file bounds
        frameOffset = max(0, min(frameOffset, totalFrames - 1))
        frameCount = max(0, min(frameCount, totalFrames - frameOffset))

        guard frameCount > 0 else { return }

        // Schedule the segment
        playerNode.scheduleSegment(
            audioFile,
            startingFrame: frameOffset,
            frameCount: AVAudioFrameCount(frameCount),
            at: scheduleTime,
            completionCallbackType: .dataPlayedBack
        ) { _ in
            // Completion handler (can be used for monitoring if needed)
        }
    }

    /// Stops all scheduled playback for a track
    /// - Parameter track: The track to stop
    func stopTrack(_ track: Track) {
        track.playerNode.stop()
        track.playerNode.reset()
    }

    /// Clears all cached audio files
    func clearCache() {
        audioFiles.removeAll()
    }

    // MARK: - Private Helpers

    /// Loads and caches an audio file
    /// - Parameter url: The file URL
    /// - Returns: The loaded AVAudioFile
    private func getAudioFile(for url: URL) throws -> AVAudioFile {
        if let cached = audioFiles[url] {
            return cached
        }

        let file = try AVAudioFile(forReading: url)
        audioFiles[url] = file
        return file
    }
}
