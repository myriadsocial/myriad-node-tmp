FROM rust:1.64.0-bullseye@sha256:8c50afd6d977e7770d190103df9877ed7a9200a3625dbeebaa9ffad76359d822 AS chef
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      clang \
      curl \
      libssl-dev \
      llvm \
      libudev-dev \
      make \
      protobuf-compiler \
      ; \
    rm -rf /var/lib/apt/lists/*; \
    rustup install nightly-2022-09-25; \
    rustup target add wasm32-unknown-unknown --toolchain nightly-2022-09-25; \
    cargo install cargo-chef --version 0.1.45;
WORKDIR /myriad

FROM chef AS planner
ENV WASM_BUILD_TOOLCHAIN=nightly-2022-09-25
COPY ./node /myriad/node
COPY ./pallets /myriad/pallets
COPY ./runtime /myriad/runtime
COPY ./Cargo.lock /myriad/Cargo.lock
COPY ./Cargo.toml /myriad/Cargo.toml
RUN cargo +nightly-2022-09-25 chef prepare --recipe-path recipe.json

FROM chef AS builder
ENV WASM_BUILD_TOOLCHAIN=nightly-2022-09-25
COPY --from=planner /myriad/recipe.json recipe.json
RUN cargo +nightly-2022-09-25 chef cook --release --recipe-path recipe.json
COPY ./node /myriad/node
COPY ./pallets /myriad/pallets
COPY ./runtime /myriad/runtime
COPY ./Cargo.lock /myriad/Cargo.lock
COPY ./Cargo.toml /myriad/Cargo.toml
RUN cargo build --release --locked

FROM debian:bullseye-slim@sha256:8b702518a671c926b5ece4efe386a476eb4777646a36d996d4bd50944f2f11a2 AS runner
LABEL social.myriad.image.authors="dev@myriad.social"
COPY --from=builder /myriad/target/release/myriad /usr/local/bin
COPY --from=builder /myriad/target/release/wbuild/myriad-runtime/myriad_runtime.compact.compressed.wasm /myriad
RUN useradd -m -u 1001 -U -s /bin/sh -d /myriad myriad && \
  mkdir -p /data /myriad/.local/share && \
  chown -R myriad:myriad /data && \
  ln -s /data /myriad/.local/share/myriad && \
  # unclutter and minimize the attack surface
	rm -rf /usr/bin /usr/sbin && \
  # check if executable works in this container
	/usr/local/bin/myriad --version
USER myriad
EXPOSE 30333 9933 9944 9615
VOLUME ["/data"]
ENTRYPOINT ["/usr/local/bin/myriad"]
