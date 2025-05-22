#!/usr/bin/env bash

# --- Path Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Load Libraries ---
. "${SCRIPT_DIR}/lib/shflags/shflags"
. "${SCRIPT_DIR}/lib/bashlog/log.sh"

# --- Define Flags ---
DEFINE_string 'engine' '' 'Preset search engine (elvi)' 'e'
DEFINE_boolean 'debug' false 'Enable debug logging' 'd'

# --- Parse Flags ---
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

# Enable bashlog debug mode if --debug is passed
[ "${FLAGS_debug}" -eq "${FLAGS_TRUE}" ] && DEBUG=1 || DEBUG=0

# --- Main ---
main() {
  log debug "q.sh starting up"

  local elvi_list engine query input
  elvi_list=$(sr -elvi | awk 'NR>1 {print $1}')
  local dmenu_cmd=$(command -v dmenu)

  if [ -z "$dmenu_cmd" ]; then
    log error "dmenu not found in PATH"
    exit 1
  fi

  if [ -n "${FLAGS_engine}" ]; then
    engine="${FLAGS_engine}"
    if echo "$elvi_list" | grep -qx "$engine"; then
      log info "Using curried engine: $engine"
      query=$(echo "" | $dmenu_cmd -p "Search $engine:")
      [ -z "$query" ] && log info "No query provided; exiting" && exit 0
      sr "$engine" "$query"
      exit $?
    else
      log error "Unknown engine: $engine"
      exit 1
    fi
  fi

  # One-shot input: first word is engine, rest is query
  input=$(echo "$elvi_list" | $dmenu_cmd -p "Search (engine query):")
  [ -z "$input" ] && log info "No input provided; exiting" && exit 0

  engine=$(echo "$input" | awk '{print $1}')
  query=$(echo "$input" | cut -d' ' -f2-)

  if echo "$elvi_list" | grep -qx "$engine"; then
    log info "Launching: sr $engine '$query'"
    sr "$engine" "$query"
  else
    log warn "Engine not recognized; defaulting to duckduckgo"
    sr duckduckgo "$input"
  fi
}

main "$@"
