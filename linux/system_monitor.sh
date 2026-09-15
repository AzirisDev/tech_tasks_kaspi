#!/usr/bin/env bash

#  system_monitor.sh — collect host health metrics, log them, and alert
#  when a threshold is breached.
#
#  Metrics: CPU load, memory usage, disk usage, running-process count.
#  On breach: writes a WARN/CRIT line to the log and (optionally) fires
#  a Telegram alert via the Bot API.
#
#  Designed to run from cron every N minutes. Idempotent, no external
#  deps beyond coreutils + (optional) curl for Telegram.
#
#  Usage:
#    ./system_monitor.sh                 # use defaults / env vars
#    CPU_THRESHOLD=90 ./system_monitor.sh
#    TELEGRAM_BOT_TOKEN=123:abc TELEGRAM_CHAT_ID=456 ./system_monitor.sh

set -euo pipefail

# Configuration
CPU_THRESHOLD="${CPU_THRESHOLD:-80}"        # % of total CPU capacity
MEM_THRESHOLD="${MEM_THRESHOLD:-80}"        # % of RAM used
DISK_THRESHOLD="${DISK_THRESHOLD:-85}"      # % of / used
PROC_THRESHOLD="${PROC_THRESHOLD:-300}"     # number of processes
LOG_FILE="${LOG_FILE:-/var/log/system_monitor.log}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"  # empty = Telegram disabled
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"      # target chat / channel / group id
HOSTNAME_SHORT="$(hostname -s 2>/dev/null || hostname)"

# Logging helper — timestamped, also echoes to stdout for cron mail.
# Falls back to a user-writable path if LOG_FILE is not writable.
if ! { : >> "$LOG_FILE"; } 2>/dev/null; then
    LOG_FILE="${TMPDIR:-/tmp}/system_monitor.log"
fi

log() {
    local level="$1"; shift
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '%s [%s] %s\n' "$ts" "$level" "$*" | tee -a "$LOG_FILE"
}

# Telegram alert — only fires if a bot token AND chat id are configured.
# Uses the Bot API sendMessage endpoint. Never aborts the script if the
# network call fails (guarded by || log WARN).
send_telegram() {
    local text="$1"
    { [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; } && return 0
    command -v curl >/dev/null 2>&1 || { log "WARN" "curl not found, cannot send Telegram alert"; return 0; }
    local message
    message=$(printf '*%s*%s%s' "$HOSTNAME_SHORT" $'\n' "$text")
    curl -s -X POST \
         --max-time 10 \
         --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
         --data-urlencode "text=${message}" \
         --data-urlencode "parse_mode=Markdown" \
         "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" >/dev/null 2>&1 \
         || log "WARN" "Telegram API call failed"
}

# Metric collectors

# CPU usage %
get_cpu_usage() {
    local idle
    idle=$(top -bn1 | grep -iE '^%?Cpu' | head -1 \
           | sed -E 's/.*[, ]([0-9.]+)[ ]*id.*/\1/')
    if [ -z "${idle:-}" ]; then echo 0; return; fi
    awk -v idle="$idle" 'BEGIN { printf "%d", 100 - idle }'
}

# Memory usage % from free(1): used/total * 100.
get_mem_usage() {
    free | awk '/^Mem:/ { printf "%d", ($3/$2)*100 }'
}

# Disk usage % of the root filesystem
get_disk_usage() {
    df -P / | awk 'NR==2 { gsub("%","",$5); print $5 }'
}

# Number of running processes.
get_proc_count() {
    ps -e --no-headers | wc -l
}

# Threshold check
ALERTS=()
check() {
    local label="$1" value="$2" threshold="$3" unit="$4"
    if [ "$value" -ge "$threshold" ]; then
        log "CRIT" "${label} = ${value}${unit} (threshold ${threshold}${unit}) — BREACH"
        ALERTS+=("${label}: ${value}${unit} >= ${threshold}${unit}")
    else
        log "INFO" "${label} = ${value}${unit} (threshold ${threshold}${unit}) — ok"
    fi
}

# Main
main() {
    local cpu mem disk procs
    cpu=$(get_cpu_usage)
    mem=$(get_mem_usage)
    disk=$(get_disk_usage)
    procs=$(get_proc_count)

    log "INFO" "=== monitor run on ${HOSTNAME_SHORT} ==="
    check "CPU"       "$cpu"   "$CPU_THRESHOLD"  "%"
    check "Memory"    "$mem"   "$MEM_THRESHOLD"  "%"
    check "Disk(/)"   "$disk"  "$DISK_THRESHOLD" "%"
    check "Processes" "$procs" "$PROC_THRESHOLD" ""

    if [ "${#ALERTS[@]}" -gt 0 ]; then
        local summary
        summary=$(printf '%s\n' "${ALERTS[@]}")
        send_telegram "$summary"
        exit 1   # non-zero so cron / callers can detect a breach
    fi
    exit 0
}

main "$@"