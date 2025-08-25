import Foundation

// Protocol defining what an endpoint should provide
public protocol EndpointSpec {
  var path: String { get }
  var cacheKey: String? { get }
}

struct HTTPRequest {
  let baseURL: URL
  let endpoint: EndpointSpec
  let method: HTTPMethod
  let headers: [String: String]?
  let queryParams: [URLQueryItem]?
  let body: Codable?

  init(
    baseURL: URL,
    endpoint: EndpointSpec,
    method: HTTPMethod,
    headers: [String: String]? = nil,
    queryParams: [URLQueryItem]? = nil,
    body: Codable? = nil
  ) {
    self.baseURL = baseURL
    self.endpoint = endpoint
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

    guard let url = urlComponents?.url?.appendingPathComponent(endpoint.path) else {
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
  private let endPoint: EndpointSpec
  private let queryParams: [URLQueryItem]?

  init(baseUrl: URL, endPoint: EndpointSpec, queryParams: [URLQueryItem]? = nil) {
    baseURL = baseUrl
    self.endPoint = endPoint
    self.queryParams = queryParams
  }

  func buildURLRequest() throws(RequestError) -> URLRequest {
    try HTTPRequest(
      baseURL: baseURL,
      endpoint: endPoint,
      method: .get,
      queryParams: queryParams
    ).buildURLRequest()
  }
}

struct Post: GenericRequest {
  private let baseURL: URL
  private let endPoint: EndpointSpec
  private let body: Codable

  init(baseURL: URL, endPoint: EndpointSpec, body: Codable) {
    self.baseURL = baseURL
    self.endPoint = endPoint
    self.body = body
  }

  func buildURLRequest() throws(RequestError) -> URLRequest {
    try HTTPRequest(
      baseURL: baseURL,
      endpoint: endPoint,
      method: .post,
      body: body
    ).buildURLRequest()
  }
}
