set shell := ["bash", "-cu"]

container_tool := "podman"
registry := "localhost"
tag := "latest"
pull := "0"
no_cache := "0"
layers := "0"

# Toggle build behavior by passing variables, e.g.:
#   just bases pull=1 no_cache=1 layers=1

# Build base images first.
bases:
    pull_flag=""; no_cache_flag=""; layers_flag=""; \
      if [[ "{{pull}}" == "1" ]]; then pull_flag="--pull=always"; fi; \
      if [[ "{{no_cache}}" == "1" ]]; then no_cache_flag="--no-cache"; fi; \
      if [[ "{{layers}}" == "1" ]]; then layers_flag="--layers"; fi; \
      git_sha="$(git rev-parse --short HEAD 2>/dev/null || true)"; \
      build_date="$(date -u +%Y%m%d)"; \
      build_time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; \
      source_url="$(git config --get remote.origin.url 2>/dev/null || true)"; \
      user_name="${USER:-aros}"; user_uid="$(id -u)"; user_gid="$(id -g)"; \
      tag_args=(-t {{registry}}/fedora-dev:{{tag}} -t {{registry}}/fedora-dev:${build_date}); \
      label_args=(--label "org.opencontainers.image.created=${build_time}"); \
      label_args+=(--label "org.opencontainers.image.revision=${git_sha}"); \
      if [[ -n "${source_url}" ]]; then label_args+=(--label "org.opencontainers.image.source=${source_url}"); fi; \
      {{container_tool}} build $pull_flag $no_cache_flag $layers_flag \
        "${label_args[@]}" \
        --build-arg USERNAME="${user_name}" \
        --build-arg USER_UID="${user_uid}" \
        --build-arg USER_GID="${user_gid}" \
        -f ContainerFiles/fedora-dev \
        "${tag_args[@]}" \
        .
    pull_flag=""; no_cache_flag=""; layers_flag=""; \
      if [[ "{{pull}}" == "1" ]]; then pull_flag="--pull=always"; fi; \
      if [[ "{{no_cache}}" == "1" ]]; then no_cache_flag="--no-cache"; fi; \
      if [[ "{{layers}}" == "1" ]]; then layers_flag="--layers"; fi; \
      git_sha="$(git rev-parse --short HEAD 2>/dev/null || true)"; \
      build_date="$(date -u +%Y%m%d)"; \
      build_time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; \
      source_url="$(git config --get remote.origin.url 2>/dev/null || true)"; \
      user_name="${USER:-aros}"; user_uid="$(id -u)"; user_gid="$(id -g)"; \
      tag_args=(-t {{registry}}/ubuntu-dev:{{tag}} -t {{registry}}/ubuntu-dev:${build_date}); \
      label_args=(--label "org.opencontainers.image.created=${build_time}"); \
      label_args+=(--label "org.opencontainers.image.revision=${git_sha}"); \
      if [[ -n "${source_url}" ]]; then label_args+=(--label "org.opencontainers.image.source=${source_url}"); fi; \
      {{container_tool}} build $pull_flag $no_cache_flag $layers_flag \
        "${label_args[@]}" \
        --build-arg USERNAME="${user_name}" \
        --build-arg USER_UID="${user_uid}" \
        --build-arg USER_GID="${user_gid}" \
        -f ContainerFiles/ubuntu-dev \
        "${tag_args[@]}" \
        .
    pull_flag=""; no_cache_flag=""; layers_flag=""; \
      if [[ "{{pull}}" == "1" ]]; then pull_flag="--pull=always"; fi; \
      if [[ "{{no_cache}}" == "1" ]]; then no_cache_flag="--no-cache"; fi; \
      if [[ "{{layers}}" == "1" ]]; then layers_flag="--layers"; fi; \
      git_sha="$(git rev-parse --short HEAD 2>/dev/null || true)"; \
      build_date="$(date -u +%Y%m%d)"; \
      build_time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; \
      source_url="$(git config --get remote.origin.url 2>/dev/null || true)"; \
      user_name="${USER:-aros}"; user_uid="$(id -u)"; user_gid="$(id -g)"; \
      tag_args=(-t {{registry}}/notes:{{tag}} -t {{registry}}/notes:${build_date}); \
      label_args=(--label "org.opencontainers.image.created=${build_time}"); \
      label_args+=(--label "org.opencontainers.image.revision=${git_sha}"); \
      if [[ -n "${source_url}" ]]; then label_args+=(--label "org.opencontainers.image.source=${source_url}"); fi; \
      {{container_tool}} build $pull_flag $no_cache_flag $layers_flag \
        "${label_args[@]}" \
        --build-arg USERNAME="${user_name}" \
        --build-arg USER_UID="${user_uid}" \
        --build-arg USER_GID="${user_gid}" \
        --build-arg BASE_IMAGE={{registry}}/fedora-dev:{{tag}} \
        -f ContainerFiles/notes \
        "${tag_args[@]}" \
        .

# Build derivative images on top of bases.
derivatives:

# Build everything locally.
all: bases derivatives

# Build a single image: just build image=fedora-dev
build image base="":
    pull_flag=""; no_cache_flag=""; layers_flag=""; \
      if [[ "{{pull}}" == "1" ]]; then pull_flag="--pull=always"; fi; \
      if [[ "{{no_cache}}" == "1" ]]; then no_cache_flag="--no-cache"; fi; \
      if [[ "{{layers}}" == "1" ]]; then layers_flag="--layers"; fi; \
      git_sha="$(git rev-parse --short HEAD 2>/dev/null || true)"; \
      build_date="$(date -u +%Y%m%d)"; \
      build_time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; \
      source_url="$(git config --get remote.origin.url 2>/dev/null || true)"; \
      user_name="${USER:-aros}"; user_uid="$(id -u)"; user_gid="$(id -g)"; \
      tag_args=(-t {{registry}}/{{image}}:{{tag}} -t {{registry}}/{{image}}:${build_date}); \
      label_args=(--label "org.opencontainers.image.created=${build_time}"); \
      label_args+=(--label "org.opencontainers.image.revision=${git_sha}"); \
      if [[ -n "${source_url}" ]]; then label_args+=(--label "org.opencontainers.image.source=${source_url}"); fi; \
      base_args=(); \
      if [[ -n "{{base}}" ]]; then base_args=(--build-arg BASE_IMAGE={{base}}); fi; \
      {{container_tool}} build $pull_flag $no_cache_flag $layers_flag \
        "${label_args[@]}" \
        --build-arg USERNAME="${user_name}" \
        --build-arg USER_UID="${user_uid}" \
        --build-arg USER_GID="${user_gid}" \
        "${base_args[@]}" \
        -f ContainerFiles/{{image}} \
        "${tag_args[@]}" \
        .
