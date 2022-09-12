//
//  ContentView.swift
//  ParseMigrateKeychain
//
//  Created by Corey Baker on 9/11/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    @State var username = ""
    @State var password = ""

    var body: some View {
        Spacer()
        Form {
            Section("Objective-C SDK") {
                if viewModel.objCSDKLoggedIn {
                    Text("User objectId: \(viewModel.objCUserObjectId)")
                        .padding()
                        .foregroundColor(.green)
                    Button("Logout", action: {
                        viewModel.logoutObjCUser()
                    })
                } else {
                    Text("Not logged in")
                        .padding()
                        .foregroundColor(.red)
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                    Button("Signup", action: {
                        viewModel.signUpUsingObjcSDK(username,
                                                     password: password)
                    })
                    Button("Login", action: {
                        viewModel.loginUsingObjcSDK(username,
                                                    password: password)
                    })
                }
                Text("Installation id: \(viewModel.objCInstallationId)")
                    .padding()
                    .foregroundColor(.green)
                Button("Save Installation", action: {
                    viewModel.saveInstallationUsingObjcSDK()
                })
            }

            Section("Swift SDK") {
                if viewModel.swiftSDKLoggedIn {
                    Text("User objectId: \(viewModel.swiftUserObjectId)")
                        .padding()
                        .foregroundColor(.green)
                    Button("Logout", action: {
                        Task {
                            await viewModel.logoutSwiftUser()
                        }
                    })
                } else {
                    Text("Not logged in")
                        .padding()
                        .foregroundColor(.red)
                }
                Text("Installation id: \(viewModel.swiftInstallationId)")
                    .padding()
                    .foregroundColor(.green)
            }
        }
        if !viewModel.errorMessage.isEmpty {
            Text("Error: \(viewModel.errorMessage)")
                .padding()
                .foregroundColor(.red)
        }
        Spacer()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
