import SwiftUI
import Combine

/// The log level
public enum LogLevel {
    case info
    case warning
    case error
}

/// A service for logging messages to the output and debug views
public final class LoggingService: ObservableObject {
    /// The shared instance
    public static let shared = LoggingService()
    
    /// The output subject
    private let outputSubject = PassthroughSubject<String, Never>()
    
    /// The debug subject
    private let debugSubject = PassthroughSubject<(String, LogLevel), Never>()
    
    /// The cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Creates a new logging service
    private init() {}
    
    /// Logs a message to the output view
    /// - Parameter text: The text to log
    public func output(_ text: String) {
        outputSubject.send(text)
    }
    
    /// Logs a message to the debug view
    /// - Parameters:
    ///   - text: The text to log
    ///   - level: The log level
    public func debug(_ text: String, level: LogLevel = .info) {
        debugSubject.send((text, level))
    }
    
    /// Logs an error message to the debug view
    /// - Parameter error: The error to log
    public func error(_ error: Error) {
        debug(error.localizedDescription, level: .error)
    }
    
    /// Logs a warning message to the debug view
    /// - Parameter text: The text to log
    public func warning(_ text: String) {
        debug(text, level: .warning)
    }
    
    /// Logs an info message to the debug view
    /// - Parameter text: The text to log
    public func info(_ text: String) {
        debug(text, level: .info)
    }
    
    /// The output publisher
    public var outputPublisher: AnyPublisher<String, Never> {
        outputSubject.eraseToAnyPublisher()
    }
    
    /// The debug publisher
    public var debugPublisher: AnyPublisher<(String, LogLevel), Never> {
        debugSubject.eraseToAnyPublisher()
    }
}

/// Extension to add logging to any object
public protocol Loggable {}

extension Loggable {
    /// The logging service
    public var logger: LoggingService { .shared }
}
