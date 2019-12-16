//
//  ContentView.swift
//  LoginWithAppleFirebaseSwiftUI
//
//  Created by Joseph Hinkle on 12/15/19.
//  Copyright © 2019 Joseph Hinkle. All rights reserved.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State var text = "Nobody is logged in"
    
    var body: some View {
        NavigationView {
            VStack {
                Text(text)
                SignInWithAppleToFirebase({ response in
                    if response == .success {
                        self.text = "Success"
                        Auth.auth().addStateDidChangeListener { (auth: Auth, user: User?) in
                            if let user = user {
                                if let email = user.email {
                                    self.text = "Successfully logged into Firebase with Sign in with Apple\n\nuser.id: \(user.uid)\nuser.email: \(email)\nauth: \(auth)"
                                }
                            }
                        }
                    } else if response == .error {
                        self.text = "Error"
                    }
                })
                    .frame(height: 50, alignment: .center)
                    .padding(25)
                Text("Add the button and login logic to your project like this")
                Image("example")
                    .resizable()
                    .scaledToFit()
                    .padding([.bottom], 5)
                Button(action: {
                    let webURL = URL(string: "https://github.com/joehinkle11/Login-with-Apple-Firebase-SwiftUI")!
                    if UIApplication.shared.canOpenURL(webURL as URL) {
                        UIApplication.shared.open(webURL)
                    }
                }) {
                    Text("Source Code on GitHub 📃")
                }.padding([.bottom], 5)
                Button(action: {
                    let screenName =  "joehink95"
                    let appURL = URL(string: "twitter://user?screen_name=\(screenName)")!
                    let webURL = URL(string: "https://twitter.com/\(screenName)")!
                    if UIApplication.shared.canOpenURL(appURL as URL) {
                        UIApplication.shared.open(appURL)
                    } else {
                        UIApplication.shared.open(webURL)
                    }
                }) {
                    Text("Contact me ♥️")
                }.padding([.bottom], 5)
                Button(action: {
                    let tweetText = "I found a SwiftUI component which lets you use Sign in with Apple to login to Firebase! #SwiftUI"
                    let tweetUrl = "https://github.com/joehinkle11/Login-with-Apple-Firebase-SwiftUI"
                    let shareString = "https://twitter.com/intent/tweet?text=\(tweetText)&url=\(tweetUrl)"
                    let escapedShareString = shareString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                    let url = URL(string: escapedShareString)!
                    UIApplication.shared.open(url)
                }) {
                    Text("Share 🐦")
                }
            }
            .navigationBarTitle("Sign in with Apple to Firebase with SwiftUI Demo", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
            .padding(0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
