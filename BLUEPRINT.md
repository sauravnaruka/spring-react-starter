# Project Blueprint: Spring Boot + React Fullstack

This document describes how to build this fullstack project structure from scratch.
It is written to be followed by a human or given directly to an AI agent.
`init.sh` and other template machinery are not part of these steps.

---

## Stack

| Layer     | Technology                    | Version  |
|-----------|-------------------------------|----------|
| Backend   | Spring Boot                   | 4.1.0    |
| Backend   | Java (Temurin distribution)   | 25       |
| Backend   | Build tool                    | Maven (with wrapper) |
| Frontend  | React                         | 19       |
| Frontend  | Build tool                    | Vite 8   |
| Frontend  | Language                      | TypeScript 6 |
| Frontend  | Package manager               | npm      |
| Formatter | Backend                       | Spotless (Eclipse formatter) |
| Formatter | Frontend                      | Prettier |
| Testing   | Backend                       | JUnit 5 via Spring Boot test slice |
| Testing   | Frontend                      | Vitest + Testing Library |
| Coverage  | Backend                       | JaCoCo   |
| Coverage  | Frontend                      | Vitest v8 |
| Container | Runtime image                 | eclipse-temurin:25-jre |
| CI        | GitHub Actions                | on PR to main / develop |

---

## Final Directory Structure

```
<project-name>/
├── .github/
│   └── workflows/
│       └── ci.yml
├── .githooks/
│   └── pre-commit
├── backend/
│   ├── .mvn/wrapper/
│   │   └── maven-wrapper.properties
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/<base-package>/<app-name-lower>/
│   │   │   │   ├── <AppName>Application.java
│   │   │   │   └── controller/
│   │   │   │       └── HealthController.java
│   │   │   └── resources/
│   │   │       └── application.yaml
│   │   └── test/
│   │       └── java/<base-package>/<app-name-lower>/
│   │           ├── <AppName>ApplicationTests.java
│   │           └── SanityTest.java
│   ├── mvnw
│   ├── mvnw.cmd
│   └── pom.xml
├── frontend/
│   ├── src/
│   │   ├── test/
│   │   │   ├── sanity.test.ts
│   │   │   └── setup.ts
│   │   ├── App.tsx
│   │   ├── index.css
│   │   └── main.tsx
│   ├── public/
│   │   └── favicon.svg
│   ├── eslint.config.js
│   ├── index.html
│   ├── package.json
│   ├── tsconfig.app.json
│   ├── tsconfig.json
│   ├── tsconfig.node.json
│   ├── vite.config.ts
│   ├── .prettierignore
│   └── .prettierrc.json
├── .dockerignore
├── .gitignore
├── Dockerfile
└── Makefile
```

Naming conventions used below:
- `<project-name>` — kebab-case (e.g. `my-blog`)
- `<app-name-lower>` — lowercase, no hyphens (e.g. `myblog`)
- `<AppName>` — PascalCase (e.g. `MyBlog`)
- `<base-package>` — dot-separated Java package (e.g. `io.github.username`)
- `<full-package>` — `<base-package>.<app-name-lower>` (e.g. `io.github.username.myblog`)

---

## Step 1 — Scaffold the backend

Use [Spring Initializr](https://start.spring.io) or the Spring CLI to generate a Maven project with these settings:

- **Group:** `<base-package>`
- **Artifact:** `<project-name>`
- **Java:** 25
- **Packaging:** Jar
- **Spring Boot:** 4.1.0
- **Dependencies:** Spring Web MVC, Validation, Spring Boot DevTools, Lombok

Place the generated project at `backend/`.

### `backend/pom.xml`

Replace the generated file content. Key decisions below — all other standard scaffolding (parent, scm, license stubs) can stay as generated.

```xml
<groupId><base-package></groupId>
<artifactId><project-name></artifactId>
<version>0.0.1-SNAPSHOT</version>
```

**Dependencies block** — use exactly these (no extras unless opting into DB, see optional section):

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-devtools</artifactId>
        <scope>runtime</scope>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webmvc-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

**Plugins block** — four plugins are required:

```xml
<build>
    <plugins>
        <!-- 1. Spring Boot fat JAR, with Lombok excluded from the final artifact -->
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <configuration>
                <excludes>
                    <exclude>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok</artifactId>
                    </exclude>
                </excludes>
            </configuration>
        </plugin>

        <!-- 2. Compiler plugin with Lombok annotation processor wired in for both compile and test-compile -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <executions>
                <execution>
                    <id>default-compile</id>
                    <phase>compile</phase>
                    <goals><goal>compile</goal></goals>
                    <configuration>
                        <annotationProcessorPaths>
                            <path>
                                <groupId>org.projectlombok</groupId>
                                <artifactId>lombok</artifactId>
                            </path>
                        </annotationProcessorPaths>
                    </configuration>
                </execution>
                <execution>
                    <id>default-testCompile</id>
                    <phase>test-compile</phase>
                    <goals><goal>testCompile</goal></goals>
                    <configuration>
                        <annotationProcessorPaths>
                            <path>
                                <groupId>org.projectlombok</groupId>
                                <artifactId>lombok</artifactId>
                            </path>
                        </annotationProcessorPaths>
                    </configuration>
                </execution>
            </executions>
        </plugin>

        <!-- 3. JaCoCo: prepare-agent on compile, report on test -->
        <plugin>
            <groupId>org.jacoco</groupId>
            <artifactId>jacoco-maven-plugin</artifactId>
            <executions>
                <execution>
                    <id>prepare-agent</id>
                    <goals><goal>prepare-agent</goal></goals>
                </execution>
                <execution>
                    <id>report</id>
                    <phase>test</phase>
                    <goals><goal>report</goal></goals>
                </execution>
            </executions>
        </plugin>

        <!-- 4. Spotless: Eclipse formatter for Java, checked on verify -->
        <plugin>
            <groupId>com.diffplug.spotless</groupId>
            <artifactId>spotless-maven-plugin</artifactId>
            <version>2.44.0</version>
            <configuration>
                <java>
                    <eclipse/>
                </java>
            </configuration>
            <executions>
                <execution>
                    <goals><goal>check</goal></goals>
                    <phase>verify</phase>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

### `backend/src/main/resources/application.yaml`

Use YAML, not `.properties`.

```yaml
spring:
  application:
    name: <project-name>
```

### `backend/src/main/java/<full-package>/<AppName>Application.java`

```java
package <full-package>;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class <AppName>Application {

    public static void main(String[] args) {
        SpringApplication.run(<AppName>Application.class, args);
    }

}
```

### `backend/src/main/java/<full-package>/controller/HealthController.java`

```java
package <full-package>.controller;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class HealthController {

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP", "version", "0.0.1-SNAPSHOT");
    }
}
```

### `backend/src/test/java/<full-package>/<AppName>ApplicationTests.java`

Disabled by default because a Spring context test requires the full environment (e.g. a running DB if one is configured). Enable it once the environment is ready.

```java
package <full-package>;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@Disabled("Enable once the full application environment is configured")
@SpringBootTest
class <AppName>ApplicationTests {

    @Test
    void contextLoads() {
    }

}
```

### `backend/src/test/java/<full-package>/SanityTest.java`

```java
package <full-package>;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

class SanityTest {

    @Test
    void junitIsWorking() {
        assertTrue(true);
    }
}
```

---

## Step 2 — Scaffold the frontend

```bash
npm create vite@latest frontend -- --template react-ts
cd frontend
```

Then install additional dev dependencies:

```bash
npm install --save-dev \
  vitest @vitest/ui @vitest/coverage-v8 \
  @testing-library/react @testing-library/user-event @testing-library/jest-dom \
  jsdom \
  @rolldown/plugin-babel babel-plugin-react-compiler @babel/core @types/babel__core \
  prettier
```

### `frontend/vite.config.ts`

Replace the generated file entirely:

```ts
import { defineConfig } from 'vitest/config'
import react, { reactCompilerPreset } from '@vitejs/plugin-react'
import babel from '@rolldown/plugin-babel'

export default defineConfig({
  plugins: [react(), babel({ presets: [reactCompilerPreset()] })],
  server: {
    proxy: {
      '/api': 'http://localhost:8080',
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    globals: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
      reportsDirectory: './coverage',
    },
  },
})
```

Key points:
- `vitest/config` (not `vite/config`) — required for Vitest type resolution.
- The React Compiler is wired in via `@rolldown/plugin-babel` + `reactCompilerPreset`, not as a standalone Vite plugin.
- The `/api` proxy means the frontend dev server forwards all `/api` requests to the Spring Boot backend on port 8080. No CORS configuration is needed.

### `frontend/tsconfig.app.json`

```json
{
  "compilerOptions": {
    "tsBuildInfoFile": "./node_modules/.tmp/tsconfig.app.tsbuildinfo",
    "target": "es2023",
    "lib": ["ES2023", "DOM"],
    "module": "esnext",
    "types": ["vite/client", "vitest/globals", "@testing-library/jest-dom"],
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "erasableSyntaxOnly": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
```

The `types` array adds global types for `vitest/globals` and `@testing-library/jest-dom` so neither needs to be imported in every test file.

### `frontend/eslint.config.js`

```js
import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import tseslint from 'typescript-eslint'
import { defineConfig, globalIgnores } from 'eslint/config'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      globals: globals.browser,
    },
  },
])
```

### `frontend/.prettierrc.json`

```json
{
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5"
}
```

### `frontend/.prettierignore`

```
dist
node_modules
coverage
```

### `frontend/index.html`

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title><project-name></title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

### `frontend/src/test/setup.ts`

```ts
import '@testing-library/jest-dom'
```

### `frontend/src/test/sanity.test.ts`

```ts
import { describe, it, expect } from 'vitest'

describe('test setup', () => {
  it('vitest is working', () => {
    expect(true).toBe(true)
  })
})
```

---

## Step 3 — Root project files

### `Makefile`

```makefile
FRONTEND_DIR=frontend
BACKEND_DIR=backend

IMAGE_NAME=<project-name>

.PHONY: dev frontend backend build clean install test test-frontend test-backend setup format format-frontend format-backend docker-build docker-run

dev:
	$(MAKE) -j2 frontend backend

frontend:
	cd $(FRONTEND_DIR) && npm run dev

backend:
	cd $(BACKEND_DIR) && ./mvnw spring-boot:run

install:
	cd $(FRONTEND_DIR) && npm install

build:
	cd $(BACKEND_DIR) && ./mvnw package -DskipTests
	cd $(FRONTEND_DIR) && npm run build

clean:
	cd $(BACKEND_DIR) && ./mvnw clean
	cd $(FRONTEND_DIR) && rm -rf dist node_modules

test: test-frontend test-backend

test-frontend:
	cd $(FRONTEND_DIR) && npm test -- --run

test-backend:
	cd $(BACKEND_DIR) && ./mvnw test

setup:
	git config core.hooksPath .githooks

format: format-frontend format-backend

format-frontend:
	cd $(FRONTEND_DIR) && npx prettier --write .

format-backend:
	cd $(BACKEND_DIR) && ./mvnw spotless:apply

docker-build:
	docker build -t $(IMAGE_NAME):latest .

docker-run:
	docker run --rm -p 8080:8080 $(IMAGE_NAME):latest
```

Note: Makefile recipes use a real tab character, not spaces.

### `Dockerfile`

Three-stage build: frontend assets are compiled first, then embedded into the backend JAR as static resources, and finally the JAR runs in a minimal JRE image.

```dockerfile
# Stage 1: Build frontend
FROM node:lts-alpine AS frontend-build
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Stage 2: Build backend JAR
FROM eclipse-temurin:25-jdk AS backend-build
WORKDIR /backend
COPY backend/.mvn ./.mvn
COPY backend/mvnw ./
RUN chmod +x ./mvnw
COPY backend/pom.xml ./
RUN ./mvnw dependency:go-offline -q
COPY backend/src ./src
COPY --from=frontend-build /frontend/dist ./src/main/resources/static
RUN ./mvnw package -DskipTests -q

# Stage 3: Runtime image (JRE only)
FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=backend-build /backend/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

The frontend `dist/` is copied into `src/main/resources/static` before Maven packages the JAR. Spring Boot serves static resources from that path automatically, so the entire app is served from port 8080 in production with no separate web server.

### `.dockerignore`

```
backend/target/
frontend/node_modules/
frontend/dist/
.git/
.githooks/
```

### `.gitignore`

```gitignore
# Java / Maven
backend/target/
backend/.mvn/wrapper/maven-wrapper.jar
*.class
*.jar
*.war

# Spring Boot — local overrides, never committed
backend/src/main/resources/application-local.yaml
backend/src/main/resources/application-local.properties

# Node / Vite
frontend/node_modules/
frontend/dist/
frontend/dist-ssr/
frontend/.env*.local
*.local

# Logs
logs/
*.log
npm-debug.log*

# IDE / OS
.idea/
.vscode/
!.vscode/extensions.json
*.DS_Store
Thumbs.db

# Environment / Secrets
.env
.env.*
!.env.example
```

---

## Step 4 — Git hooks

### `.githooks/pre-commit`

This hook formats only the staged files before every commit and re-stages the formatted result.

```sh
#!/bin/sh
set -e

STAGED_JAVA=$(git diff --cached --name-only --diff-filter=ACM | grep '\.java$' || true)
STAGED_FRONTEND=$(git diff --cached --name-only --diff-filter=ACM | grep '^frontend/.*\.\(ts\|tsx\|js\|jsx\|json\|css\)$' || true)

if [ -n "$STAGED_JAVA" ]; then
  echo "Formatting Java files..."
  (cd backend && ./mvnw spotless:apply -q)
  git add $STAGED_JAVA
fi

if [ -n "$STAGED_FRONTEND" ]; then
  echo "Formatting frontend files..."
  RELATIVE=$(echo "$STAGED_FRONTEND" | sed 's|^frontend/||')
  (cd frontend && npx prettier --write $RELATIVE)
  git add $STAGED_FRONTEND
fi
```

Make it executable:

```bash
chmod +x .githooks/pre-commit
```

Activate with:

```bash
git config core.hooksPath .githooks
```

This is what `make setup` runs.

---

## Step 5 — CI (GitHub Actions)

### `.github/workflows/ci.yml`

Runs on every PR targeting `main` or `develop`. Two parallel jobs: one for the frontend, one for the backend. Both report coverage to the GitHub Actions step summary.

```yaml
name: CI

on:
  pull_request:
    branches: [main, develop]

jobs:
  test-frontend:
    name: Frontend Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: npm
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        run: npm ci
        working-directory: frontend

      - name: Run tests with coverage
        run: npm test -- --run --coverage
        working-directory: frontend

      - name: Coverage summary
        if: always()
        run: |
          echo "## Frontend Coverage" >> $GITHUB_STEP_SUMMARY
          node -e "
            const s = require('./frontend/coverage/coverage-summary.json').total;
            const fmt = n => n.pct.toFixed(1) + '%';
            console.log('| Metric | Coverage |');
            console.log('|--------|----------|');
            console.log(\`| Statements | \${fmt(s.statements)} |\`);
            console.log(\`| Lines      | \${fmt(s.lines)} |\`);
            console.log(\`| Functions  | \${fmt(s.functions)} |\`);
            console.log(\`| Branches   | \${fmt(s.branches)} |\`);
          " >> $GITHUB_STEP_SUMMARY

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: frontend-coverage
          path: frontend/coverage/

  test-backend:
    name: Backend Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          java-version: '25'
          distribution: temurin
          cache: maven

      - name: Cache Maven wrapper
        uses: actions/cache@v4
        with:
          path: ~/.m2/wrapper
          key: maven-wrapper-${{ hashFiles('backend/.mvn/wrapper/maven-wrapper.properties') }}

      - name: Run tests with coverage
        run: ./mvnw test -q
        working-directory: backend

      - name: Coverage summary
        if: always()
        run: |
          echo "## Backend Coverage" >> $GITHUB_STEP_SUMMARY
          REPORT=backend/target/site/jacoco/jacoco.xml
          if [ -f "$REPORT" ]; then
            node -e "
              const fs = require('fs');
              const xml = fs.readFileSync('$REPORT', 'utf8');
              const parse = (type) => {
                const m = xml.match(new RegExp(\`<counter type=\"\${type}\" missed=\"(\\\\d+)\" covered=\"(\\\\d+)\"\`));
                if (!m) return 'n/a';
                const [, missed, covered] = m.map(Number);
                const total = missed + covered;
                return total ? ((covered / total) * 100).toFixed(1) + '%' : 'n/a';
              };
              console.log('| Metric | Coverage |');
              console.log('|--------|----------|');
              console.log(\`| Lines      | \${parse('LINE')} |\`);
              console.log(\`| Branches   | \${parse('BRANCH')} |\`);
              console.log(\`| Methods    | \${parse('METHOD')} |\`);
            " >> $GITHUB_STEP_SUMMARY
          fi

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: backend-coverage
          path: backend/target/site/jacoco/
```

---

## Step 6 — Initialize git

```bash
git init
git add .
git commit -m "chore: initial project setup"
```

Then install frontend dependencies and activate the pre-commit hook:

```bash
make install
make setup
```

---

## Optional: PostgreSQL Database

Add these only if the project needs a database.

### Additional `pom.xml` dependencies

Add inside `<dependencies>`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-database-postgresql</artifactId>
</dependency>
```

### `backend/src/main/resources/application.yaml` (additions)

Append under `spring:`:

```yaml
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/<app-name-lower>}
    username: ${DB_USER:postgres}
    password: ${DB_PASSWORD:postgres}
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
  flyway:
    enabled: true
    locations: classpath:db/migration
```

`${DB_URL:...}` is Spring's env-var-with-default syntax. The default points to local Docker. For cloud environments (AWS RDS, Supabase, etc.) set `DB_URL`, `DB_USER`, and `DB_PASSWORD` — the JDBC URL works with any PostgreSQL-compatible host.

### `docker-compose.yml` (local development only)

```yaml
services:
  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: <app-name-lower>
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### `backend/src/main/resources/db/migration/V1__init.sql`

```sql
-- V1: initial schema
-- Add your first CREATE TABLE statements here.
```

Flyway picks up files named `V<n>__<description>.sql` from `db/migration` on the classpath and runs them in order. Never edit a migration that has already been applied — add a new version instead.

### Additional `Makefile` targets

```makefile
.PHONY: db-start db-stop db-logs

db-start:
	docker compose up -d postgres

db-stop:
	docker compose down

db-logs:
	docker compose logs -f postgres
```
