#!/bin/sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
. "${script_dir}/lib/log.sh"

usage() {
  cat <<'USAGE'
Usage: scripts/create-derivative.sh --base <image> --name <containerfile> [--script]

Options:
  -b, --base   Base image (fedora-dev, ubuntu-dev, or full reference)
  -n, --name   New ContainerFile name (e.g. fedora-dev-ansible)
  -s, --script Create a setup script (prompts if omitted)
      --no-script  Do not create a setup script
  -h, --help   Show this help

If --base or --name are omitted, the script will prompt for them.
Shorthand base names use BOXKIT_BASE_REGISTRY (default: ghcr.io/REPLACE_ME).
USAGE
}

default_registry="${BOXKIT_BASE_REGISTRY:-ghcr.io/REPLACE_ME}"

base=""
name=""
with_script=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -b|--base)
      if [ $# -lt 2 ]; then
        die "Missing value for --base"
      fi
      base="$2"
      shift 2
      ;;
    -n|--name)
      if [ $# -lt 2 ]; then
        die "Missing value for --name"
      fi
      name="$2"
      shift 2
      ;;
    -s|--script)
      with_script="yes"
      shift 1
      ;;
    --no-script)
      with_script="no"
      shift 1
      ;;
    --base=*)
      base="${1#*=}"
      shift 1
      ;;
    --name=*)
      name="${1#*=}"
      shift 1
      ;;
    --)
      shift
      break
      ;;
    -*)
      log_error "Unknown option: $1"
      usage >&2
      exit 1
      ;;
    *)
      log_error "Unexpected argument: $1"
      usage >&2
      exit 1
      ;;
  esac
done

resolve_base() {
  case "$1" in
    1|fedora|fedora-dev)
      printf '%s/fedora-dev:latest' "$default_registry"
      ;;
    2|ubuntu|ubuntu-dev)
      printf '%s/ubuntu-dev:latest' "$default_registry"
      ;;
    *)
      printf '%s' "$1"
      ;;
  esac
}

if [ -z "$base" ]; then
  printf "Choose base image [1] fedora-dev [2] ubuntu-dev (default 1): "
  read -r base_choice
  case "$base_choice" in
    ""|1|fedora|fedora-dev)
      base="fedora-dev"
      ;;
    2|ubuntu|ubuntu-dev)
      base="ubuntu-dev"
      ;;
    *)
      base="$base_choice"
      ;;
  esac
fi

if [ -z "$name" ]; then
  printf "Derivative name (ContainerFile name): "
  read -r name
fi

if [ -z "$with_script" ]; then
  printf "Create setup script? [y/N]: "
  read -r reply
  case "$reply" in
    y|Y|yes|YES)
      with_script="yes"
      ;;
    *)
      with_script="no"
      ;;
  esac
fi

base="$(resolve_base "$base")"

if [ -z "$base" ] || [ -z "$name" ]; then
  die "Both base image and name are required."
fi

case "$name" in
  *" "*|*"\t"*|*"/"*)
    die "Name must be a single path segment without spaces or slashes."
    ;;
  *)
    ;;
esac

repo_root=$(CDPATH= cd -- "${script_dir}/.." && pwd -P)
containerfiles_dir="${repo_root}/ContainerFiles"
packages_dir="${repo_root}/packages"
scripts_dir="${repo_root}/scripts"

if [ ! -d "$containerfiles_dir" ]; then
  die "ContainerFiles directory not found at ${containerfiles_dir}"
fi
if [ ! -d "$packages_dir" ]; then
  die "packages directory not found at ${packages_dir}"
fi
if [ ! -d "$scripts_dir" ]; then
  die "scripts directory not found at ${scripts_dir}"
fi

target="${containerfiles_dir}/${name}"
if [ -e "$target" ]; then
  die "${target} already exists. Pick a different name or remove it first."
fi

packages_target="${packages_dir}/${name}.packages"
if [ -e "$packages_target" ]; then
  die "${packages_target} already exists. Pick a different name or remove it first."
fi

script_target="${scripts_dir}/${name}.sh"
if [ "$with_script" = "yes" ] && [ -e "$script_target" ]; then
  die "${script_target} already exists. Pick a different name or remove it first."
fi

log_step "Creating derivative ${name} from ${base}"

if [ "$with_script" = "yes" ]; then
  cat <<EOCONTAINER > "$target"
ARG BASE_IMAGE=${base}
FROM \${BASE_IMAGE}

LABEL com.github.containers.toolbox="true" \\
      usage="This image is meant to be used with the toolbox or distrobox command" \\
      summary="Derivative image: ${name}" \\
      maintainer="contact@alirostami.net"

ARG USERNAME=aros

COPY --chown=\${USERNAME}:\${USERNAME} ../scripts/${name}.sh /home/\${USERNAME}/${name}.sh
COPY --chown=\${USERNAME}:\${USERNAME} ../packages/${name}.packages /home/\${USERNAME}/${name}.packages

USER \${USERNAME}
WORKDIR /home/\${USERNAME}

# Run the setup script
RUN chmod +x ${name}.sh && ./${name}.sh && rm -f ${name}.sh ${name}.packages
EOCONTAINER
else
  cat <<EOCONTAINER > "$target"
ARG BASE_IMAGE=${base}
FROM \${BASE_IMAGE}

LABEL com.github.containers.toolbox="true" \
      usage="This image is meant to be used with the toolbox or distrobox command" \
      summary="Derivative image: ${name}" \
      maintainer="contact@alirostami.net"

# Add customization below.
EOCONTAINER
fi

cat <<EOF > "$packages_target"
# Add package names here (one per line).
EOF

if [ "$with_script" = "yes" ]; then
  cat <<EOF > "$script_target"
#!/bin/sh
set -e

# Install packages using the appropriate package manager for your base image.
# For Fedora:
#   grep -v '^#' ./${name}.packages | xargs sudo dnf install -y
# For Ubuntu:
#   sudo apt-get update
#   sudo apt-get install -y --no-install-recommends \$(grep -v '^#' ./${name}.packages)

# Add customization below.
EOF
  chmod +x "$script_target"
fi

log_info "Created ${target}"
log_info "Created ${packages_target}"
if [ "$with_script" = "yes" ]; then
  log_info "Created ${script_target}"
fi
log_info "Next steps: edit the new files and add ${name} to the derivatives matrix in .github/workflows/build-boxkit.yml"
