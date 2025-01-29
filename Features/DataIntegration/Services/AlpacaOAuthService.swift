import Foundation

class AlpacaOAuthService {
    private let clientID: String
    private let clientSecret: String
    private let redirectURI = "alpaca://oauth"
    private let authorizationEndpoint = "https://app.alpaca.markets/oauth/authorize"
    private let tokenEndpoint = "https://api.alpaca.markets/oauth/token"
    
    init(clientID: String, clientSecret: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
    }
    
    func getAuthorizationURL() -> URL? {
        var components = URLComponents(string: authorizationEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "account:write trading")
        ]
        return components?.url
    }
    
    func exchangeCodeForToken(code: String) async throws -> String {
        guard let url = URL(string: tokenEndpoint) else {
            throw NSError(domain: "AlpacaOAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid token endpoint URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientID,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI
        ]
        
        request.httpBody = parameters.map { key, value in
            return "\(key)=\(value)"
        }.joined(separator: "&").data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw NSError(domain: "AlpacaOAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from token endpoint"])
        }
        
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let accessToken = jsonResult?["access_token"] as? String else {
            throw NSError(domain: "AlpacaOAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Access token not found in response"])
        }
        
        return accessToken
    }
}
