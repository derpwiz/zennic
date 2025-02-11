import SwiftUI

public struct ToolbarView: View {
    @StateObject private var viewModel: ToolbarViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    public init(viewModel: ToolbarViewModel = ToolbarViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Left side
            HStack(spacing: 12) {
                navigationButtons
                projectInfoView
            }
            
            Spacer()
            
            // Center divider
            Divider()
                .frame(height: 12)
                .opacity(0.5)
                .padding(.horizontal, 8)
            
            // Right side
            HStack(spacing: 12) {
                tasksIndicator
                versionLabel
            }
        }
        .frame(height: 28)
        .padding(.horizontal)
        .background {
            EffectView(.windowBackground)
                .overlay(alignment: .bottom) {
                    Divider()
                        .opacity(0.5)
                }
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 4) {
            Button(action: viewModel.goBack) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(viewModel.canGoBack ? .primary : .tertiary)
            }
            .disabled(!viewModel.canGoBack)
            
            Button(action: viewModel.goForward) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(viewModel.canGoForward ? .primary : .tertiary)
            }
            .disabled(!viewModel.canGoForward)
        }
        .buttonStyle(.borderless)
        .font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 2)
    }
    
    private var projectInfoView: some View {
        Button {
            viewModel.selectBranch()
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.projectName)
                    .font(.system(size: 11, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .medium))
                Text(viewModel.currentBranch)
                    .font(.system(size: 11))
            }
            .foregroundStyle(.primary)
        }
        .buttonStyle(.borderless)
    }
    
    @State private var isRotating = false
    
    private var tasksIndicator: some View {
        HStack(spacing: 4) {
            if viewModel.runningTasks > 0 {
                Image(systemName: "circle.dashed")
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), 
                             value: isRotating)
                    .onAppear { isRotating = true }
                    .onDisappear { isRotating = false }
                Text("Running \(viewModel.runningTasks) of \(viewModel.totalTasks) tasks")
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }
    
    private var versionLabel: some View {
        Text(viewModel.version)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    ToolbarView()
}
