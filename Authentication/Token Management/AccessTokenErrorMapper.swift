final class AccessTokenErrorMapper {
    private struct RefreshTokenErrorResponse: Decodable {
        let statusCode: Int
        let message: String
        let validationErrors: [ValidationRefreshTokenErrorModel]
    }

    private struct ValidationRefreshTokenErrorModel: Decodable {
        let field: String
        let resource: String?
        let error: String
    }

    private static var EXPIRED_REFRESH_TOKEN_401: Int { return 401 }

    static func map(from responseData: Data?, httpResponse: HTTPURLResponse?) -> TokenService.Error {
        guard let responseData,
              let httpResponse,
              httpResponse.statusCode == EXPIRED_REFRESH_TOKEN_401,
              let responseData = try? JSONDecoder().decode(RefreshTokenErrorResponse.self, from: responseData),
              !responseData.validationErrors.filter({ $0.resource == "Error_RefreshTokenCouldNotBeFound" }).isEmpty else {
            return .connectivitiy
        }

        return .invalidRefreshToken
    }
}
