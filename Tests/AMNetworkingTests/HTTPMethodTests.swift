@testable import AMNetworking
import Foundation
import Testing

// MARK: - HTTPMethod Tests

@Test("HTTPMethod raw values are correct")
func httpMethodRawValues() {
  #expect(HTTPMethod.get.rawValue == "GET")
  #expect(HTTPMethod.post.rawValue == "POST")
  #expect(HTTPMethod.put.rawValue == "PUT")
  #expect(HTTPMethod.delete.rawValue == "DELETE")
  #expect(HTTPMethod.patch.rawValue == "PATCH")
  #expect(HTTPMethod.head.rawValue == "HEAD")
  #expect(HTTPMethod.options.rawValue == "OPTIONS")
}

@Test("HTTPMethod body requirements")
func httpMethodBodyRequirements() {
  // Methods that require a body
  #expect(HTTPMethod.post.requiresBody == true)
  #expect(HTTPMethod.put.requiresBody == true)
  #expect(HTTPMethod.patch.requiresBody == true)

  // Methods that don't require a body
  #expect(HTTPMethod.get.requiresBody == false)
  #expect(HTTPMethod.delete.requiresBody == false)
  #expect(HTTPMethod.head.requiresBody == false)
  #expect(HTTPMethod.options.requiresBody == false)
}

@Test("HTTPMethod can be created from raw values")
func httpMethodFromRawValues() {
  #expect(HTTPMethod(rawValue: "GET") == .get)
  #expect(HTTPMethod(rawValue: "POST") == .post)
  #expect(HTTPMethod(rawValue: "PUT") == .put)
  #expect(HTTPMethod(rawValue: "DELETE") == .delete)
  #expect(HTTPMethod(rawValue: "PATCH") == .patch)
  #expect(HTTPMethod(rawValue: "HEAD") == .head)
  #expect(HTTPMethod(rawValue: "OPTIONS") == .options)

  // Invalid raw values return nil
  #expect(HTTPMethod(rawValue: "INVALID") == nil)
  #expect(HTTPMethod(rawValue: "get") == nil) // case sensitive
}
