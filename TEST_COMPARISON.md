# Memory Violation Test Comparison

## Test Results Template

### Full Mode Results
**Build Configuration:** Full Mode
**Device:** iPhone 17 Pro, iOS 26.4

| Test # | Test Name | Result | Notes |
|--------|-----------|--------|-------|
| 1 | Use-After-Free | ⬜ Pass / ❌ Crash | Value read: |
| 2 | Read-Only Write | ⬜ Pass / ❌ Crash | Crash signal: |
| 3 | Extreme Out-of-Bounds | ⬜ Pass / ❌ Crash | |
| 4 | Invalid Pointer | ⬜ Pass / ❌ Crash | |

**Xcode Console Output:**
```
(paste full console output here)
```

---

### Soft Mode Results
**Build Configuration:** Soft Mode
**Device:** iPhone 17 Pro, iOS 26.4

| Test # | Test Name | Result | Notes |
|--------|-----------|--------|-------|
| 1 | Use-After-Free | ⬜ Pass / ❌ Crash | Value read: |
| 2 | Read-Only Write | ⬜ Pass / ❌ Crash | Crash signal: |
| 3 | Extreme Out-of-Bounds | ⬜ Pass / ❌ Crash | |
| 4 | Invalid Pointer | ⬜ Pass / ❌ Crash | |

**Xcode Console Output:**
```
(paste full console output here)
```

---

## Comparison Analysis

### Differences Found:
- [ ] Full Mode crashes earlier than Soft Mode
- [ ] Full Mode crashes at different test
- [ ] No observable difference
- [ ] Other: _______

### Crash Signals Observed:
- EXC_BAD_ACCESS
- SIGSEGV
- SIGBUS
- Other: _______

### Memory Protection Observations:
1. Use-After-Free Protection:
   - Full Mode: 
   - Soft Mode: 

2. Read-Only Memory Protection:
   - Full Mode:
   - Soft Mode:

3. Out-of-Bounds Detection:
   - Full Mode:
   - Soft Mode:

4. Invalid Pointer Detection:
   - Full Mode:
   - Soft Mode:

---

## Conclusions

### Are there observable differences between Full and Soft Mode?
YES / NO

### If YES, what are they?


### If NO, possible reasons:


### Recommendations:

