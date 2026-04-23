ARG BASE_IMAGE=localhost/fedora-dev:latest
FROM ${BASE_IMAGE}

LABEL com.github.containers.toolbox="true" \
      usage="This image is meant to be used for scientific development" \
      summary="Fedora dev science image" \
      maintainer="contact@alirostami.net"

ARG USERNAME=aros

COPY --chown=${USERNAME}:${USERNAME} ../scripts/fedora-dev-science.sh /home/${USERNAME}/fedora-dev-science.sh
COPY --chown=${USERNAME}:${USERNAME} ../scripts/lib/ /home/${USERNAME}/lib/
COPY --chown=${USERNAME}:${USERNAME} ../packages/fedora-dev-science.packages /home/${USERNAME}/fedora-dev-science.packages

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Run the setup script
RUN chmod +x fedora-dev-science.sh \
    && ./fedora-dev-science.sh \
    && rm -f fedora-dev-science.sh fedora-dev-science.packages \
    && rm -rf lib
