//
//  AudioEngineManager.swift
//  WaveMixer
//
//  Created by Ali Madhoun on 22/03/2026.
//

import Foundation
import AVFoundation

/// Manages the AVAudioEngine instance and all audio nodes.
/// Responsible for attaching tracks, connecting nodes, and engine lifecycle.
internal final class AudioEngineManager {

    // MARK: - Properties

    private let engine: AVAudioEngine
    private let mainMixer: AVAudioMixerNode
    private var attachedTracks: Set<UUID> = []

    /// The sample rate of the engine's output format
    var sampleRate: Double {
        return engine.outputNode.outputFormat(forBus: 0).sampleRate
    }

    /// Returns the engine's output node format
    var outputFormat: AVAudioFormat {
        return engine.outputNode.outputFormat(forBus: 0)
    }

    // MARK: - Initialization

    init() {
        self.engine = AVAudioEngine()
        self.mainMixer = engine.mainMixerNode
    }

    // MARK: - Engine Lifecycle

    /// Starts the audio engine
    func start() throws {
        if !engine.isRunning {
            try engine.start()
        }
    }

    /// Stops the audio engine
    func stop() {
        if engine.isRunning {
            engine.stop()
        }
    }

    /// Pauses the audio engine
    func pause() {
        engine.pause()
    }

    /// Resets the engine
    func reset() {
        engine.reset()
        attachedTracks.removeAll()
    }

    // MARK: - Track Management

    /// Attaches and connects a track to the engine
    /// - Parameter track: The track to attach
    func attachTrack(_ track: Track) {
        guard !attachedTracks.contains(track.id) else { return }

        // Attach nodes
        engine.attach(track.playerNode)
        engine.attach(track.mixerNode)

        // Get the format from the main mixer
        let format = mainMixer.outputFormat(forBus: 0)

        // Connect: PlayerNode → MixerNode → MainMixer
        engine.connect(track.playerNode, to: track.mixerNode, format: format)
        engine.connect(track.mixerNode, to: mainMixer, format: format)

        attachedTracks.insert(track.id)
    }

    /// Detaches a track from the engine
    /// - Parameter track: The track to detach
    func detachTrack(_ track: Track) {
        guard attachedTracks.contains(track.id) else { return }

        track.playerNode.stop()
        engine.disconnectNodeOutput(track.playerNode)
        engine.disconnectNodeOutput(track.mixerNode)
        engine.detach(track.playerNode)
        engine.detach(track.mixerNode)

        attachedTracks.remove(track.id)
    }

    /// Returns the current render time from the engine
    func currentRenderTime() -> AVAudioTime? {
        return engine.mainMixerNode.lastRenderTime
    }
}
