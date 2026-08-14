#!/usr/bin/env bash
#
# tailnet-diagnose.sh
#
# Diagnose a Tailscale / Tailnet HTTPS application URL and write
# all test results to a CSV file.
#
# Examples:
#
#   ./tailnet-diagnose.sh https://openclaw.tiger-bushmaster.ts.net
#
#   ./tailnet-diagnose.sh \
#       https://mission-control.tiger-bushmaster.ts.net \
#       mission-control-diagnostics.csv
#
# Optional environment variables:
#
#   APP_CONTAINER=mission-control
#   TAILSCALE_CONTAINER=tailscale-mission-control
#   APP_PORT=4000
#
# The script is intentionally read-only. It does not modify Tailscale,
# Docker, networking, firewall, DNS, or application configuration.
#

set -u
set -o pipefail

TARGET_URL="${1:-}"
OUTPUT_CSV="${2:-tailnet-diagnostics-$(date +%Y%m%d-%H%M%S).csv}"

APP_CONTAINER="${APP_CONTAINER:-}"
TAILSCALE_CONTAINER="${TAILSCALE_CONTAINER:-}"
APP_PORT="${APP_PORT:-}"

if [[ -z "$TARGET_URL" ]]; then
    echo "Usage:"
    echo "  $0 https://app.your-tailnet.ts.net [output.csv]"
    echo
    echo "Optional:"
    echo "  APP_CONTAINER=my-app \\"
    echo "  TAILSCALE_CONTAINER=tailscale-my-app \\"
    echo "  APP_PORT=4000 \\"
    echo "  $0 https://my-app.tailnet.ts.net"
    exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

timestamp() {
    date --iso-8601=seconds
}

csv_escape() {
    local value="${1:-}"

    value="${value//$'\r'/ }"
    value="${value//$'\n'/ }"
    value="${value//\"/\"\"}"

    printf '"%s"' "$value"
}

write_row() {
    local category="$1"
    local check="$2"
    local status="$3"
    local details="${4:-}"

    {
        csv_escape "$(timestamp)"
        printf ","
        csv_escape "$category"
        printf ","
        csv_escape "$check"
        printf ","
        csv_escape "$status"
        printf ","
        csv_escape "$details"
        printf "\n"
    } >> "$OUTPUT_CSV"
}

run_check() {
    local category="$1"
    local check="$2"
    shift 2

    local output
    local rc

    output="$("$@" 2>&1)"
    rc=$?

    if [[ $rc -eq 0 ]]; then
        write_row "$category" "$check" "PASS" "$output"
    else
        write_row "$category" "$check" "FAIL" "exit=$rc; $output"
    fi

    return 0
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

safe_cmd() {
    "$@" 2>&1
}

section() {
    printf '\n=== %s ===\n' "$1"
}

# ---------------------------------------------------------------------------
# Parse target
# ---------------------------------------------------------------------------

TARGET_HOST="$(printf '%s\n' "$TARGET_URL" |
    sed -E 's#^[a-zA-Z]+://##; s#/.*$##; s/:.*$//')"

TARGET_SCHEME="$(printf '%s\n' "$TARGET_URL" |
    sed -nE 's#^([a-zA-Z]+)://.*#\1#p')"

TARGET_SCHEME="${TARGET_SCHEME:-https}"

# ---------------------------------------------------------------------------
# CSV header
# ---------------------------------------------------------------------------

printf '"timestamp","category","check","status","details"\n' > "$OUTPUT_CSV"

echo
echo "Tailnet URL diagnostics"
echo "======================="
echo
echo "Target URL : $TARGET_URL"
echo "Target host: $TARGET_HOST"
echo "Output     : $OUTPUT_CSV"
echo

write_row \
    "metadata" \
    "target" \
    "INFO" \
    "url=$TARGET_URL host=$TARGET_HOST scheme=$TARGET_SCHEME"

# ---------------------------------------------------------------------------
# Basic host information
# ---------------------------------------------------------------------------

section "System"

write_row \
    "system" \
    "hostname" \
    "INFO" \
    "$(hostname -f 2>/dev/null || hostname)"

write_row \
    "system" \
    "kernel" \
    "INFO" \
    "$(uname -a)"

if [[ -r /etc/os-release ]]; then
    write_row \
        "system" \
        "operating system" \
        "INFO" \
        "$(grep -E '^(PRETTY_NAME|NAME|VERSION)=' /etc/os-release | tr '\n' ' ')"
fi

write_row \
    "system" \
    "current user" \
    "INFO" \
    "$(id)"

# ---------------------------------------------------------------------------
# Required / useful tools
# ---------------------------------------------------------------------------

section "Tools"

for tool in \
    tailscale \
    curl \
    openssl \
    docker \
    ss \
    getent \
    dig \
    ping \
    ip \
    jq
do
    if command_exists "$tool"; then
        write_row \
            "tools" \
            "$tool installed" \
            "PASS" \
            "$(command -v "$tool")"
    else
        write_row \
            "tools" \
            "$tool installed" \
            "WARN" \
            "command not found"
    fi
done

# ---------------------------------------------------------------------------
# DNS
# ---------------------------------------------------------------------------

section "DNS"

if command_exists getent; then
    DNS_RESULT="$(getent ahosts "$TARGET_HOST" 2>&1)"
    if [[ $? -eq 0 && -n "$DNS_RESULT" ]]; then
        write_row \
            "dns" \
            "getent resolution" \
            "PASS" \
            "$DNS_RESULT"
    else
        write_row \
            "dns" \
            "getent resolution" \
            "FAIL" \
            "$DNS_RESULT"
    fi
fi

if command_exists dig; then
    DIG_A="$(dig +short A "$TARGET_HOST" 2>&1)"
    [[ -n "$DIG_A" ]] \
        && write_row "dns" "A record" "PASS" "$DIG_A" \
        || write_row "dns" "A record" "WARN" "No A record returned"

    DIG_AAAA="$(dig +short AAAA "$TARGET_HOST" 2>&1)"
    [[ -n "$DIG_AAAA" ]] \
        && write_row "dns" "AAAA record" "PASS" "$DIG_AAAA" \
        || write_row "dns" "AAAA record" "INFO" "No AAAA record returned"
fi

if grep -q "$TARGET_HOST" /etc/hosts 2>/dev/null; then
    write_row \
        "dns" \
        "/etc/hosts override" \
        "WARN" \
        "$(grep "$TARGET_HOST" /etc/hosts)"
else
    write_row \
        "dns" \
        "/etc/hosts override" \
        "PASS" \
        "No matching /etc/hosts entry"
fi

# ---------------------------------------------------------------------------
# Tailscale
# ---------------------------------------------------------------------------

section "Tailscale"

if command_exists tailscale; then

    TS_VERSION="$(tailscale version 2>&1)"
    if [[ $? -eq 0 ]]; then
        write_row \
            "tailscale" \
            "tailscale version" \
            "PASS" \
            "$TS_VERSION"
    else
        write_row \
            "tailscale" \
            "tailscale version" \
            "FAIL" \
            "$TS_VERSION"
    fi

    TS_STATUS="$(tailscale status 2>&1)"
    TS_STATUS_RC=$?

    if [[ $TS_STATUS_RC -eq 0 ]]; then
        write_row \
            "tailscale" \
            "tailscale status" \
            "PASS" \
            "$TS_STATUS"
    else
        write_row \
            "tailscale" \
            "tailscale status" \
            "FAIL" \
            "$TS_STATUS"
    fi

    TS_IP4="$(tailscale ip -4 2>&1)"
    if [[ $? -eq 0 ]]; then
        write_row \
            "tailscale" \
            "local tailscale IPv4" \
            "PASS" \
            "$TS_IP4"
    else
        write_row \
            "tailscale" \
            "local tailscale IPv4" \
            "FAIL" \
            "$TS_IP4"
    fi

    TS_IP6="$(tailscale ip -6 2>&1)"
    if [[ $? -eq 0 ]]; then
        write_row \
            "tailscale" \
            "local tailscale IPv6" \
            "PASS" \
            "$TS_IP6"
    else
        write_row \
            "tailscale" \
            "local tailscale IPv6" \
            "INFO" \
            "$TS_IP6"
    fi

    if tailscale status --json >/dev/null 2>&1; then
        TS_JSON="$(tailscale status --json 2>/dev/null)"

        if command_exists jq; then
            SELF_INFO="$(
                printf '%s' "$TS_JSON" |
                    jq -c '{
                        HostName: .Self.HostName,
                        DNSName: .Self.DNSName,
                        Online: .Self.Online,
                        TailscaleIPs: .Self.TailscaleIPs,
                        Tags: .Self.Tags
                    }' 2>&1
            )"

            write_row \
                "tailscale" \
                "local node metadata" \
                "INFO" \
                "$SELF_INFO"
        fi
    fi

    TS_PING="$(tailscale ping -c 3 "$TARGET_HOST" 2>&1)"
    TS_PING_RC=$?

    if [[ $TS_PING_RC -eq 0 ]]; then
        write_row \
            "tailscale" \
            "tailscale ping target" \
            "PASS" \
            "$TS_PING"
    else
        write_row \
            "tailscale" \
            "tailscale ping target" \
            "FAIL" \
            "$TS_PING"
    fi

    if tailscale serve status >/dev/null 2>&1; then
        SERVE_STATUS="$(tailscale serve status 2>&1)"

        write_row \
            "tailscale" \
            "tailscale serve status" \
            "INFO" \
            "$SERVE_STATUS"
    else
        SERVE_STATUS="$(tailscale serve status 2>&1)"

        write_row \
            "tailscale" \
            "tailscale serve status" \
            "WARN" \
            "$SERVE_STATUS"
    fi

else
    write_row \
        "tailscale" \
        "tailscale checks" \
        "SKIP" \
        "tailscale CLI unavailable"
fi

# ---------------------------------------------------------------------------
# Network interfaces and routes
# ---------------------------------------------------------------------------

section "Networking"

if command_exists ip; then
    write_row \
        "network" \
        "interfaces" \
        "INFO" \
        "$(ip -brief address 2>&1)"

    write_row \
        "network" \
        "routes" \
        "INFO" \
        "$(ip route 2>&1)"
fi

if command_exists ss; then
    write_row \
        "network" \
        "listening TCP ports" \
        "INFO" \
        "$(ss -lntp 2>&1)"
fi

# ---------------------------------------------------------------------------
# HTTP / HTTPS
# ---------------------------------------------------------------------------

section "HTTP"

if command_exists curl; then

    CURL_HEADERS="$(
        curl \
            --connect-timeout 10 \
            --max-time 20 \
            -sS \
            -D - \
            -o /dev/null \
            "$TARGET_URL" \
            2>&1
    )"
    CURL_RC=$?

    if [[ $CURL_RC -eq 0 ]]; then
        write_row \
            "http" \
            "HTTP request" \
            "PASS" \
            "$CURL_HEADERS"
    else
        write_row \
            "http" \
            "HTTP request" \
            "FAIL" \
            "curl exit=$CURL_RC; $CURL_HEADERS"
    fi

    HTTP_CODE="$(
        curl \
            --connect-timeout 10 \
            --max-time 20 \
            -sS \
            -o /dev/null \
            -w '%{http_code}' \
            "$TARGET_URL" \
            2>/dev/null
    )"

    case "$HTTP_CODE" in
        2??|3??)
            HTTP_STATUS="PASS"
            ;;
        4??)
            HTTP_STATUS="WARN"
            ;;
        5??)
            HTTP_STATUS="FAIL"
            ;;
        *)
            HTTP_STATUS="FAIL"
            ;;
    esac

    write_row \
        "http" \
        "HTTP status code" \
        "$HTTP_STATUS" \
        "$HTTP_CODE"

    CURL_TIMINGS="$(
        curl \
            --connect-timeout 10 \
            --max-time 20 \
            -sS \
            -o /dev/null \
            -w 'remote_ip=%{remote_ip} remote_port=%{remote_port} http_code=%{http_code} dns=%{time_namelookup}s connect=%{time_connect}s tls=%{time_appconnect}s starttransfer=%{time_starttransfer}s total=%{time_total}s\n' \
            "$TARGET_URL" \
            2>&1
    )"

    write_row \
        "http" \
        "request timings" \
        "INFO" \
        "$CURL_TIMINGS"

    REDIRECT_RESULT="$(
        curl \
            -L \
            --connect-timeout 10 \
            --max-time 30 \
            -sS \
            -o /dev/null \
            -w 'final_url=%{url_effective} final_status=%{http_code} redirects=%{num_redirects}' \
            "$TARGET_URL" \
            2>&1
    )"

    write_row \
        "http" \
        "redirect chain result" \
        "INFO" \
        "$REDIRECT_RESULT"

    INSECURE_TEST="$(
        curl \
            -k \
            --connect-timeout 10 \
            --max-time 20 \
            -sS \
            -o /dev/null \
            -w 'status=%{http_code} remote_ip=%{remote_ip}' \
            "$TARGET_URL" \
            2>&1
    )"

    INSECURE_RC=$?

    if [[ $INSECURE_RC -eq 0 ]]; then
        write_row \
            "http" \
            "HTTPS request ignoring certificate verification" \
            "PASS" \
            "$INSECURE_TEST"
    else
        write_row \
            "http" \
            "HTTPS request ignoring certificate verification" \
            "FAIL" \
            "$INSECURE_TEST"
    fi
fi

# ---------------------------------------------------------------------------
# TLS certificate
# ---------------------------------------------------------------------------

section "TLS"

if [[ "$TARGET_SCHEME" == "https" ]] && command_exists openssl; then

    TLS_RAW="$(
        timeout 15 \
            openssl s_client \
            -connect "${TARGET_HOST}:443" \
            -servername "$TARGET_HOST" \
            -showcerts \
            </dev/null \
            2>&1
    )"
    TLS_RC=$?

    if [[ $TLS_RC -eq 0 ]]; then
        write_row \
            "tls" \
            "TLS handshake" \
            "PASS" \
            "$TLS_RAW"
    else
        write_row \
            "tls" \
            "TLS handshake" \
            "FAIL" \
            "$TLS_RAW"
    fi

    CERT="$(
        printf '%s\n' "$TLS_RAW" |
            openssl x509 \
                -noout \
                -subject \
                -issuer \
                -dates \
                -serial \
                -ext subjectAltName \
                2>&1
    )"

    if [[ $? -eq 0 ]]; then
        write_row \
            "tls" \
            "certificate details" \
            "PASS" \
            "$CERT"
    else
        write_row \
            "tls" \
            "certificate details" \
            "WARN" \
            "$CERT"
    fi

    VERIFY_RESULT="$(
        printf '%s\n' "$TLS_RAW" |
            grep -E 'Verify return code|Verification error' |
            tail -n 5
    )"

    write_row \
        "tls" \
        "certificate verification" \
        "INFO" \
        "$VERIFY_RESULT"
fi

# ---------------------------------------------------------------------------
# TCP port checks
# ---------------------------------------------------------------------------

section "Ports"

if command_exists timeout; then
    if timeout 5 bash -c \
        "exec 3<>/dev/tcp/${TARGET_HOST}/443" 2>/dev/null
    then
        write_row \
            "network" \
            "TCP 443 reachable" \
            "PASS" \
            "${TARGET_HOST}:443"
    else
        write_row \
            "network" \
            "TCP 443 reachable" \
            "FAIL" \
            "${TARGET_HOST}:443"
    fi
fi

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

section "Docker"

if command_exists docker; then

    DOCKER_INFO="$(docker info 2>&1)"
    if [[ $? -eq 0 ]]; then
        write_row \
            "docker" \
            "Docker daemon" \
            "PASS" \
            "Docker daemon reachable"
    else
        write_row \
            "docker" \
            "Docker daemon" \
            "FAIL" \
            "$DOCKER_INFO"
    fi

    CONTAINERS="$(
        docker ps -a \
            --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}' \
            2>&1
    )"

    write_row \
        "docker" \
        "containers" \
        "INFO" \
        "$CONTAINERS"

    NETWORKS="$(docker network ls 2>&1)"
    write_row \
        "docker" \
        "docker networks" \
        "INFO" \
        "$NETWORKS"

    # -------------------------------------------------------
    # Specific application container
    # -------------------------------------------------------

    if [[ -n "$APP_CONTAINER" ]]; then

        if docker inspect "$APP_CONTAINER" >/dev/null 2>&1; then

            APP_STATE="$(
                docker inspect \
                    --format \
                    'status={{.State.Status}} running={{.State.Running}} restarting={{.State.Restarting}} exit={{.State.ExitCode}} started={{.State.StartedAt}}' \
                    "$APP_CONTAINER" \
                    2>&1
            )"

            write_row \
                "docker-app" \
                "application container state" \
                "PASS" \
                "$APP_STATE"

            APP_NETWORK="$(
                docker inspect \
                    --format '{{json .NetworkSettings.Networks}}' \
                    "$APP_CONTAINER" \
                    2>&1
            )"

            write_row \
                "docker-app" \
                "application network settings" \
                "INFO" \
                "$APP_NETWORK"

            APP_LOGS="$(
                docker logs \
                    --tail 100 \
                    "$APP_CONTAINER" \
                    2>&1
            )"

            write_row \
                "docker-app" \
                "application recent logs" \
                "INFO" \
                "$APP_LOGS"

            if [[ -n "$APP_PORT" ]]; then

                LISTEN_INSIDE="$(
                    docker exec \
                        "$APP_CONTAINER" \
                        sh -c \
                        "command -v ss >/dev/null 2>&1 && ss -lntp || command -v netstat >/dev/null 2>&1 && netstat -lntp || true" \
                        2>&1
                )"

                write_row \
                    "docker-app" \
                    "application listening ports" \
                    "INFO" \
                    "$LISTEN_INSIDE"

                LOCAL_HTTP="$(
                    docker exec \
                        "$APP_CONTAINER" \
                        sh -c \
                        "if command -v curl >/dev/null 2>&1; then curl -sS -I --max-time 5 http://127.0.0.1:${APP_PORT}; elif command -v wget >/dev/null 2>&1; then wget -S -O /dev/null http://127.0.0.1:${APP_PORT}; else exit 127; fi" \
                        2>&1
                )"

                LOCAL_HTTP_RC=$?

                if [[ $LOCAL_HTTP_RC -eq 0 ]]; then
                    write_row \
                        "docker-app" \
                        "application localhost HTTP" \
                        "PASS" \
                        "$LOCAL_HTTP"
                else
                    write_row \
                        "docker-app" \
                        "application localhost HTTP" \
                        "FAIL" \
                        "$LOCAL_HTTP"
                fi
            fi

        else
            write_row \
                "docker-app" \
                "application container" \
                "FAIL" \
                "Container not found: $APP_CONTAINER"
        fi
    fi

    # -------------------------------------------------------
    # Specific Tailscale sidecar
    # -------------------------------------------------------

    if [[ -n "$TAILSCALE_CONTAINER" ]]; then

        if docker inspect "$TAILSCALE_CONTAINER" >/dev/null 2>&1; then

            TS_CONTAINER_STATE="$(
                docker inspect \
                    --format \
                    'status={{.State.Status}} running={{.State.Running}} restarting={{.State.Restarting}} exit={{.State.ExitCode}} started={{.State.StartedAt}}' \
                    "$TAILSCALE_CONTAINER" \
                    2>&1
            )"

            write_row \
                "docker-tailscale" \
                "sidecar state" \
                "PASS" \
                "$TS_CONTAINER_STATE"

            TS_CONTAINER_LOGS="$(
                docker logs \
                    --tail 150 \
                    "$TAILSCALE_CONTAINER" \
                    2>&1
            )"

            write_row \
                "docker-tailscale" \
                "sidecar recent logs" \
                "INFO" \
                "$TS_CONTAINER_LOGS"

            TS_CONTAINER_STATUS="$(
                docker exec \
                    "$TAILSCALE_CONTAINER" \
                    tailscale status \
                    2>&1
            )"
            TS_CONTAINER_STATUS_RC=$?

            if [[ $TS_CONTAINER_STATUS_RC -eq 0 ]]; then
                write_row \
                    "docker-tailscale" \
                    "sidecar tailscale status" \
                    "PASS" \
                    "$TS_CONTAINER_STATUS"
            else
                write_row \
                    "docker-tailscale" \
                    "sidecar tailscale status" \
                    "FAIL" \
                    "$TS_CONTAINER_STATUS"
            fi

            TS_CONTAINER_IP="$(
                docker exec \
                    "$TAILSCALE_CONTAINER" \
                    tailscale ip -4 \
                    2>&1
            )"

            write_row \
                "docker-tailscale" \
                "sidecar Tailscale IP" \
                "INFO" \
                "$TS_CONTAINER_IP"

            TS_CONTAINER_SERVE="$(
                docker exec \
                    "$TAILSCALE_CONTAINER" \
                    tailscale serve status \
                    2>&1
            )"

            write_row \
                "docker-tailscale" \
                "sidecar serve status" \
                "INFO" \
                "$TS_CONTAINER_SERVE"

            SIDECAR_ENV="$(
                docker inspect \
                    --format '{{range .Config.Env}}{{println .}}{{end}}' \
                    "$TAILSCALE_CONTAINER" |
                    grep -E \
                        '^(TS_HOSTNAME|TS_STATE_DIR|TS_USERSPACE|TS_SERVE_CONFIG|TS_EXTRA_ARGS|TS_AUTH_ONCE)=' \
                    2>&1
            )"

            write_row \
                "docker-tailscale" \
                "sidecar relevant environment" \
                "INFO" \
                "$SIDECAR_ENV"

            SIDECAR_MOUNTS="$(
                docker inspect \
                    --format '{{range .Mounts}}{{println .Source " -> " .Destination " (" .Mode ")"}}{{end}}' \
                    "$TAILSCALE_CONTAINER" \
                    2>&1
            )"

            write_row \
                "docker-tailscale" \
                "sidecar mounts" \
                "INFO" \
                "$SIDECAR_MOUNTS"

            if [[ -n "$APP_PORT" ]]; then

                SIDECAR_TO_APP="$(
                    docker exec \
                        "$TAILSCALE_CONTAINER" \
                        sh -c \
                        "if command -v curl >/dev/null 2>&1; then curl -sS -I --max-time 5 http://127.0.0.1:${APP_PORT}; elif command -v wget >/dev/null 2>&1; then wget -S -O /dev/null http://127.0.0.1:${APP_PORT}; else exit 127; fi" \
                        2>&1
                )"

                SIDECAR_TO_APP_RC=$?

                if [[ $SIDECAR_TO_APP_RC -eq 0 ]]; then
                    write_row \
                        "docker-tailscale" \
                        "sidecar to application localhost" \
                        "PASS" \
                        "$SIDECAR_TO_APP"
                else
                    write_row \
                        "docker-tailscale" \
                        "sidecar to application localhost" \
                        "FAIL" \
                        "$SIDECAR_TO_APP"
                fi
            fi

        else
            write_row \
                "docker-tailscale" \
                "tailscale sidecar" \
                "FAIL" \
                "Container not found: $TAILSCALE_CONTAINER"
        fi
    fi

else
    write_row \
        "docker" \
        "Docker checks" \
        "SKIP" \
        "docker command unavailable"
fi

# ---------------------------------------------------------------------------
# Firewall
# ---------------------------------------------------------------------------

section "Firewall"

if command_exists ufw; then
    UFW_STATUS="$(ufw status verbose 2>&1)"

    write_row \
        "firewall" \
        "ufw status" \
        "INFO" \
        "$UFW_STATUS"
fi

if command_exists nft; then
    NFT_RULES="$(nft list ruleset 2>&1 | head -c 20000)"

    write_row \
        "firewall" \
        "nftables rules" \
        "INFO" \
        "$NFT_RULES"
fi

# ---------------------------------------------------------------------------
# Potential proxy / port conflicts
# ---------------------------------------------------------------------------

section "Port conflicts"

if command_exists ss; then

    HTTPS_LISTENERS="$(
        ss -lntp \
            2>&1 |
            grep -E '(:443[[:space:]]|:443$)' ||
            true
    )"

    if [[ -n "$HTTPS_LISTENERS" ]]; then
        write_row \
            "network" \
            "port 443 listeners" \
            "INFO" \
            "$HTTPS_LISTENERS"
    else
        write_row \
            "network" \
            "port 443 listeners" \
            "INFO" \
            "No host listener found on TCP 443"
    fi

    if [[ -n "$APP_PORT" ]]; then

        APP_PORT_LISTENERS="$(
            ss -lntp \
                2>&1 |
                grep -E ":${APP_PORT}[[:space:]]" ||
                true
        )"

        if [[ -n "$APP_PORT_LISTENERS" ]]; then
            write_row \
                "network" \
                "application port listeners" \
                "INFO" \
                "$APP_PORT_LISTENERS"
        else
            write_row \
                "network" \
                "application port listeners" \
                "WARN" \
                "No host listener found on TCP $APP_PORT. This may be normal with network_mode=service:tailscale."
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Basic heuristic diagnosis
# ---------------------------------------------------------------------------

section "Summary"

FAIL_COUNT="$(
    awk -F',' '
        NR > 1 && $4 ~ /"FAIL"/ {
            count++
        }
        END {
            print count + 0
        }
    ' "$OUTPUT_CSV"
)"

WARN_COUNT="$(
    awk -F',' '
        NR > 1 && $4 ~ /"WARN"/ {
            count++
        }
        END {
            print count + 0
        }
    ' "$OUTPUT_CSV"
)"

PASS_COUNT="$(
    awk -F',' '
        NR > 1 && $4 ~ /"PASS"/ {
            count++
        }
        END {
            print count + 0
        }
    ' "$OUTPUT_CSV"
)"

write_row \
    "summary" \
    "result counts" \
    "INFO" \
    "pass=$PASS_COUNT warn=$WARN_COUNT fail=$FAIL_COUNT"

echo
echo "Diagnostics complete."
echo
echo "PASS : $PASS_COUNT"
echo "WARN : $WARN_COUNT"
echo "FAIL : $FAIL_COUNT"
echo
echo "CSV saved to:"
echo "  $OUTPUT_CSV"
echo