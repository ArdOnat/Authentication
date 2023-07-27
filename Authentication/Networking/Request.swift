public struct Request: Equatable {
    public let url: URL
    public let header: [String: String]

    public init(url: URL, header: [String : String]) {
        self.url = url
        self.header = header
    }
}
