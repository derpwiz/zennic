//
//  TaskManager.swift
//  zennic
//

import Foundation
import Combine

/// Manages background tasks and their output
final class TaskManager: ObservableObject {
    /// The currently active task
    @Published private(set) var activeTask: CEActiveTask?
    
    /// The list of available tasks
    @Published private(set) var availableTasks: [CETask] = []
    
    /// The task output buffer
    @Published private(set) var taskOutput: String = ""
    
    /// Whether a task is currently running
    var isTaskRunning: Bool {
        activeTask != nil
    }
    
    /// The current task's status
    var taskStatus: CETaskStatus {
        activeTask?.status ?? .idle
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    /// Starts a task with the given configuration
    func startTask(_ task: CETask) {
        guard !isTaskRunning else { return }
        
        let activeTask = CEActiveTask(task: task)
        self.activeTask = activeTask
        
        // Set up task output handling
        activeTask.$output
            .sink { [weak self] output in
                self?.taskOutput = output
            }
            .store(in: &cancellables)
        
        // Start the task
        activeTask.start()
    }
    
    /// Stops the currently running task
    func stopTask() {
        activeTask?.stop()
        activeTask = nil
        taskOutput = ""
    }
    
    /// Clears the task output buffer
    func clearOutput() {
        taskOutput = ""
    }
    
    /// Updates the list of available tasks
    func updateAvailableTasks(_ tasks: [CETask]) {
        availableTasks = tasks
    }
}

// MARK: - Task Models

/// Represents a task configuration
struct CETask: Identifiable, Codable {
    let id: String
    let name: String
    let command: String
    let workingDirectory: String?
    let environment: [String: String]?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        command: String,
        workingDirectory: String? = nil,
        environment: [String: String]? = nil
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.workingDirectory = workingDirectory
        self.environment = environment
    }
}

/// Represents a running task
final class CEActiveTask: ObservableObject {
    let task: CETask
    @Published private(set) var status: CETaskStatus = .idle
    @Published private(set) var output: String = ""
    
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    init(task: CETask) {
        self.task = task
    }
    
    func start() {
        guard status == .idle else { return }
        
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", task.command]
        
        if let workingDirectory = task.workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }
        
        if let environment = task.environment {
            process.environment = environment
        }
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        self.process = process
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
        
        // Set up output handling
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let data = try? handle.read(upToCount: 1024),
                  let output = String(data: data, encoding: .utf8) else { return }
            
            DispatchQueue.main.async {
                self?.appendOutput(output)
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let data = try? handle.read(upToCount: 1024),
                  let output = String(data: data, encoding: .utf8) else { return }
            
            DispatchQueue.main.async {
                self?.appendOutput(output)
            }
        }
        
        // Start the process
        do {
            try process.run()
            status = .running
            
            // Handle process termination
            process.terminationHandler = { [weak self] process in
                DispatchQueue.main.async {
                    self?.status = process.terminationStatus == 0 ? .completed : .failed
                }
            }
        } catch {
            status = .failed
            appendOutput("Failed to start task: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        process?.terminate()
        cleanup()
    }
    
    private func appendOutput(_ newOutput: String) {
        output += newOutput
    }
    
    private func cleanup() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        process = nil
        outputPipe = nil
        errorPipe = nil
    }
}

/// The status of a task
enum CETaskStatus {
    case idle
    case running
    case completed
    case failed
}
