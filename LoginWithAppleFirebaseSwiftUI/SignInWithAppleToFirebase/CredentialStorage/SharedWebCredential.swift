/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

enum SharedWebCredentialError: Error {
  case SecRequestFailure(CFError)
  case MissingCredentials
  case ConversionFailure
}

struct SharedWebCredential {
  private let domain: CFString
  private let safeForTutorialCode: Bool

  init(domain: String) {
    self.domain = domain as CFString
    safeForTutorialCode = !domain.isEmpty
  }

  func retrieve(account: String? = nil, completion: @escaping (Result<(account: String?, password: String?), SharedWebCredentialError>) -> Void) {
    guard safeForTutorialCode else {
      print("Please set your domain for SharedWebCredential constructor in UserAndPassword.swift!")
      return
    }

    var acct: CFString? = nil

    if let account = account {
      acct = account as CFString
    }

    SecRequestSharedWebCredential(domain, acct) { credentials, error in
      if let error = error {
        DispatchQueue.main.async {
          completion(.failure(.SecRequestFailure(error)))
        }

        return
      }

      guard
        let credentials = credentials,
        CFArrayGetCount(credentials) > 0
        else {
          DispatchQueue.main.async {
            completion(.failure(.MissingCredentials))
          }
          
          return
      }

      let unsafeCredential = CFArrayGetValueAtIndex(credentials, 0)
      let credential: CFDictionary = unsafeBitCast(unsafeCredential, to: CFDictionary.self)
      guard let dict = credential as? Dictionary<String, String> else {
        DispatchQueue.main.async {
          completion(.failure(.ConversionFailure))
        }

        return
      }

      let username = dict[kSecAttrAccount as String]
      let password = dict[kSecSharedPassword as String]

      DispatchQueue.main.async {
        completion(.success((username, password)))
      }
    }
  }

  private func update(account: String, password: String?, completion: @escaping (Result<Bool, SharedWebCredentialError>) -> Void) {
    guard safeForTutorialCode else {
      print("Please set your domain for SharedWebCredential constructor in UserAndPassword.swift!")
      return
    }

    var pwd: CFString? = nil
    if let password = password {
      pwd = password as CFString
    }

    SecAddSharedWebCredential(domain, account as CFString, pwd) { error in
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(.SecRequestFailure(error)))
        } else {
          completion(.success(true))
        }
      }
    }
  }

  func store(account: String, password: String, completion: @escaping (Result<Bool, SharedWebCredentialError>) -> Void) {
    update(account: account, password: password, completion: completion)
  }

  func delete(account: String, completion: @escaping (Result<Bool, SharedWebCredentialError>) -> Void) {
    update(account: account, password: nil, completion: completion)
  }
}
