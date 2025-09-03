import Foundation

struct HTTPRequest {
  let baseURL: URL
  let path: String
  let method: HTTPMethod
  let headers: [String: String]?
  let queryParams: [URLQueryItem]?
  let body: Codable?
  let authentication: AuthenticationProvider?

  init(
    baseURL: URL,
    path: String,
    method: HTTPMethod,
    headers: [String: String]? = nil,
    queryParams: [URLQueryItem]? = nil,
    body: Codable? = nil,
    authentication: AuthenticationProvider? = nil
  ) {
    self.baseURL = baseURL
    self.path = path
    self.method = method
    self.headers = headers
    self.queryParams = queryParams
    self.body = body
    self.authentication = authentication
  }

  func buildURLRequest() throws(RequestError) -> URLRequest {
    var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)

    if let queryParams {
      urlComponents?.queryItems = queryParams
    }

    guard let url = urlComponents?.url?.appendingPathComponent(path) else {
      throw RequestError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue

    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")

    // Add authentication headers first
    if let authentication {
      let authHeaders = authentication.authenticationHeaders()
      authHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
    }

    // Add custom headers (these can override authentication headers if needed)
    if let headers {
      headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
    }

    if method.requiresBody {
      guard let body else {
        throw RequestError.missingBody
      }
      let encoder = JSONEncoder()
      do {
        request.httpBody = try encoder.encode(body)
      } catch let error as EncodingError {
        throw RequestError.encodingError(error)
      } catch {
        throw RequestError.encodingError(
          EncodingError.invalidValue(
            body,
            EncodingError.Context(codingPath: [], debugDescription: "Unknown encoding error")
          )
        )
      }
    }

    return request
  }
}

protocol GenericRequest {
  func buildURLRequest() throws(RequestError) -> URLRequest
}

struct Get: GenericRequest {
  private let baseURL: URL
  private let path: String
  private let queryParams: [URLQueryItem]?
  private let authentication: AuthenticationProvider?

  init(baseURL: URL, path: String, queryParams: [URLQueryItem]? = nil, authentication: AuthenticationProvider? = nil) {
    self.baseURL = baseURL
    self.path = path
    self.queryParams = queryParams
    self.authentication = authentication
  }

  func buildURLRequest() throws(RequestError) -> URLRequest {
    try HTTPRequest(
      baseURL: baseURL,
      path: path,
      method: .get,
      queryParams: queryParams,
      authentication: authentication
    ).buildURLRequest()
  }
}

struct Post: GenericRequest {
  private let baseURL: URL
  private let path: String
  private let body: Codable
  private let authentication: AuthenticationProvider?

  init(baseURL: URL, path: String, body: Codable, authentication: AuthenticationProvider? = nil) {
    self.baseURL = baseURL
    self.path = path
    self.body = body
    self.authentication = authentication
  }

  func buildURLRequest() throws(RequestError) -> URLRequest {
    try HTTPRequest(
      baseURL: baseURL,
      path: path,
      method: .post,
      body: body,
      authentication: authentication
    ).buildURLRequest()
  }
}
