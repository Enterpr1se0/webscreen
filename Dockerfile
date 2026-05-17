# 1. 必须放在最顶端，这样才能被所有的 FROM 识别
ARG BUILD_VERSION=lite
ARG TARGETARCH
ARG BINARY_PATH=dist/webscreen-linux-${TARGETARCH}

# ==========================================
# [阶段 1] Lite 版本
# ==========================================
FROM alpine:latest AS env-lite
RUN apk add --no-cache android-tools
RUN adduser -D appuser && \
    apk add --no-cache sudo && \
    echo "appuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/appuser
COPY ${BINARY_PATH} ./webscreen

# ==========================================
# [阶段 2] Full 版本
# ==========================================
FROM ubuntu:24.04 AS env-full
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo adb xorg ffmpeg sway wf-recorder xfce4 xvfb seatd xwayland xterm

RUN useradd -m -s /bin/bash -G video,input appuser \
    && echo "appuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/appuser \
    && chmod 0440 /etc/sudoers.d/appuser

# ==========================================
# [最终阶段] 动态继承
# ==========================================
# 这里的 ${BUILD_VERSION} 会正确读取到顶层传进来的 full 或 lite
FROM env-${BUILD_VERSION} AS final

WORKDIR /app
COPY entrypoint.sh /app/entrypoint.sh
ARG BINARY_PATH
COPY ${BINARY_PATH} /app/webscreen
# 【防坑提示】：如果你想在之后的 RUN 指令中也使用这个变量，必须重新声明一次
ARG BUILD_VERSION 
RUN echo "Currently building: ${BUILD_VERSION} version"

RUN chmod +x /app/entrypoint.sh 
RUN chmod +x /app/webscreen

USER appuser
ENV PIN="123456"
ENV PORT=8079
EXPOSE $PORT

ENTRYPOINT ["/app/entrypoint.sh"]