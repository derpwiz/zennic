import SwiftUI
import Core

public struct FileTreeView: View {
    @ObservedObject var viewModel: CodeEditorViewModel
    
    public var body: some View {
        List {
            ForEach(viewModel.files, id: \.self) { file in
                Text(file)
            }
        }
    }
}
