@testable import AMNetworking
import Foundation
import XCTest

final class AuthenticationTests: XCTestCase {
  func testBasicAuthProvider() {
    let provider = BasicAuthProvider(username: "user", password: "pass")
    let headers = provider.authenticationHeaders()

    XCTAssertEqual(headers["Authorization"], "Basic dXNlcjpwYXNz")
  }

  func testBasicAuthProviderWithSpecialCharacters() {
    let provider = BasicAuthProvider(username: "user@domain.com", password: "p@ssw0rd!")
    let headers = provider.authenticationHeaders()

    let authHeader = headers["Authorization"]!
    let base64Part = String(authHeader.dropFirst(6))
    let decodedData = Data(base64Encoded: base64Part)!
    let decodedString = String(data: decodedData, encoding: .utf8)

    XCTAssertEqual(decodedString, "user@domain.com:p@ssw0rd!")
  }

  func testBearerTokenProvider() {
    let provider = BearerTokenProvider(token: "test-token")
    let headers = provider.authenticationHeaders()

    XCTAssertEqual(headers["Authorization"], "Bearer test-token")
  }

  func testHTTPRequestWithBasicAuth() throws {
    let baseURL = URL(string: "https://api.example.com")!
    let auth = BasicAuthProvider(username: "user", password: "pass")

    let httpRequest = HTTPRequest(
      baseURL: baseURL,
      path: "/test",
      method: .get,
      authentication: auth
    )

    let urlRequest = try httpRequest.buildURLRequest()

    XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Basic dXNlcjpwYXNz")
  }

  func testHTTPRequestWithBearerToken() throws {
    let baseURL = URL(string: "https://api.example.com")!
    let auth = BearerTokenProvider(token: "test-token")

    let httpRequest = HTTPRequest(
      baseURL: baseURL,
      path: "/test",
      method: .get,
      authentication: auth
    )

    let urlRequest = try httpRequest.buildURLRequest()

    XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
  }

  func testHTTPRequestWithoutAuthentication() throws {
    let baseURL = URL(string: "https://api.example.com")!

    let httpRequest = HTTPRequest(
      baseURL: baseURL,
      path: "/test",
      method: .get
    )

    let urlRequest = try httpRequest.buildURLRequest()

    XCTAssertNil(urlRequest.value(forHTTPHeaderField: "Authorization"))
  }

  func testCustomHeadersOverrideAuth() throws {
    let baseURL = URL(string: "https://api.example.com")!
    let auth = BasicAuthProvider(username: "user", password: "pass")
    let customHeaders = ["Authorization": "Custom token"]

    let httpRequest = HTTPRequest(
      baseURL: baseURL,
      path: "/test",
      method: .get,
      headers: customHeaders,
      authentication: auth
    )

    let urlRequest = try httpRequest.buildURLRequest()

    XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Custom token")
  }
}
