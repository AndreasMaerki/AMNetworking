import Foundation

public struct APIClient {
  private let baseURL: URL
  private let codableCache: CodableCacheProtocol
  private let validator = HTTPResponseValidator()
  private let decoder: JSONDecoder
  public init(baseURL: URL) {
    self.baseURL = baseURL
    codableCache = CodableCache()
    decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
  }

  public func get<T: Codable>(
    path: String,
    queryItems: [URLQueryItem]? = nil,
    invalidateCache: Bool = false
  ) async throws(RequestError) -> T {
    let request = Get(baseUrl: baseURL, path: path, queryParams: queryItems)
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
    } catch {
      throw mapCacheError(error)
    }

    do {
      let urlRequest = try request.buildURLRequest()
      let (data, response) = try await URLSession.shared.data(for: urlRequest)

      try validator.validateResponse(response)

      let result = try decoder.decode(T.self, from: data)

      codableCache.write(result, to: cacheKey)
      return result
    } catch let error as DecodingError {
      throw .parsingError(error)
    } catch let error as EncodingError {
      throw .parsingError(error)
    } catch let error as URLError {
      throw .networkError(error)
    } catch let error as RequestError {
      throw error
    } catch {
      throw .unknownError(error)
    }
  }

  private func mapCacheError(_ error: Error) -> RequestError {
    // Handle common error types directly
    if let decodingError = error as? DecodingError {
      return .parsingError(decodingError)
    }
    if let encodingError = error as? EncodingError {
      return .parsingError(encodingError)
    }
    return .unknownError(error)
  }
}

// helper function to print debug statements
func prettyPrintedJSONString(from object: some Encodable) -> String? {
  let encoder = JSONEncoder()
  encoder.outputFormatting = .prettyPrinted
  do {
    let data = try encoder.encode(object)
    return String(data: data, encoding: .utf8)
  } catch {
    print("Failed to encode: \(error)")
    return nil
  }
}
