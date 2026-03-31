//
//  ContentView.swift
//  OOMBoundary
//
//  Created by Katsumasa Kimura on 2026/03/31.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var allocator = MemoryAllocator()

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // タイトル
                Text("Memory Boundary Tester")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                // メモリ情報表示
                VStack(spacing: 15) {
                    MemoryInfoRow(
                        title: "Allocated Memory",
                        value: String(format: "%.0f MB", allocator.allocatedMemoryMB),
                        color: .blue
                    )

                    MemoryInfoRow(
                        title: "Max Memory",
                        value: String(format: "%.0f MB", allocator.maxAllocatedMemoryMB),
                        color: .green
                    )

                    if allocator.hasEncounteredOOM {
                        Text("OOM Encountered!")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)

                // ステータスメッセージ
                Text(allocator.statusMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(height: 60)

                Spacer()

                // コントロールボタン
                VStack(spacing: 15) {
                    if !allocator.isRunning {
                        Button(action: {
                            allocator.startAllocation()
                        }) {
                            Label("Start Allocation", systemImage: "play.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            allocator.stopAllocation()
                        }) {
                            Label("Stop Allocation", systemImage: "stop.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }

                    Button(action: {
                        allocator.reset()
                    }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(allocator.isRunning)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MemoryInfoRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    ContentView()
}
