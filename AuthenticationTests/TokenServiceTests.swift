import XCTest
@testable import Authentication

class TokenServiceTests: XCTestCase {

    func test_init_doesNotMakeAnyRequests() {
        let refreshTokenProvider = RefreshTokenProviderStub()

        let (_, client) = makeSUT(refreshTokenProvider: refreshTokenProvider)

        XCTAssertTrue(client.requestedURLs.isEmpty)
        XCTAssertTrue(client.requestedHeaders.isEmpty)
    }

    func test_refreshAccessToken_requestsDataFromURL() {
        let url = URL(string:"https://a-given-url.com")!

        let (sut, client) = makeSUT(url: url)
        sut.refreshAccessToken(completion: { _ in })

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_refreshAccessToken_requestsDataFromURLTwice() {
        let url = URL(string:"https://a-given-url.com")!

        let (sut, client) = makeSUT(url: url)
        sut.refreshAccessToken(completion: { _ in })
        sut.refreshAccessToken(completion: { _ in })

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_refreshAccessToken_usesRefreshTokenFromTokenStoreToSetRelatedHeader() {
        let refreshTokenProvider = RefreshTokenProviderStub()
        let refreshToken = randomString(length: 5)
        refreshTokenProvider.refreshToken = refreshToken

        let (sut, client) = makeSUT(refreshTokenProvider: refreshTokenProvider)
        sut.refreshAccessToken(completion: { _ in })

        XCTAssertEqual(client.requestedHeaders, [["Cookie": refreshToken]])
    }

    func test_refreshAccessTokenTwice_usesRefreshTokenFromTokenStoreToAddCookieHeaderOncePerEachRequest() {
        let refreshTokenProvider = RefreshTokenProviderStub()
        let refreshToken = randomString(length: 5)
        refreshTokenProvider.refreshToken = refreshToken

        let (sut, client) = makeSUT(refreshTokenProvider: refreshTokenProvider)
        sut.refreshAccessToken(completion: { _ in })
        sut.refreshAccessToken(completion: { _ in })

        XCTAssertEqual(client.requestedHeaders, [["Cookie": refreshToken], ["Cookie": refreshToken]])
    }

    func test_refreshAccessToken_returnsConnectivityErrorOnClientError() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(TokenService.Error.connectivitiy)) {
            let clientError = NetworkClientError(responseData: Data(), httpURLResponse: HTTPURLResponse())
            client.complete(with: clientError)
        }
    }

    func test_refreshAccessToken_returnsConnectivityErrorOn401HTTPResponseWithoutRefreshTokenErrorData() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(TokenService.Error.connectivitiy)) {
            let errorResponseWithoutRefreshTokenError = Data("{ \"statusCode\": 401, \"message\": \"message\", \"validationErrors\": [] }".utf8)
            client.complete(with: .init(responseData: errorResponseWithoutRefreshTokenError, httpURLResponse: HTTPURLResponse(url: URL(string: "anyurl.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)!))
        }
    }

    func test_refreshAccessToken_returnsInvalidStatusCodeErrorOn401HTTPResponseWithRefreshTokenErrorData() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(TokenService.Error.invalidRefreshToken)) {
            let errorResponseWithRefreshTokenError = Data("{ \"statusCode\": 401, \"message\": \"message\", \"validationErrors\": [{\"field\": \"field\",\"resource\": \"Error_RefreshTokenCouldNotBeFound\", \"error\": \"error\"}] }".utf8)
            client.complete(with: .init(responseData: errorResponseWithRefreshTokenError, httpURLResponse: HTTPURLResponse(url: URL(string: "anyurl.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)!))
        }
    }

    func test_refreshAccessToken_returnsConnectivityErrorOnNon200Non401HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(TokenService.Error.connectivitiy)) {
                let validJSON = Data("{ \"statusCode\": 200, \"message\": \"message\", \"details\": { \"jwtToken\": \"accessToken\", \"jwtTokenValidUntil\": \"sometime\", \"userID\": 35} }".utf8)
                client.complete(with: .init(responseData: validJSON, httpURLResponse: HTTPURLResponse(url: URL(string: "anyurl.com")!, statusCode: code, httpVersion: nil, headerFields: nil)!), at: index)
            }
        }
    }

    func test_refreshAccessToken_returnsInvalidDataErrorOnInvalidClientData() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(TokenService.Error.invalidData)) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }

    func test_refreshAccessToken_returnsInvalidDataErrorOnClientDataMissingTokenDetails() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(TokenService.Error.invalidData)) {
            let validJSON = Data("{ \"statusCode\": 200, \"message\": \"message\" }".utf8)
            client.complete(withStatusCode: 200, data: validJSON)
        }
    }

    func test_refreshAccessToken_returnsConnectivityErrorOnClientErrorMissingResponseData() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(TokenService.Error.connectivitiy)) {
            client.complete(with: NetworkClientError(responseData: nil, httpURLResponse: HTTPURLResponse(url: URL(string: "anyurl.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)))
        }
    }

    func test_refreshAccessToken_returnsConnectivityErrorOnClientErrorMissingHTTPResponse() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(TokenService.Error.connectivitiy)) {
            let errorResponseWithRefreshTokenError = Data("{ \"statusCode\": 401, \"message\": \"message\", \"validationErrors\": [{\"field\": \"field\",\"resource\": \"Error_RefreshTokenCouldNotBeFound\", \"error\": \"error\"}] }".utf8)
            client.complete(with: NetworkClientError(responseData: errorResponseWithRefreshTokenError, httpURLResponse: nil))
        }
    }

    func test_refreshAccessToken_returnsNewAccessTokenOnClientSuccess() {
        let (sut, client) = makeSUT()

        let newAccessToken = "New Access Token"

        expect(sut, toCompleteWith: .success(newAccessToken)) {
            let validJSON = Data("{ \"statusCode\": 200, \"message\": \"message\", \"details\": { \"jwtToken\": \"\(newAccessToken)\", \"jwtTokenValidUntil\": \"sometime\", \"userID\": 35} }".utf8)
            client.complete(withStatusCode: 200, data: validJSON)
        }
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "http://any-url.com")!
        let client = NetworkClientSpy()
        let refreshTokenProvider = RefreshTokenProviderStub()
        var sut: TokenService? = TokenService(url: url, networkClient: client, refreshTokenProvider: refreshTokenProvider)

        var capturedResults = [Result<String, Error>]()
        sut?.refreshAccessToken { capturedResults.append($0) }

        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))

        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL =  URL(string:"https://a-url.com")!, refreshTokenProvider: RefreshTokenProvider = RefreshTokenProviderStub(), file: StaticString = #filePath, line: UInt = #line) -> (sut: TokenService, client: NetworkClientSpy) {
        let networkClient = NetworkClientSpy()
        let sut = TokenService(url: url, networkClient: networkClient, refreshTokenProvider: refreshTokenProvider)

        trackForMemoryLeaks(instance: sut, file: file, line: line)
        trackForMemoryLeaks(instance: networkClient, file: file, line: line)

        return (sut, networkClient)
    }


    
    private func expect(_ sut: TokenService, toCompleteWith expectedResult: RefreshAccessTokenResult, action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        let exp = expectation(description: "Wait for load completion")
        sut.refreshAccessToken { (receivedResult: RefreshAccessTokenResult) in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

            case let (.failure(receivedError as TokenService.Error), .failure(expectedError as TokenService.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)

            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }

        action()


        wait(for: [exp], timeout: 1.0)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private class RefreshTokenProviderStub: RefreshTokenProvider {
        var refreshToken: String = ""
    }

    private class NetworkClientSpy: NetworkClient {

        private var messages = [(url: URL, completion: (Result<NetworkClientResponse, NetworkClientError>) -> Void, headers: [String: String])]()

        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }

        var requestedHeaders: [[String: String]] {
            return messages.map { $0.headers }
        }

        func execute(request: Request, completion: @escaping (Result<NetworkClientResponse, NetworkClientError>) -> Void) {
            messages.append((request.url, completion, request.header))
        }

        func complete(with error: NetworkClientError, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(
                url: messages[index].url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }

    private func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
