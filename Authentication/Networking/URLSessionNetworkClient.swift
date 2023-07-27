public final class URLSessionNetworkClient: NetworkClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    static var acceptableStatusCodes: Range<Int> { 200 ..< 300 }

    public func execute(request: Request, completion: @escaping (Result<NetworkClientResponse, NetworkClientError>) -> Void) {
        session.dataTask(with: request.url) { responseData, urlResponse, error in
            if let _ = error {
                completion(.failure(NetworkClientError(responseData: nil, httpURLResponse: nil)))
            } else {
                completion(URLSessionNetworkClient.some(responseData: responseData, urlResponse: urlResponse))
            }
        }.resume()
    }

    private static func some(responseData: Data?, urlResponse: URLResponse?) -> Result<NetworkClientResponse, NetworkClientError> {
        if let responseData, let httpURLResponse = urlResponse as? HTTPURLResponse {
            if URLSessionNetworkClient.acceptableStatusCodes.contains(httpURLResponse.statusCode) {
                return .success((responseData: responseData, httpURLResponse: httpURLResponse))
            } else {
                return .failure(NetworkClientError(responseData: responseData, httpURLResponse: httpURLResponse))
            }
        } else {
            return .failure(NetworkClientError(responseData: nil, httpURLResponse: nil))
        }
    }
}
