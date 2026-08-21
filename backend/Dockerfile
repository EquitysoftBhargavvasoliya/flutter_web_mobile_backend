# Pinned, not "dart:stable" — that floating tag moved to Dart 3.13.1 mid-project
# and broke AOT compilation of googleapis_auth's transitive http dependency.
# 3.12 is the verified-working version; bump deliberately, not via drift.
FROM dart:3.12 AS build

# Shared packages referenced via path dependency (../packages/* relative to /app).
COPY packages/ /packages/

# Resolve app dependencies.
WORKDIR /app
COPY backend/pubspec.* ./
RUN dart pub get

# Copy app source code (except anything in .dockerignore) and AOT compile app.
COPY backend/ .
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled `/server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

# Start server.
EXPOSE 8080
CMD ["/app/bin/server"]
