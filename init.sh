#!/usr/bin/env bash
set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

info()    { printf "${BLUE}  →${NC} %s\n" "$1"; }
success() { printf "${GREEN}  ✓${NC} %s\n" "$1"; }
warn()    { printf "${YELLOW}  !${NC} %s\n" "$1" >&2; }
die()     { printf "${RED}  ✗${NC} %s\n" "$1" >&2; exit 1; }
step()    { printf "\n${BOLD}%s${NC}\n" "$1"; }

# ─── Sanity checks ───────────────────────────────────────────────────────────

((BASH_VERSINFO[0] >= 4)) || die "Requires bash 4.0+. Found: $BASH_VERSION"

[[ -f "Makefile" && -f "backend/pom.xml" ]] \
    || die "Run this script from the repository root."

# ─── Template constants ───────────────────────────────────────────────────────

TMPL_FULL_PKG="com.example.myapp"
TMPL_FULL_PKG_PATH="com/example/myapp"
TMPL_BASE_PKG="com.example"
TMPL_NAME_KEBAB="my-app"
TMPL_NAME_LOWER="myapp"
TMPL_NAME_PASCAL="MyApp"
TMPL_HTML_TITLE="vite-project"

# Guard against double-init
grep -qr "$TMPL_NAME_KEBAB" backend/pom.xml 2>/dev/null \
    || die "Template values not found — has this project already been initialized?"

# ─── Parse flags ─────────────────────────────────────────────────────────────

NEW_NAME_KEBAB=""
NEW_PACKAGE=""
SKIP_CONFIRM=false
USE_DB=""   # empty = ask interactively; "true" = yes; "false" = no

usage() {
    printf "Usage: %s [--name <project-name>] [--package <base-package>] [--db|--no-db] [-y]\n\n" "$0"
    printf "  --name      Kebab-case project name (e.g. my-blog)\n"
    printf "  --package   Java base package     (e.g. io.github.username)\n"
    printf "  --db        Add PostgreSQL + JPA + Flyway\n"
    printf "  --no-db     Skip database setup\n"
    printf "  -y, --yes   Skip confirmation prompt\n"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)       NEW_NAME_KEBAB="$2"; shift 2 ;;
        --package)    NEW_PACKAGE="$2";    shift 2 ;;
        --db)         USE_DB=true;         shift ;;
        --no-db)      USE_DB=false;        shift ;;
        -y|--yes)     SKIP_CONFIRM=true;   shift ;;
        -h|--help)    usage; exit 0 ;;
        *)            die "Unknown option: $1" ;;
    esac
done

# ─── Interactive prompts ──────────────────────────────────────────────────────

[[ -n "$NEW_NAME_KEBAB" ]] || { printf "${BOLD}Project name${NC} (kebab-case, e.g. my-blog): "; read -r NEW_NAME_KEBAB; }
[[ -n "$NEW_PACKAGE"    ]] || { printf "${BOLD}Java base package${NC} (e.g. io.github.username): "; read -r NEW_PACKAGE; }

if [[ -z "$USE_DB" ]]; then
    printf "${BOLD}Set up PostgreSQL + JPA + Flyway?${NC} [y/N] "
    read -r _db_ans
    [[ "$_db_ans" =~ ^[Yy]$ ]] && USE_DB=true || USE_DB=false
fi

# ─── Validate ────────────────────────────────────────────────────────────────

[[ "$NEW_NAME_KEBAB" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]] \
    || die "Project name must be kebab-case lowercase (e.g. my-blog). Got: '${NEW_NAME_KEBAB}'"

[[ "$NEW_PACKAGE" =~ ^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$ ]] \
    || die "Base package must be dot-separated lowercase identifiers (e.g. io.github.username). Got: '${NEW_PACKAGE}'"

[[ "$NEW_NAME_KEBAB" != "$TMPL_NAME_KEBAB" || "$NEW_PACKAGE" != "$TMPL_BASE_PKG" ]] \
    || die "Project name and package are unchanged from the template."

# ─── Derive values ────────────────────────────────────────────────────────────

NEW_NAME_LOWER="${NEW_NAME_KEBAB//-/}"

NEW_NAME_PASCAL=""
IFS='-' read -ra _parts <<< "$NEW_NAME_KEBAB"
for _p in "${_parts[@]}"; do NEW_NAME_PASCAL+="${_p^}"; done

NEW_FULL_PKG="${NEW_PACKAGE}.${NEW_NAME_LOWER}"
NEW_FULL_PKG_PATH="${NEW_FULL_PKG//.//}"

# ─── Confirm ─────────────────────────────────────────────────────────────────

[[ "$USE_DB" == "true" ]] && _db_label="PostgreSQL + JPA + Flyway" || _db_label="none"

printf "\n${BOLD}Initializing project with:${NC}\n"
printf "  Name (kebab):   %s\n" "$NEW_NAME_KEBAB"
printf "  Name (pascal):  %s\n" "$NEW_NAME_PASCAL"
printf "  Full package:   %s\n" "$NEW_FULL_PKG"
printf "  Database:       %s\n" "$_db_label"
printf "\n"
printf "This will rewrite source files and reinitialize git.\n"

if ! $SKIP_CONFIRM; then
    printf "Continue? [y/N] "
    read -r _confirm
    [[ "$_confirm" =~ ^[Yy]$ ]] || { printf "Aborted.\n"; exit 0; }
fi

# ─── Helpers ─────────────────────────────────────────────────────────────────

# Replace all occurrences of $1 with $2 across text files (skips binary, git, build dirs)
_replace() {
    local from="$1" to="$2"
    local from_esc
    from_esc=$(printf '%s' "$from" | sed 's/[[\.*^$()+?{|]/\\&/g')
    grep -rIl \
        --exclude-dir='.git' --exclude-dir='target' \
        --exclude-dir='node_modules' --exclude-dir='dist' \
        "$from" . 2>/dev/null \
    | xargs -r sed -i "s|${from_esc}|${to}|g"
}

# ─── Step 1: Rewrite file contents ───────────────────────────────────────────

step "[1/5] Replacing template values in source files..."

info "Java full package and path..."
_replace "$TMPL_FULL_PKG"      "$NEW_FULL_PKG"
_replace "$TMPL_FULL_PKG_PATH" "$NEW_FULL_PKG_PATH"

info "Java base package (groupId)..."
_replace "$TMPL_BASE_PKG" "$NEW_PACKAGE"

info "Class names and project name..."
_replace "$TMPL_NAME_PASCAL" "$NEW_NAME_PASCAL"
_replace "$TMPL_NAME_KEBAB"  "$NEW_NAME_KEBAB"
_replace "$TMPL_NAME_LOWER"  "$NEW_NAME_LOWER"

info "HTML title..."
_replace "$TMPL_HTML_TITLE" "$NEW_NAME_KEBAB"

success "Source files updated."

# ─── Step 2: Move Java package directories ────────────────────────────────────

step "[2/5] Reorganizing Java package directories..."

JAVA_MAIN_OLD="backend/src/main/java/${TMPL_FULL_PKG_PATH}"
JAVA_TEST_OLD="backend/src/test/java/${TMPL_FULL_PKG_PATH}"
JAVA_MAIN_NEW="backend/src/main/java/${NEW_FULL_PKG_PATH}"
JAVA_TEST_NEW="backend/src/test/java/${NEW_FULL_PKG_PATH}"

_move_pkg() {
    local old_dir="$1" new_dir="$2" label="$3"
    if [[ ! -d "$old_dir" ]]; then
        warn "$label directory not found, skipping: $old_dir"
        return
    fi
    if [[ "$old_dir" == "$new_dir" ]]; then
        info "$label: path unchanged, skipping."
        return
    fi
    mkdir -p "$(dirname "$new_dir")"
    cp -r "$old_dir/." "$new_dir/"
    rm -rf "$old_dir"
    info "Moved $label: $old_dir → $new_dir"
}

_move_pkg "$JAVA_MAIN_OLD" "$JAVA_MAIN_NEW" "main"
_move_pkg "$JAVA_TEST_OLD" "$JAVA_TEST_NEW" "test"

# Remove empty ancestor directories left behind
find "backend/src/main/java" -mindepth 1 -depth -type d -empty -delete 2>/dev/null || true
find "backend/src/test/java"  -mindepth 1 -depth -type d -empty -delete 2>/dev/null || true

success "Package directories reorganized."

# ─── Step 3: Rename application files ────────────────────────────────────────

step "[3/5] Renaming application source files..."

_rename() {
    local old_f="$1" new_f="$2"
    if [[ -f "$old_f" && "$old_f" != "$new_f" ]]; then
        mv "$old_f" "$new_f"
        info "$(basename "$old_f") → $(basename "$new_f")"
    fi
}

_rename "${JAVA_MAIN_NEW}/${TMPL_NAME_PASCAL}Application.java" \
        "${JAVA_MAIN_NEW}/${NEW_NAME_PASCAL}Application.java"
_rename "${JAVA_TEST_NEW}/${TMPL_NAME_PASCAL}ApplicationTests.java" \
        "${JAVA_TEST_NEW}/${NEW_NAME_PASCAL}ApplicationTests.java"

success "Application files renamed."

# ─── Step 4: Database setup (optional) ───────────────────────────────────────

step "[4/5] Database setup..."

if [[ "$USE_DB" == "true" ]]; then

    # Inject JPA, Postgres driver, and Flyway deps before </dependencies>
    info "Adding dependencies to pom.xml..."
    awk '
    /^[[:space:]]*<\/dependencies>/ && !done {
        print "\t\t<dependency>"
        print "\t\t\t<groupId>org.springframework.boot</groupId>"
        print "\t\t\t<artifactId>spring-boot-starter-data-jpa</artifactId>"
        print "\t\t</dependency>"
        print "\t\t<dependency>"
        print "\t\t\t<groupId>org.postgresql</groupId>"
        print "\t\t\t<artifactId>postgresql</artifactId>"
        print "\t\t\t<scope>runtime</scope>"
        print "\t\t</dependency>"
        print "\t\t<dependency>"
        print "\t\t\t<groupId>org.flywaydb</groupId>"
        print "\t\t\t<artifactId>flyway-core</artifactId>"
        print "\t\t</dependency>"
        print "\t\t<dependency>"
        print "\t\t\t<groupId>org.flywaydb</groupId>"
        print "\t\t\t<artifactId>flyway-database-postgresql</artifactId>"
        print "\t\t</dependency>"
        done=1
    }
    { print }
    ' backend/pom.xml > backend/pom.xml.tmp && mv backend/pom.xml.tmp backend/pom.xml

    # Append datasource/JPA/Flyway config to application.yaml.
    # \${VAR} keeps Spring's ${VAR} syntax literal; ${NEW_NAME_LOWER} is expanded by bash.
    info "Configuring datasource in application.yaml..."
    cat >> backend/src/main/resources/application.yaml << EOF
  datasource:
    url: \${DB_URL:jdbc:postgresql://localhost:5432/${NEW_NAME_LOWER}}
    username: \${DB_USER:postgres}
    password: \${DB_PASSWORD:postgres}
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
  flyway:
    enabled: true
    locations: classpath:db/migration
EOF

    # docker-compose.yml for local Postgres — cloud uses DB_URL/DB_USER/DB_PASSWORD env vars
    info "Creating docker-compose.yml..."
    cat > docker-compose.yml << EOF
services:
  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: ${NEW_NAME_LOWER}
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
EOF

    info "Creating initial Flyway migration..."
    mkdir -p backend/src/main/resources/db/migration
    cat > backend/src/main/resources/db/migration/V1__init.sql << 'EOF'
-- V1: initial schema
-- Add your first CREATE TABLE statements here.
EOF

    info "Adding db-start / db-stop targets to Makefile..."
    cat >> Makefile << 'EOF'

.PHONY: db-start db-stop db-logs

db-start:
	docker compose up -d postgres

db-stop:
	docker compose down

db-logs:
	docker compose logs -f postgres
EOF

    success "Database configured."
    printf "\n"
    printf "  Local:   ${BOLD}make db-start${NC}  — runs Postgres in Docker on port 5432\n"
    printf "  Cloud:   set DB_URL, DB_USER, DB_PASSWORD environment variables\n"
    printf "           (works with RDS, Supabase, or any Postgres-compatible host)\n"
    printf "  Migrations: backend/src/main/resources/db/migration/\n"

else
    info "Skipped."
fi

# ─── Step 5: Git + dependencies ──────────────────────────────────────────────

step "[5/5] Reinitializing git and installing dependencies..."

info "Reinitializing git..."
rm -rf .git
git init -q
git add .
git commit -q -m "chore: initialize ${NEW_NAME_KEBAB} from spring-react-starter"

info "Running make install..."
make install

info "Running make setup..."
make setup

success "Done."

# ─── Summary ─────────────────────────────────────────────────────────────────

printf "\n${GREEN}${BOLD}Project '${NEW_NAME_KEBAB}' is ready.${NC}\n\n"
printf "  Start developing:  ${BOLD}make dev${NC}\n"
printf "  Run tests:         ${BOLD}make test${NC}\n"
if [[ "$USE_DB" == "true" ]]; then
    printf "  Start database:    ${BOLD}make db-start${NC}\n"
fi
printf "\n"
