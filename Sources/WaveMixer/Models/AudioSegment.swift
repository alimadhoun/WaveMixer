//
//  AudioSegment.swift
//  WaveMixer
//
//  Created by Ali Madhoun on 22/03/2026.
//

import Foundation

/// Represents a single audio segment within a track.
/// Each segment references an audio file and defines its position in the timeline.
public struct AudioSegment {
    /// The URL to the audio file
    public let fileURL: URL

    /// The start time of this segment in the global timeline (in seconds)
    public let startTime: TimeInterval

    /// The duration of this segment (in seconds)
    public let duration: TimeInterval

    /// End time of this segment in the timeline
    public var endTime: TimeInterval {
        return startTime + duration
    }

    public init(fileURL: URL, startTime: TimeInterval, duration: TimeInterval) {
        self.fileURL = fileURL
        self.startTime = startTime
        self.duration = duration
    }
}
