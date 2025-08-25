@testable import AMNetworking
import Foundation
import Testing

// MARK: - HTTPRequest Tests

private struct TestModel: Codable, Equatable {
  let id: Int
  let name: String
}

@Test("HTTPRequest builds basic URL correctly")
func httpRequestBasicURL() throws {
  let baseURL = URL(string: "https://api.example.com")!
  let request = HTTPRequest(baseURL: baseURL, path: "users", method: .get)

  let urlRequest = try request.buildURLRequest()

  #expect(urlRequest.url?.absoluteString == "https://api.example.com/users")
  #expect(urlRequest.httpMethod == "GET")
}

@Test("HTTPRequest adds query parameters")
func httpRequestQueryParameters() throws {
  let baseURL = URL(string: "https://api.example.com")!
  let queryItems = [URLQueryItem(name: "page", value: "1")]
  let request = HTTPRequest(baseURL: baseURL, path: "users", method: .get, queryParams: queryItems)

  let urlRequest = try request.buildURLRequest()

  #expect(urlRequest.url?.absoluteString == "https://api.example.com/users?page=1")
}

@Test("HTTPRequest sets default headers")
func httpRequestDefaultHeaders() throws {
  let baseURL = URL(string: "https://api.example.com")!
  let request = HTTPRequest(baseURL: baseURL, path: "users", method: .get)

  let urlRequest = try request.buildURLRequest()

  #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
  #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
}

@Test("HTTPRequest adds custom headers")
func httpRequestCustomHeaders() throws {
  let baseURL = URL(string: "https://api.example.com")!
  let headers = ["Authorization": "Bearer token"]
  let request = HTTPRequest(baseURL: baseURL, path: "users", method: .get, headers: headers)

  let urlRequest = try request.buildURLRequest()

  #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
}

@Test("HTTPRequest encodes body for POST method")
func httpRequestBodyEncoding() throws {
  let baseURL = URL(string: "https://api.example.com")!
  let testModel = TestModel(id: 1, name: "Test")
  let request = HTTPRequest(baseURL: baseURL, path: "users", method: .post, body: testModel)

  let urlRequest = try request.buildURLRequest()

  #expect(urlRequest.httpBody != nil)

  // Verify body contains encoded JSON
  let decodedModel = try JSONDecoder().decode(TestModel.self, from: urlRequest.httpBody!)
  #expect(decodedModel == testModel)
}

@Test("HTTPRequest throws error when body missing for POST")
func httpRequestMissingBodyError() {
  let baseURL = URL(string: "https://api.example.com")!
  let request = HTTPRequest(baseURL: baseURL, path: "users", method: .post, body: nil)

  #expect(throws: RequestError.missingBody) {
    try request.buildURLRequest()
  }
}

@Test("HTTPRequest doesn't require body for GET method")
func httpRequestGetWithoutBody() throws {
  let baseURL = URL(string: "https://api.example.com")!
  let request = HTTPRequest(baseURL: baseURL, path: "users", method: .get, body: nil)

  let urlRequest = try request.buildURLRequest()

  #expect(urlRequest.httpBody == nil)
}
