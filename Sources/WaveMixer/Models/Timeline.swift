//
//  Timeline.swift
//  WaveMixer
//
//  Created by Ali Madhoun on 22/03/2026.
//

import Foundation

/// Represents the global timeline for multi-track playback.
/// All tracks follow this shared timeline.
public struct Timeline {
    /// Total duration of the timeline (in seconds)
    public let duration: TimeInterval

    public init(duration: TimeInterval) {
        self.duration = duration
    }
}
