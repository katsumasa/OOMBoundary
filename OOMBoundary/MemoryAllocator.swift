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
    var availableMemoryMB: Double = 0
    var absoluteLimitMB: Double = 0
}

class MemoryAllocator: ObservableObject {
    @Published var allocatedMemoryMB: Double = 0
    @Published var maxAllocatedMemoryMB: Double = 0
    @Published var isRunning: Bool = false
    @Published var hasEncounteredOOM: Bool = false
    @Published var statusMessage: String = "Ready"
    @Published var memoryDetails: MemoryDetails = MemoryDetails()
    @Published var memoryWarningThresholdMB: Double = 0
    @Published var previousSessionMaxMB: Double = 0
    @Published var hasPreviousResults: Bool = false

    private var allocatedPointers: [UnsafeMutableRawPointer] = []
    private var timer: Timer?
    private let chunkSizeMB: Int = 10 // 10MBずつ確保
    private let pageSize: Int = 16384 // 16KB - iOSのページサイズ
    private var memoryWarningObserver: NSObjectProtocol?

    private let kLastFootprintKey = "LastMemoryFootprint"
    private let kLastAbsoluteLimitKey = "LastAbsoluteLimit"
    private let kMemoryWarningThresholdKey = "MemoryWarningThreshold"
    private let kMeasurementInProgressKey = "MeasurementInProgress"

    init() {
        // 初期メモリ情報を取得
        memoryDetails = getDetailedMemoryInfo()

        // 前回のセッション結果を確認
        loadPreviousResults()
    }

    func startAllocation() {
        guard !isRunning else { return }

        isRunning = true
        hasEncounteredOOM = false
        statusMessage = "Allocating memory..."

        // 計測開始フラグを保存
        UserDefaults.standard.set(true, forKey: kMeasurementInProgressKey)
        UserDefaults.standard.synchronize()

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

        // 計測終了フラグをクリア
        UserDefaults.standard.removeObject(forKey: kMeasurementInProgressKey)
        UserDefaults.standard.synchronize()

        statusMessage = hasEncounteredOOM ? "OOM Encountered" : "Stopped"
    }

    private func handleMemoryWarning() {
        // メモリ警告時の閾値を記録
        let currentFootprint = getPhysicalFootprint()
        let warningThreshold = Double(currentFootprint) / (1024 * 1024)
        memoryWarningThresholdMB = warningThreshold

        UserDefaults.standard.set(warningThreshold, forKey: kMemoryWarningThresholdKey)
        UserDefaults.standard.synchronize()

        hasEncounteredOOM = true

        os_log("Memory warning at %.2f MB", log: .default, type: .error, warningThreshold)

        statusMessage = String(format: "Memory Warning at %.0f MB\nAbsolute Limit: %.0f MB",
                             warningThreshold,
                             memoryDetails.absoluteLimitMB)
    }

    func reset() {
        stopAllocation()

        // すべてのポインタを解放
        for pointer in allocatedPointers {
            pointer.deallocate()
        }
        allocatedPointers.removeAll()

        allocatedMemoryMB = 0
        maxAllocatedMemoryMB = 0
        hasEncounteredOOM = false
        memoryWarningThresholdMB = 0
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

    private func allocateMemoryChunk() {
        let chunkSizeBytes = chunkSizeMB * 1024 * 1024

        // 低レベルなメモリアロケーション
        let alignment = MemoryLayout<UInt8>.alignment
        let pointer = UnsafeMutableRawPointer.allocate(
            byteCount: chunkSizeBytes,
            alignment: alignment
        )

        // ランダムデータで埋めてDirty化（メモリ圧縮を回避）
        let typedPointer = pointer.bindMemory(to: UInt8.self, capacity: chunkSizeBytes)

        // 各16KBページにランダムデータを書き込んでDirty化
        for offset in stride(from: 0, to: chunkSizeBytes, by: pageSize) {
            typedPointer[offset] = UInt8.random(in: 0...255)
        }

        // ポインタを保持（解放されないように）
        allocatedPointers.append(pointer)

        // 確保済みメモリ量を更新
        allocatedMemoryMB = Double(allocatedPointers.count * chunkSizeMB)

        if allocatedMemoryMB > maxAllocatedMemoryMB {
            maxAllocatedMemoryMB = allocatedMemoryMB
        }

        // メモリ詳細情報を更新
        memoryDetails = getDetailedMemoryInfo()

        // データを永続化（OOMクラッシュに備える）
        persistCurrentState()

        os_log("Allocated: %.2f MB, Footprint: %.2f MB, Available: %.2f MB, Limit: %.2f MB",
               log: .default, type: .info,
               allocatedMemoryMB,
               memoryDetails.footprintMB,
               memoryDetails.availableMemoryMB,
               memoryDetails.absoluteLimitMB)

        statusMessage = String(format: "Allocated: %.0f MB\nFootprint: %.0f MB / %.0f MB\nAvailable: %.0f MB",
                             allocatedMemoryMB,
                             memoryDetails.footprintMB,
                             memoryDetails.absoluteLimitMB,
                             memoryDetails.availableMemoryMB)

        // 限界の95%に達したら警告
        if memoryDetails.availableMemoryMB < memoryDetails.absoluteLimitMB * 0.05 {
            statusMessage += "\n⚠️ Approaching Memory Limit!"
        }
    }

    private func persistCurrentState() {
        UserDefaults.standard.set(memoryDetails.footprintMB, forKey: kLastFootprintKey)
        UserDefaults.standard.set(memoryDetails.absoluteLimitMB, forKey: kLastAbsoluteLimitKey)
        UserDefaults.standard.synchronize()
    }

    private func loadPreviousResults() {
        let wasInProgress = UserDefaults.standard.bool(forKey: kMeasurementInProgressKey)

        if wasInProgress {
            // 前回のセッションでOOMが発生した
            hasPreviousResults = true
            previousSessionMaxMB = UserDefaults.standard.double(forKey: kLastFootprintKey)
            memoryWarningThresholdMB = UserDefaults.standard.double(forKey: kMemoryWarningThresholdKey)

            // フラグをクリア
            UserDefaults.standard.removeObject(forKey: kMeasurementInProgressKey)
            UserDefaults.standard.synchronize()

            statusMessage = String(format: "Previous Session:\nMax Memory: %.0f MB\nWarning Threshold: %.0f MB",
                                 previousSessionMaxMB,
                                 memoryWarningThresholdMB)
        }
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

        // os_proc_available_memory()を使用して残存メモリを取得
        let availableBytes = os_proc_available_memory()
        let availableMB = Double(availableBytes) / (1024 * 1024)

        // デバッグ: 値を確認
        if availableBytes == 0 {
            os_log("WARNING: os_proc_available_memory() returned 0!", log: .default, type: .error)
        } else {
            os_log("os_proc_available_memory() = %llu bytes (%.2f MB)",
                   log: .default, type: .info, availableBytes, availableMB)
        }

        // 絶対的限界 = 現在のフットプリント + 利用可能メモリ
        let absoluteLimitMB = footprintMB + availableMB

        return MemoryDetails(
            footprintMB: footprintMB,
            cleanMB: cleanMB,
            dirtyMB: max(0, dirtyMB),
            compressedMB: compressedMB,
            totalMB: totalMemory,
            availableMemoryMB: availableMB,
            absoluteLimitMB: absoluteLimitMB
        )
    }

    private func getPhysicalFootprint() -> UInt64 {
        let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(MemoryLayout.offset(of: \task_vm_info_data_t.min_address)! / MemoryLayout<integer_t>.size)

        var info = task_vm_info_data_t()
        var count = TASK_VM_INFO_COUNT

        let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }

        guard kr == KERN_SUCCESS, count >= TASK_VM_INFO_REV1_COUNT else {
            return 0
        }

        return info.phys_footprint
    }

    func updateMemoryInfo() {
        memoryDetails = getDetailedMemoryInfo()
    }
}
