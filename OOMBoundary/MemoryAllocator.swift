//
//  MemoryAllocator.swift
//  OOMBoundary
//
//  Created by Katsumasa Kimura on 2026/03/31.
//

import Foundation
import Combine
import UIKit
import os.log

class MemoryAllocator: ObservableObject {
    @Published var allocatedMemoryMB: Double = 0
    @Published var maxAllocatedMemoryMB: Double = 0
    @Published var isRunning: Bool = false
    @Published var hasEncounteredOOM: Bool = false
    @Published var statusMessage: String = "Ready"

    private var memoryChunks: [[UInt8]] = []
    private var timer: Timer?
    private let chunkSizeMB: Int = 10 // 10MBずつ確保
    private var memoryWarningObserver: NSObjectProtocol?

    func startAllocation() {
        guard !isRunning else { return }

        isRunning = true
        hasEncounteredOOM = false
        statusMessage = "Allocating memory..."

        // メモリ警告を監視
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.allocateMemoryChunk()
        }
    }

    func stopAllocation() {
        timer?.invalidate()
        timer = nil
        isRunning = false

        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
            memoryWarningObserver = nil
        }

        statusMessage = hasEncounteredOOM ? "OOM Encountered" : "Stopped"
    }

    private func handleMemoryWarning() {
        hasEncounteredOOM = true
        stopAllocation()
        statusMessage = String(format: "Memory Warning at %.0f MB\nMax: %.0f MB",
                             allocatedMemoryMB,
                             maxAllocatedMemoryMB)
        os_log("Memory warning at %.2f MB", log: .default, type: .error, allocatedMemoryMB)
    }

    func reset() {
        stopAllocation()
        memoryChunks.removeAll()
        allocatedMemoryMB = 0
        maxAllocatedMemoryMB = 0
        hasEncounteredOOM = false
        statusMessage = "Reset complete"

        // メモリ解放を強制
        DispatchQueue.global(qos: .background).async {
            autoreleasepool {
                _ = 0
            }
        }
    }

    private func allocateMemoryChunk() {
        let chunkSize = chunkSizeMB * 1024 * 1024 // バイト単位

        // メモリチャンクを確保
        let chunk = [UInt8](repeating: 0, count: chunkSize)
        memoryChunks.append(chunk)

        // 確保済みメモリ量を更新
        allocatedMemoryMB = Double(memoryChunks.count * chunkSizeMB)

        if allocatedMemoryMB > maxAllocatedMemoryMB {
            maxAllocatedMemoryMB = allocatedMemoryMB
        }

        os_log("Allocated: %.2f MB", log: .default, type: .info, allocatedMemoryMB)

        // システムメモリ情報を取得
        let memoryInfo = getMemoryInfo()
        statusMessage = String(format: "Allocated: %.0f MB\nUsed: %.0f MB / %.0f MB",
                             allocatedMemoryMB,
                             memoryInfo.used,
                             memoryInfo.total)
    }

    private func getMemoryInfo() -> (used: Double, total: Double) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / (1024 * 1024)

            // デバイスの総メモリを取得
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024)

            return (used: usedMB, total: totalMemory)
        }

        return (used: 0, total: 0)
    }
}
