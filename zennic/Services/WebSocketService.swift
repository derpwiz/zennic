import Foundation

/// Represents different types of WebSocket messages that can be received
enum WebSocketMessageType {
    case tradeUpdate
    case quote(symbol: String)
    case trade(symbol: String)
    case news
}

/// Protocol for handling WebSocket events
protocol WebSocketDelegate: AnyObject {
    func didReceiveMessage(_ message: Data, type: WebSocketMessageType)
    func didConnect()
    func didDisconnect(error: Error?)
}

/// Service responsible for managing WebSocket connections to Alpaca's real-time data streams
final class WebSocketService: NSObject {
    private var tradingSocket: URLSessionWebSocketTask?
    private var marketDataSocket: URLSessionWebSocketTask?
    private let session: URLSession
    private let apiKey: String
    private let apiSecret: String
    private weak var delegate: WebSocketDelegate?
    
    private let tradingWSEndpoint = "wss://paper-api.alpaca.markets/stream"
    private let marketDataWSEndpoint = "wss://data.alpaca.markets/stream"
    
    private var subscribedSymbols: Set<String> = []
    private var isConnected = false
    
    init(apiKey: String, apiSecret: String, delegate: WebSocketDelegate) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.delegate = delegate
        
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        
        super.init()
    }
    
    /// Connects to both trading and market data WebSocket endpoints
    func connect() {
        connectTradingSocket()
        connectMarketDataSocket()
    }
    
    /// Disconnects from all WebSocket endpoints
    func disconnect() {
        tradingSocket?.cancel()
        marketDataSocket?.cancel()
        isConnected = false
    }
    
    /// Subscribe to real-time updates for specific symbols
    /// - Parameter symbols: Array of stock symbols to subscribe to
    func subscribeToSymbols(_ symbols: [String]) {
        guard isConnected else { return }
        
        subscribedSymbols.formUnion(symbols)
        
        let message: [String: Any] = [
            "action": "subscribe",
            "data": [
                "streams": symbols.flatMap { symbol in
                    ["T.\(symbol)", "Q.\(symbol)"] // Subscribe to trades and quotes
                }
            ]
        ]
        
        send(message, to: .marketData)
    }
    
    /// Unsubscribe from real-time updates for specific symbols
    /// - Parameter symbols: Array of stock symbols to unsubscribe from
    func unsubscribeFromSymbols(_ symbols: [String]) {
        subscribedSymbols.subtract(symbols)
        
        let message: [String: Any] = [
            "action": "unsubscribe",
            "data": [
                "streams": symbols.flatMap { symbol in
                    ["T.\(symbol)", "Q.\(symbol)"]
                }
            ]
        ]
        
        send(message, to: .marketData)
    }
    
    // MARK: - Private Methods
    
    private func connectTradingSocket() {
        guard let url = URL(string: tradingWSEndpoint) else { return }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
        
        tradingSocket = session.webSocketTask(with: request)
        tradingSocket?.resume()
        
        receiveTradingMessages()
        authenticateTradingSocket()
    }
    
    private func connectMarketDataSocket() {
        guard let url = URL(string: marketDataWSEndpoint) else { return }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
        
        marketDataSocket = session.webSocketTask(with: request)
        marketDataSocket?.resume()
        
        receiveMarketDataMessages()
        authenticateMarketDataSocket()
    }
    
    private func authenticateTradingSocket() {
        let message: [String: Any] = [
            "action": "listen",
            "data": [
                "streams": ["trade_updates"]
            ]
        ]
        
        send(message, to: .trading)
    }
    
    private func authenticateMarketDataSocket() {
        let message: [String: Any] = [
            "action": "auth",
            "key": apiKey,
            "secret": apiSecret
        ]
        
        send(message, to: .marketData)
    }
    
    private enum SocketType {
        case trading
        case marketData
    }
    
    private func send(_ message: [String: Any], to socketType: SocketType) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let socket = socketType == .trading ? tradingSocket : marketDataSocket
        socket?.send(.string(jsonString)) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    private func receiveTradingMessages() {
        tradingSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self?.delegate?.didReceiveMessage(data, type: .tradeUpdate)
                    }
                case .data(let data):
                    self?.delegate?.didReceiveMessage(data, type: .tradeUpdate)
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self?.receiveTradingMessages()
                
            case .failure(let error):
                print("Trading WebSocket error: \(error)")
                self?.delegate?.didDisconnect(error: error)
            }
        }
    }
    
    private func receiveMarketDataMessages() {
        marketDataSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        // Parse the message to determine the type
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let stream = json["stream"] as? String {
                            let messageType: WebSocketMessageType
                            
                            if stream.hasPrefix("T.") {
                                messageType = .trade(symbol: String(stream.dropFirst(2)))
                            } else if stream.hasPrefix("Q.") {
                                messageType = .quote(symbol: String(stream.dropFirst(2)))
                            } else if stream == "news" {
                                messageType = .news
                            } else {
                                messageType = .tradeUpdate
                            }
                            
                            self?.delegate?.didReceiveMessage(data, type: messageType)
                        }
                    }
                case .data(let data):
                    // Handle binary data if needed
                    break
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self?.receiveMarketDataMessages()
                
            case .failure(let error):
                print("Market Data WebSocket error: \(error)")
                self?.delegate?.didDisconnect(error: error)
            }
        }
    }
}
