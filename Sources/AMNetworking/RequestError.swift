import Foundation

public enum RequestError: Error, LocalizedError {
  case invalidURL
  case missingBody
  case invalidResponse
  case encodingError(EncodingError)
  case decodingError(DecodingError)
  case networkError(Error)
  case unauthorised
  case forbidden
  case notFound
  case methodNotAllowed
  case internalServerError
  case badGateway
  case serviceUnavailable
  case unexpectedStatusCode(Int)
  case parsingError(Error)
  case unknownError(Error)

  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      "The URL is invalid"
    case .missingBody:
      "Request body is required for this method"
    case .invalidResponse:
      "Invalid response from server"
    case let .encodingError(error):
      "Failed to encode request body: \(error.localizedDescription)"
    case let .decodingError(error):
      "Failed to decode response body: \(error.localizedDescription)"
    case let .networkError(error):
      "Network error: \(error.localizedDescription)"
    case .unauthorised:
      "Unauthorised: Authentication is required and has failed or has not yet been provided"
    case .forbidden:
      "Forbidden: The server understood the request but refuses to authorise it"
    case .notFound:
      "Not Found: The requested resource could not be found"
    case .methodNotAllowed:
      "Method Not Allowed: The request method is not supported for the requested resource"
    case .internalServerError:
      "Internal Server Error: The server encountered an unexpected condition that prevented it from fulfilling the request"
    case .badGateway:
      "Bad Gateway: The server was acting as a gateway or proxy and received an invalid response from the upstream server"
    case .serviceUnavailable:
      "Service Unavailable: The server is not ready to handle the request"
    case let .unexpectedStatusCode(statusCode):
      "Unexpected status code: \(statusCode)"
    case let .parsingError(error):
      "Parsing error: \(error.localizedDescription)"
    case let .unknownError(error):
      "Unknown error: \(error.localizedDescription)"
    }
  }

  // Convenience initializer to map HTTP status codes to RequestError cases
  init(statusCode: Int) {
    switch statusCode {
    case 400:
      self = .invalidResponse
    case 401:
      self = .unauthorised
    case 403:
      self = .forbidden
    case 404:
      self = .notFound
    case 405:
      self = .methodNotAllowed
    case 500:
      self = .internalServerError
    case 502:
      self = .badGateway
    case 503:
      self = .serviceUnavailable
    default:
      self = .unexpectedStatusCode(statusCode)
    }
  }
}
