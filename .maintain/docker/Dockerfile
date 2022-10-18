FROM rust:1.64.0-bullseye@sha256:8c50afd6d977e7770d190103df9877ed7a9200a3625dbeebaa9ffad76359d822 AS chef
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      clang \
      libclang-dev \
      pkg-config \
      libssl-dev \
      ; \
    rm -rf /var/lib/apt/lists/*; \
    rustup install nightly-2022-09-25; \
    rustup target add wasm32-unknown-unknown --toolchain nightly-2022-09-25; \
    cargo install cargo-chef --version 0.1.45;
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo +nightly-2022-09-25 chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo +nightly-2022-09-25 chef cook --release --recipe-path recipe.json
COPY . .
ENV WASM_BUILD_TOOLCHAIN=nightly-2022-09-25
RUN cargo build --release --locked

FROM debian:bullseye-slim@sha256:8b702518a671c926b5ece4efe386a476eb4777646a36d996d4bd50944f2f11a2 AS runner
LABEL social.myriad.image.authors="dev@myriad.social"
RUN useradd -m -u 1001 -U -s /bin/sh -d /myriad myriad && \
    mkdir -p /data /myriad/.local/share && \
    chown -R myriad:myriad /data && \
    ln -s /data /myriad/.local/share/myriad
COPY --from=builder /app/target/release/myriad /usr/local/bin
COPY --from=builder /app/target/release/wbuild/myriad-runtime/myriad_runtime.compact.compressed.wasm /myriad
# unclutter and minimize the attack surface
RUN rm -rf /usr/bin /usr/sbin
# check if executable works in this container
RUN /usr/local/bin/myriad --version
USER myriad
EXPOSE 30333 9933 9944 9615
VOLUME ["/data"]
ENTRYPOINT ["/usr/local/bin/myriad"]
