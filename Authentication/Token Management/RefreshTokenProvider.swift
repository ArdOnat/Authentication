public protocol RefreshTokenProvider {
    var refreshToken: String { get }
}

public class TokenStore: RefreshTokenProvider {
    public var refreshToken: String = ""

    public init() {
        
    }
}
