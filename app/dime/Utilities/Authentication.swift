//
//  Authentication.swift
//  Bonsai
//
//  Created by Rafael Soh on 7/7/22.
//

import Foundation
import LocalAuthentication
import SwiftUI
// All App Lock related methods will be handled here

class AppLockViewModel: ObservableObject {
    // Publishing the applock state from user defaults
    @Published var isAppLockEnabled: Bool = false
    // Publishing if the app is curretly unlocked or not
    @Published var isAppUnLocked: Bool = false

    @Published var enrollmentError: Bool = false

    init() {
        getAppLockState()
    }

    // To enable the AppLock in UserDefaults
    func enableAppLock() {
        UserDefaults.standard.set(true, forKey: "appLockEnabled")
        isAppLockEnabled = true
    }

    // To disable the AppLock in UserDefaults
    func disableAppLock() {
        UserDefaults.standard.set(false, forKey: "appLockEnabled")
        isAppLockEnabled = false
    }

    // To Publish the AppLock state
    func getAppLockState() {
        isAppLockEnabled = UserDefaults.standard.bool(forKey: "appLockEnabled")
    }

    // Checking if the device is having BioMetric hardware and enrolled
    func checkIfBioMetricAvailable() -> Bool {
        var error: NSError?
        let laContext = LAContext()

        let isBiometricAvailable = laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if let error = error {
            print(error.localizedDescription)
        }

        if isBiometricAvailable {
            enrollmentError = false
        } else {
            enrollmentError = true
        }

        return isBiometricAvailable
    }

    // This method used to change the AppLock state.
    // If user is going to enable the AppLock then 'appLockState' should be 'true' and vice versa
    func appLockStateChange(appLockState: Bool) {
        let laContext = LAContext()
        if checkIfBioMetricAvailable() {
            var reason = ""
            if appLockState {
                reason = "Provice Touch ID/Face ID to enable App Lock"
            } else {
                reason = "Provice Touch ID/Face ID to disable App Lock"
            }

            laContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success {
                    if appLockState {
                        DispatchQueue.main.async {
                            self.enableAppLock()
                            self.isAppUnLocked = true
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.disableAppLock()
                            self.isAppUnLocked = true
                        }
                    }
                } else {
                    if let error = error {
                        DispatchQueue.main.async {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        } else {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }

    // This method will call on every launch of the app if user has enabled AppLock
    func appLockValidation() {
        let laContext = LAContext()
        if checkIfBioMetricAvailable() {
            let reason = "Enable App Lock"
            laContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.isAppUnLocked = true
                    }
                } else {
                    if let error = error {
                        DispatchQueue.main.async {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        } else {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
}
