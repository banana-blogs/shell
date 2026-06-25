#!/usr/bin/env bash
#
# 在 Debian 13 (Trixie) 上安装 Docker —— 省心版
# 使用 Debian 官方仓库的 docker.io 包，
# 不涉及第三方仓库，绕开 sqv/SHA1 签名校验问题。
#
set -euo pipefail

# 必须以 root 或 sudo 运行
if [[ $EUID -ne 0 ]]; then
    echo "请以 root 身份运行，或在命令前加 sudo" >&2
    exit 1
fi

echo "==> 1. 更新软件包索引"
apt-get update

echo "==> 2. 安装 docker.io 与 compose"
# docker.io      : Debian 维护的 Docker Engine + CLI
# docker-compose : Debian 13 里这个包已是 Go 版 compose v2
apt-get install -y docker.io docker-compose

echo "==> 3. 启动并设置开机自启"
systemctl enable --now docker

echo "==> 4. 将当前登录用户加入 docker 组（免 sudo 运行 docker）"
TARGET_USER="${SUDO_USER:-${USER}}"
if [[ -n "${TARGET_USER}" && "${TARGET_USER}" != "root" ]]; then
    usermod -aG docker "${TARGET_USER}"
    echo "已将用户 ${TARGET_USER} 加入 docker 组（需重新登录或执行 newgrp docker 后生效）"
fi

echo
echo "==> 安装完成，版本信息："
docker --version
# Debian 的 docker-compose 可能是子命令形式，也可能是独立命令，两种都试
if docker compose version >/dev/null 2>&1; then
    docker compose version
elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose version
else
    echo "（未检测到 compose，可单独执行： apt install -y docker-compose）"
fi

echo
echo "验证： docker run --rm hello-world"
