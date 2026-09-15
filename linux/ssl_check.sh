#!/usr/bin/env bash

#  ssl_check.sh — check TLS certificate expiry for a list of domains
#  and warn when a certificate expires within N days.
#
#  For each domain it opens a TLS connection, reads the leaf cert,
#  extracts notAfter, computes days remaining, logs the result, and
#  sends a Telegram alert for anything expiring soon or
#  already expired / unreachable.
#
#  Usage:
#    ./ssl_check.sh example.com google.com
#    ./ssl_check.sh -f domains.txt
#    WARN_DAYS=14 ./ssl_check.sh -f domains.txt
#    TELEGRAM_BOT_TOKEN=123:abc TELEGRAM_CHAT_ID=456 ./ssl_check.sh example.com
#
#  domains.txt: one domain per line

set -euo pipefail

WARN_DAYS="${WARN_DAYS:-30}"
LOG_FILE="${LOG_FILE:-/var/log/ssl_check.log}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
TIMEOUT="${TIMEOUT:-10}"

if ! { : >> "$LOG_FILE"; } 2>/dev/null; then
    LOG_FILE="${TMPDIR:-/tmp}/ssl_check.log"
fi

log() {
    local level="$1"; shift
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE"
}

usage() {
    cat <<USAGE
Usage: $0 [-f domains_file] [domain ...]
  -f FILE   read domains from FILE (one per line, # comments allowed)
  domains   one or more domains passed directly (domain or domain:port)

Env: WARN_DAYS (default 30), TIMEOUT (default 10s),
     TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID (optional),
     LOG_FILE (default /var/log/ssl_check.log)
USAGE
}

send_telegram() {
    local text="$1"
    { [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; } && return 0
    command -v curl >/dev/null 2>&1 || { log "WARN" "curl not found, cannot send Telegram alert"; return 0; }
    local message
    message=$(printf '*SSL check*%s%s' $'\n' "$text")
    curl -s -X POST \
         --max-time 10 \
         --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
         --data-urlencode "text=${message}" \
         --data-urlencode "parse_mode=Markdown" \
         "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" >/dev/null 2>&1 \
         || log "WARN" "Telegram API call failed"
}

# Fetch notAfter date for one domain[:port]. Echoes epoch seconds on
# success; returns non-zero on connection/parse failure.
get_cert_expiry_epoch() {
    local target="$1"
    local host="${target%%:*}"
    local port="443"
    case "$target" in *:*) port="${target##*:}";; esac

    local not_after
    not_after=$(timeout "$TIMEOUT" bash -c \
        "echo | openssl s_client -servername '$host' -connect '$host:$port' 2>/dev/null \
         | openssl x509 -noout -enddate 2>/dev/null" \
        | sed -E 's/^notAfter=//')

    [ -z "$not_after" ] && return 1
    date -d "$not_after" +%s 2>/dev/null
}

ALERTS=()

check_domain() {
    local domain="$1"
    local expiry_epoch now_epoch days_left
    if ! expiry_epoch=$(get_cert_expiry_epoch "$domain"); then
        log "ERROR" "${domain}: could not retrieve certificate (unreachable / no TLS)"
        ALERTS+=("${domain}: UNREACHABLE or no valid certificate")
        return
    fi
    now_epoch=$(date +%s)
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

    if [ "$days_left" -lt 0 ]; then
        log "CRIT" "${domain}: certificate EXPIRED $(( -days_left )) day(s) ago"
        ALERTS+=("${domain}: EXPIRED ${days_left#-} day(s) ago")
    elif [ "$days_left" -le "$WARN_DAYS" ]; then
        log "WARN" "${domain}: expires in ${days_left} day(s) (threshold ${WARN_DAYS})"
        ALERTS+=("${domain}: expires in ${days_left} day(s)")
    else
        log "INFO" "${domain}: valid, expires in ${days_left} day(s)"
    fi
}

# Argument parsing
main() {
    command -v openssl >/dev/null 2>&1 || { log "ERROR" "openssl is required"; exit 2; }

    local -a domains=()
    local file=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -f) file="$2"; shift 2;;
            -h|--help) usage; exit 0;;
            *)  domains+=("$1"); shift;;
        esac
    done

    if [ -n "$file" ]; then
        [ -r "$file" ] || { log "ERROR" "cannot read domains file: $file"; exit 2; }
        while IFS= read -r line; do
            line="${line%%#*}"                       # strip comments
            line="$(echo "$line" | tr -d '[:space:]')" # trim whitespace
            [ -n "$line" ] && domains+=("$line")
        done < "$file"
    fi

    if [ "${#domains[@]}" -eq 0 ]; then
        usage; exit 2
    fi

    log "INFO" "=== SSL check: ${#domains[@]} domain(s), warn <= ${WARN_DAYS} day(s) ==="
    local d
    for d in "${domains[@]}"; do
        check_domain "$d"
    done

    if [ "${#ALERTS[@]}" -gt 0 ]; then
        send_telegram "$(printf '%s\n' "${ALERTS[@]}")"
        exit 1
    fi
    exit 0
}

main "$@"
