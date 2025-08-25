import Foundation

public protocol CodableCacheProtocol {
  func read<T: Codable>(_ key: String) throws -> T?
  func write(_ contents: some Codable, to key: String)
  func invalidateCache(_ key: String)
  func clearAllCache()
}

public struct CodableCache: CodableCacheProtocol {
  private static let defaultCacheLifetime: TimeInterval = 60 * 10 // 10 minutes

  private let documentDirectory: URL?
  private let cacheLifetime: TimeInterval
  private let cacheFilePrefix: String

  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  init(
    _ documentDirectory: URL? = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    ).first,
    _ cacheLifetime: TimeInterval = CodableCache.defaultCacheLifetime,
    _ cacheFilePrefix: String = "AMNetworkingCache_"
  ) {
    self.documentDirectory = documentDirectory
    self.cacheLifetime = cacheLifetime
    self.cacheFilePrefix = cacheFilePrefix

    // clear all so that on app launch we start fresh
    clearAllCache()
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
    let unsafeCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
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

public struct NilCodableCache: CodableCacheProtocol {
  public func read<T>(_ key: String) throws -> T? where T: Decodable, T: Encodable { nil }
  public func write(_ contents: some Codable, to key: String) {}
  public func invalidateCache(_ key: String) {}
  public func clearAllCache() {}
}
