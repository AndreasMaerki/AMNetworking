@testable import AMNetworking
import Foundation
import XCTest

final class APIClientAuthenticationTests: XCTestCase {
  func testAPIClientWithBasicAuth() {
    let baseURL = URL(string: "https://api.example.com")!
    let auth = BasicAuthProvider(username: "user", password: "pass")

    let client = APIClient(baseURL: baseURL, authentication: auth)

    XCTAssertNotNil(client)
  }

  func testAPIClientWithBearerToken() {
    let baseURL = URL(string: "https://api.example.com")!
    let auth = BearerTokenProvider(token: "token123")

    let client = APIClient(baseURL: baseURL, authentication: auth)

    XCTAssertNotNil(client)
  }

  func testGetRequestWithAuth() throws {
    let baseURL = URL(string: "https://api.example.com")!
    let auth = BasicAuthProvider(username: "user", password: "pass")

    let getRequest = Get(baseURL: baseURL, path: "/test", authentication: auth)
    let urlRequest = try getRequest.buildURLRequest()

    XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Basic dXNlcjpwYXNz")
    XCTAssertEqual(urlRequest.httpMethod, "GET")
  }

  func testPostRequestWithAuth() throws {
    let baseURL = URL(string: "https://api.example.com")!
    let auth = BearerTokenProvider(token: "token123")

    struct TestBody: Codable {
      let name: String
    }

    let body = TestBody(name: "test")
    let postRequest = Post(baseURL: baseURL, path: "/test", body: body, authentication: auth)
    let urlRequest = try postRequest.buildURLRequest()

    XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Bearer token123")
    XCTAssertEqual(urlRequest.httpMethod, "POST")
    XCTAssertNotNil(urlRequest.httpBody)
  }
}
