import Foundation

public enum CodeLanguage: String, CaseIterable {
    case python = "Python"
    case r = "R"
    case sql = "SQL"
}

extension CodeLanguage {
    var snippetKeys: [String] {
        switch self {
        case .python:
            return ["import_numpy", "import_pandas", "import_matplotlib", "import_alpaca", "create_alpaca_api", "fetch_stock_data", "calculate_moving_average"]
        case .r, .sql:
            return []
        }
    }
}
