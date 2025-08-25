# AMNetworking

A modern, lightweight Swift networking library with built-in caching and robust error handling.

> **Note:** This library is a work in progress I developed for my personal use. Additional features will be added on a need-to-basis as requirements evolve.

## Features

- ✅ **Modern async/await API** - Clean, readable networking code
- ✅ **Built-in Response Caching** - Automatic caching with configurable TTL
- ✅ **Type-Safe Error Handling** - Comprehensive error types with detailed information
- ✅ **Dependency Injection** - Flexible initialization with custom decoders and caches
- ✅ **iOS 15+ Support** - Built for modern iOS development
- ✅ **Protocol-Oriented Design** - Testable and extensible architecture

## Installation

### Swift Package Manager

Add AMNetworking to your project using Xcode:

1. **File → Add Package Dependencies**
2. **Enter URL**: `https://github.com/AndreasMaerki/AMNetworking.git`
3. **Select version**: `1.0.0` or later
4. **Add to your target**

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AndreasMaerki/AMNetworking.git", from: "1.0.0")
]
```

## Quick Start

```swift
import AMNetworking

// Initialize the API client
let client = APIClient(baseURL: URL(string: "https://jsonplaceholder.typicode.com")!)

// Define your models
struct Post: Codable {
    let id: Int
    let title: String
    let body: String
    let userId: Int
}

// Make requests
do {
    // GET request
    let posts: [Post] = try await client.get(path: "/posts")
    print("Fetched \(posts.count) posts")
    
    // POST request
    let newPost = Post(id: 0, title: "My Post", body: "Post content", userId: 1)
    let createdPost: Post = try await client.post(path: "/posts", body: newPost)
    print("Created post with ID: \(createdPost.id)")
    
} catch {
    print("Request failed: \(error)")
}
```

## Advanced Usage

### Custom Configuration

```swift
// Custom JSON decoder
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
decoder.keyDecodingStrategy = .convertFromSnakeCase

// Custom cache (or disable caching)
let customCache = CodableCache(
    nil, // custom directory
    300, // 5 minute cache lifetime
    "MyApp_" // custom cache prefix
)

// Initialize with custom configuration
let client = APIClient(
    baseURL: baseURL,
    decoder: decoder,
    cache: customCache
)
```

### Cache Management

```swift
// GET with cache control
let users: [User] = try await client.get(
    path: "/users",
    invalidateCache: true // Force refresh
)

// Clear all cached data
client.clearAllCache()
```

### Query Parameters

```swift
let queryItems = [
    URLQueryItem(name: "page", value: "1"),
    URLQueryItem(name: "limit", value: "10")
]

let posts: [Post] = try await client.get(
    path: "/posts",
    queryItems: queryItems
)
```

## Error Handling

AMNetworking provides comprehensive error handling with detailed information:

```swift
do {
    let data: MyModel = try await client.get(path: "/endpoint")
} catch RequestError.unauthorised {
    // Handle 401 - redirect to login
    showLoginScreen()
} catch RequestError.notFound {
    // Handle 404 - show not found message
    showNotFoundAlert()
} catch RequestError.decodingError(let decodingError) {
    // Handle JSON parsing errors with full context
    print("Parsing failed: \(decodingError.localizedDescription)")
} catch RequestError.networkError(let networkError) {
    // Handle network connectivity issues
    print("Network error: \(networkError.localizedDescription)")
} catch {
    // Handle any other errors
    print("Unexpected error: \(error)")
}
```

### Error Types

- **`invalidURL`** - Malformed URL
- **`missingBody`** - Required request body missing
- **`encodingError(EncodingError)`** - JSON encoding failed
- **`decodingError(DecodingError)`** - JSON decoding failed
- **`networkError(Error)`** - Network connectivity issues
- **`unauthorised`** - 401 HTTP status
- **`forbidden`** - 403 HTTP status
- **`notFound`** - 404 HTTP status
- **`internalServerError`** - 500 HTTP status
- **`unexpectedStatusCode(Int)`** - Other HTTP status codes
- **`unknownError(Error)`** - Unexpected errors

## Caching

AMNetworking includes intelligent caching:

- **Automatic**: Responses are cached automatically
- **TTL-based**: 10-minute default cache lifetime (configurable)
- **Path-based keys**: Each endpoint is cached separately

### Cache Behavior

```swift
// First call - fetches from network and caches
let users: [User] = try await client.get(path: "/users")

// Second call within 10 minutes - returns cached data
let cachedUsers: [User] = try await client.get(path: "/users")

// Force refresh - bypasses cache
let freshUsers: [User] = try await client.get(path: "/users", invalidateCache: true)
```

## Testing

For testing, use the `NilCodableCache` to disable caching:

```swift
let testClient = APIClient(
    baseURL: testURL,
    cache: NilCodableCache()
)
```

## Requirements

- iOS 15.0+
- Swift 6.1+
- Xcode 14.0+

## Architecture

AMNetworking follows modern Swift best practices:

- **Protocol-oriented design** for testability
- **Dependency injection** for flexibility  
- **Typed errors** for robust error handling
- **async/await** for clean concurrency
- **Separation of concerns** between networking, caching, and validation

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
