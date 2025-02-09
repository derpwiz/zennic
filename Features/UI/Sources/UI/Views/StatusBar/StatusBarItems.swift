import SwiftUI

/// A view that displays the cursor position in the status bar.
public struct StatusBarCursorPositionLabel: View {
    @EnvironmentObject private var viewModel: StatusBarViewModel
    
    public var body: some View {
        Text("Line \(viewModel.cursorPosition.line), Column \(viewModel.cursorPosition.column)")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
    }
}

/// A view that displays file information in the status bar.
public struct StatusBarFileInfoView: View {
    @EnvironmentObject private var viewModel: StatusBarViewModel
    
    public var body: some View {
        HStack(spacing: 4) {
            if !viewModel.filePath.isEmpty {
                Text(viewModel.fileName)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                if viewModel.hasUnsavedChanges {
                    Circle()
                        .fill(.secondary)
                        .frame(width: 4, height: 4)
                }
            }
        }
    }
}

/// A button that toggles the utility area.
public struct StatusBarToggleUtilityAreaButton: View {
    @EnvironmentObject private var utilityAreaViewModel: UtilityAreaViewModel
    
    public var body: some View {
        Button {
            utilityAreaViewModel.toggleCollapsed()
        } label: {
            StatusBarIcon(
                systemName: utilityAreaViewModel.isCollapsed ? "chevron.up" : "chevron.down",
                isActive: !utilityAreaViewModel.isCollapsed
            )
        }
        .buttonStyle(StatusBarIconStyle(isActive: !utilityAreaViewModel.isCollapsed))
    }
}

/// A button that selects the line ending type.
public struct StatusBarLineEndSelector: View {
    @EnvironmentObject private var viewModel: StatusBarViewModel
    
    public var body: some View {
        Menu {
            ForEach(LineEnding.allCases, id: \.self) { lineEnding in
                Button {
                    viewModel.lineEnding = lineEnding
                } label: {
                    HStack {
                        Text(lineEnding.description)
                        if viewModel.lineEnding == lineEnding {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 2) {
                StatusBarIcon(systemName: viewModel.lineEnding.icon)
                Text(viewModel.lineEnding.rawValue)
                    .font(.system(size: 11))
            }
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(StatusBarMenuStyle())
    }
}

/// A button that selects the indentation type.
public struct StatusBarIndentSelector: View {
    @EnvironmentObject private var viewModel: StatusBarViewModel
    
    public var body: some View {
        Menu {
            ForEach(IndentationType.allCases, id: \.self) { indentationType in
                Button {
                    viewModel.indentationType = indentationType
                } label: {
                    HStack {
                        Text(indentationType.description)
                        if viewModel.indentationType == indentationType {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 2) {
                StatusBarIcon(systemName: viewModel.indentationType.icon)
                Text(viewModel.indentationType.rawValue)
                    .font(.system(size: 11))
            }
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(StatusBarMenuStyle())
    }
}

/// A button that selects the file encoding.
public struct StatusBarEncodingSelector: View {
    @EnvironmentObject private var viewModel: StatusBarViewModel
    
    public var body: some View {
        Menu {
            ForEach(FileEncoding.allCases, id: \.self) { encoding in
                Button {
                    viewModel.fileEncoding = encoding
                } label: {
                    HStack {
                        Text(encoding.description)
                        if viewModel.fileEncoding == encoding {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 2) {
                StatusBarIcon(systemName: viewModel.fileEncoding.icon)
                Text(viewModel.fileEncoding.rawValue)
                    .font(.system(size: 11))
            }
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(StatusBarMenuStyle())
    }
}
