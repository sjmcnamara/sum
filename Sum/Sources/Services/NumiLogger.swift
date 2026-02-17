import os

/// Centralized logging for crash diagnosis and debugging.
/// View logs in Console.app filtering by subsystem "org.sum.calculator".
enum NumiLogger {
    static let parser = Logger(subsystem: "org.sum.calculator", category: "parser")
    static let storage = Logger(subsystem: "org.sum.calculator", category: "storage")
    static let currency = Logger(subsystem: "org.sum.calculator", category: "currency")
}
