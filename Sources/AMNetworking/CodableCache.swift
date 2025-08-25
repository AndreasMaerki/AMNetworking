import Foundation

/// Protocol defining the interface for caching `Codable` objects.
///
/// Implementations should provide thread-safe caching with automatic expiration
/// and the ability to invalidate specific entries or clear all cached data.
public protocol CodableCacheProtocol {
  /// Reads a cached object for the given key.
  ///
  /// - Parameter key: The cache key to lookup
  /// - Returns: The cached object if found and still valid, nil otherwise
  /// - Throws: Decoding errors if cached data is corrupted
  func read<T: Codable>(_ key: String) throws -> T?
  
  /// Writes an object to the cache with the given key.
  ///
  /// - Parameters:
  ///   - contents: The object to cache
  ///   - key: The cache key to store under
  func write(_ contents: some Codable, to key: String)
  
  /// Removes a specific cache entry.
  ///
  /// - Parameter key: The cache key to invalidate
  func invalidateCache(_ key: String)
  
  /// Removes all cache entries and associated metadata.
  func clearAllCache()
}

/// A file-based cache implementation for `Codable` objects with automatic expiration.
///
/// `CodableCache` stores objects as JSON files in the device's document directory
/// and tracks expiration times using UserDefaults. Cache keys are automatically
/// sanitized to be filesystem-safe.
///
/// ## Features
/// - Automatic expiration based on configurable TTL
/// - Thread-safe file operations with atomic writes
/// - Automatic cache key sanitization for filesystem safety
/// - Configurable cache file prefix for isolation
/// - Optional cache clearing on initialization
///
/// ## Example Usage
/// ```swift
/// let cache = CodableCache()
/// 
/// // Write to cache
/// cache.write(userData, to: "user_123")
/// 
/// // Read from cache (returns nil if expired)
/// let cachedUser: User? = try cache.read("user_123")
/// ```
public struct CodableCache: CodableCacheProtocol {
  private static let defaultCacheLifetime: TimeInterval = 60 * 10 // 10 minutes

  private let documentDirectory: URL?
  private let cacheLifetime: TimeInterval
  private let cacheFilePrefix: String

  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  /// Creates a new file-based cache with the specified configuration.
  ///
  /// - Parameters:
  ///   - documentDirectory: Directory to store cache files. Defaults to system document directory
  ///   - cacheLifetime: How long cached objects remain valid in seconds. Defaults to 10 minutes
  ///   - cacheFilePrefix: Prefix for cache filenames to avoid conflicts. Defaults to "AMNetworkingCache_"
  ///   - clearOnInit: Whether to clear existing cache on initialization. Defaults to true
  init(
    _ documentDirectory: URL? = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    ).first,
    _ cacheLifetime: TimeInterval = CodableCache.defaultCacheLifetime,
    _ cacheFilePrefix: String = "AMNetworkingCache_",
    _ clearOnInit: Bool = true
  ) {
    self.documentDirectory = documentDirectory
    self.cacheLifetime = cacheLifetime
    self.cacheFilePrefix = cacheFilePrefix

    // clear all so that on app launch we start fresh
    if clearOnInit {
      clearAllCache()
    }
  }

  public func read<T: Codable>(_ key: String) throws -> T? {
    guard !needsRefreshFor(key) else { return nil }
    guard let fileURL = fileForKey(key),
          FileManager.default.fileExists(atPath: fileURL.path)
    else {
      return nil
    }
    let data = try Data(contentsOf: fileURL)
    return try decoder.decode(T.self, from: data)
  }

  public func write(_ contents: some Codable, to key: String) {
    guard let fileURL = fileForKey(key) else {
      return
    }

    encoder.outputFormatting = [.prettyPrinted]
    let data = try? encoder.encode(contents)
    try? data?.write(to: fileURL, options: [.atomic])
    saveLastFetchTimeFor(key)
  }

  public func invalidateCache(_ key: String) {
    guard let fileURL = fileForKey(key) else {
      return
    }
    try? FileManager.default.removeItem(at: fileURL)
    deleteLastFetchTimeFor(key)
  }

  public func clearAllCache() {
    // Clear all cache files
    guard let documentDirectory else { return }

    do {
      let fileURLs = try FileManager.default.contentsOfDirectory(
        at: documentDirectory,
        includingPropertiesForKeys: nil
      )

      // Remove files that match our cache prefix
      let cacheFiles = fileURLs.filter { url in
        let fileName = url.lastPathComponent
        return fileName.hasPrefix(cacheFilePrefix)
      }

      for fileURL in cacheFiles {
        try? FileManager.default.removeItem(at: fileURL)
      }

      // Clear corresponding UserDefaults entries
      // Since UserDefaults keys now use the same sanitized format as filenames,
      // we can map them directly
      for cacheFile in cacheFiles {
        let userDefaultsKey = cacheFile.lastPathComponent
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
      }
    } catch {
      // Silently ignore directory reading errors as cache clearing is best-effort
    }
  }

  private func fileForKey(_ key: String) -> URL? {
    let safeKey = sanitizeCacheKey(key)
    return documentDirectory?.appendingPathComponent(cacheFilePrefix + safeKey, isDirectory: false)
  }

  private func sanitizeCacheKey(_ key: String) -> String {
    // Replace filesystem-unsafe characters with underscores
    let unsafeCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|&")
    return key.components(separatedBy: unsafeCharacters).joined(separator: "_")
  }

  private func needsRefreshFor(_ key: String) -> Bool {
    guard let lastFetchTime = lastFetchTimeFor(key) else {
      return true
    }
    return Date().timeIntervalSince(lastFetchTime) > cacheLifetime
  }

  private func saveLastFetchTimeFor(_ key: String) {
    let safeKey = sanitizeCacheKey(key)
    UserDefaults.standard.set(Date(), forKey: cacheFilePrefix + safeKey)
  }

  private func deleteLastFetchTimeFor(_ key: String) {
    let safeKey = sanitizeCacheKey(key)
    UserDefaults.standard.removeObject(forKey: cacheFilePrefix + safeKey)
  }

  private func lastFetchTimeFor(_ key: String) -> Date? {
    let safeKey = sanitizeCacheKey(key)
    return UserDefaults.standard.object(forKey: cacheFilePrefix + safeKey) as? Date
  }
}

/// A no-op cache implementation that disables caching entirely.
///
/// Use `NilCodableCache` when you want to disable caching behavior,
/// such as during development or for specific use cases where fresh
/// data is always required.
///
/// ## Example Usage
/// ```swift
/// // Create an APIClient with no caching
/// let client = APIClient(
///     baseURL: URL(string: "https://api.example.com")!,
///     cache: NilCodableCache()
/// )
/// ```
public struct NilCodableCache: CodableCacheProtocol {
  public func read<T>(_ key: String) throws -> T? where T: Decodable, T: Encodable { nil }
  public func write(_ contents: some Codable, to key: String) {}
  public func invalidateCache(_ key: String) {}
  public func clearAllCache() {}
}
