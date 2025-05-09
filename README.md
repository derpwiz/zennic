# Zennic

A sophisticated macOS application that leverages artificial intelligence for portfolio management and trading decisions. Built with SwiftUI and modern Apple frameworks.

## Features

- **Secure Authentication**
  - Touch ID integration for secure access
  - Built-in biometric authentication using LocalAuthentication framework

- **Portfolio Management**
  - Real-time portfolio tracking
  - Holdings visualization
  - Performance analytics

- **AI-Powered Trading**
  - Automated trading signals
  - Market analysis
  - Risk assessment

- **Market Data Integration**
  - Real-time market data via Alpha Vantage API
  - Historical data analysis
  - Technical indicators

- **Advanced Analytics**
  - AI-driven market insights using OpenAI
  - Portfolio performance metrics
  - Risk management tools

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5.7 or later
- Alpha Vantage API key
- OpenAI API key

## Installation

1. Clone the repository:
```bash
git clone https://github.com/derpwiz/zennic.git
```

2. Open the project in Xcode:
```bash
cd zennic
open zennic.xcodeproj
```

3. Configure API Keys:
   - Launch the app
   - Go to Settings
   - Enter your Alpha Vantage API key
   - Enter your OpenAI API key

## Architecture

The app follows a modern SwiftUI architecture with:

- **MVVM Pattern**
  - Clear separation of concerns
  - Observable view models
  - Reactive updates

- **Services Layer**
  - Market data service
  - Portfolio service
  - Authentication service

- **Views**
  - Dashboard
  - Portfolio
  - Trading
  - Analysis
  - Settings

## Security

- Biometric authentication using Touch ID
- Secure API key storage
- Encrypted local data storage

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

MIT License

## Contact

derpwiz - derpwiz@sysctl.dev

Project Link: [https://github.com/derpwiz/zennic](https://github.com/derpwiz/zennic)
