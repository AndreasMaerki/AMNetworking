@testable import AMNetworking
import Foundation
import Testing

// MARK: - APIClient Tests

@Test("APIClient clearAllCache delegates to cache")
func apiClientClearCache() {
  let baseURL = URL(string: "https://api.example.com")!

  // Mock cache to verify clearAllCache is called
  final class MockCache: CodableCacheProtocol {
    var clearAllCacheCalled = false

    func read<T: Codable>(_ key: String) throws -> T? { nil }
    func write(_ contents: some Codable, to key: String) {}
    func invalidateCache(_ key: String) {}

    func clearAllCache() {
      clearAllCacheCalled = true
    }
  }

  let mockCache = MockCache()
  let client = APIClient(baseURL: baseURL, cache: mockCache)

  // Call clearAllCache
  client.clearAllCache()

  // Verify the cache's clearAllCache was called
  #expect(mockCache.clearAllCacheCalled == true)
}

@Test("APIClient accepts dependency injection parameters")
func apiClientDependencyInjection() {
  let baseURL = URL(string: "https://api.example.com")!

  // Test with default configuration
  _ = APIClient(baseURL: baseURL)

  // Test with custom decoder
  let customDecoder = JSONDecoder()
  customDecoder.dateDecodingStrategy = .secondsSince1970
  _ = APIClient(baseURL: baseURL, decoder: customDecoder)

  // Test with custom cache
  let customCache = NilCodableCache()
  _ = APIClient(baseURL: baseURL, cache: customCache)

  // Test with both custom decoder and cache
  _ = APIClient(baseURL: baseURL, decoder: customDecoder, cache: customCache)

  // If we reach this point, all initializations succeeded
  #expect(true)
}
