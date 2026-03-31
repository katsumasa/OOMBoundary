//
//  MetricReporter.swift
//  OOMBoundary
//
//  Created by Katsumasa Kimura on 2026/03/31.
//

import Foundation
import MetricKit
import os.log

final class MetricReporter: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricReporter()

    private let kLastPeakMemoryKey = "LastPeakMemoryFromOS"
    private let kLastOOMDiagnosticKey = "LastOOMDiagnostic"

    private override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }

    // iOS 13+: メトリクスペイロード（過去24時間の集計データ）
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            os_log("Received MetricKit payload for timeRange: %@ to %@",
                   log: .default, type: .info,
                   payload.timeStampBegin.description,
                   payload.timeStampEnd.description)

            if let memoryMetric = payload.memoryMetrics {
                // OSが記録したピークメモリ使用量
                let peakMemoryBytes = memoryMetric.peakMemoryUsage.value
                let peakMemoryMB = Double(peakMemoryBytes) / (1024 * 1024)

                os_log("OS Reported Peak Memory Usage: %.2f MB", log: .default, type: .info, peakMemoryMB)

                // UserDefaultsに保存
                UserDefaults.standard.set(peakMemoryMB, forKey: kLastPeakMemoryKey)
                UserDefaults.standard.synchronize()
            }
        }
    }

    // iOS 14+: 診断ペイロード（クラッシュ・OOMの詳細データ）
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for diagnostic in payloads {
            os_log("Received MetricKit diagnostic payload", log: .default, type: .info)

            // クラッシュ診断
            if let crashDiagnostics = diagnostic.crashDiagnostics {
                for crash in crashDiagnostics {
                    os_log("Crash detected", log: .default, type: .error)

                    // 終了理由を確認
                    if let exceptionInfo = crash.exceptionType,
                       exceptionInfo == 0 {
                        // Code 0 はOOMの可能性がある
                        os_log("Potential OOM termination detected", log: .default, type: .error)

                        // 診断情報を保存
                        let diagnosticInfo: [String: Any] = [
                            "exceptionType": crash.exceptionType ?? -1,
                            "exceptionCode": crash.exceptionCode ?? -1,
                            "signal": crash.signal ?? -1
                        ]

                        if let data = try? JSONSerialization.data(withJSONObject: diagnosticInfo, options: .prettyPrinted),
                           let jsonString = String(data: data, encoding: .utf8) {
                            UserDefaults.standard.set(jsonString, forKey: kLastOOMDiagnosticKey)
                            UserDefaults.standard.synchronize()
                        }
                    }
                }
            }
        }
    }

    func getLastPeakMemory() -> Double? {
        let value = UserDefaults.standard.double(forKey: kLastPeakMemoryKey)
        return value > 0 ? value : nil
    }

    func getLastOOMDiagnostic() -> String? {
        return UserDefaults.standard.string(forKey: kLastOOMDiagnosticKey)
    }
}
