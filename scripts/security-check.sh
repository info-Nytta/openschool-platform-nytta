#!/bin/bash
# =============================================================================
# OpenSchool Platform — Security Checklist Verification
# Automatically checks the items from the "Éles rendszer biztonsági ellenőrzőlista"
#
# Usage: ./scripts/security-check.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="${COMPOSE_FILE:-$PROJECT_DIR/docker-compose.prod.yml}"
COMPOSE="docker compose -f $COMPOSE_FILE"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

PASS=0; FAIL=0; WARN=0

check_pass() { echo -e "  ${GREEN}✓${NC} $*"; PASS=$((PASS + 1)); }
check_fail() { echo -e "  ${RED}✗${NC} $*"; FAIL=$((FAIL + 1)); }
check_warn() { echo -e "  ${YELLOW}⚠${NC} $*"; WARN=$((WARN + 1)); }

# Load env
if [ -f "$PROJECT_DIR/.env.prod" ]; then
    set -a; source "$PROJECT_DIR/.env.prod"; set +a
elif [ -f "$PROJECT_DIR/.env" ]; then
    set -a; source "$PROJECT_DIR/.env"; set +a
fi

echo ""
echo "========================================="
echo " OpenSchool — Security Checklist"
echo "========================================="
echo ""

# --- SECRET_KEY ---------------------------------------------------------------
echo "SECRET_KEY:"
if [ -z "${SECRET_KEY:-}" ]; then
    check_fail "Not set"
elif [ "$SECRET_KEY" = "change-me-in-production" ]; then
    check_fail "Using default value — change immediately!"
elif [ ${#SECRET_KEY} -lt 32 ]; then
    check_warn "Too short (${#SECRET_KEY} chars, need ≥32)"
else
    check_pass "Set and strong (${#SECRET_KEY} chars)"
fi

# --- ENVIRONMENT --------------------------------------------------------------
echo "ENVIRONMENT:"
if [ "${ENVIRONMENT:-}" = "production" ]; then
    check_pass "Set to 'production' (Swagger UI disabled)"
elif [ "${ENVIRONMENT:-}" = "staging" ]; then
    check_warn "Set to 'staging' (Swagger UI visible)"
else
    check_fail "Set to '${ENVIRONMENT:-development}' — Swagger UI is exposed!"
fi

# --- ALLOWED_ORIGINS ----------------------------------------------------------
echo "ALLOWED_ORIGINS:"
if [ -z "${ALLOWED_ORIGINS:-}" ]; then
    check_warn "Not set — CORS may be too permissive"
elif echo "$ALLOWED_ORIGINS" | grep -q "localhost"; then
    check_fail "Contains 'localhost' — remove for production"
else
    check_pass "$ALLOWED_ORIGINS"
fi

# --- DB_PASSWORD --------------------------------------------------------------
echo "DB_PASSWORD:"
if [ -z "${DB_PASSWORD:-}" ]; then
    check_fail "Not set"
elif [ "$DB_PASSWORD" = "openschool" ]; then
    check_fail "Using default password — change immediately!"
elif [ ${#DB_PASSWORD} -lt 12 ]; then
    check_warn "Short password (${#DB_PASSWORD} chars)"
else
    check_pass "Set and strong (${#DB_PASSWORD} chars)"
fi

# --- GITHUB_WEBHOOK_SECRET ---------------------------------------------------
echo "GITHUB_WEBHOOK_SECRET:"
if [ -z "${GITHUB_WEBHOOK_SECRET:-}" ]; then
    check_warn "Not set — webhook signature verification disabled"
else
    check_pass "Set (${#GITHUB_WEBHOOK_SECRET} chars)"
fi

# --- .env.prod permissions ----------------------------------------------------
echo ".env.prod permissions:"
if [ -f "$PROJECT_DIR/.env.prod" ]; then
    perms=$(stat -c '%a' "$PROJECT_DIR/.env.prod")
    if [ "$perms" = "600" ]; then
        check_pass "Restricted (600)"
    else
        check_fail "Too permissive ($perms) — run: chmod 600 .env.prod"
    fi
else
    check_warn ".env.prod not found (using .env?)"
fi

# --- HTTPS / SSL --------------------------------------------------------------
echo "HTTPS:"
if [ -n "${BASE_URL:-}" ] && echo "$BASE_URL" | grep -q "^https://"; then
    check_pass "BASE_URL uses HTTPS: $BASE_URL"
else
    check_fail "BASE_URL not using HTTPS: ${BASE_URL:-not set}"
fi

domain=$(echo "${BASE_URL:-}" | sed 's|https\?://||' | sed 's|/.*||')
if [ -n "$domain" ] && [ "$domain" != "localhost" ]; then
    if [ -d "/etc/letsencrypt/live/$domain" ]; then
        check_pass "SSL certificate found for $domain"
    else
        check_warn "No Let's Encrypt cert found for $domain"
    fi
fi

# --- Firewall -----------------------------------------------------------------
echo "Firewall (UFW):"
if command -v ufw &>/dev/null; then
    if ufw status | grep -q "Status: active"; then
        check_pass "UFW is active"
        if ufw status | grep -q "5432"; then
            check_fail "PostgreSQL port (5432) is exposed!"
        else
            check_pass "PostgreSQL port (5432) not exposed"
        fi
    else
        check_fail "UFW is not active"
    fi
else
    check_warn "UFW not installed"
fi

# --- Docker healthchecks ------------------------------------------------------
echo "Container health:"
if $COMPOSE ps &>/dev/null 2>&1; then
    containers=$($COMPOSE ps --format '{{.Name}} {{.Status}}' 2>/dev/null || true)
    while IFS= read -r line; do
        name=$(echo "$line" | awk '{print $1}')
        if echo "$line" | grep -qi "up"; then
            check_pass "$name running"
        else
            check_fail "$name not running"
        fi
    done <<< "$containers"
else
    check_warn "Cannot check containers (compose not running?)"
fi

# --- Backend /health ----------------------------------------------------------
echo "Health endpoint:"
if curl -sf http://localhost/health &>/dev/null || curl -sf http://localhost:8000/health &>/dev/null; then
    check_pass "/health responding"
else
    check_fail "/health not responding"
fi

# --- Swagger UI ---------------------------------------------------------------
echo "Swagger UI exposure:"
swagger_code=$(curl -sf -o /dev/null -w '%{http_code}' http://localhost:8000/docs 2>/dev/null || echo "000")
if [ "$swagger_code" = "404" ] || [ "$swagger_code" = "000" ]; then
    check_pass "Swagger UI not accessible (/docs returns $swagger_code)"
elif [ "$swagger_code" = "200" ]; then
    if [ "${ENVIRONMENT:-}" = "production" ]; then
        check_fail "Swagger UI accessible in production!"
    else
        check_warn "Swagger UI accessible (OK for non-production)"
    fi
else
    check_pass "Swagger UI returns $swagger_code"
fi

# --- Backup -------------------------------------------------------------------
echo "Backup:"
BACKUP_DIR="${BACKUP_DIR:-/opt/openschool/backups}"
if [ -d "$BACKUP_DIR" ]; then
    latest=$(find "$BACKUP_DIR" -name "db_*.sql.gz" -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2)
    if [ -n "$latest" ]; then
        age_hours=$(( ($(date +%s) - $(stat -c %Y "$latest")) / 3600 ))
        if [ "$age_hours" -le 24 ]; then
            check_pass "Latest backup: $(basename "$latest") (${age_hours}h ago)"
        else
            check_warn "Latest backup is ${age_hours}h old (should be <24h)"
        fi
    else
        check_warn "No backups found in $BACKUP_DIR"
    fi
else
    check_fail "Backup directory does not exist: $BACKUP_DIR"
fi

# --- Cron ---------------------------------------------------------------------
echo "Cron jobs:"
if [ -f /etc/cron.d/openschool-maintenance ]; then
    check_pass "Maintenance cron installed"
else
    check_fail "No cron jobs — run: sudo ./scripts/setup-cron.sh"
fi

# --- Summary ------------------------------------------------------------------
echo ""
echo "========================================="
echo "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$WARN warnings${NC}"
echo "========================================="
echo ""

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
