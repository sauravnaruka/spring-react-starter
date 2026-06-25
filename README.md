# spring-react-starter

Fullstack starter template: Spring Boot 4.1.0 + React 19 + Vite.

## Quick start

Clone the repo, then run the init script to rename the project to your own:

```bash
./init.sh --name my-app --package io.github.yourname
```

Or run it interactively (prompts for name and package):

```bash
./init.sh
```

This rewrites package names, class names, and project identifiers throughout the codebase, reorganizes the Java directory structure, and reinitializes git with an initial commit.

## Prerequisites

- Java 25
- Maven (or use `./mvnw`)
- Node.js + npm

## Setup

After running `./init.sh`, dependencies and git hooks are configured automatically. If you need to redo it manually:

```bash
make install
make setup
```

## Local Development

Run frontend and backend in separate terminals:

```bash
# Terminal 1 — Spring Boot on http://localhost:8080
make backend

# Terminal 2 — Vite on http://localhost:5173
make frontend
```

Open `http://localhost:5173`. Vite automatically proxies `/api` requests to the backend, so no CORS configuration is needed.

To start both with a single command:
```bash
make dev
```

### Debugging the backend in VS Code

1. Open the **Run and Debug** panel (`Ctrl+Shift+D`)
2. Select **Debug Backend** from the dropdown
3. Press **F5**

Spring Boot starts with the debugger attached — set breakpoints anywhere in `backend/src/` and they will hit normally. Run the frontend separately in a terminal with `make frontend`.

## Docker

Build a production image (frontend embedded in the backend JAR, served from port 8080):

```bash
make docker-build
```

Run it locally:
```bash
make docker-run
```

Then open `http://localhost:8080`. The multi-stage build handles the frontend and backend automatically — no local Node or Java install required.

## Commands

| Command | Description |
|---|---|
| `make dev` | Start frontend and backend in parallel |
| `make frontend` | Start Vite dev server only |
| `make backend` | Start Spring Boot only |
| `make build` | Build both for production |
| `make clean` | Clean build artifacts |

## Testing

| Command | Description |
|---|---|
| `make test` | Run all tests (frontend + backend) |
| `make test-frontend` | Run Vitest unit tests |
| `make test-backend` | Run JUnit tests via Maven |

To run frontend tests in watch mode:
```bash
cd frontend && npm test
```

To run frontend tests with the Vitest UI:
```bash
cd frontend && npm run test:ui
```

## Formatting

| Command | Description |
|---|---|
| `make format` | Format all code |
| `make format-frontend` | Run Prettier on frontend |
| `make format-backend` | Run Eclipse JDT formatter via Spotless |

The pre-commit git hook runs formatting automatically on staged files.
Install it once after cloning with `make setup`.

**VS Code:** Install the recommended extensions when prompted (`.vscode/extensions.json`).
Formatting on save is pre-configured in `.vscode/settings.json`.
