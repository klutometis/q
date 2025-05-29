#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
. "${SCRIPT_DIR}/lib/shflags/shflags"
. "${SCRIPT_DIR}/lib/bashlog/log.sh"

# Flags
DEFINE_string 'engine' '' 'Preset search engine (elvi)' 'e'
DEFINE_boolean 'debug' false 'Enable debug logging' 'd'
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
[ "${FLAGS_debug}" -eq "${FLAGS_TRUE}" ] && DEBUG=1 || DEBUG=0

main() {
  log debug "Starting q.sh"
  local elvi_list input engine query
  elvi_list=$(sr -elvi | awk 'NR > 1 {print $1}')

  if [ -n "$FLAGS_engine" ]; then
    engine="$FLAGS_engine"
    if echo "$elvi_list" | grep -qx "$engine"; then
      query=$(echo "" | dmenu -p "Search $engine:")
      [ -z "$query" ] && log info "No query; exiting" && exit 0
      log info "Launching: sr $engine '$query'"
      sr "$engine" "$query"
    else
      log error "Unknown engine: '$engine'"
      exit 1
    fi
    exit 0
  fi

  # Use dmenu with trailing-space elvi list
  input=$(echo "$elvi_list" | sed 's/$/ /' | dmenu -p "Search:")
  [ -z "$input" ] && log info "No input; exiting" && exit 0

  engine=$(echo "$input" | awk '{print $1}')
  query=$(echo "$input" | cut -d' ' -f2-)

  if echo "$elvi_list" | grep -qx "$engine"; then
    log info "Launching: sr $engine '$query'"
    sr "$engine" $query
  else
    log error "Unknown engine: '$engine'"
    exit 1
  fi
}

main "$@"
