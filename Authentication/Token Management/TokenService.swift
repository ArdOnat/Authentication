import Foundation

/// Fetches new Access Token
/// Fetches new Refresh Token
///
public final class TokenService: TokenRefresher {
    private let url: URL
    private let networkClient: NetworkClient
    private var refreshTokenProvider: RefreshTokenProvider

    public enum Error: Swift.Error {
        case invalidData
        case connectivitiy
        case invalidRefreshToken
    }

    public init(url: URL, networkClient: NetworkClient, refreshTokenProvider: RefreshTokenProvider) {
        self.url = url
        self.networkClient = networkClient
        self.refreshTokenProvider = refreshTokenProvider
    }

    public func refreshAccessToken(completion: @escaping (RefreshAccessTokenResult) -> Void) {
        networkClient.execute(request: Request(url: url, header: ["Cookie": refreshTokenProvider.refreshToken])) { [weak self] (result: Result<NetworkClientResponse, NetworkClientError>) in
            guard self != nil else { return }
            switch result {
            case .success(let response):
                completion(AccessTokenMapper.map(from: response.responseData, httpResponse: response.httpURLResponse))
            case .failure(let error):
                completion(.failure(AccessTokenErrorMapper.map(from: error.responseData, httpResponse: error.httpURLResponse)))
            }
        }
    }
}
