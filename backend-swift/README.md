# zennic Backend API

This is the Swift backend API for the zennic project.

## Setup

1. Make sure you have PostgreSQL and Redis installed and running
2. Copy `.env.development` to `.env` and update the values for your environment
3. Run `swift build` to build the project
4. Run `swift run` to start the server

## Environment Variables

The following environment variables need to be configured:

- `DATABASE_HOST`: PostgreSQL host (default: localhost)
- `DATABASE_PORT`: PostgreSQL port (default: 5432)
- `DATABASE_USERNAME`: PostgreSQL username (default: postgres)
- `DATABASE_PASSWORD`: PostgreSQL password (default: postgres)
- `DATABASE_NAME`: PostgreSQL database name (default: zennic)
- `REDIS_HOST`: Redis host (default: localhost)
- `REDIS_PORT`: Redis port (default: 6379)
- `JWT_SECRET`: Secret key for JWT token signing

⚠️ **SECURITY WARNING**: The default JWT secret key in `.env.development` is for development only. 
In production, you MUST set a strong, unique secret key at least 32 characters long.

## API Endpoints

- `GET /health`: Health check endpoint
- User endpoints (see UserController for details)

## Development

The project uses SwiftLint for code style enforcement. Make sure to install it:
```bash
brew install swiftlint
