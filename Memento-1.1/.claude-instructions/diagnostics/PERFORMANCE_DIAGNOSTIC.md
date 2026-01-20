# 🔍 PERFORMANCE DIAGNOSTIC: App Launch Delays

## Problem Summary
- First open/login: Extremely slow
- Close & reopen: Fast
- UI not responsive (buttons/tabs don't work)

## Root Cause Analysis
The issue is NOT just EntryViewModel. There are multiple init() calls happening:

1. MeetMementoApp.swift → @StateObject authViewModel = AuthViewModel()
2. AuthViewModel.init() → Task { await checkAuthState() }  
3. checkAuthState() → isLoading = true, network call
4. When auth is true → ContentView appears
5. ContentView → @StateObject entryViewModel = EntryViewModel()
6. JournalView appears → .task { await loadEntriesIfNeeded() }

## The Chain Reaction:
```
App Launch
  ↓
AuthViewModel created
  ↓
checkAuthState() runs
  ↓ 
isLoading = true (blocks UI)
  ↓
auth check completes
  ↓
ContentView created (NEW during transition - slow)
  ↓
EntryViewModel created
  ↓
JournalView.task runs
  ↓
entries.load() runs
```

What happens on restart:
```
App Launch (auth cached)
  ↓
AuthViewModel created
  ↓
Auth state already known → instant UI
  ↓ 
ContentView created immediately (no transition)
```

