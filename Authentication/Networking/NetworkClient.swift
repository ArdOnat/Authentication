public protocol NetworkClient {
    func execute(request: Request, completion: @escaping (Result<NetworkClientResponse, NetworkClientError>) -> Void)
}

public struct NetworkClientError: Error {
    public let responseData: Data?
    public let httpURLResponse: HTTPURLResponse?

    public init(responseData: Data?, httpURLResponse: HTTPURLResponse?) {
        self.responseData = responseData
        self.httpURLResponse = httpURLResponse
    }
}

public typealias NetworkClientResponse = (responseData: Data, httpURLResponse: HTTPURLResponse)
