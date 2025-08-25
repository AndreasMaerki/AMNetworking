import Foundation

public enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
  case patch = "PATCH"
  case head = "HEAD"
  case options = "OPTIONS"

  var requiresBody: Bool {
    switch self {
    case .post,
         .put,
         .patch:
      true
    case .get,
         .delete,
         .head,
         .options:
      false
    }
  }
}
