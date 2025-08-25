import Foundation

struct HTTPRequest {
  let baseURL: URL
  let path: String
  let method: HTTPMethod
  let headers: [String: String]?
  let queryParams: [URLQueryItem]?
  let body: Codable?

  init(
    baseURL: URL,
    path: String,
    method: HTTPMethod,
    headers: [String: String]? = nil,
    queryParams: [URLQueryItem]? = nil,
    body: Codable? = nil
  ) {
    self.baseURL = baseURL
    self.path = path
    self.method = method
    self.headers = headers
    self.queryParams = queryParams
    self.body = body
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

    if let headers {
      headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
    }

    if method.requiresBody {
      guard let body else {
        throw RequestError.missingBody
      }
      let encoder = JSONEncoder()
      do {
        request.httpBody = try encoder.encode(body)
      } catch {
        throw RequestError.encodingError
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

  init(baseUrl: URL, path: String, queryParams: [URLQueryItem]? = nil) {
    baseURL = baseUrl
    self.path = path
    self.queryParams = queryParams
  }

  func buildURLRequest() throws(RequestError) -> URLRequest {
    try HTTPRequest(
      baseURL: baseURL,
      path: path,
      method: .get,
      queryParams: queryParams
    ).buildURLRequest()
  }
}

struct Post: GenericRequest {
  private let baseURL: URL
  private let path: String
  private let body: Codable

  init(baseURL: URL, path: String, body: Codable) {
    self.baseURL = baseURL
    self.path = path
    self.body = body
  }

  func buildURLRequest() throws(RequestError) -> URLRequest {
    try HTTPRequest(
      baseURL: baseURL,
      path: path,
      method: .post,
      body: body
    ).buildURLRequest()
  }
}
