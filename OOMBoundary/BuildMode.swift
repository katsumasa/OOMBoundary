//
//  BuildMode.swift
//  OOMBoundary
//
//  Created by Katsumasa Kimura on 2026/04/10.
//

import Foundation

/// Detects the Memory Enforcement Mode at runtime
struct BuildModeDetector {
    static func detectMode() -> String {
        // Method 1: Use generated build mode (most reliable)
        // This is set by switch-memory-enforcement.sh at build time
        // GENERATED_BUILD_MODE is defined in BuildModeGenerated.swift
        // Note: This will be used directly and is the primary detection method
        return GENERATED_BUILD_MODE
    }

    // Fallback methods (kept for reference but not currently used)
    // These methods could be used if GENERATED_BUILD_MODE is unavailable

    static func detectModeWithFallback() -> String {
        // Method 1: Try to read from bundle resources
        if let modeFromResource = readModeFromResource() {
            return modeFromResource
        }

        // Method 2: Parse entitlements file directly
        if let modeFromEntitlements = readModeFromEntitlements() {
            return modeFromEntitlements
        }

        // Method 3: Use compiler flags as fallback
        #if MEMORY_ENFORCEMENT_FULL
        return "Full Mode Build"
        #elseif MEMORY_ENFORCEMENT_SOFT
        return "Soft Mode Build"
        #else
        return "Standard Build"
        #endif
    }

    private static func readModeFromResource() -> String? {
        guard let url = Bundle.main.url(forResource: "BuildMode", withExtension: "txt"),
              let mode = try? String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }

        return mode
    }

    private static func readModeFromEntitlements() -> String? {
        // Try to read the entitlements file embedded in the bundle
        // Note: This is a best-effort approach as iOS restricts direct entitlements access

        guard let infoDictionary = Bundle.main.infoDictionary else {
            return nil
        }

        // Check for custom key that might be set during build
        if let mode = infoDictionary["MemoryEnforcementMode"] as? String {
            switch mode.lowercased() {
            case "full":
                return "Full Mode Build"
            case "soft":
                return "Soft Mode Build"
            default:
                return "Standard Build"
            }
        }

        return nil
    }
}
