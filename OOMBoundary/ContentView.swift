//
//  ContentView.swift
//  OOMBoundary
//
//  Created by Katsumasa Kimura on 2026/03/31.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var allocator = MemoryAllocator()
    @State private var updateTimer: Timer?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // タイトル
                    Text("Memory Boundary Tester")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

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

                    MemoryInfoRow(
                        title: "Memory Footprint",
                        value: String(format: "%.0f MB", allocator.memoryDetails.footprintMB),
                        color: .purple
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

                // メモリタイプ別表示
                VStack(alignment: .leading, spacing: 10) {
                    Text("Memory Breakdown")
                        .font(.headline)
                        .padding(.bottom, 5)

                    MemoryBar(
                        title: "Clean",
                        value: allocator.memoryDetails.cleanMB,
                        total: allocator.memoryDetails.footprintMB,
                        color: .green
                    )

                    MemoryBar(
                        title: "Dirty",
                        value: allocator.memoryDetails.dirtyMB,
                        total: allocator.memoryDetails.footprintMB,
                        color: .orange
                    )

                    MemoryBar(
                        title: "Compressed",
                        value: allocator.memoryDetails.compressedMB,
                        total: allocator.memoryDetails.footprintMB,
                        color: .blue
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)

                // ステータスメッセージ
                Text(allocator.statusMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(minHeight: 60)

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
                .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 定期的にメモリ情報を更新
                updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    if !allocator.isRunning {
                        allocator.updateMemoryInfo()
                    }
                }
            }
            .onDisappear {
                updateTimer?.invalidate()
                updateTimer = nil
            }
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

struct MemoryBar: View {
    let title: String
    let value: Double
    let total: Double
    let color: Color

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return min(value / total, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f MB (%.1f%%)", value, percentage * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .cornerRadius(10)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 20)
                        .cornerRadius(10)
                }
            }
            .frame(height: 20)
        }
    }
}

#Preview {
    ContentView()
}
