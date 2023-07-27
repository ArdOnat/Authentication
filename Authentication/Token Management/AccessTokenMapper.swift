final class AccessTokenMapper {
    private struct RefreshAccessTokenResponse: Decodable {
        let statusCode: Int
        let message: String
        let details: JWTTokenDetailModel?
        let validationErrors: [ValidationErrorModel]?
    }

    private struct JWTTokenDetailModel: Decodable {
        let jwtToken: String
        let jwtTokenValidUntil: String
        let userID: Int
    }

    private struct ValidationErrorModel: Decodable {
        let field: String
        let error: String
    }

    private static var OK_200: Int { return 200 }

    static func map(from responseData: Data, httpResponse: HTTPURLResponse) -> Result<String, Error> {
        guard httpResponse.statusCode == OK_200,
                let responseData = try? JSONDecoder().decode(RefreshAccessTokenResponse.self, from: responseData),
                let tokenDetails = responseData.details else {
            return .failure(TokenService.Error.invalidData)
        }

        return .success(tokenDetails.jwtToken)
    } //w
}
