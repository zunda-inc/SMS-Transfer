#!/bin/bash

# --- ISO 8601-ish & Path Settings ---
# Uses %Z for timezone name (e.g., JST, UTC)
TIMESTAMP=$(date "+%Y-%m-%dT%H%M%S%Z")
DESTINATION=${1:-"one.one.one.one"}
LOG_DIR="network_diag"
LOG_FILE="${LOG_DIR}/network_diag_${TIMESTAMP}.log"
JSON_FILE="${LOG_DIR}/network_diag_${TIMESTAMP}.json"

mkdir -p "$LOG_DIR"

# --- Color Definitions ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
CYAN='\033[0;36m'; GRAY='\033[0;90m'; ORANGE='\033[38;5;208m'
BOLD='\033[1m'; NC='\033[0m'

declare -A TEST_RESULTS
SUCCESS_COUNT=0; FAILURE_COUNT=0

# --- Helper: Logging ---
log_msg() {
    local level=$1; local message=$2; local color=""
    case $level in "info") color=$CYAN ;; "success") color=$GREEN ;; "error") color=$RED ;; "header") color=$BLUE ;; "warn") color=$YELLOW ;; *) color=$NC ;; esac
    local ts=$(date "+%Y-%m-%dT%H:%M:%S.%3N%Z")
    
    echo -e "${color}${message}${NC}"
    echo -e "[$ts] ${message}" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >> "$LOG_FILE"
}

check_tool() { command -v "$1" &> /dev/null; }

# --- Function: Comprehensive JSON Export ---
export_full_json() {
    {
        echo "{"
        echo "  \"report_meta\": { \"timestamp\": \"$(date --iso-8601=seconds)\", \"destination\": \"$DESTINATION\" },"
        
        # DNS Configuration
        echo -n "  \"dns_config\": { \"nameservers\": ["
        grep '^nameserver' /etc/resolv.conf | awk '{print "\""$2"\""}' | paste -sd, - | tr -d '\n'
        echo " ] },"

        # Full Routing Tables
        echo "  \"routing_tables\": {"
        echo "    \"ipv4\": [ $(ip -4 route show | awk '{printf "\"%s\", ", $0}' | sed 's/, $//') ],"
        echo "    \"ipv6\": [ $(ip -6 route show | awk '{printf "\"%s\", ", $0}' | sed 's/, $//') ]"
        echo "  },"

        # Detailed Interface Inventory
        echo "  \"interfaces\": ["
        local if_list=($(ip -brief link show | awk '{print $1}'))
        for i in "${!if_list[@]}"; do
            local iface=${if_list[$i]}
            local state=$(ip -brief link show "$iface" | awk '{print $2}')
            local mac=$(ip link show "$iface" | awk '/link\/ether/ {print $2}')
            local mtu=$(ip link show "$iface" | grep -oP 'mtu \K[0-9]+')
            echo "    {"
            echo "      \"name\": \"$iface\", \"state\": \"$state\", \"mac\": \"${mac:-null}\", \"mtu\": $mtu,"
            echo "      \"ipv4\": [ $(ip -4 addr show "$iface" | grep "inet " | awk '{print "\""$2"\""}' | paste -sd, -) ],"
            echo "      \"ipv6\": [ $(ip -6 addr show "$iface" | grep "inet6" | awk '{print "\""$2"\""}' | paste -sd, -) ]"
            echo -n "    }"
            [[ $i -lt $((${#if_list[@]} - 1)) ]] && echo "," || echo ""
        done
        echo "  ],"

        # Connectivity Test Results
        echo "  \"connectivity_results\": {"
        local keys=("${!TEST_RESULTS[@]}")
        for i in "${!keys[@]}"; do
            local k=${keys[$i]}; local v=${TEST_RESULTS[$k]}
            if [[ "$v" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then echo -n "    \"$k\": $v"
            elif [[ "$v" == "null" ]]; then echo -n "    \"$k\": null"
            else echo -n "    \"$k\": \"$v\""; fi
            [[ $i -lt $((${#keys[@]} - 1)) ]] && echo "," || echo ""
        done
        echo "  }"
        echo "}"
    } > "$JSON_FILE"
}

# --- Helper: Test Execution ---
run_test() {
    local cmd=$1; local label=$2; local key=$3
    echo -n "Testing: $label ... " | tee -a "$LOG_FILE"
    tmp_log=$(mktemp)
    eval "$cmd" > "$tmp_log" 2>&1
    local status=$?
    if [ $status -eq 0 ]; then
        local rtt=$(grep "rtt" "$tmp_log" | cut -d'/' -f5)
        local out_val=$(cat "$tmp_log" | head -n 1 | xargs)
        if [[ "$label" == *"DNS"* || "$label" == *"Public"* || "$label" == *"Port"* ]]; then
            [ -z "$out_val" ] && out_val="OPEN"
            echo -e "${GREEN}[$out_val]${NC}"; TEST_RESULTS["$key"]="$out_val"
        else
            echo -e "${GREEN}[OK]${NC} [${rtt}ms]"; TEST_RESULTS["$key"]="$rtt"
        fi
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}[NG]${NC}"; TEST_RESULTS["$key"]="null"
        ((FAILURE_COUNT++))
    fi
    rm -f "$tmp_log"
}

# --- START TERMINAL TAKEOVER ---
clear
log_msg "header" "================================================="
log_msg "header" "       FULL STACK NETWORK CONFIG & DIAG          "
log_msg "header" "================================================="

# [0] Interface Config Inventory

log_msg "warn" "[0] Network Interface Inventory"
while read -r iface state rest; do
    case "$state" in "UP") s_col="${GREEN}UP${NC}" ;; "DOWN") s_col="${GRAY}DOWN${NC}" ;; *) s_col="${ORANGE}$state${NC}" ;; esac
    mac=$(ip link show "$iface" | awk '/link\/ether/ {print $2}')
    mtu=$(ip link show "$iface" | grep -oP 'mtu \K[0-9]+')
    echo -e "  ${BOLD}$iface${NC} : $s_col [MAC: ${mac:-N/A}] [MTU: $mtu]"
    ip -brief addr show "$iface" | awk '{for(i=3;i<=NF;i++) print "    IP: "$i}'
done < <(ip -brief link show)

# [1] Route & Resolver Config
echo ""
log_msg "warn" "[1] Routing & DNS Configuration"
log_msg "info" "Nameservers (/etc/resolv.conf):"
grep '^nameserver' /etc/resolv.conf | awk '{print "  " $2}' | tee -a "$LOG_FILE"
log_msg "info" "IPv4 Routes (ip -4 r s):"
ip -4 route show | while read -r line; do log_msg "plain" "  $line"; done
log_msg "info" "IPv6 Routes (ip -6 r s):"
ip -6 route show | while read -r line; do log_msg "plain" "  $line"; done

# [2] Connectivity Tests
echo ""
log_msg "warn" "[2.1] Connectivity & DNS Diagnostic IPv4"
if check_tool "dig"; then
    run_test "dig +short A $DESTINATION" "DNS IPv4 (A)" "dns_v4"
fi
run_test "ping -4 -c 2 -W 2 $DESTINATION" "IPv4 Ping" "dest_v4_rtt"
if check_tool "curl"; then
    run_test "curl -4 -s --connect-timeout 3 icanhazip.com" "Public IPv4" "public_ipv4"
fi
echo ""
log_msg "warn" "[2.2] Connectivity & DNS Diagnostic IPv6"
if check_tool "dig"; then
    run_test "dig +short AAAA $DESTINATION" "DNS IPv6 (AAAA)" "dns_v6"
fi
run_test "ping -6 -c 2 -W 2 $DESTINATION" "IPv6 Ping" "dest_v6_rtt"
if check_tool "curl"; then
    run_test "curl -6 -s --connect-timeout 3 icanhazip.com" "Public IPv6" "public_ipv6"
fi

# [3] Results Summary
echo ""
log_msg "warn" "[3] Test Results Summary"
log_msg "header" "================================================="
log_msg "plain" "  SUCCESS: $SUCCESS_COUNT / FAIL: $FAILURE_COUNT"
log_msg "header" "================================================="

# [4] Results Files Location
echo ""
log_msg "warn" "[4] Results Files"
log_msg "info" "Log File: $LOG_FILE"
log_msg "info" "JSON File: $JSON_FILE"

# [5] Final JSON Dump
echo ""
export_full_json
log_msg "warn" "[5] Final JSON Report"
log_msg "header" "-------------------------------------------------"
log_msg "header" "           PRETTY-PRINTED JSON DATA              "
log_msg "header" "-------------------------------------------------"
if check_tool "jq"; then
    cat "$JSON_FILE" | jq . | tee -a "$LOG_FILE"
else
    cat "$JSON_FILE" | tee -a "$LOG_FILE"
fi