//
//  DirectoryEventStream.swift
//  zennic
//
//  Created by Claude on 2/11/25.
//

import Foundation

/// A class that monitors a directory for changes and notifies a callback when changes occur.
final class DirectoryEventStream {
    private var stream: FSEventStreamRef?
    private let callback: ([String]) -> Void

    /// Creates a new directory event stream.
    /// - Parameters:
    ///   - directory: The directory to monitor.
    ///   - callback: A closure that is called when changes occur in the directory.
    init(directory: String, callback: @escaping ([String]) -> Void) {
        self.callback = callback

        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        var pathsToWatch = [directory]

        var context2 = FSEventStreamContext(
            version: 0,
            info: context,
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { _, context, numEvents, eventPaths, _, _ in
                let watcher = unsafeBitCast(context, to: DirectoryEventStream.self)
                let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]
                watcher.callback(Array(paths[0..<numEvents]))
            },
            &context2,
            pathsToWatch as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5, // 500ms latency
            UInt32(kFSEventStreamCreateFlagFileEvents)
        )

        if let stream = stream {
            FSEventStreamScheduleWithRunLoop(
                stream,
                CFRunLoopGetMain(),
                CFRunLoopMode.defaultMode.rawValue
            )
            FSEventStreamStart(stream)
        }
    }

    /// Cancels the directory event stream.
    func cancel() {
        if let stream = stream {
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
