# Workstream 1: Server API Fixes

## Status: COMPLETED (2026-01-10)

All tasks in this workstream have been implemented.

---

## Tasks

### 1.1 Latency Harness Suite Deletion (P0) - DONE
**File:** `server/management/latency_harness_api.py`

Implemented proper `handle_delete_suite()` function that:
- Validates suite exists before deletion via `storage.get_suite()`
- Prevents deletion of built-in suites (`quick_validation`, `provider_comparison`)
- Calls `storage.delete_suite(suite_id)` with proper error handling
- Returns appropriate HTTP status codes (400, 404, 500)

---

### 1.2 CK-12 Course Detail View - DONE
**File:** `server/management/static/app.js`

Implemented full detail view matching MIT OCW pattern:
- `viewCK12CourseDetail(courseId)` - Main detail view with lesson cards
- `selectAllCK12Lessons(select)` - Select/deselect all lessons
- `updateCK12LessonSelectionCount()` - Live count updates
- `importCK12Course()` - Import with selected lessons

---

### 1.3 Plugin Discovery Metadata Extraction - DONE
**File:** `server/importers/core/discovery.py`

Added `_extract_module_metadata(module)` function that extracts:
- `__version__` from module attribute or docstring "Version:" pattern
- `__author__` from module attribute or docstring "Author:" pattern
- `__url__` from module attribute or docstring "Reference:" pattern

Added metadata to all 5 source plugins:
- `ck12_flexbook.py` - `__version__`, `__author__`, `__url__`
- `mit_ocw.py` - `__version__`, `__author__`, `__url__`
- `merlot.py` - `__version__`, `__author__`, `__url__`
- `engageny.py` - `__version__`, `__author__`, `__url__`
- `coreknowledge.py` - `__version__`, `__author__`, `__url__`

---

## Verification

All tasks verified:
1. Suite deletion API properly calls storage layer
2. CK-12 detail view displays course structure
3. Plugin metadata extraction works with fallbacks

Note: iOS build failures in `/validate` are pre-existing issues unrelated to these server-side changes (see Workstream 3 for iOS fixes).
