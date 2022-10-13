FROM rust:1.64.0-slim-bullseye@sha256:8c50afd6d977e7770d190103df9877ed7a9200a3625dbeebaa9ffad76359d822 AS chef
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      make \
      clang \
      ; \
    rm -rf /var/lib/apt/lists/*; \
    rustup install nightly-2022-09-25; \
    rustup target add wasm32-unknown-unknown --toolchain nightly-2022-09-25; \
    cargo install cargo-chef --version 0.1.45;
WORKDIR /app

FROM chef AS planner
ENV WASM_BUILD_TOOLCHAIN=nightly-2022-09-25
COPY ./node /app/node
COPY ./pallets /app/pallets
COPY ./runtime /app/runtime
COPY ./Cargo.lock /app/Cargo.lock
COPY ./Cargo.toml /app/Cargo.toml
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
ENV WASM_BUILD_TOOLCHAIN=nightly-2022-09-25
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY ./node /app/node
COPY ./pallets /app/pallets
COPY ./runtime /app/runtime
COPY ./Cargo.lock /app/Cargo.lock
COPY ./Cargo.toml /app/Cargo.toml
RUN cargo build --release --locked

FROM debian:bullseye-slim@sha256:8b702518a671c926b5ece4efe386a476eb4777646a36d996d4bd50944f2f11a2 AS runner
LABEL social.myriad.image.authors="devops@myriad.social"
# Create user and set ownership and permissions as required
RUN useradd -m -u 1001 -U -s /bin/sh -d /home/myriad myriad && \
  # manage folder data
  mkdir -p /home/myriad/.local/share && \
  mkdir /data && \
  chown -R myriad:myriad /data && \
  ln -s /data /home/myriad/.local/share/myriad
# Copy from builder stage
COPY --from=builder /app/target/release/myriad /usr/local/bin
COPY --from=builder /app/target/wbuild/myriad-runtime/myriad_runtime.compact.compressed.wasm /home/myriad
# Set to a non-root built-in user
USER myriad
# check if executable works in this container
RUN /usr/local/bin/debio --version
# Set environment variable
ENV RUST_BACKTRACE=1
EXPOSE 30333 9933 9944 9615
VOLUME ["/data"]
ENTRYPOINT ["/usr/local/bin/myriad"]
