import Foundation

protocol CodableCacheProtocol {
  func read<T: Codable>(_ key: String) throws -> T?
  func write(_ contents: some Codable, to key: String)
  func invalidateCache(_ key: String)
  func clearAllCache()
}

struct CodableCache: CodableCacheProtocol {
  private let documentDirectory: URL?
  private let cacheLifetime: TimeInterval

  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  init(
    _ documentDirectory: URL? = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    ).first,
    _ cacheLifetime: TimeInterval = 60 * 10
  ) {
    self.documentDirectory = documentDirectory
    self.cacheLifetime = cacheLifetime

    // clear all so that on app launch we start fresh
    clearAllCache()
  }

  func read<T: Codable>(_ key: String) throws -> T? {
    guard !needsRefreshFor(key) else { return nil }
    guard let fileURL = fileForKey(key),
          FileManager.default.fileExists(atPath: fileURL.path)
    else {
      return nil
    }
    do {
      let data = try Data(contentsOf: fileURL)
      return try decoder.decode(T.self, from: data)
    } catch {
      throw RequestError.unknownError(error)
    }
  }

  func write(_ contents: some Codable, to key: String) {
    guard let fileURL = fileForKey(key) else {
      return
    }

    encoder.outputFormatting = [.prettyPrinted]
    let data = try? encoder.encode(contents)
    try? data?.write(to: fileURL, options: [.atomic])
    saveLastFetchTimeFor(key)
  }

  func invalidateCache(_ key: String) {
    guard let fileURL = fileForKey(key) else {
      return
    }
    try? FileManager.default.removeItem(at: fileURL)
    deleteLastFetchTimeFor(key)
  }

  func clearAllCache() {
    // Clear all cache files
    guard let documentDirectory else { return }

    do {
      let fileURLs = try FileManager.default.contentsOfDirectory(
        at: documentDirectory,
        includingPropertiesForKeys: nil
      )

      // Remove files that match our cache patterns (events, eventLD*, countries)
      let cacheFiles = fileURLs.filter { url in
        let fileName = url.lastPathComponent
        return fileName == "events" ||
          fileName == "countries" ||
          fileName.hasPrefix("eventLD")
      }

      for fileURL in cacheFiles {
        try? FileManager.default.removeItem(at: fileURL)
      }
    } catch {
      print("Error clearing cache files: \(error)")
    }
  }

  private func fileForKey(_ key: String) -> URL? {
    documentDirectory?.appendingPathComponent(key, isDirectory: false)
  }

  private func needsRefreshFor(_ key: String) -> Bool {
    guard let lastFetchTime = lastFetchTimeFor(key) else {
      return true
    }
    return Date().timeIntervalSince(lastFetchTime) > cacheLifetime
  }

  private func saveLastFetchTimeFor(_ key: String) {
    UserDefaults.standard.set(Date(), forKey: key)
  }

  private func deleteLastFetchTimeFor(_ key: String) {
    UserDefaults.standard.removeObject(forKey: key)
  }

  private func lastFetchTimeFor(_ key: String) -> Date? {
    UserDefaults.standard.object(forKey: key) as? Date
  }
}

public struct NilCodableCache: CodableCacheProtocol {
  func read<T>(_ key: String) throws -> T? where T: Decodable, T: Encodable { nil }
  func write(_ contents: some Codable, to key: String) {}
  func invalidateCache(_ key: String) {}
  func clearAllCache() {}
}
