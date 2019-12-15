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

enum KeychainError: Error {
  case secCallFailed(OSStatus)
  case notFound
  case badData
  case archiveFailure(Error)
}

protocol Keychain {
  associatedtype DataType: Codable

  var account: String { get set }
  var service: String { get set }

  func remove() throws
  func retrieve() throws -> DataType
  func store(_ data: DataType) throws
}

extension Keychain {
  func remove() throws {
    let status = SecItemDelete(keychainQuery() as CFDictionary)
    guard status == noErr || status == errSecItemNotFound else {
      throw KeychainError.secCallFailed(status)
    }
  }

  func retrieve() throws -> DataType {
    var query = keychainQuery()
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    query[kSecReturnAttributes as String] = kCFBooleanTrue
    query[kSecReturnData as String] = kCFBooleanTrue

    var result: AnyObject?
    let status = withUnsafeMutablePointer(to: &result) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }

    guard status != errSecItemNotFound else { throw KeychainError.notFound }
    guard status == noErr else { throw KeychainError.secCallFailed(status) }

    do {
      guard
        let dict = result as? [String: AnyObject],
        let data = dict[kSecAttrGeneric as String] as? Data,
        let userData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? DataType
        else {
          throw KeychainError.badData
      }

      return userData
    } catch {
      throw KeychainError.archiveFailure(error)
    }
  }

  func store(_ data: DataType) throws {
    var query = keychainQuery()

    let archived: AnyObject
    do {
      archived = try NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true) as AnyObject
    } catch {
      throw KeychainError.archiveFailure(error)
    }

    let status: OSStatus
    do {
      // If doesn't already exist, this will throw a KeychainError.notFound,
      // causing the catch block to add it.
       _ = try retrieve()

      let updates = [
        String(kSecAttrGeneric): archived
      ]

      status = SecItemUpdate(query as CFDictionary, updates as CFDictionary)
    } catch KeychainError.notFound {
      query[kSecAttrGeneric as String] = archived
      status = SecItemAdd(query as CFDictionary, nil)
    } 

    guard status == noErr else {
      throw KeychainError.secCallFailed(status)
    }
  }

  private func keychainQuery() -> [String: AnyObject] {
    var query: [String: AnyObject] = [:]
    query[kSecClass as String] = kSecClassGenericPassword
    query[kSecAttrService as String] = service as AnyObject
    query[kSecAttrAccount as String] = account as AnyObject

    return query
  }
}
