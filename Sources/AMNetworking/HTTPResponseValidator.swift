import Foundation

struct HTTPResponseValidator {
  func validateResponse(_ response: URLResponse) throws(RequestError) {
    guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
      throw RequestError.unexpectedStatusCode(-1)
    }

    guard (200 ... 299).contains(statusCode) else {
      throw RequestError(statusCode: statusCode)
    }
  }
}
