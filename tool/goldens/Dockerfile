# The one setup that renders and checks goldens: Linux x86_64 with the Flutter
# version from .fvmrc. Build it with --platform linux/amd64 on every host so a
# Mac (through Rosetta), CI and a Boat sandbox rasterise the same pixels.
FROM ubuntu:24.04@sha256:562111b88caa79c71391c0c4d3c2114a7d5c35915c20561fd893cb1e07929e6b

ARG FLUTTER_VERSION=3.44.4
ARG FLUTTER_COMMIT=ad70ec4617166f1c38e5d2bfd388af71fda14f06

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git /opt/flutter \
 && test "$(git -C /opt/flutter rev-parse HEAD)" = "$FLUTTER_COMMIT" \
 && git config --system --add safe.directory '*'

ENV PATH=/opt/flutter/bin:$PATH \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    PUB_CACHE=/opt/pub-cache

RUN flutter config --no-analytics --no-cli-animations \
 && flutter precache --no-android --no-ios --no-web --linux \
 && test -x /opt/flutter/bin/cache/artifacts/engine/linux-x64/flutter_tester \
 && test -f /opt/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf \
 && flutter --version
