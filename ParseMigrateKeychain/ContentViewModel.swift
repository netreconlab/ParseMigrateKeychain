//
//  ContentViewModel.swift
//  ParseMigrateKeychain
//
//  Created by Corey Baker on 9/11/22.
//

import Foundation
import ParseSwift
import Parse

class ContentViewModel: ObservableObject {
    @Published var objCUserObjectId = ""
    @Published var objCInstallationId = ""
    @Published var objCSDKLoggedIn = false {
        willSet {
            guard newValue else {
                return
            }
            errorMessage = ""
        }
    }
    @Published var swiftUserObjectId = ""
    @Published var swiftInstallationId = ""
    @Published var swiftSDKLoggedIn = false
    @Published var errorMessage = "" {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    var objCUser: PFUser? {
        willSet {
            DispatchQueue.main.async {
                self.objCUserObjectId = newValue?.objectId ?? ""
                guard newValue != nil else {
                    self.objCSDKLoggedIn = false
                    return
                }
                self.objCSDKLoggedIn = true
            }
        }
    }
    var objCInstallation: PFInstallation? {
        willSet {
            DispatchQueue.main.async {
                self.objCInstallationId = newValue?.installationId ?? ""
            }
        }
    }
    var swiftUser: User? {
        willSet {
            DispatchQueue.main.async {
                self.swiftUserObjectId = newValue?.objectId ?? ""
                guard newValue != nil else {
                    self.swiftSDKLoggedIn = false
                    return
                }
                self.swiftSDKLoggedIn = true
            }
        }
    }
    var swiftInstallation: Installation? {
        willSet {
            DispatchQueue.main.async {
                self.swiftInstallationId = newValue?.installationId ?? ""
            }
        }
    }
    
    init() {
        setupSDKs()
        updateAllProperties()
    }

    // MARK: Helper Methods
    func setupSDKs() {
        let applicationId = "applicationId"
        let clientKey = "clientKey"
        let serverURLString = "http://localhost:1337/1"

        // Swift SDK setup
        let swiftConfiguration = ParseConfiguration(applicationId: applicationId,
                                                    clientKey: clientKey,
                                                    serverURL: URL(string: serverURLString)!)
        ParseSwift.initialize(configuration: swiftConfiguration)

        // Objective-C SDK setup
        let objCConfiguration = ParseClientConfiguration { config in
            config.applicationId = applicationId
            config.clientKey = clientKey
            config.server = serverURLString
        }
        Parse.initialize(with: objCConfiguration)
    }

    func updateAllProperties() {
        if let currentUser = PFUser.current() {
            objCUserObjectId = currentUser.objectId ?? ""
            objCSDKLoggedIn = true
        } else {
            objCSDKLoggedIn = false
        }
        if let currentInstallation = PFInstallation.current() {
            objCInstallationId = currentInstallation.installationId
        }
        if let currentUser = User.current {
            swiftUserObjectId = currentUser.objectId ?? ""
            swiftSDKLoggedIn = true
        } else {
            swiftSDKLoggedIn = false
        }
        if let currentInstallation = Installation.current {
            swiftInstallationId = currentInstallation.installationId ?? ""
        }
    }

    @MainActor
    func loginToSwiftSDK() async {
        do {
            self.swiftUser = try await User.loginUsingObjCKeychain()
        } catch {
            guard let parseError = error as? ParseError else {
                self.errorMessage = error.localizedDescription
                return
            }
            self.errorMessage = parseError.message
        }
    }

    // MARK: Intents
    @MainActor
    func signUpUsingObjcSDK(_ username: String, password: String) {
        guard PFUser.current() == nil else {
            self.errorMessage = "User is already logged in"
            return
        }
        let newUser = PFUser()
        newUser.username = username
        newUser.password = password
        newUser.signUpInBackground { (user, error) in
            guard error == nil else {
                self.errorMessage = error?.localizedDescription ?? "Could not sign up"
                return
            }
            self.objCUser = PFUser.current()
            Task {
                await self.loginToSwiftSDK()
            }
        }
    }

    @MainActor
    func loginUsingObjcSDK(_ username: String, password: String) {
        guard PFUser.current() == nil else {
            self.errorMessage = "User is already logged in"
            return
        }
        PFUser.logInWithUsername(inBackground: username, password: password) { (user, error) in
            guard error == nil else {
                self.errorMessage = error?.localizedDescription ?? "Could not log in"
                return
            }
            self.objCUser = user
            Task {
                await self.loginToSwiftSDK()
            }
        }
    }

    @MainActor
    func saveInstallationUsingObjcSDK() {
        let dummyChannels = ["global"]
        let installation = PFInstallation.current()
        installation?.channels = dummyChannels
        installation?.saveInBackground { (success, error) in
            guard success,
                error == nil,
                let currentInstallation = PFInstallation.current(),
                let objectId = currentInstallation.objectId else {
                self.errorMessage = error?.localizedDescription ?? "Could not save installation"
                return
            }
            self.objCInstallation = currentInstallation
            Task {
                do {
                    self.swiftInstallation = try await Installation.become(objectId)
                } catch {
                    guard let parseError = error as? ParseError else {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    self.errorMessage = parseError.message
                }
            }
        }
    }

    @MainActor
    func logoutObjCUser() {
        PFUser.logOutInBackground { error in
            self.updateAllProperties()
            guard error == nil else {
                self.errorMessage = error?.localizedDescription ?? "Could not log out"
                return
            }
        }
    }

    @MainActor
    func logoutSwiftUser() async {
        do {
            try await User.logout()
            self.updateAllProperties()
        } catch {
            self.updateAllProperties()
            guard let parseError = error as? ParseError else {
                self.errorMessage = error.localizedDescription
                return
            }
            self.errorMessage = parseError.message
        }
    }
}
