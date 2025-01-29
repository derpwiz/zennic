import Foundation

public class CodeAssistant {
    public static let shared = CodeAssistant()
    
    private init() {}
    
    public func getAutoCompleteSuggestions(for prefix: String, language: CodeLanguage) -> [String] {
        switch language {
        case .python:
            return pythonSuggestions.filter { $0.hasPrefix(prefix) }
        case .r:
            return rSuggestions.filter { $0.hasPrefix(prefix) }
        case .sql:
            return sqlSuggestions.filter { $0.hasPrefix(prefix) }
        }
    }
    
    public func getCodeSnippet(for key: String, language: CodeLanguage) -> String? {
        switch language {
        case .python:
            return pythonSnippets[key]
        case .r:
            return rSnippets[key]
        case .sql:
            return sqlSnippets[key]
        }
    }
    
    public func getSnippetKeys(for language: CodeLanguage) -> [String] {
        switch language {
        case .python:
            return Array(pythonSnippets.keys)
        case .r:
            return Array(rSnippets.keys)
        case .sql:
            return Array(sqlSnippets.keys)
        }
    }
    
    private let pythonSuggestions = [
        "import", "def", "class", "for", "while", "if", "elif", "else", "try", "except", "finally",
        "with", "as", "lambda", "return", "yield", "break", "continue", "pass", "assert", "raise",
        "numpy", "pandas", "matplotlib", "sklearn", "scipy", "alpaca_trade_api"
    ]
    
    private let rSuggestions = [
        "function", "if", "else", "for", "while", "repeat", "break", "next", "return",
        "library", "data.frame", "matrix", "vector", "list", "apply", "lapply", "sapply",
        "ggplot2", "dplyr", "tidyr", "lubridate", "stringr", "readr", "purrr"
    ]
    
    private let sqlSuggestions = [
        "SELECT", "FROM", "WHERE", "JOIN", "INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL JOIN",
        "GROUP BY", "HAVING", "ORDER BY", "LIMIT", "INSERT INTO", "UPDATE", "DELETE", "CREATE TABLE",
        "ALTER TABLE", "DROP TABLE", "CREATE INDEX", "DROP INDEX"
    ]
    
    private let pythonSnippets = [
        "import_numpy": "import numpy as np\n",
        "import_pandas": "import pandas as pd\n",
        "import_matplotlib": "import matplotlib.pyplot as plt\n",
        "import_alpaca": "import alpaca_trade_api as tradeapi\n",
        "create_alpaca_api": """
        api = tradeapi.REST(
            key_id='YOUR_API_KEY',
            secret_key='YOUR_SECRET_KEY',
            base_url='https://paper-api.alpaca.markets'
        )
        """,
        "fetch_stock_data": """
        symbol = 'AAPL'
        timeframe = '1D'
        start_date = '2023-01-01'
        end_date = '2023-12-31'
        df = api.get_bars(symbol, timeframe, start=start_date, end=end_date).df
        print(df.head())
        """,
        "calculate_moving_average": """
        def calculate_moving_average(data, window):
            return data.rolling(window=window).mean()
        
        # Example usage:
        df['MA_20'] = calculate_moving_average(df['close'], 20)
        """
    ]
    
    private let rSnippets: [String: String] = [:]
    private let sqlSnippets: [String: String] = [:]
}
