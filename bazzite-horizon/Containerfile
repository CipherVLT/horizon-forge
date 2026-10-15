# Bazzite Horizon
# Scaffold from ublue-os/image-template. Event Horizon is compiled in a
# throwaway stage so the compiler toolchain does not land in the image.
# BASE_IMAGE selects the Bazzite variant (AMD/Intel or NVIDIA open).

FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite:stable

FROM ${BASE_IMAGE} AS eh-builder
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    bash /ctx/build-event-horizon.sh

FROM ${BASE_IMAGE}
ARG BASE_IMAGE
ENV BAZZITE_HORIZON_BASE=${BASE_IMAGE}

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=eh-builder,source=/ehroot,target=/ehroot \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    bash /ctx/build.sh

RUN bootc container lint
