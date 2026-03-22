//
//  Track.swift
//  WaveMixer
//
//  Created by Ali Madhoun on 22/03/2026.
//

import Foundation
import AVFoundation

/// Represents a single audio track containing one or more segments.
/// Each track has its own player node and mixer node for independent control.
public final class Track {
    /// Unique identifier for this track
    public let id: UUID

    /// Audio segments in this track, sorted by startTime
    public var segments: [AudioSegment] {
        didSet {
            segments.sort { $0.startTime < $1.startTime }
        }
    }

    /// The player node responsible for playing audio
    internal let playerNode: AVAudioPlayerNode

    /// The mixer node for volume control
    internal let mixerNode: AVAudioMixerNode

    /// Volume level (0.0 to 1.0)
    public var volume: Float {
        get { mixerNode.outputVolume }
        set { mixerNode.outputVolume = max(0.0, min(1.0, newValue)) }
    }

    public init(id: UUID = UUID(), segments: [AudioSegment] = []) {
        self.id = id
        self.segments = segments.sorted { $0.startTime < $1.startTime }
        self.playerNode = AVAudioPlayerNode()
        self.mixerNode = AVAudioMixerNode()
    }

    /// Returns the total duration of this track
    public var duration: TimeInterval {
        return segments.map { $0.endTime }.max() ?? 0
    }
}
