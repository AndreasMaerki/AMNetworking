import Foundation

public struct APIClient {
  private let baseURL: URL
  private let codableCache: CodableCacheProtocol
  private let validator = HTTPResponseValidator()
  private let decoder: JSONDecoder

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

  public func post<T: Codable>(
    path: String,
    body: some Codable,
    queryItems: [URLQueryItem]? = nil
  ) async throws(RequestError) -> T {
    let request = Post(baseURL: baseURL, path: path, body: body)
    return try await performRequest(request, path)
  }

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
