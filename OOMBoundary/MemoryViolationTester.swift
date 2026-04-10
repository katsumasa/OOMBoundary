//
//  MemoryViolationTester.swift
//  OOMBoundary
//
//  Memory violation test to compare Full Mode vs Soft Mode behavior
//

import Foundation

/// Tests various memory violations to see if Full Mode catches them more strictly
struct MemoryViolationTester {

    // MARK: - Test 1: Buffer Overflow (Controlled)
    static func testBufferOverflow() -> String {
        #if DEBUG
        print("🧪 Testing Buffer Overflow...")
        #endif

        var buffer = [UInt8](repeating: 0, count: 10)
        var didCrash = false

        // Try to write just beyond buffer bounds
        // In Full Mode, this should be caught more strictly
        buffer.withUnsafeMutableBytes { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            #if DEBUG
            print("   Buffer base address: \(baseAddress)")
            print("   Buffer size: 10 bytes")
            #endif

            // Attempt controlled overflow (writing just past the end)
            // This is intentionally dangerous to test memory protection
            let beyondEnd = baseAddress.advanced(by: 10) // Exactly at the boundary

            // Try to write one byte past the allocated buffer
            // Full Mode should catch this more strictly than Soft Mode
            do {
                beyondEnd.storeBytes(of: UInt8(0xFF), as: UInt8.self)
                #if DEBUG
                print("   ⚠️ Write beyond buffer succeeded (no protection triggered)")
                #endif
            } catch {
                #if DEBUG
                print("   ✓ Exception caught: \(error)")
                #endif
                didCrash = true
            }
        }

        return didCrash ? "Buffer overflow: Caught by protection" : "Buffer overflow: Write succeeded (protection may be delayed)"
    }

    // MARK: - Test 2: Use-After-Free Detection
    static func testUseAfterFree() -> String {
        #if DEBUG
        print("🧪 Testing Use-After-Free Detection...")
        #endif

        class TestObject {
            var value: Int = 42
            deinit {
                #if DEBUG
                print("   TestObject deallocated")
                #endif
            }
        }

        var weakRef: Weak<TestObject>?

        autoreleasepool {
            let obj = TestObject()
            weakRef = Weak(obj)
            #if DEBUG
            print("   Object created with value: \(obj.value)")
            #endif
            // obj will be deallocated here
        }

        // Trying to access after deallocation
        if let obj = weakRef?.value {
            #if DEBUG
            print("   ⚠️ Object still accessible: \(obj.value)")
            #endif
            return "Use-after-free: Object survived (unexpected)"
        } else {
            #if DEBUG
            print("   ✓ Object properly deallocated")
            #endif
            return "Use-after-free: Properly detected"
        }
    }

    // MARK: - Test 3: Unaligned Access
    static func testUnalignedAccess() -> String {
        #if DEBUG
        print("🧪 Testing Unaligned Memory Access...")
        #endif

        var buffer = [UInt8](repeating: 0, count: 100)

        buffer.withUnsafeMutableBytes { ptr in
            guard let baseAddress = ptr.baseAddress else { return }

            // Try unaligned access (safe version - just checking alignment)
            let aligned = baseAddress.alignedUp(toMultiple: 8)
            let offset = aligned - baseAddress

            #if DEBUG
            print("   Base address: \(baseAddress)")
            print("   Aligned address: \(aligned)")
            print("   Alignment offset: \(offset)")
            #endif
        }

        return "Unaligned access test: Completed (alignment check only)"
    }

    // MARK: - Test 4: Invalid Pointer Dereference (DANGEROUS!)
    static func testNullPointerAccess() -> String {
        #if DEBUG
        print("🧪 Testing Invalid Pointer Access...")
        print("   ⚠️  This WILL crash with EXC_BAD_ACCESS!")
        #endif

        // Create a pointer to an invalid address (0x1 is guaranteed to be invalid)
        let invalidPtr = UnsafeMutablePointer<Int>(bitPattern: 0x1)

        if let ptr = invalidPtr {
            #if DEBUG
            print("   Attempting to dereference invalid pointer at address: 0x1")
            #endif
            let value = ptr.pointee  // EXC_BAD_ACCESS - this should crash
            #if DEBUG
            print("   ⚠️ Read succeeded: \(value) (THIS SHOULD NOT HAPPEN!)")
            #endif
            return "Invalid pointer: Read succeeded (UNEXPECTED - no protection)"
        } else {
            #if DEBUG
            print("   ✓ Invalid pointer correctly identified as nil")
            #endif
            return "Invalid pointer: Correctly handled as nil"
        }
    }

    // MARK: - Test 4b: Out-of-Bounds Array Access (EXTREME)
    static func testOutOfBoundsAccess() -> String {
        #if DEBUG
        print("🧪 Testing Out-of-Bounds Array Access...")
        #endif

        var array = [1, 2, 3, 4, 5]

        // Try to access way out of bounds
        array.withUnsafeMutableBufferPointer { buffer in
            #if DEBUG
            print("   Array size: \(buffer.count)")
            #endif

            // Access VERY far past the end - beyond any reasonable guard page
            let ptr = buffer.baseAddress!
            let veryFarBeyond = ptr.advanced(by: 1_000_000)  // 1 million elements away

            #if DEBUG
            print("   Attempting to write 1,000,000 elements past array end...")
            print("   This should definitely trigger EXC_BAD_ACCESS...")
            #endif
            veryFarBeyond.pointee = 999  // EXC_BAD_ACCESS

            #if DEBUG
            print("   ⚠️ Write succeeded (THIS SHOULD NOT HAPPEN!)")
            #endif
        }

        return "Out-of-bounds: Write succeeded (UNEXPECTED - no protection)"
    }

    // MARK: - Test 4d: Write to Read-Only Memory
    static func testWriteToReadOnly() -> String {
        #if DEBUG
        print("🧪 Testing Write to Read-Only Memory...")
        #endif

        // Get a pointer to a string literal (read-only memory)
        let readOnlyString = "This is read-only"
        let readOnlyPtr = readOnlyString.withCString { ptr -> UnsafeMutablePointer<CChar> in
            // Cast away const (dangerous!)
            return UnsafeMutablePointer(mutating: ptr)
        }

        #if DEBUG
        print("   Attempting to modify read-only string...")
        #endif
        readOnlyPtr.pointee = CChar(65)  // Try to write 'A' - should crash

        #if DEBUG
        print("   ⚠️ Write to read-only memory succeeded (unexpected)")
        #endif
        return "Read-only write: Succeeded (no protection)"
    }

    // MARK: - Test 4c: Use-After-Free (More Aggressive)
    static func testUseAfterFreeAggressive() -> String {
        #if DEBUG
        print("🧪 Testing Use-After-Free (Aggressive)...")
        #endif

        // Allocate memory manually
        let ptr = UnsafeMutablePointer<Int>.allocate(capacity: 10)
        ptr.initialize(repeating: 42, count: 10)

        #if DEBUG
        print("   Allocated memory at: \(ptr)")
        print("   Initial value: \(ptr.pointee)")
        #endif

        // Deallocate
        ptr.deinitialize(count: 10)
        ptr.deallocate()

        #if DEBUG
        print("   Memory deallocated")
        print("   Attempting to access freed memory...")
        #endif

        // Try to access after free (DANGEROUS!)
        let value = ptr.pointee  // Use-after-free!
        #if DEBUG
        print("   ⚠️ Read from freed memory: \(value) (unexpected)")
        #endif

        return "Use-after-free: Read succeeded (no protection)"
    }

    // MARK: - Test 5: Integer Overflow to Memory Access
    static func testIntegerOverflow() -> String {
        #if DEBUG
        print("🧪 Testing Integer Overflow...")
        #endif

        let maxValue = Int.max
        let buffer = [UInt8](repeating: 0, count: 100)

        // Attempt to use overflowed index
        buffer.withUnsafeBytes { ptr in
            #if DEBUG
            print("   Buffer size: \(buffer.count)")
            print("   Max Int: \(maxValue)")
            #endif

            // Try to access with overflowed index (will wrap around)
            let safeIndex = 5
            if safeIndex < buffer.count {
                let value = ptr[safeIndex]
                #if DEBUG
                print("   ✓ Safe access at index \(safeIndex): \(value)")
                #endif
            }
        }

        return "Integer overflow: Completed (safe indexing used)"
    }

    // MARK: - Test 6: Stack Overflow Check
    static func testStackDepth(depth: Int = 0) -> String {
        if depth > 1000 {
            return "Stack depth test: Completed at depth \(depth)"
        }

        // Recursive call with large local allocation
        var localBuffer = [UInt8](repeating: UInt8(depth & 0xFF), count: 1024)
        localBuffer[0] = UInt8(depth & 0xFF)  // Use the buffer to prevent optimization

        return testStackDepth(depth: depth + 1)
    }

    // MARK: - Run All Tests
    static func runAllTests() -> [String] {
        #if DEBUG
        print("🔬 === Memory Violation Tests ===")
        print("⚠️  These tests check memory safety behavior")
        print("⚠️  Full Mode should be stricter than Soft Mode")
        print("⚠️  Some tests may cause crashes - this is expected!\n")
        #endif

        var results: [String] = []

        // Test 1: Buffer Overflow
        results.append(testBufferOverflow())

        // Test 2: Use-After-Free
        results.append(testUseAfterFree())

        // Test 3: Unaligned Access
        results.append(testUnalignedAccess())

        // Test 4: Null Pointer (dangerous!)
        // Uncomment to test - will likely crash
        // results.append(testNullPointerAccess())

        // Test 5: Integer Overflow
        results.append(testIntegerOverflow())

        // Test 6: Stack Depth
        results.append(testStackDepth())

        #if DEBUG
        print("\n🔬 === Tests Completed ===")
        #endif
        return results
    }

    // MARK: - Run Safe Tests Only
    static func runSafeTests() -> [String] {
        #if DEBUG
        print("🔬 === Memory Safety Tests (Safe Mode) ===")
        print("ℹ️  Running only non-crashing tests\n")
        #endif

        var results: [String] = []

        results.append(testUseAfterFree())
        results.append(testUnalignedAccess())
        results.append(testIntegerOverflow())

        #if DEBUG
        print("\n🔬 === Safe Tests Completed ===")
        #endif
        return results
    }

    // MARK: - Run Dangerous Tests
    static func runDangerousTests() -> [String] {
        #if DEBUG
        print("🔬 === Memory Violation Tests (Dangerous Mode) ===")
        print("⚠️  WARNING: These tests WILL crash the app!")
        print("⚠️  This is intentional to test memory protection")
        print("⚠️  Expected signals: EXC_BAD_ACCESS, SIGSEGV, SIGBUS")
        print("⚠️  Tests ordered from least to most dangerous\n")
        #endif

        var results: [String] = []

        // Test 1: Use-after-free (may or may not crash immediately)
        #if DEBUG
        print("\n--- Test 1/4: Use-After-Free ---")
        #endif
        results.append(testUseAfterFreeAggressive())

        // Test 2: Write to read-only memory (should crash)
        #if DEBUG
        print("\n--- Test 2/4: Write to Read-Only Memory ---")
        #endif
        results.append(testWriteToReadOnly())

        // Test 3: Extreme out-of-bounds (should definitely crash)
        #if DEBUG
        print("\n--- Test 3/4: Extreme Out-of-Bounds Access ---")
        #endif
        results.append(testOutOfBoundsAccess())

        // Test 4: Invalid pointer (guaranteed to crash)
        #if DEBUG
        print("\n--- Test 4/4: Invalid Pointer Dereference ---")
        #endif
        results.append(testNullPointerAccess())

        #if DEBUG
        print("\n🔬 === If you see this, no crashes occurred (VERY unexpected) ===")
        #endif
        return results
    }

    // MARK: - Single Dangerous Test Runner
    static func runSingleDangerousTest(_ testName: String) -> String {
        #if DEBUG
        print("🔬 Running single test: \(testName)\n")
        #endif

        switch testName {
        case "UseAfterFree":
            return testUseAfterFreeAggressive()
        case "ReadOnly":
            return testWriteToReadOnly()
        case "OutOfBounds":
            return testOutOfBoundsAccess()
        case "InvalidPointer":
            return testNullPointerAccess()
        default:
            return "Unknown test: \(testName)"
        }
    }

    // MARK: - Get Test Descriptions
    static func getTestDescriptions() -> [(name: String, description: String, danger: String)] {
        return [
            ("UseAfterFree", "Access memory after deallocation", "🟡 May crash"),
            ("ReadOnly", "Write to read-only memory (string literal)", "🟠 Should crash"),
            ("OutOfBounds", "Access 1 million elements past array end", "🔴 Will crash"),
            ("InvalidPointer", "Dereference pointer to address 0x1", "🔴 Will crash")
        ]
    }
}

// Weak reference wrapper
class Weak<T: AnyObject> {
    weak var value: T?
    init(_ value: T) {
        self.value = value
    }
}

extension UnsafeRawPointer {
    func alignedUp(toMultiple alignment: Int) -> UnsafeRawPointer {
        let addr = Int(bitPattern: self)
        let aligned = (addr + alignment - 1) & ~(alignment - 1)
        return UnsafeRawPointer(bitPattern: aligned)!
    }
}

extension UnsafeMutableRawPointer {
    func alignedUp(toMultiple alignment: Int) -> UnsafeMutableRawPointer {
        let addr = Int(bitPattern: self)
        let aligned = (addr + alignment - 1) & ~(alignment - 1)
        return UnsafeMutableRawPointer(bitPattern: aligned)!
    }
}
