//
//  MasterClock.swift
//  WaveMixer
//
//  Created by Ali Madhoun on 22/03/2026.
//

import Foundation
import AVFoundation

/// Manages accurate playback time calculation using engine render time.
/// Handles seek offsets and sample-to-time conversion.
internal final class MasterClock {

    // MARK: - Properties

    private let engineManager: AudioEngineManager
    private var startSampleTime: AVAudioFramePosition = 0
    private var seekOffset: TimeInterval = 0
    private var isPlaying: Bool = false

    // MARK: - Initialization

    init(engineManager: AudioEngineManager) {
        self.engineManager = engineManager
    }

    // MARK: - Time Tracking

    /// Returns the current playback time in seconds
    var currentTime: TimeInterval {
        guard isPlaying else {
            return seekOffset
        }

        guard let lastRenderTime = engineManager.currentRenderTime(),
              lastRenderTime.isSampleTimeValid else {
            return seekOffset
        }

        let currentSample = lastRenderTime.sampleTime
        let elapsedSamples = currentSample - startSampleTime
        let elapsedTime = TimeConverter.samplesToSeconds(
            elapsedSamples,
            sampleRate: engineManager.sampleRate
        )

        return max(0, elapsedTime + seekOffset)
    }

    // MARK: - Playback Control

    /// Marks playback as started and records the start sample time
    func startPlayback() {
        if let renderTime = engineManager.currentRenderTime() {
            startSampleTime = renderTime.sampleTime
        }
        isPlaying = true
    }

    /// Marks playback as paused
    func pausePlayback() {
        if isPlaying {
            seekOffset = currentTime
        }
        isPlaying = false
    }

    /// Stops playback and resets to beginning
    func stopPlayback() {
        isPlaying = false
        seekOffset = 0
        startSampleTime = 0
    }

    /// Updates the seek offset when seeking to a new time
    /// - Parameter time: The target time in seconds
    func seek(to time: TimeInterval) {
        seekOffset = max(0, time)
        if let renderTime = engineManager.currentRenderTime() {
            startSampleTime = renderTime.sampleTime
        }
    }

    /// Resets the clock completely
    func reset() {
        isPlaying = false
        seekOffset = 0
        startSampleTime = 0
    }
}
