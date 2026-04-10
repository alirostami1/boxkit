#!/bin/sh
set -e

arch_map() {
  x86_64_value="$1"
  arm64_value="$2"

  case "$(uname -m)" in
    x86_64)
      printf '%s' "${x86_64_value}"
      ;;
    aarch64|arm64)
      printf '%s' "${arm64_value}"
      ;;
    *)
      if command -v log_error >/dev/null 2>&1; then
        log_error "Unsupported architecture: $(uname -m)"
      else
        echo "Unsupported architecture: $(uname -m)" >&2
      fi
      return 1
      ;;
  esac
}
