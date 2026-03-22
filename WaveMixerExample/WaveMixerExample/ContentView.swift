//
//  ContentView.swift
//  WaveMixerExample
//
//  Created by Ali Madhoun on 22/03/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PlayerViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Timeline Section
                VStack(spacing: 12) {
                    // Time labels
                    HStack {
                        Text(viewModel.formatTime(viewModel.currentTime))
                            .font(.system(.caption, design: .monospaced))

                        Spacer()

                        Text(viewModel.formatTime(viewModel.duration))
                            .font(.system(.caption, design: .monospaced))
                    }
                    .foregroundColor(.secondary)

                    // Seek slider
                    Slider(
                        value: Binding(
                            get: { viewModel.currentTime },
                            set: { viewModel.seek(to: $0) }
                        ),
                        in: 0...max(viewModel.duration, 1)
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Playback Controls
                HStack(spacing: 30) {
                    Button(action: { viewModel.skipBackward() }) {
                        Image(systemName: "gobackward.10")
                            .font(.title2)
                    }

                    Button(action: { viewModel.isPlaying ? viewModel.pause() : viewModel.play() }) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                    }

                    Button(action: { viewModel.skipForward() }) {
                        Image(systemName: "goforward.10")
                            .font(.title2)
                    }
                }
                .padding()

                Button(action: { viewModel.stop() }) {
                    Label("Stop", systemImage: "stop.fill")
                        .foregroundColor(.red)
                }

                Divider()

                // Tracks List
                if viewModel.tracks.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()

                        Text("Loading tracks...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.tracks) { track in
                                TrackRow(
                                    trackInfo: track,
                                    onVolumeChange: { volume in
                                        viewModel.setVolume(volume, for: track.id)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding()
            .navigationTitle("Multi-Track Player")
        }
    }
}

struct TrackRow: View {
    let trackInfo: PlayerViewModel.TrackInfo
    let onVolumeChange: (Float) -> Void

    @State private var volume: Float

    init(trackInfo: PlayerViewModel.TrackInfo, onVolumeChange: @escaping (Float) -> Void) {
        self.trackInfo = trackInfo
        self.onVolumeChange = onVolumeChange
        self._volume = State(initialValue: trackInfo.volume)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trackInfo.name)
                .font(.headline)
                .lineLimit(1)

            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.secondary)

                Slider(
                    value: $volume,
                    in: 0...1,
                    onEditingChanged: { editing in
                        if !editing {
                            onVolumeChange(volume)
                        }
                    }
                )

                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
