public protocol TokenRefresher {
    func refreshAccessToken(completion: @escaping (RefreshAccessTokenResult) -> Void)
}

public typealias RefreshAccessTokenResult = Result<String, Error>
