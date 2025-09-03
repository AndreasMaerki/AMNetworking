import Foundation

/// Protocol defining authentication providers for HTTP requests.
///
/// `AuthenticationProvider` allows different authentication mechanisms to be
/// plugged into the networking layer. Implementations should return the appropriate
/// authentication headers for their specific authentication type.
///
/// ## Available Implementations
/// - `BasicAuthProvider`: Username/password basic authentication
/// - `BearerTokenProvider`: Token-based authentication (JWT, OAuth, etc.)
///
/// ## Example Usage
/// ```swift
/// // Basic authentication
/// let basicAuth = BasicAuthProvider(username: "user", password: "password")
/// let client = APIClient(baseURL: baseURL, authentication: basicAuth)
///
/// // Bearer token authentication
/// let tokenAuth = BearerTokenProvider(token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
/// let client = APIClient(baseURL: baseURL, authentication: tokenAuth)
/// ```
public protocol AuthenticationProvider {
  /// Returns the authentication headers to be added to HTTP requests.
  ///
  /// - Returns: A dictionary of header field names and values for authentication
  func authenticationHeaders() -> [String: String]
}

/// Provides HTTP Basic Authentication using username and password.
///
/// `BasicAuthProvider` implements the HTTP Basic Authentication scheme as defined
/// in RFC 7617. It automatically encodes the username and password combination
/// using Base64 encoding and adds the appropriate Authorization header.
///
/// ## Security Considerations
/// - Basic auth transmits credentials in Base64 encoding (not encryption)
/// - Always use HTTPS when using basic authentication in production
/// - Consider using more secure authentication methods for sensitive applications
///
/// ## Example Usage
/// ```swift
/// let basicAuth = BasicAuthProvider(username: "admin", password: "secret123")
/// let client = APIClient(baseURL: baseURL, authentication: basicAuth)
///
/// // All requests will automatically include:
/// // Authorization: Basic YWRtaW46c2VjcmV0MTIz
/// let users: [User] = try await client.get(path: "/users")
/// ```
public struct BasicAuthProvider: AuthenticationProvider, Sendable {
  private let username: String
  private let password: String

  /// Creates a new basic authentication provider.
  ///
  /// - Parameters:
  ///   - username: The username for authentication
  ///   - password: The password for authentication
  public init(username: String, password: String) {
    self.username = username
    self.password = password
  }

  /// Returns the Basic Authentication header.
  ///
  /// - Returns: Dictionary containing the Authorization header with Base64-encoded credentials
  public func authenticationHeaders() -> [String: String] {
    let credentials = "\(username):\(password)"
    let encodedCredentials = Data(credentials.utf8).base64EncodedString()
    return ["Authorization": "Basic \(encodedCredentials)"]
  }
}

/// Provides Bearer Token Authentication for APIs.
///
/// `BearerTokenProvider` implements Bearer token authentication as commonly used
/// with JWT tokens, OAuth 2.0 access tokens, and other token-based authentication
/// schemes. The token is included in the Authorization header with the "Bearer" prefix.
///
/// ## Common Use Cases
/// - JWT (JSON Web Token) authentication
/// - OAuth 2.0 access tokens
/// - API keys that use Bearer token format
/// - Custom authentication tokens
///
/// ## Example Usage
/// ```swift
/// // JWT token
/// let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
/// let tokenAuth = BearerTokenProvider(token: jwtToken)
/// let client = APIClient(baseURL: baseURL, authentication: tokenAuth)
///
/// // All requests will automatically include:
/// // Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
/// let profile: UserProfile = try await client.get(path: "/profile")
/// ```
public struct BearerTokenProvider: AuthenticationProvider, Sendable {
  private let token: String

  /// Creates a new bearer token authentication provider.
  ///
  /// - Parameter token: The bearer token (without the "Bearer " prefix)
  public init(token: String) {
    self.token = token
  }

  /// Returns the Bearer Token Authentication header.
  ///
  /// - Returns: Dictionary containing the Authorization header with the bearer token
  public func authenticationHeaders() -> [String: String] {
    ["Authorization": "Bearer \(token)"]
  }
}
