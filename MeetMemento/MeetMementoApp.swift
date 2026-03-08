//
//  MeetMementoApp.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 9/30/25.
//

import SwiftUI

@main
struct MeetMementoApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var lockScreenViewModel = LockScreenViewModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        print("🔴 MeetMementoApp init() called")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isInitializing {
                    // Show launch screen / loading while checking auth
                    LaunchLoadingView()
                        .useTheme()
                        .useTypography()
                } else if authViewModel.isAuthenticated && authViewModel.hasCompletedOnboarding {
                    // LOGGED IN: Show lock screen for verification, then main app
                    if lockScreenViewModel.shouldShowLockScreen {
                        LockScreenView(viewModel: lockScreenViewModel)
                            .useTheme()
                            .useTypography()
                            .environmentObject(authViewModel)
                    } else {
                        ContentView()
                            .useTheme()
                            .useTypography()
                            .environmentObject(authViewModel)
                            .onAppear {
                                #if DEBUG
                                print("🔴 ContentView appeared")
                                #endif
                            }
                    }
                } else if authViewModel.isAuthenticated && !authViewModel.hasCompletedOnboarding {
                    // Authenticated but needs onboarding
                    OnboardingCoordinatorView()
                        .useTheme()
                        .useTypography()
                        .environmentObject(authViewModel)
                } else {
                    // LOGGED OUT: Show welcome/sign-in
                    WelcomeView()
                        .useTheme()
                        .useTypography()
                        .environmentObject(authViewModel)
                        .onAppear {
                            #if DEBUG
                            print("🔴 WelcomeView appeared")
                            print("🔴 Auth state: isAuthenticated=\(authViewModel.isAuthenticated), hasCompletedOnboarding=\(authViewModel.hasCompletedOnboarding)")
                            #endif
                        }
                }
            }
            .task {
                #if DEBUG
                print("🔴 .task block started")
                #endif
                await authViewModel.initializeAuth()
                #if DEBUG
                print("🔴 .task block completed")
                #endif
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                #if DEBUG
                print("🔴 Scene phase changed: \(oldPhase) -> \(newPhase)")
                #endif
                if newPhase == .background || newPhase == .inactive {
                    lockScreenViewModel.lock()
                }
                if newPhase == .active && authViewModel.isAuthenticated {
                    // Update activity timestamp when app becomes active
                    SecurityService.shared.updateActivityTimestamp()
                }
            }
            .onOpenURL { url in
                #if DEBUG
                print("🔴 Received deep link URL: \(url)")
                #endif
                SupabaseService.shared.client.auth.handle(url)
            }
        }
    }
}
