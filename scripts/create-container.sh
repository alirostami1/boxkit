#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ${0} [options] [name] [image]

Options:
  -n, --name NAME         Container name (default: dev)
  -i, --image [IMAGE]     Pick from local images (optional preselect)
      --keepalive         Keep the container running after exit (tmux if available, otherwise sleep)
      --no-docs           Skip all Documents mounts
      --no-docs-projects  Skip ~/Documents/projects
      --no-docs-work      Skip ~/Documents/work
      --no-docs-education Skip ~/Documents/education
      --wayland           Forward Wayland socket (default: off)
      --no-wayland        Do not forward Wayland socket
      --x11               Forward X11 socket (default: off)
      --no-x11            Do not forward X11 socket
      --dev-home          Include .dev-home mounts
      --no-dev-home       Skip .dev-home mounts (default)
  -h, --help              Show this help

If --image is omitted, the default image is used.
By default, containers stop when you exit. Use --keepalive to keep them running.
USAGE
}

NAME=""
IMAGE=""
IMAGE_INPUT=""
IMAGE_REQUESTED=0
INCLUDE_DOCS_PROJECTS=1
INCLUDE_DOCS_WORK=1
INCLUDE_DOCS_EDUCATION=1
INCLUDE_DEV_HOME=0
INCLUDE_WAYLAND=0
INCLUDE_X11=0
KEEPALIVE=0
DETACH_KEYS="ctrl-q,ctrl-q"
TMUX_SESSION="dev"
TMUX_KEEPALIVE_SCRIPT="trap 'exit 0' TERM INT HUP QUIT; if command -v tmux >/dev/null 2>&1; then tmux new -d -s ${TMUX_SESSION} >/dev/null 2>&1 || true; fi; while :; do sleep 3600 & wait \$!; done"
TMUX_ATTACH_SCRIPT="if command -v tmux >/dev/null 2>&1; then tmux attach -t ${TMUX_SESSION} || tmux new -As ${TMUX_SESSION}; exit; fi; exec bash"

while [[ $# -gt 0 ]]; do
  case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
  -n | --name)
    if [[ $# -lt 2 ]]; then
      echo "Missing value for --name" >&2
      exit 1
    fi
    NAME="$2"
    shift 2
    ;;
  -i | --image)
    IMAGE_REQUESTED=1
    if [[ $# -ge 2 && "$2" != "--" && "$2" != "-"* ]]; then
      IMAGE_INPUT="$2"
      shift 2
    else
      shift 1
    fi
    ;;
  --name=*)
    NAME="${1#*=}"
    shift 1
    ;;
  --image=*)
    IMAGE_REQUESTED=1
    IMAGE_INPUT="${1#*=}"
    shift 1
    ;;
  --keepalive)
    KEEPALIVE=1
    shift 1
    ;;
  --no-docs)
    INCLUDE_DOCS_PROJECTS=0
    INCLUDE_DOCS_WORK=0
    INCLUDE_DOCS_EDUCATION=0
    shift 1
    ;;
  --no-docs-projects)
    INCLUDE_DOCS_PROJECTS=0
    shift 1
    ;;
  --no-docs-work)
    INCLUDE_DOCS_WORK=0
    shift 1
    ;;
  --no-docs-education)
    INCLUDE_DOCS_EDUCATION=0
    shift 1
    ;;
  --dev-home)
    INCLUDE_DEV_HOME=1
    shift 1
    ;;
  --wayland)
    INCLUDE_WAYLAND=1
    shift 1
    ;;
  --no-wayland)
    INCLUDE_WAYLAND=0
    shift 1
    ;;
  --x11)
    INCLUDE_X11=1
    shift 1
    ;;
  --no-x11)
    INCLUDE_X11=0
    shift 1
    ;;
  --no-dev-home)
    INCLUDE_DEV_HOME=0
    shift 1
    ;;
  --)
    shift
    break
    ;;
  -*)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
  *)
    if [[ -z "$NAME" ]]; then
      NAME="$1"
    elif [[ -z "$IMAGE_INPUT" ]]; then
      IMAGE_REQUESTED=1
      IMAGE_INPUT="$1"
    else
      echo "Unexpected argument: $1" >&2
      usage >&2
      exit 1
    fi
    shift 1
    ;;
  esac
done

USER_NAME="${USER:-$(id -un)}"
HOME_DIR="/home/${USER_NAME}"

HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

DEFAULT_NAME="dev"
DEFAULT_IMAGE="localhost/dev:latest"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/container-creator"
CONFIG_FILE="${CONFIG_DIR}/config.yml"

read_config_value() {
  local key="$1" value
  value="$(sed -n "s/^[[:space:]]*${key}:[[:space:]]*//p" "$CONFIG_FILE" |
    sed 's/[[:space:]]*#.*$//' |
    head -n 1 |
    sed 's/[[:space:]]*$//')"
  if [[ -n "$value" ]]; then
    printf '%s' "$value"
  fi
}

load_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$CONFIG_DIR"
    cat <<EOF >"$CONFIG_FILE"
default_name: ${DEFAULT_NAME}
default_image: ${DEFAULT_IMAGE}
EOF
  fi

  local cfg_name cfg_image
  cfg_name="$(read_config_value "default_name" || true)"
  cfg_image="$(read_config_value "default_image" || true)"

  if [[ -n "$cfg_name" ]]; then
    DEFAULT_NAME="$cfg_name"
  fi
  if [[ -n "$cfg_image" ]]; then
    DEFAULT_IMAGE="$cfg_image"
  fi
}

load_config

if [[ -z "$NAME" ]]; then
  NAME="$DEFAULT_NAME"
fi
image_choices=()
image_values=()

collect_images() {
  local output line repo_tag image_id label value rank
  local -a lines sorted
  image_choices=()
  image_values=()
  if output=$(podman images --format '{{.Repository}}:{{.Tag}}|{{.ID}}' 2>/dev/null); then
    lines=()
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      repo_tag="${line%%|*}"
      image_id="${line##*|}"
      if [[ "$repo_tag" == "<none>:<none>" || "$repo_tag" == "<none>:" || "$repo_tag" == "<none>" ]]; then
        label="${image_id} (untagged)"
        value="${image_id}"
      else
        label="${repo_tag}"
        value="${repo_tag}"
      fi
      rank=3
      case "$value" in
      localhose/* | localhost/*)
        rank=1
        ;;
      ghcr.io/alirostami1/*)
        rank=2
        ;;
      esac
      lines+=("${rank}|${label}|${value}")
    done <<<"$output"

    if [[ ${#lines[@]} -gt 0 ]]; then
      mapfile -t sorted < <(printf '%s\n' "${lines[@]}" | sort -t'|' -k1,1n -k2,2)
      for line in "${sorted[@]}"; do
        label="${line#*|}"
        label="${label%%|*}"
        value="${line##*|}"
        image_choices+=("${label}")
        image_values+=("${value}")
      done
    fi
  fi
}

resolve_image_choice() {
  local choice="$1"
  if [[ "$choice" =~ ^[0-9]+$ ]]; then
    if ((choice < 1 || choice > ${#image_values[@]})); then
      echo "Image index out of range: $choice" >&2
      return 1
    fi
    printf '%s' "${image_values[$((choice - 1))]}"
    return 0
  fi
  printf '%s' "$choice"
}

if [[ "$IMAGE_REQUESTED" == "0" ]]; then
  IMAGE="$DEFAULT_IMAGE"
else
  collect_images
  if [[ ${#image_values[@]} -eq 0 ]]; then
    echo "No local images found; using ${DEFAULT_IMAGE}." >&2
    IMAGE="$DEFAULT_IMAGE"
  else
    echo "Available images:"
    for i in "${!image_choices[@]}"; do
      printf " [%d] %s\n" "$((i + 1))" "${image_choices[$i]}"
    done
    if [[ -t 0 ]]; then
      if [[ -n "$IMAGE_INPUT" ]]; then
        printf "Image number or name (default %s): " "$IMAGE_INPUT"
        read -r image_choice
        image_choice="${image_choice:-$IMAGE_INPUT}"
      else
        printf "Image number or name (default 1): "
        read -r image_choice
        image_choice="${image_choice:-1}"
      fi
    else
      image_choice="${IMAGE_INPUT:-1}"
    fi
    if ! IMAGE="$(resolve_image_choice "$image_choice")"; then
      exit 1
    fi
  fi
fi

container_exists=0
container_running="false"
container_keepalive=""
if podman container exists "${NAME}"; then
  container_exists=1
  container_running="$(podman inspect --format '{{.State.Running}}' "${NAME}" 2>/dev/null || true)"
  container_keepalive="$(podman inspect --format '{{ index .Config.Labels "com.boxkit.keepalive" }}' "${NAME}" 2>/dev/null || true)"
  container_image_id="$(podman inspect --format '{{.Image}}' "${NAME}" 2>/dev/null || true)"
  container_image_name="$(podman inspect --format '{{.ImageName}}' "${NAME}" 2>/dev/null || true)"
  requested_image_id="$(podman image inspect --format '{{.Id}}' "${IMAGE}" 2>/dev/null || true)"

  if [[ "$IMAGE_REQUESTED" == "1" ]]; then
    if [[ -n "$requested_image_id" && -n "$container_image_id" ]]; then
      if [[ "$requested_image_id" != "$container_image_id" ]]; then
        echo "Container ${NAME} already exists with a different image." >&2
        echo "Existing image: ${container_image_name:-$container_image_id}" >&2
        echo "Requested image: ${IMAGE}" >&2
        exit 1
      fi
    elif [[ -n "$container_image_name" && "$IMAGE" != "$container_image_name" ]]; then
      echo "Container ${NAME} already exists with a different image." >&2
      echo "Existing image: ${container_image_name}" >&2
      echo "Requested image: ${IMAGE}" >&2
      exit 1
    fi
  fi
fi

# -----------------------------
# Mounts: "HOST_PATH:CONTAINER_PATH[:OPTIONS]"
# OPTIONS default: Z
# -----------------------------
DOC_PROJECTS_MOUNTS=(
  "$HOME/Documents/projects:${HOME_DIR}/projects:Z"
)

DOC_WORK_MOUNTS=(
  "$HOME/Documents/work:${HOME_DIR}/work:Z"
)

DOC_EDUCATION_MOUNTS=(
  "$HOME/Documents/education:${HOME_DIR}/education:Z"
)

DEV_HOME_MOUNTS=(
  "$HOME/.dev-home/.config:${HOME_DIR}/.config/github-copilot:Z"
  "$HOME/.dev-home/.config:${HOME_DIR}/.config/gh:Z"
  "$HOME/.dev-home/.gitconfig:${HOME_DIR}/.gitconfig:ro,Z"
  "$HOME/.dev-home/.codex:${HOME_DIR}/.codex:Z"
)

BASE_MOUNTS=(
  "$HOME/Documents/scripts:${HOME_DIR}/scripts:ro,Z"
  "$HOME/Downloads:${HOME_DIR}/Downloads:ro,Z"
  "$HOME/.ssh/id_ed25519.pub:${HOME_DIR}/.ssh/id_ed25519.pub:ro,Z"
)

MOUNTS=("${BASE_MOUNTS[@]}")
if [[ "$INCLUDE_DOCS_PROJECTS" == "1" ]]; then
  MOUNTS+=("${DOC_PROJECTS_MOUNTS[@]}")
fi
if [[ "$INCLUDE_DOCS_WORK" == "1" ]]; then
  MOUNTS+=("${DOC_WORK_MOUNTS[@]}")
fi
if [[ "$INCLUDE_DOCS_EDUCATION" == "1" ]]; then
  MOUNTS+=("${DOC_EDUCATION_MOUNTS[@]}")
fi
if [[ "$INCLUDE_DEV_HOME" == "1" ]]; then
  MOUNTS+=("${DEV_HOME_MOUNTS[@]}")
fi

VOLUME_ARGS=()

add_mounts() {
  local m host cont opts
  for m in "$@"; do
    IFS=':' read -r host cont opts <<<"$m"
    [[ -n "${host:-}" && -n "${cont:-}" ]] || {
      echo "Invalid mount: $m" >&2
      exit 2
    }

    host="${host/#\~/$HOME}"
    [[ -e "$host" ]] || {
      echo "Mount source missing: $host" >&2
      exit 2
    }

    [[ -n "${opts:-}" ]] || opts="Z"

    VOLUME_ARGS+=("-v" "${host}:${cont}:${opts}")
  done
}

add_mounts "${MOUNTS[@]}"

# -----------------------------
# Optional: forward ssh-agent and GUI sockets (SELinux label disable usually needed)
# -----------------------------
need_label_disable=0
EXTRA_ARGS=()

if [[ -n "${SSH_AUTH_SOCK:-}" && -S "${SSH_AUTH_SOCK}" ]]; then
  need_label_disable=1
  EXTRA_ARGS+=(-v "${SSH_AUTH_SOCK}:/tmp/ssh-agent" -e "SSH_AUTH_SOCK=/tmp/ssh-agent")
fi

if [[ "$INCLUDE_WAYLAND" == "1" ]]; then
  if [[ -n "${XDG_RUNTIME_DIR:-}" && -n "${WAYLAND_DISPLAY:-}" && -S "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}" ]]; then
    need_label_disable=1
    EXTRA_ARGS+=(
      -v "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}:/tmp/${WAYLAND_DISPLAY}"
      -e "WAYLAND_DISPLAY=${WAYLAND_DISPLAY}"
      -e "XDG_RUNTIME_DIR=/tmp"
    )
  else
    echo "Wayland forwarding requested but no socket found." >&2
  fi
fi

if [[ "$INCLUDE_X11" == "1" ]]; then
  if [[ -n "${DISPLAY:-}" && -d "/tmp/.X11-unix" ]]; then
    need_label_disable=1
    EXTRA_ARGS+=(
      -v "/tmp/.X11-unix:/tmp/.X11-unix"
      -e "DISPLAY=${DISPLAY}"
    )
  else
    echo "X11 forwarding requested but DISPLAY or /tmp/.X11-unix is missing." >&2
  fi
fi

if [[ "$INCLUDE_WAYLAND" == "1" || "$INCLUDE_X11" == "1" ]]; then
  dbus_socket=""
  if [[ -n "${XDG_RUNTIME_DIR:-}" && -S "${XDG_RUNTIME_DIR}/bus" ]]; then
    dbus_socket="${XDG_RUNTIME_DIR}/bus"
  elif [[ -S "/run/user/${HOST_UID}/bus" ]]; then
    dbus_socket="/run/user/${HOST_UID}/bus"
  fi

  if [[ -n "$dbus_socket" ]]; then
    need_label_disable=1
    EXTRA_ARGS+=(
      -v "${dbus_socket}:/tmp/dbus-bus"
      -e "DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/dbus-bus"
    )
  else
    echo "GUI forwarding requested but no D-Bus session bus found." >&2
  fi
fi

if [[ "$need_label_disable" == "1" ]]; then
  EXTRA_ARGS+=(--security-opt label=disable)
fi

# create/start container (keepalive runs detached; default attaches and stops on exit)
if [[ "$container_exists" == "0" ]]; then
  echo "Creating the container '${NAME}' with '${IMAGE}', this may take some time..."
  if [[ "$KEEPALIVE" == "1" ]]; then
    podman run -dit \
      --name "${NAME}" \
      --hostname "${NAME}" \
      --label "com.boxkit.keepalive=1" \
      --userns=keep-id --group-add keep-groups \
      -e "HOME=${HOME_DIR}" -e "USER=${USER_NAME}" \
      -e "SHELL=/bin/bash" \
      --network=host \
      -w "${HOME_DIR}" \
      "${VOLUME_ARGS[@]}" \
      "${EXTRA_ARGS[@]}" \
      "${IMAGE}" \
      bash -lc "${TMUX_KEEPALIVE_SCRIPT}"
    exec podman exec -it --detach-keys="${DETACH_KEYS}" "${NAME}" \
      bash -lc "${TMUX_ATTACH_SCRIPT}"
  else
    exec podman run -it \
      --detach-keys="${DETACH_KEYS}" \
      --name "${NAME}" \
      --hostname "${NAME}" \
      --label "com.boxkit.keepalive=0" \
      --userns=keep-id --group-add keep-groups \
      -e "HOME=${HOME_DIR}" -e "USER=${USER_NAME}" \
      -e "SHELL=/bin/bash" \
      --network=host \
      -w "${HOME_DIR}" \
      "${VOLUME_ARGS[@]}" \
      "${EXTRA_ARGS[@]}" \
      "${IMAGE}" \
      bash
  fi
fi

if [[ "$KEEPALIVE" == "1" ]]; then
  if [[ "$container_running" != "true" ]]; then
    podman start "${NAME}" >/dev/null
  fi
  exec podman exec -it --detach-keys="${DETACH_KEYS}" "${NAME}" \
    bash -lc "${TMUX_ATTACH_SCRIPT}"
fi

if [[ "$container_running" == "true" ]]; then
  exec podman exec -it --detach-keys="${DETACH_KEYS}" "${NAME}" bash
fi

if [[ "$container_keepalive" == "0" ]]; then
  exec podman start -ai --detach-keys="${DETACH_KEYS}" "${NAME}"
fi

podman start "${NAME}" >/dev/null
exec podman exec -it --detach-keys="${DETACH_KEYS}" "${NAME}" bash
