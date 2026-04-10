//
//  MemoryIntegrityChecker.swift
//  OOMBoundary
//
//  Created by Katsumasa Kimura on 2026/04/10.
//

import Foundation
import Security
import Darwin
import UIKit

// Code Signing Operations
private let CS_OPS_STATUS: UInt32 = 0

// Code Signing Flags
private let CS_HARD: UInt32 = 0x00000100         // Hardened Runtime
private let CS_RUNTIME: UInt32 = 0x00010000      // Runtime flag
private let CS_ENFORCEMENT: UInt32 = 0x00001000  // Enforcement enabled
private let CS_RESTRICT: UInt32 = 0x00000800     // Restrictions enabled
private let CS_REQUIRE_LV: UInt32 = 0x00000080   // Library validation required
private let CS_EXEC_SET_HARD: UInt32 = 0x00000200 // Exec segment validation

// Memory Integrity Enforcement Mode (iOS 18+)
// Note: These values are determined from actual runtime observation on iOS 26.4
private let CS_MEMINT_ENABLED: UInt32 = 0x20000000  // Memory integrity enforcement enabled (observed on iOS 26.4)
// Original guessed values (not observed in practice):
// private let CS_MEMINT_FULL: UInt32 = 0x80000000  // Full memory integrity enforcement (guessed)
// private let CS_MEMINT_SOFT: UInt32 = 0x40000000  // Soft memory integrity enforcement (guessed)

// Memory Integrity Enforcement Mode
enum MemoryIntegrityEnforcementMode {
    case full       // Full protection mode (iOS 18+)
    case soft       // Soft protection mode (default)
    case unknown    // Cannot determine or not supported

    var description: String {
        switch self {
        case .full: return "Full Mode"
        case .soft: return "Soft Mode"
        case .unknown: return "Unknown"
        }
    }

    var detailDescription: String {
        switch self {
        case .full: return "Complete memory integrity enforcement enabled"
        case .soft: return "Basic memory protection (default)"
        case .unknown: return "Mode detection not available"
        }
    }
}

struct MemoryIntegrityStatus {
    let hasHardenedRuntime: Bool
    let hasRuntimeFlag: Bool
    let hasEnforcement: Bool
    let hasRestrict: Bool
    let hasLibraryValidation: Bool
    let hasExecValidation: Bool
    let wxProtectionActive: Bool
    let hasPACSupport: Bool
    let enforcementMode: MemoryIntegrityEnforcementMode
    let codeSigningFlags: UInt32
    let entitlements: [String: Any]?

    var isFullyProtected: Bool {
        return hasHardenedRuntime && hasEnforcement && wxProtectionActive && enforcementMode == .full
    }
}

final class MemoryIntegrityChecker {
    static let shared = MemoryIntegrityChecker()

    private init() {}

    // メモリインテグリティの全体チェック
    func checkMemoryIntegrity() -> MemoryIntegrityStatus {
        #if DEBUG
        print("🔍 === Memory Integrity Check ===")
        print("📱 Device: \(UIDevice.current.model)")
        print("📱 iOS Version: \(UIDevice.current.systemVersion)")
        #endif

        let codeSigningFlags = getCodeSigningFlags()
        let wxActive = testWXProtection()
        let pacSupported = checkPACSupport()

        #if DEBUG
        // Check if app is properly signed
        print("🔏 Code Signing Status:")
        print("   Hardened Runtime: \((codeSigningFlags & CS_HARD) != 0)")
        print("   Runtime Flag: \((codeSigningFlags & CS_RUNTIME) != 0)")
        print("   Enforcement: \((codeSigningFlags & CS_ENFORCEMENT) != 0)")
        print("   W^X Protection: \(wxActive)")
        print("   PAC Support: \(pacSupported)")
        #endif

        let enforcementMode = detectEnforcementMode(flags: codeSigningFlags)
        let entitlements = getEntitlements()

        #if DEBUG
        print("🔍 === End Memory Integrity Check ===\n")
        #endif

        return MemoryIntegrityStatus(
            hasHardenedRuntime: (codeSigningFlags & CS_HARD) != 0,
            hasRuntimeFlag: (codeSigningFlags & CS_RUNTIME) != 0,
            hasEnforcement: (codeSigningFlags & CS_ENFORCEMENT) != 0,
            hasRestrict: (codeSigningFlags & CS_RESTRICT) != 0,
            hasLibraryValidation: (codeSigningFlags & CS_REQUIRE_LV) != 0,
            hasExecValidation: (codeSigningFlags & CS_EXEC_SET_HARD) != 0,
            wxProtectionActive: wxActive,
            hasPACSupport: pacSupported,
            enforcementMode: enforcementMode,
            codeSigningFlags: codeSigningFlags,
            entitlements: entitlements
        )
    }

    // Code Signing Flagsを取得
    private func getCodeSigningFlags() -> UInt32 {
        var flags: UInt32 = 0
        let result = withUnsafeMutablePointer(to: &flags) { pointer in
            csops(getpid(), UInt32(CS_OPS_STATUS), pointer, MemoryLayout<UInt32>.size)
        }

        if result == 0 {
            #if DEBUG
            // デバッグ: 実際のフラグ値を出力
            print("🔍 Code Signing Flags: 0x\(String(flags, radix: 16, uppercase: true))")
            print("   CS_HARD (0x100): \((flags & CS_HARD) != 0)")
            print("   CS_RUNTIME (0x10000): \((flags & CS_RUNTIME) != 0)")
            print("   CS_ENFORCEMENT (0x1000): \((flags & CS_ENFORCEMENT) != 0)")
            print("   CS_MEMINT_ENABLED (0x20000000): \((flags & CS_MEMINT_ENABLED) != 0)")

            // Additional flags observed in the actual value (0x32003005)
            print("   Unknown flags:")
            print("     0x1: \((flags & 0x1) != 0)")
            print("     0x4: \((flags & 0x4) != 0)")
            print("     0x20000: \((flags & 0x20000) != 0)")
            print("     0x2000000: \((flags & 0x2000000) != 0)")
            print("     0x10000000: \((flags & 0x10000000) != 0)")
            #endif
            return flags
        }

        return 0
    }

    // W^X (Write XOR Execute) 保護が有効かテスト
    private func testWXProtection() -> Bool {
        let pageSize = vm_page_size
        var addr: vm_address_t = 0

        // 書き込み可能なメモリを確保
        let allocResult = vm_allocate(mach_task_self_, &addr, pageSize, VM_FLAGS_ANYWHERE)

        guard allocResult == KERN_SUCCESS else {
            return false
        }

        defer {
            vm_deallocate(mach_task_self_, addr, pageSize)
        }

        // 書き込み + 実行の両方を同時に設定しようとする（W^Xが有効なら失敗するはず）
        let protectResult = vm_protect(
            mach_task_self_,
            addr,
            pageSize,
            0,
            VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE
        )

        // 失敗すればW^Xが有効
        return protectResult != KERN_SUCCESS
    }

    // PAC (Pointer Authentication Code) サポートの確認
    private func checkPACSupport() -> Bool {
        #if arch(arm64e)
        return true
        #else
        // arm64eアーキテクチャでなければ、プロセッサをチェック
        var size = 0
        sysctlbyname("hw.optional.arm.FEAT_PAuth", nil, &size, nil, 0)

        if size > 0 {
            var value: Int32 = 0
            sysctlbyname("hw.optional.arm.FEAT_PAuth", &value, &size, nil, 0)
            return value != 0
        }

        return false
        #endif
    }

    // Entitlementsを取得
    // Note: iOS doesn't provide API to read entitlements at runtime
    // This is a security feature to prevent malicious code from reading app permissions
    private func getEntitlements() -> [String: Any]? {
        // iOS does not allow reading entitlements at runtime for security reasons
        // Return nil as this information is only available during build/signing
        return nil
    }

    // Memory Integrity Enforcement Mode を検出
    private func detectEnforcementMode(flags: UInt32) -> MemoryIntegrityEnforcementMode {
        #if DEBUG
        print("🔍 Detecting Enforcement Mode...")
        #endif

        // 方法1: ビルド時に生成された定数をチェック（最も確実）
        // BuildModeDetector uses GENERATED_BUILD_MODE from BuildModeGenerated.swift
        let buildMode = BuildModeDetector.detectMode()
        #if DEBUG
        print("   Build Mode from BuildModeDetector: \(buildMode)")
        #endif
        if buildMode.contains("Full Mode") {
            #if DEBUG
            print("   ✅ Detected Full Mode from build configuration")
            #endif
            return .full
        } else if buildMode.contains("Soft Mode") {
            #if DEBUG
            print("   ⚠️ Detected Soft Mode from build configuration")
            #endif
            return .soft
        }

        // 方法2: ビルド時のコンパイラフラグをチェック
        #if MEMORY_ENFORCEMENT_FULL
        #if DEBUG
        print("   ✅ Compiler flag: MEMORY_ENFORCEMENT_FULL")
        #endif
        return .full
        #elseif MEMORY_ENFORCEMENT_SOFT
        #if DEBUG
        print("   ⚠️ Compiler flag: MEMORY_ENFORCEMENT_SOFT")
        #endif
        return .soft
        #endif

        // iOS 18+ の新機能なので、まずOS バージョンをチェック
        guard #available(iOS 18.0, *) else {
            #if DEBUG
            print("   ❌ iOS version < 18.0, defaulting to Soft Mode")
            #endif
            return .soft  // iOS 18未満はSoft Modeのみ
        }

        // 方法3: Code Signing フラグで確認
        // Note: 実際のiOS 26.4では、FullとSoftの区別がCode Signing Flagsに反映されない
        // 0x20000000が立っている場合、何らかのMemory Integrity機能が有効だが、
        // FullとSoftの区別はEntitlements（ビルド設定）から判断する必要がある
        #if DEBUG
        print("   Checking Code Signing flags...")
        if (flags & CS_MEMINT_ENABLED) != 0 {
            print("   ℹ️  CS_MEMINT_ENABLED (0x20000000) flag detected")
            print("   Note: This flag indicates Memory Integrity is enabled,")
            print("         but Full vs Soft distinction requires build configuration check")
        }
        #endif

        // 方法4: task_infoで詳細なメモリ保護状態を確認
        if let mode = checkTaskMemoryIntegrity() {
            #if DEBUG
            print("   Task info mode: \(mode)")
            #endif
            return mode
        }

        // 方法5: 実際のメモリ保護の厳格さをテスト
        if testMemoryIntegrityStrictness() {
            #if DEBUG
            print("   ✅ Strictness test indicates Full Mode")
            #endif
            return .full
        }

        // デフォルトはSoft Mode
        #if DEBUG
        print("   ⚠️ Defaulting to Soft Mode (no positive detection)")
        #endif
        return .soft
    }

    // ビルド時に設定されたモードを取得
    func getBuildTimeEnforcementMode() -> String {
        #if MEMORY_ENFORCEMENT_FULL
        return "Full Mode (Build Setting)"
        #elseif MEMORY_ENFORCEMENT_SOFT
        return "Soft Mode (Build Setting)"
        #else
        return "Default (No explicit setting)"
        #endif
    }

    // task_infoでメモリインテグリティをチェック
    private func checkTaskMemoryIntegrity() -> MemoryIntegrityEnforcementMode? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        // task_vm_info から推測できる情報をチェック
        // (実際のフィールドは iOS 18 のヘッダーファイルを確認する必要がある)
        return nil
    }

    // メモリインテグリティの厳格さをテスト
    private func testMemoryIntegrityStrictness() -> Bool {
        // Full Modeでは、より厳格なメモリアクセス制御が行われる
        // 例: 境界外アクセスの即座の検出、Use-After-Freeの検出など

        // テスト1: アライメント違反の検出
        let strictnessScore = testAlignmentEnforcement() +
                             testBoundsChecking() +
                             testPointerValidation()

        // スコアが高ければFull Modeの可能性が高い
        return strictnessScore >= 2
    }

    // アライメント違反の厳格さをテスト
    private func testAlignmentEnforcement() -> Int {
        // Full Modeではアライメント違反をより厳格にチェック
        // （実際のテストは慎重に実装する必要がある）
        return 0
    }

    // 境界チェックの厳格さをテスト
    private func testBoundsChecking() -> Int {
        // Full Modeでは境界外アクセスをより早期に検出
        return 0
    }

    // ポインタ検証の厳格さをテスト
    private func testPointerValidation() -> Int {
        // Full Modeでは不正なポインタをより厳格に検証
        return 0
    }

    // 主要なセキュリティ関連のEntitlementsをチェック
    func getSecurityEntitlements() -> [String: Bool] {
        guard let entitlements = getEntitlements() else {
            return [:]
        }

        let securityKeys = [
            "com.apple.security.cs.allow-jit",
            "com.apple.security.cs.allow-unsigned-executable-memory",
            "com.apple.security.cs.allow-dyld-environment-variables",
            "com.apple.security.cs.disable-library-validation",
            "com.apple.security.cs.disable-executable-page-protection",
            "com.apple.security.get-task-allow"
        ]

        var result: [String: Bool] = [:]
        for key in securityKeys {
            if let value = entitlements[key] as? Bool {
                result[key] = value
            }
        }

        return result
    }

    // システムインテグリティのレベルを判定
    func getProtectionLevel() -> String {
        let status = checkMemoryIntegrity()

        // Build configurationからモードを取得
        let buildMode = BuildModeDetector.detectMode()
        let isFullModeBuild = buildMode.contains("Full Mode")

        // Full Mode entitlements が設定されている場合
        if isFullModeBuild && status.hasEnforcement {
            return "Maximum Protection"
        } else if status.isFullyProtected {
            return "Full Protection"
        } else if status.hasEnforcement && status.wxProtectionActive {
            return "Standard Protection"
        } else if status.hasEnforcement || status.wxProtectionActive {
            return "Partial Protection"
        } else {
            return "Minimal Protection"
        }
    }
}
