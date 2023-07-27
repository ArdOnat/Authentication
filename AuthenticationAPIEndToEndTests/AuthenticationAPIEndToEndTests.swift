import XCTest
import Authentication

final class AuthenticationAPIEndToEndTests: XCTestCase {

    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() {
        let testServerURL = URL(string: "https://wa.ooautos.com/api/mobile/refresh-jwt-token")!
        let client = URLSessionNetworkClient()
        let refreshTokenProvider = TokenStore()
        let tokenService = TokenService(url: testServerURL, networkClient: client, refreshTokenProvider: refreshTokenProvider)

        let exp = expectation(description: "Wait for token refresh")
        var receivedResult: RefreshAccessTokenResult?

        tokenService.refreshAccessToken { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5)

        switch receivedResult {
        case let .success(token):
            XCTAssertEqual(token, "Arda")
        case let .failure(error)?:
            XCTFail("Expected successful feed result, got \(error) instead")
        default:
            XCTFail("Expected successful feed result, got no result instead")
        }
    }
}
