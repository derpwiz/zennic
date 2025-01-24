import Foundation

/// Protocol defining methods that a delegate must implement to handle WebSocket events
protocol WebSocketDelegate: WebSocketMessageDelegate, WebSocketObserver {}

/// Service class for managing WebSocket connections to Alpaca API
final class WebSocketService {
    // MARK: - Shared Instance
    
    static var shared: WebSocketService = {
        // Use same keys as AlpacaService for consistency
        let apiKey = ProcessInfo.processInfo.environment["ALPACA_API_KEY"] ?? 
                    UserDefaults.standard.string(forKey: "ALPACA_API_KEY") ?? ""
        let apiSecret = ProcessInfo.processInfo.environment["ALPACA_API_SECRET"] ?? 
                       UserDefaults.standard.string(forKey: "ALPACA_API_SECRET") ?? ""
        return WebSocketService(apiKey: apiKey, apiSecret: apiSecret)
    }()
    
    // MARK: - Properties
    
    private var webSocket: URLSessionWebSocketTask?
    private weak var delegate: WebSocketDelegate?
    private let apiKey: String
    private let apiSecret: String
    private var isConnected: Bool = false {
        didSet {
            if !isConnected {
                subscribedSymbols.removeAll()
            }
        }
    }
    private var subscribedSymbols: Set<String> = []
    private var observers: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    private let session: URLSession
    private let baseURL: URL
    private let queue = DispatchQueue(label: "com.zennic.websocket", qos: .userInitiated)
    private var reconnectTimer: Timer?
    private let maxReconnectAttempts = 5
    private var reconnectAttempts = 0
    private let connectionTimeout: TimeInterval = 10
    private var isReconnecting = false
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    init(apiKey: String, apiSecret: String) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.baseURL = URL(string: "wss://stream.data.alpaca.markets/v2/iex")!
        self.session = URLSession(configuration: .default)
        
        // Configure JSON coding
        encoder.keyEncodingStrategy = .convertToSnakeCase
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    deinit {
        disconnect()
        reconnectTimer?.invalidate()
        observers.removeAllObjects()
    }
    
    /// Updates the shared instance with new API credentials
    static func updateShared(apiKey: String, apiSecret: String) {
        // Store credentials in UserDefaults for consistency with AlpacaService
        UserDefaults.standard.set(apiKey, forKey: "ALPACA_API_KEY")
        UserDefaults.standard.set(apiSecret, forKey: "ALPACA_API_SECRET")
        shared = WebSocketService(apiKey: apiKey, apiSecret: apiSecret)
    }
    
    /// Adds an observer to receive WebSocket events
    func addObserver(_ observer: WebSocketObserver) {
        queue.async { [weak self] in
            guard let self = self else { return }
            // Check if observer is already added to prevent duplicates
            if !self.observers.contains(observer) {
                self.observers.add(observer)
            }
        }
    }
    
    /// Removes an observer from receiving WebSocket events
    func removeObserver(_ observer: WebSocketObserver) {
        queue.async { [weak self] in
            self?.observers.remove(observer)
        }
    }
    
    /// Connects to the WebSocket server
    func connect() {
        queue.async { [weak self] in
            guard let self = self, !self.isConnected else { return }
            
            self.reconnectAttempts = 0
            self.connectWithTimeout()
        }
    }
    
    private func connectWithTimeout() {
        var request = URLRequest(url: baseURL)
        request.timeoutInterval = connectionTimeout
        
        // Add authentication headers
        let credentials = "\(apiKey):\(apiSecret)".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        
        webSocket = session.webSocketTask(with: request)
        
        // Set up a timeout timer
        DispatchQueue.main.asyncAfter(deadline: .now() + connectionTimeout) { [weak self] in
            guard let self = self, !self.isConnected else { return }
            self.handleError(NSError(domain: "WebSocketService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection timeout"]))
        }
        
        webSocket?.resume()
        isConnected = true
        
        receiveMessage()
        
        DispatchQueue.main.async { [weak self] in
            self?.notifyObserversDidConnect()
        }
        
        // Send authentication message
        let auth = WebSocketSubscription(
            action: "auth",
            trades: nil,
            quotes: nil,
            bars: nil,
            dailyBars: nil,
            statuses: nil,
            lulds: nil,
            tradeUpdates: nil
        )
        send(message: auth)
    }
    
    /// Disconnects from the WebSocket server
    func disconnect(error: Error? = nil) {
        queue.async { [weak self] in
            guard let self = self, self.isConnected else { return }
            
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = nil
            self.reconnectAttempts = 0
            self.isReconnecting = false
            
            self.webSocket?.cancel(with: .normalClosure, reason: nil)
            self.webSocket = nil
            self.isConnected = false
            
            DispatchQueue.main.async { [weak self] in
                self?.notifyObserversDidDisconnect(error: error)
            }
        }
    }
    
    /// Subscribes to updates for specified symbols
    func subscribeToSymbols(_ symbols: [String]) {
        queue.async { [weak self] in
            guard let self = self, self.isConnected else { return }
            let newSymbols = Set(symbols).subtracting(self.subscribedSymbols)
            guard !newSymbols.isEmpty else { return }
            
            let subscription = WebSocketSubscription(
                action: "subscribe",
                trades: Array(newSymbols),
                quotes: Array(newSymbols),
                bars: nil,
                dailyBars: nil,
                statuses: nil,
                lulds: nil,
                tradeUpdates: nil
            )
            self.send(message: subscription)
            self.subscribedSymbols.formUnion(newSymbols)
        }
    }
    
    /// Unsubscribes from updates for specified symbols
    func unsubscribeFromSymbols(_ symbols: [String]) {
        queue.async { [weak self] in
            guard let self = self, self.isConnected else { return }
            let existingSymbols = Set(symbols).intersection(self.subscribedSymbols)
            guard !existingSymbols.isEmpty else { return }
            
            let subscription = WebSocketSubscription(
                action: "unsubscribe",
                trades: Array(existingSymbols),
                quotes: Array(existingSymbols),
                bars: nil,
                dailyBars: nil,
                statuses: nil,
                lulds: nil,
                tradeUpdates: nil
            )
            self.send(message: subscription)
            self.subscribedSymbols.subtract(existingSymbols)
        }
    }
    
    // MARK: - Private Methods
    
    private func send(message: WebSocketSubscription) {
        queue.async { [weak self] in
            guard let self = self, self.isConnected else { return }
            
            do {
                let data = try self.encoder.encode(message)
                guard let string = String(data: data, encoding: .utf8) else {
                    throw NSError(domain: "WebSocketService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode message"])
                }
                
                let message = URLSessionWebSocketTask.Message.string(string)
                self.webSocket?.send(message) { [weak self] error in
                    if let error = error {
                        self?.handleError(error)
                    }
                }
            } catch {
                self.handleError(error)
            }
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                // Reset reconnect attempts on successful message
                self.reconnectAttempts = 0
                
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self.handleMessage(data)
                    }
                case .data(let data):
                    self.handleMessage(data)
                @unknown default:
                    print("Unknown WebSocket message type received")
                }
                
                // Continue receiving messages if still connected
                if self.isConnected {
                    self.receiveMessage()
                }
                
            case .failure(let error):
                self.handleError(error)
            }
        }
    }
    
    private func handleMessage(_ data: Data) {
        do {
            let message = try decoder.decode(WebSocketMessage.self, from: data)
            let messageType: WebSocketMessageType
            
            messageType = switch message.data {
            case .trade(_): .trade
            case .quote(_): .quote
            case .tradeUpdate(_): .tradeUpdate
            case .news(_): .news
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.notifyObserversDidReceiveMessage(data, type: messageType)
            }
        } catch {
            print("Error decoding WebSocket message: \(error)")
            // Don't disconnect on decode error, just log it
        }
    }
    
    private func handleError(_ error: Error) {
        print("WebSocket error: \(error)")
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.disconnect(error: error)
            
            // Attempt reconnection if not manually disconnected and not already reconnecting
            if !self.isReconnecting && self.reconnectAttempts < self.maxReconnectAttempts {
                self.isReconnecting = true
                self.reconnectAttempts += 1
                let delay = TimeInterval(pow(2.0, Double(self.reconnectAttempts))) // Exponential backoff
                
                self.reconnectTimer?.invalidate()
                self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    self?.isReconnecting = false
                    self?.connectWithTimeout()
                }
            } else if self.reconnectAttempts >= self.maxReconnectAttempts {
                print("Max reconnection attempts reached")
                // Notify observers of permanent disconnection
                DispatchQueue.main.async { [weak self] in
                    self?.notifyObserversDidDisconnect(error: NSError(domain: "WebSocketService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max reconnection attempts reached"]))
                }
            }
        }
    }
    
    private func notifyObserversDidConnect() {
        for case let observer as WebSocketObserver in observers.allObjects {
            observer.didConnect()
        }
    }
    
    private func notifyObserversDidDisconnect(error: Error?) {
        for case let observer as WebSocketObserver in observers.allObjects {
            observer.didDisconnect(error: error)
        }
    }
    
    private func notifyObserversDidReceiveMessage(_ data: Data, type: WebSocketMessageType) {
        for case let observer as WebSocketMessageDelegate in observers.allObjects {
            observer.didReceiveMessage(data, type: type)
        }
    }
}
