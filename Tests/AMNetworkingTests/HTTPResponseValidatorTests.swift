@testable import AMNetworking
import Foundation
import Testing

// MARK: - HTTPResponseValidator Tests

@Test("HTTPResponseValidator accepts 200 OK status")
func responseValidatorAccepts200() throws {
  let validator = HTTPResponseValidator()
  let response = HTTPURLResponse(
    url: URL(string: "https://api.example.com")!,
    statusCode: 200,
    httpVersion: nil,
    headerFields: nil
  )!

  // Should not throw
  try validator.validateResponse(response)
}

@Test("HTTPResponseValidator accepts all 2xx status codes")
func responseValidatorAccepts2xx() throws {
  let validator = HTTPResponseValidator()
  let url = URL(string: "https://api.example.com")!

  for statusCode in [200, 201, 202, 204, 299] {
    let response = HTTPURLResponse(
      url: url,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: nil
    )!

    // Should not throw for any 2xx status
    try validator.validateResponse(response)
  }
}

@Test("HTTPResponseValidator throws for 400 Bad Request")
func responseValidatorRejects400() {
  let validator = HTTPResponseValidator()
  let response = HTTPURLResponse(
    url: URL(string: "https://api.example.com")!,
    statusCode: 400,
    httpVersion: nil,
    headerFields: nil
  )!

  #expect(throws: RequestError.invalidResponse) {
    try validator.validateResponse(response)
  }
}

@Test("HTTPResponseValidator throws for 404 Not Found")
func responseValidatorRejects404() {
  let validator = HTTPResponseValidator()
  let response = HTTPURLResponse(
    url: URL(string: "https://api.example.com")!,
    statusCode: 404,
    httpVersion: nil,
    headerFields: nil
  )!

  #expect(throws: RequestError.notFound) {
    try validator.validateResponse(response)
  }
}

@Test("HTTPResponseValidator throws for 500 Internal Server Error")
func responseValidatorRejects500() {
  let validator = HTTPResponseValidator()
  let response = HTTPURLResponse(
    url: URL(string: "https://api.example.com")!,
    statusCode: 500,
    httpVersion: nil,
    headerFields: nil
  )!

  #expect(throws: RequestError.internalServerError) {
    try validator.validateResponse(response)
  }
}

@Test("HTTPResponseValidator throws for non-HTTP response")
func responseValidatorRejectsNonHTTP() {
  let validator = HTTPResponseValidator()
  let response = URLResponse(
    url: URL(string: "https://api.example.com")!,
    mimeType: nil,
    expectedContentLength: 0,
    textEncodingName: nil
  )

  #expect(throws: RequestError.unexpectedStatusCode(-1)) {
    try validator.validateResponse(response)
  }
}
