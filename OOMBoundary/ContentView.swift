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

    let raw = withUnsafePointer(to: &systemInfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(cString: $0)
        }
    }

    // シミュレーター実行時は環境変数から実際のデバイス識別子を取得
    if raw == "i386" || raw == "x86_64" || raw == "arm64" {
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? raw
    }

    return raw
}

// デバイスモデル名を取得
func getDeviceModel() -> String {
    let identifier = getDeviceIdentifier()

    let appleDeviceModelMap: [String: String] = [
        // MARK: - iPhone
        "iPhone1,1": "iPhone (1st generation)",
        "iPhone1,2": "iPhone 3G",
        "iPhone2,1": "iPhone 3GS",
        "iPhone3,1": "iPhone 4",
        "iPhone3,2": "iPhone 4",
        "iPhone3,3": "iPhone 4",
        "iPhone4,1": "iPhone 4s",
        "iPhone5,1": "iPhone 5",
        "iPhone5,2": "iPhone 5",
        "iPhone5,3": "iPhone 5c",
        "iPhone5,4": "iPhone 5c",
        "iPhone6,1": "iPhone 5s",
        "iPhone6,2": "iPhone 5s",
        "iPhone7,1": "iPhone 6 Plus",
        "iPhone7,2": "iPhone 6",
        "iPhone8,1": "iPhone 6s",
        "iPhone8,2": "iPhone 6s Plus",
        "iPhone8,4": "iPhone SE (1st generation)",
        "iPhone9,1": "iPhone 7",
        "iPhone9,2": "iPhone 7 Plus",
        "iPhone9,3": "iPhone 7",
        "iPhone9,4": "iPhone 7 Plus",
        "iPhone10,1": "iPhone 8",
        "iPhone10,2": "iPhone 8 Plus",
        "iPhone10,3": "iPhone X",
        "iPhone10,4": "iPhone 8",
        "iPhone10,5": "iPhone 8 Plus",
        "iPhone10,6": "iPhone X",
        "iPhone11,2": "iPhone XS",
        "iPhone11,4": "iPhone XS Max",
        "iPhone11,6": "iPhone XS Max",
        "iPhone11,8": "iPhone XR",
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone12,8": "iPhone SE (2nd generation)",
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        "iPhone14,6": "iPhone SE (3rd generation)",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,5": "iPhone 16e",
        "iPhone18,1": "iPhone 17 Pro",
        "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17",
        "iPhone18,4": "iPhone Air",
        "iPhone18,5": "iPhone 17e",

        // MARK: - iPad
        "iPad2,1": "iPad 2",
        "iPad2,2": "iPad 2",
        "iPad2,3": "iPad 2",
        "iPad2,4": "iPad 2",
        "iPad2,5": "iPad mini",
        "iPad2,6": "iPad mini",
        "iPad2,7": "iPad mini",
        "iPad3,1": "iPad (3rd generation)",
        "iPad3,2": "iPad (3rd generation)",
        "iPad3,3": "iPad (3rd generation)",
        "iPad3,4": "iPad (4th generation)",
        "iPad3,5": "iPad (4th generation)",
        "iPad3,6": "iPad (4th generation)",
        "iPad4,1": "iPad Air",
        "iPad4,2": "iPad Air",
        "iPad4,3": "iPad Air",
        "iPad4,4": "iPad mini 2",
        "iPad4,5": "iPad mini 2",
        "iPad4,6": "iPad mini 2",
        "iPad4,7": "iPad mini 3",
        "iPad4,8": "iPad mini 3",
        "iPad4,9": "iPad mini 3",
        "iPad5,1": "iPad mini 4",
        "iPad5,2": "iPad mini 4",
        "iPad5,3": "iPad Air 2",
        "iPad5,4": "iPad Air 2",
        "iPad6,3": "iPad Pro (9.7-inch)",
        "iPad6,4": "iPad Pro (9.7-inch)",
        "iPad6,7": "iPad Pro (12.9-inch)",
        "iPad6,8": "iPad Pro (12.9-inch)",
        "iPad6,11": "iPad (5th generation)",
        "iPad6,12": "iPad (5th generation)",
        "iPad7,1": "iPad Pro (12.9-inch) (2nd generation)",
        "iPad7,2": "iPad Pro (12.9-inch) (2nd generation)",
        "iPad7,3": "iPad Pro (10.5-inch)",
        "iPad7,4": "iPad Pro (10.5-inch)",
        "iPad7,5": "iPad (6th generation)",
        "iPad7,6": "iPad (6th generation)",
        "iPad7,11": "iPad (7th generation)",
        "iPad7,12": "iPad (7th generation)",
        "iPad8,1": "iPad Pro (11-inch)",
        "iPad8,2": "iPad Pro (11-inch)",
        "iPad8,3": "iPad Pro (11-inch)",
        "iPad8,4": "iPad Pro (11-inch)",
        "iPad8,5": "iPad Pro (12.9-inch) (3rd generation)",
        "iPad8,6": "iPad Pro (12.9-inch) (3rd generation)",
        "iPad8,7": "iPad Pro (12.9-inch) (3rd generation)",
        "iPad8,8": "iPad Pro (12.9-inch) (3rd generation)",
        "iPad8,9": "iPad Pro (11-inch) (2nd generation)",
        "iPad8,10": "iPad Pro (11-inch) (2nd generation)",
        "iPad8,11": "iPad Pro (12.9-inch) (4th generation)",
        "iPad8,12": "iPad Pro (12.9-inch) (4th generation)",
        "iPad11,1": "iPad mini (5th generation)",
        "iPad11,2": "iPad mini (5th generation)",
        "iPad11,3": "iPad Air (3rd generation)",
        "iPad11,4": "iPad Air (3rd generation)",
        "iPad11,6": "iPad (8th generation)",
        "iPad11,7": "iPad (8th generation)",
        "iPad12,1": "iPad (9th generation)",
        "iPad12,2": "iPad (9th generation)",
        "iPad13,1": "iPad Air (4th generation)",
        "iPad13,2": "iPad Air (4th generation)",
        "iPad13,4": "iPad Pro (11-inch) (3rd generation)",
        "iPad13,5": "iPad Pro (11-inch) (3rd generation)",
        "iPad13,6": "iPad Pro (11-inch) (3rd generation)",
        "iPad13,7": "iPad Pro (11-inch) (3rd generation)",
        "iPad13,8": "iPad Pro (12.9-inch) (5th generation)",
        "iPad13,9": "iPad Pro (12.9-inch) (5th generation)",
        "iPad13,10": "iPad Pro (12.9-inch) (5th generation)",
        "iPad13,11": "iPad Pro (12.9-inch) (5th generation)",
        "iPad13,16": "iPad Air (5th generation)",
        "iPad13,17": "iPad Air (5th generation)",
        "iPad13,18": "iPad (10th generation)",
        "iPad13,19": "iPad (10th generation)",
        "iPad14,1": "iPad mini (6th generation)",
        "iPad14,2": "iPad mini (6th generation)",
        "iPad14,3": "iPad Pro (11-inch) (4th generation)",
        "iPad14,4": "iPad Pro (11-inch) (4th generation)",
        "iPad14,5": "iPad Pro (12.9-inch) (6th generation)",
        "iPad14,6": "iPad Pro (12.9-inch) (6th generation)",
        "iPad14,8": "iPad Air (11-inch) (M2)",
        "iPad14,9": "iPad Air (11-inch) (M2)",
        "iPad14,10": "iPad Air (13-inch) (M2)",
        "iPad14,11": "iPad Air (13-inch) (M2)",
        "iPad15,3": "iPad Air (11-inch) (M3)",
        "iPad15,4": "iPad Air (11-inch) (M3)",
        "iPad15,5": "iPad Air (13-inch) (M3)",
        "iPad15,6": "iPad Air (13-inch) (M3)",
        "iPad15,7": "iPad (A16)",
        "iPad15,8": "iPad (A16)",
        "iPad16,1": "iPad mini (A17 Pro)",
        "iPad16,2": "iPad mini (A17 Pro)",
        "iPad16,3": "iPad Pro (11-inch) (M4)",
        "iPad16,4": "iPad Pro (11-inch) (M4)",
        "iPad16,5": "iPad Pro (13-inch) (M4)",
        "iPad16,6": "iPad Pro (13-inch) (M4)",
        "iPad16,8": "iPad Air (11-inch) (M4)",
        "iPad16,9": "iPad Air (11-inch) (M4)",
        "iPad16,10": "iPad Air (13-inch) (M4)",
        "iPad16,11": "iPad Air (13-inch) (M4)",
        "iPad17,1": "iPad Pro (11-inch) (M5)",
        "iPad17,2": "iPad Pro (11-inch) (M5)",
        "iPad17,3": "iPad Pro (13-inch) (M5)",
        "iPad17,4": "iPad Pro (13-inch) (M5)",

        // MARK: - Simulator
        "x86_64": "Simulator (x86_64)",
        "arm64": "Simulator (arm64)"
    ]

    return appleDeviceModelMap[identifier] ?? "Unknown Device (\(identifier))"
}

#Preview {
    ContentView()
}
