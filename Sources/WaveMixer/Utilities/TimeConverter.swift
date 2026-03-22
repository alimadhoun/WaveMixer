//
//  TimeConverter.swift
//  WaveMixer
//
//  Created by Ali Madhoun on 22/03/2026.
//

import Foundation
import AVFoundation

/// Utility for converting between sample frames and time intervals
internal struct TimeConverter {

    /// Convert samples to seconds
    /// - Parameters:
    ///   - samples: Number of sample frames
    ///   - sampleRate: Sample rate in Hz
    /// - Returns: Time in seconds
    static func samplesToSeconds(_ samples: AVAudioFramePosition, sampleRate: Double) -> TimeInterval {
        guard sampleRate > 0 else { return 0 }
        return TimeInterval(samples) / sampleRate
    }

    /// Convert seconds to samples
    /// - Parameters:
    ///   - seconds: Time in seconds
    ///   - sampleRate: Sample rate in Hz
    /// - Returns: Number of sample frames
    static func secondsToSamples(_ seconds: TimeInterval, sampleRate: Double) -> AVAudioFramePosition {
        guard seconds >= 0 else { return 0 }
        return AVAudioFramePosition(seconds * sampleRate)
    }

    /// Convert seconds to frame count (for scheduling)
    /// - Parameters:
    ///   - seconds: Duration in seconds
    ///   - sampleRate: Sample rate in Hz
    /// - Returns: Number of frames
    static func secondsToFrameCount(_ seconds: TimeInterval, sampleRate: Double) -> AVAudioFrameCount {
        guard seconds >= 0 else { return 0 }
        return AVAudioFrameCount(seconds * sampleRate)
    }
}
