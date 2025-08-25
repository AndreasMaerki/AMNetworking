import Foundation

/// A modern, async/await-based HTTP client with automatic caching and robust error handling.
///
/// `APIClient` provides a simple interface for making GET and POST requests with automatic JSON
/// encoding/decoding and built-in response caching. All requests are cached by default with
/// configurable time-to-live (TTL) settings.
///
/// ## Example Usage
/// ```swift
/// let client = APIClient(baseURL: URL(string: "https://api.example.com")!)
///
/// // GET request
/// let users: [User] = try await client.get(path: "/users")
///
/// // POST request
/// let newUser: User = try await client.post(path: "/users", body: userData)
/// ```
public struct APIClient {
  private let baseURL: URL
  private let codableCache: CodableCacheProtocol
  private let validator = HTTPResponseValidator()
  private let decoder: JSONDecoder

  /// Creates a new API client with the specified configuration.
  ///
  /// - Parameters:
  ///   - baseURL: The base URL for all API requests
  ///   - decoder: Custom JSON decoder. If nil, uses a default decoder with ISO8601 date strategy
  ///   - cache: Custom cache implementation. If nil, uses the default file-based cache
  ///
  /// ## Example
  /// ```swift
  /// // Basic initialization
  /// let client = APIClient(baseURL: URL(string: "https://api.example.com")!)
  ///
  /// // With custom decoder
  /// let decoder = JSONDecoder()
  /// decoder.dateDecodingStrategy = .secondsSince1970
  /// let client = APIClient(baseURL: baseURL, decoder: decoder)
  ///
  /// // With no caching
  /// let client = APIClient(baseURL: baseURL, cache: NilCodableCache())
  /// ```
  public init(
    baseURL: URL,
    decoder: JSONDecoder? = nil,
    cache: CodableCacheProtocol? = nil
  ) {
    self.baseURL = baseURL

    if let decoder {
      self.decoder = decoder
    } else {
      let defaultDecoder = JSONDecoder()
      defaultDecoder.dateDecodingStrategy = .iso8601
      self.decoder = defaultDecoder
    }

    codableCache = cache ?? CodableCache()
  }

  /// Performs a GET request to the specified path.
  ///
  /// This method automatically handles caching, JSON decoding, and error mapping.
  /// Responses are cached by default and will be returned from cache if still valid.
  ///
  /// - Parameters:
  ///   - path: The API endpoint path (will be appended to baseURL)
  ///   - queryItems: Optional query parameters to include in the request
  ///   - invalidateCache: If true, forces a fresh network request by invalidating cached data
  ///
  /// - Returns: The decoded response object of type T
  /// - Throws: `RequestError` for various failure scenarios (network, parsing, validation, etc.)
  ///
  /// ## Example
  /// ```swift
  /// // Simple GET request
  /// let users: [User] = try await client.get(path: "/users")
  ///
  /// // With query parameters
  /// let queryItems = [URLQueryItem(name: "page", value: "1")]
  /// let users: [User] = try await client.get(path: "/users", queryItems: queryItems)
  ///
  /// // Force fresh data (bypass cache)
  /// let users: [User] = try await client.get(path: "/users", invalidateCache: true)
  /// ```
  public func get<T: Codable>(
    path: String,
    queryItems: [URLQueryItem]? = nil,
    invalidateCache: Bool = false
  ) async throws(RequestError) -> T {
    let request = Get(baseURL: baseURL, path: path, queryParams: queryItems)
    if invalidateCache {
      codableCache.invalidateCache(path)
    }
    return try await performRequest(request, path)
  }

  /// Performs a POST request to the specified path with a JSON body.
  ///
  /// This method automatically handles JSON encoding/decoding and error mapping.
  /// POST requests are not cached by design since they typically modify server state.
  ///
  /// - Parameters:
  ///   - path: The API endpoint path (will be appended to baseURL)
  ///   - body: The request body object that will be JSON encoded
  ///   - queryItems: Optional query parameters to include in the request
  ///
  /// - Returns: The decoded response object of type T
  /// - Throws: `RequestError` for various failure scenarios (network, encoding, validation, etc.)
  ///
  /// ## Example
  /// ```swift
  /// struct CreateUserRequest: Codable {
  ///     let name: String
  ///     let email: String
  /// }
  ///
  /// let newUser = CreateUserRequest(name: "John", email: "john@example.com")
  /// let createdUser: User = try await client.post(path: "/users", body: newUser)
  /// ```
  public func post<T: Codable>(
    path: String,
    body: some Codable,
    queryItems: [URLQueryItem]? = nil
  ) async throws(RequestError) -> T {
    let request = Post(baseURL: baseURL, path: path, body: body)
    return try await performRequest(request, path)
  }

  /// Clears all cached responses.
  ///
  /// This method removes all cached data and their associated timestamps.
  /// Useful for implementing cache refresh functionality or when user logs out.
  ///
  /// ## Example
  /// ```swift
  /// // Clear cache when user logs out
  /// client.clearAllCache()
  /// ```
  public func clearAllCache() {
    codableCache.clearAllCache()
  }

  private func performRequest<T: Codable>(
    _ request: GenericRequest,
    _ cacheKey: String
  ) async throws(RequestError) -> T {
    do {
      if let cachedData: T = try codableCache.read(cacheKey) {
        return cachedData
      }

      let urlRequest = try request.buildURLRequest()
      let (data, response) = try await URLSession.shared.data(for: urlRequest)

      try validator.validateResponse(response)

      let result = try decoder.decode(T.self, from: data)

      codableCache.write(result, to: cacheKey)
      return result
    } catch let error as DecodingError {
      throw .decodingError(error)
    } catch let error as EncodingError {
      throw .encodingError(error)
    } catch let error as URLError {
      throw .networkError(error)
    } catch let error as RequestError {
      throw error
    } catch {
      throw .unknownError(error)
    }
  }
}
