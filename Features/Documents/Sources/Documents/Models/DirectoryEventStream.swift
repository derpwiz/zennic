//
//  DirectoryEventStream.swift
//  Documents
//
//  Created by Claude on 2/11/25.
//

import Foundation

/// A stream that monitors a directory for changes.
public final class DirectoryEventStream {
    private var stream: FSEventStreamRef?
    private let callback: ([String]) -> Void
    private let path: String

    /// Initialize a new directory event stream.
    /// - Parameters:
    ///   - directory: The directory to monitor.
    ///   - callback: The callback to invoke when changes occur.
    public init(directory: String, callback: @escaping ([String]) -> Void) {
        self.callback = callback
        self.path = directory
        createStream()
    }

    private func createStream() {
        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer
        )

        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { _, info, numEvents, eventPaths, _, _ in
                let stream = Unmanaged<DirectoryEventStream>.fromOpaque(info!).takeUnretainedValue()
                let paths = Unmanaged<CFArray>.fromOpaque(UnsafeRawPointer(eventPaths)!).takeUnretainedValue() as! [String]
                stream.callback(Array(paths[..<numEvents]))
            },
            &context,
            [path] as CFArray,
            UInt64(kFSEventStreamEventIdSinceNow),
            0.5,
            flags
        )

        if let stream {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
        }
    }

    /// Cancel the event stream.
    public func cancel() {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    deinit {
        cancel()
    }
}
