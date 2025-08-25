@testable import AMNetworking
import Foundation
import Testing

// MARK: - CodableCache Tests

private struct TestModel: Codable, Equatable {
  let id: Int
  let name: String
}

@Test
func codableCacheWriteAndRead() throws {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  let cache = CodableCache(tempDir, 600, "WriteRead_")
  let testModel = TestModel(id: 1, name: "Test User")

  // Write to cache
  cache.write(testModel, to: "user_1")

  // Read from cache
  let cachedModel: TestModel? = try cache.read("user_1")

  #expect(cachedModel == testModel)
}

@Test
func codableCacheReturnsNilForMissingKey() throws {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  let cache = CodableCache(tempDir, 600, "Missing_")

  let result: TestModel? = try cache.read("nonexistent_key")
  #expect(result == nil)
}

@Test
func codableCacheInvalidation() throws {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  let cache = CodableCache(tempDir, 600, "Invalidate_")
  let testModel = TestModel(id: 1, name: "Test User")

  // Write and verify it exists
  cache.write(testModel, to: "user_1")
  let cachedModel: TestModel? = try cache.read("user_1")
  #expect(cachedModel == testModel)

  // Invalidate and verify it's gone
  cache.invalidateCache("user_1")
  let invalidatedModel: TestModel? = try cache.read("user_1")
  #expect(invalidatedModel == nil)
}

@Test
func codableCacheExpiration() throws {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  // Use very short cache lifetime (1 second) and don't clear on init
  let cache = CodableCache(tempDir, 1.0, "Expire_", false)
  let testModel = TestModel(id: 1, name: "Test User")

  // Write to cache
  cache.write(testModel, to: "user_1")

  // Should be available immediately
  let cachedModel: TestModel? = try cache.read("user_1")
  #expect(cachedModel == testModel)

  // Wait for expiration
  Thread.sleep(forTimeInterval: 1.1)

  // Should return nil after expiration
  let expiredModel: TestModel? = try cache.read("user_1")
  #expect(expiredModel == nil)
}

@Test
func codableCacheKeySanitization() throws {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  let cache = CodableCache(tempDir, 600, "Sanitize_")
  let testModel = TestModel(id: 1, name: "Test User")

  // Use a key with unsafe filesystem characters
  let unsafeKey = "api/users/1?include=posts&format=json"

  // Should work without throwing filesystem errors
  cache.write(testModel, to: unsafeKey)
  let cachedModel: TestModel? = try cache.read(unsafeKey)

  #expect(cachedModel == testModel)

  // Verify file was created with sanitized name
  let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
  let cacheFiles = contents.filter { $0.lastPathComponent.hasPrefix("Sanitize_") }
  #expect(cacheFiles.count == 1)

  // Verify the filename doesn't contain unsafe characters
  let fileName = cacheFiles.first!.lastPathComponent
  #expect(!fileName.contains("/"))
  #expect(!fileName.contains("?"))
  #expect(!fileName.contains("&"))
}

@Test
func codableCacheClearAll() throws {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  // Don't clear on init so we can test the clearAll functionality
  let cache = CodableCache(tempDir, 600, "ClearAll_", false)
  let testModel1 = TestModel(id: 1, name: "User 1")
  let testModel2 = TestModel(id: 2, name: "User 2")

  // Write multiple items
  cache.write(testModel1, to: "user_1")
  cache.write(testModel2, to: "user_2")

  // Verify they exist
  let cached1: TestModel? = try cache.read("user_1")
  let cached2: TestModel? = try cache.read("user_2")
  #expect(cached1 == testModel1)
  #expect(cached2 == testModel2)

  // Clear all cache
  cache.clearAllCache()

  // Verify all items are gone
  let cleared1: TestModel? = try cache.read("user_1")
  let cleared2: TestModel? = try cache.read("user_2")
  #expect(cleared1 == nil)
  #expect(cleared2 == nil)

  // Verify files are deleted
  let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
  let cacheFiles = contents.filter { $0.lastPathComponent.hasPrefix("ClearAll_") }
  #expect(cacheFiles.isEmpty)
}

@Test
func codableCachePrefixIsolation() throws {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  let cache1 = CodableCache(tempDir, 600, "Cache1_")
  let cache2 = CodableCache(tempDir, 600, "Cache2_")
  let testModel = TestModel(id: 1, name: "Test User")

  // Write to both caches with same key
  cache1.write(testModel, to: "shared_key")
  cache2.write(testModel, to: "shared_key")

  // Verify both exist
  let cached1: TestModel? = try cache1.read("shared_key")
  let cached2: TestModel? = try cache2.read("shared_key")
  #expect(cached1 == testModel)
  #expect(cached2 == testModel)

  // Clear only cache1
  cache1.clearAllCache()

  // Verify cache1 is cleared but cache2 remains
  let cleared1: TestModel? = try cache1.read("shared_key")
  let remaining2: TestModel? = try cache2.read("shared_key")
  #expect(cleared1 == nil)
  #expect(remaining2 == testModel)
}

@Test
func codableCacheUserDefaultsCleanup() throws {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  let cache = CodableCache(tempDir, 600, "TestDefaults_", false)
  let testModel = TestModel(id: 1, name: "Test User")

  // Write to cache
  cache.write(testModel, to: "test_key")

  // Verify UserDefaults entry exists
  let userDefaultsKey = "TestDefaults_test_key"
  let timestamp = UserDefaults.standard.object(forKey: userDefaultsKey) as? Date
  #expect(timestamp != nil)

  // Clear all cache
  cache.clearAllCache()

  // Verify UserDefaults entry is removed
  let clearedTimestamp = UserDefaults.standard.object(forKey: userDefaultsKey) as? Date
  #expect(clearedTimestamp == nil)
}

@Test
func codableCacheInitializationClearsExisting() throws {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  // Create initial cache and write data
  let cache1 = CodableCache(tempDir, 600, "Init_")
  let testModel = TestModel(id: 1, name: "Test User")
  cache1.write(testModel, to: "test_key")

  // Verify data exists
  let cached: TestModel? = try cache1.read("test_key")
  #expect(cached == testModel)

  // Create new cache instance with same prefix (should clear on init)
  let cache2 = CodableCache(tempDir, 600, "Init_")

  // Verify data is cleared
  let cleared: TestModel? = try cache2.read("test_key")
  #expect(cleared == nil)
}

@Test
func codableCacheHandlesMalformedData() throws {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }

  let cache = CodableCache(tempDir, 600, "Malformed_")

  // Manually write malformed JSON to cache file
  let fileURL = tempDir.appendingPathComponent("Malformed_malformed_key")
  let malformedData = "{ invalid json }".data(using: .utf8)!
  try malformedData.write(to: fileURL)

  // Set timestamp so it's considered fresh
  UserDefaults.standard.set(Date(), forKey: "Malformed_malformed_key")

  // Reading should throw a decoding error
  #expect(throws: DecodingError.self) {
    let _: TestModel? = try cache.read("malformed_key")
  }
}

// MARK: - NilCodableCache Tests

@Test
func nilCodableCacheAlwaysReturnsNil() throws {
  let cache = NilCodableCache()
  let testModel = TestModel(id: 1, name: "Test User")

  // Write operation should do nothing
  cache.write(testModel, to: "test_key")

  // Read should always return nil
  let result: TestModel? = try cache.read("test_key")
  #expect(result == nil)
}

@Test
func nilCodableCacheOperationsDoNothing() {
  let cache = NilCodableCache()

  // These operations should not crash or throw
  cache.invalidateCache("any_key")
  cache.clearAllCache()

  // Test passes if we reach this point without errors
  #expect(Bool(true))
}
