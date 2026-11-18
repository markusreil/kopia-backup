ARG KOPIA_VERSION=unknown
FROM kopia/kopia:${KOPIA_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends openssl \
    && rm -rf /var/lib/apt/lists/*

COPY docker/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Last: a new BUILD_DATE must not invalidate the layers above.
ARG BUILD_DATE=unknown
ENV BASE_IMAGE=kopia/kopia \
    BUILD_DATE=${BUILD_DATE}
