# Rustrak (Sentry-compatible error tracking) for Railway, PostgreSQL build.
# Upstream image: https://hub.docker.com/r/rustrak/rustrak-server
# The tag and digest are pinned together; bump both when updating (see CHANGELOG.md).
FROM busybox:1.38.0-musl@sha256:80e38f9a1b39188b8bdb28879178edb322a4402b081a9aedda1924609decd6f6 AS busybox

FROM rustrak/rustrak-server:v0.31.0-postgres@sha256:d6983b663d89e1514cd243c0db7895955301791b2db00463e695eec296cff0cf

# The upstream image is distroless (no shell). A static busybox runs the small
# start script: it waits for PostgreSQL, prepares the Railway volume and then
# runs Rustrak as the image's unprivileged user (65532).
COPY --from=busybox /bin/busybox /busybox/busybox
COPY start.sh /busybox/start.sh

USER root
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["/busybox/busybox", "sh", "/busybox/start.sh"]
