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
    @State private var osPeakMemoryMB: Double?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // タイトル
                    Text("Memory Boundary Tester")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    // デバイス情報
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "iphone")
                                .foregroundColor(.blue)
                            Text("Device Information")
                                .font(.headline)
                        }

                        HStack {
                            Text("Model:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(getDeviceModel())
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Identifier:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(getDeviceIdentifier())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        HStack {
                            Text("OS:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)

                // メモリタイプ選択
                VStack(alignment: .leading, spacing: 10) {
                    Text("Memory Type")
                        .font(.headline)

                    Picker("Memory Type", selection: $allocator.memoryType) {
                        ForEach(MemoryType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(allocator.isRunning)

                    Text(allocator.memoryType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // 説明
                    if allocator.memoryType == .dirty {
                        Label("Random data prevents memory compression", systemImage: "shuffle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Label("Zero data may be compressed by iOS", systemImage: "arrow.down.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)

                // 前回のセッション結果（OOMが発生していた場合）
                if allocator.hasPreviousResults {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("📊 Previous Session Results")
                            .font(.headline)
                            .foregroundColor(.purple)

                        MemoryInfoRow(
                            title: "Max Memory Reached (App)",
                            value: String(format: "%.0f MB", allocator.previousSessionMaxMB),
                            color: .red
                        )

                        if let osPeak = osPeakMemoryMB {
                            MemoryInfoRow(
                                title: "Peak Memory (OS Report)",
                                value: String(format: "%.0f MB", osPeak),
                                color: .blue
                            )

                            let difference = abs(allocator.previousSessionMaxMB - osPeak)
                            let accuracy = 100.0 - (difference / osPeak * 100.0)

                            Text(String(format: "Accuracy: %.1f%%", accuracy))
                                .font(.caption)
                                .foregroundColor(accuracy > 95 ? .green : .orange)
                        }

                        if allocator.memoryWarningThresholdMB > 0 {
                            MemoryInfoRow(
                                title: "Warning Threshold",
                                value: String(format: "%.0f MB", allocator.memoryWarningThresholdMB),
                                color: .orange
                            )
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(15)
                }

                // メモリ情報表示
                VStack(spacing: 15) {
                    MemoryInfoRow(
                        title: "Allocated Memory",
                        value: String(format: "%.0f MB", allocator.allocatedMemoryMB),
                        color: .blue
                    )

                    MemoryInfoRow(
                        title: "Memory Footprint",
                        value: String(format: "%.0f MB", allocator.memoryDetails.footprintMB),
                        color: .purple
                    )

                    MemoryInfoRow(
                        title: "Available Memory",
                        value: String(format: "%.0f MB", allocator.memoryDetails.availableMemoryMB),
                        color: .green
                    )

                    MemoryInfoRow(
                        title: "Absolute Limit",
                        value: String(format: "%.0f MB", allocator.memoryDetails.absoluteLimitMB),
                        color: .red
                    )

                    if allocator.hasEncounteredOOM {
                        Text("⚠️ Memory Warning Received!")
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
                // MetricKitからOSのピークメモリを取得
                osPeakMemoryMB = MetricReporter.shared.getLastPeakMemory()

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

// デバイス識別子を取得
func getDeviceIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
}

// デバイスモデル名を取得
func getDeviceModel() -> String {
    let identifier = getDeviceIdentifier()

    // 識別子をわかりやすい名前にマッピング
    let modelMap: [String: String] = [
        // iPhone 17シリーズ（仮想マッピング - 実際のデバイスが出たら更新が必要）
        "iPhone18,1": "iPhone 17",
        "iPhone18,2": "iPhone 17 Plus",
        "iPhone18,3": "iPhone 17 Pro",
        "iPhone18,4": "iPhone 17 Pro Max",

        // iPhone 16シリーズ
        "iPhone17,3": "iPhone 16 Pro",
        "iPhone17,4": "iPhone 16 Pro Max",
        "iPhone17,1": "iPhone 16",
        "iPhone17,2": "iPhone 16 Plus",

        // iPhone 15シリーズ
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone15,4": "iPhone 15",

        // iPhone 14シリーズ
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone14,7": "iPhone 14",

        // iPhone 13シリーズ
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,5": "iPhone 13",
        "iPhone14,4": "iPhone 13 mini",

        // Simulator
        "x86_64": "Simulator (x86_64)",
        "arm64": "Simulator (arm64)"
    ]

    return modelMap[identifier] ?? "Unknown Device (\(identifier))"
}

#Preview {
    ContentView()
}
