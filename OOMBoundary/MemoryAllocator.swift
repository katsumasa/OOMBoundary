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

struct MemoryDetails {
    var footprintMB: Double = 0
    var cleanMB: Double = 0
    var dirtyMB: Double = 0
    var compressedMB: Double = 0
    var totalMB: Double = 0
}

class MemoryAllocator: ObservableObject {
    @Published var allocatedMemoryMB: Double = 0
    @Published var maxAllocatedMemoryMB: Double = 0
    @Published var isRunning: Bool = false
    @Published var hasEncounteredOOM: Bool = false
    @Published var statusMessage: String = "Ready"
    @Published var memoryDetails: MemoryDetails = MemoryDetails()

    private var memoryChunks: [[UInt8]] = []
    private var timer: Timer?
    private let chunkSizeMB: Int = 10 // 10MBずつ確保
    private var memoryWarningObserver: NSObjectProtocol?

    init() {
        // 初期メモリ情報を取得
        memoryDetails = getDetailedMemoryInfo()
    }

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
        DispatchQueue.global(qos: .background).async { [weak self] in
            autoreleasepool {
                _ = 0
            }
            // メモリ情報を更新
            DispatchQueue.main.async {
                self?.memoryDetails = self?.getDetailedMemoryInfo() ?? MemoryDetails()
            }
        }
    }

    func updateMemoryInfo() {
        memoryDetails = getDetailedMemoryInfo()
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

        // メモリ詳細情報を更新
        memoryDetails = getDetailedMemoryInfo()

        os_log("Allocated: %.2f MB", log: .default, type: .info, allocatedMemoryMB)

        statusMessage = String(format: "Allocated: %.0f MB\nFootprint: %.0f MB",
                             allocatedMemoryMB,
                             memoryDetails.footprintMB)
    }

    private func getDetailedMemoryInfo() -> MemoryDetails {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size) / 4

        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(TASK_VM_INFO),
                         $0,
                         &count)
            }
        }

        guard kerr == KERN_SUCCESS else {
            return MemoryDetails()
        }

        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024)

        // Memory Footprint (phys_footprint) - アプリが実際に使用しているメモリ
        let footprintMB = Double(info.phys_footprint) / (1024 * 1024)

        // Internal memory (internal) - Dirty + Compressed
        let internalMB = Double(info.internal) / (1024 * 1024)

        // Compressed memory
        let compressedMB = Double(info.compressed) / (1024 * 1024)

        // External memory (external) - Clean memory
        let cleanMB = Double(info.external) / (1024 * 1024)

        // Dirty memory = Internal - Compressed
        let dirtyMB = internalMB - compressedMB

        return MemoryDetails(
            footprintMB: footprintMB,
            cleanMB: cleanMB,
            dirtyMB: max(0, dirtyMB),
            compressedMB: compressedMB,
            totalMB: totalMemory
        )
    }
}
