#!/usr/bin/env bash
set -euo pipefail

show_help() {
    cat <<EOF
用法: $(basename "$0") <version> <arch>

参数:
  version  Dolphinscheduler 版本, 可选: 3.3.1 或 3.1.9
  arch     架构, 可选: amd 或 arm

示例:
  $(basename "$0") 3.3.1 amd
  $(basename "$0") 3.1.9 arm
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

if [ $# -ne 2 ]; then
    echo "错误: 需要两个参数。"
    show_help
    exit 1
fi

VERSION="$1"
ARCH="$2"

if [[ "$VERSION" != "3.3.1" && "$VERSION" != "3.1.9" ]]; then
    echo "错误: 不支持的版本: $VERSION"
    echo "仅支持: 3.3.1 或 3.1.9"
    exit 2
fi

if [[ "$ARCH" != "amd" && "$ARCH" != "arm" ]]; then
    echo "错误: 不支持的架构: $ARCH"
    echo "仅支持: amd 或 arm"
    exit 3
fi

DOCKERFILE="./${VERSION}/Dockerfile"
if [ ! -f "$DOCKERFILE" ]; then
    echo "错误: 找不到 Dockerfile: $DOCKERFILE"
    exit 4
fi

# 解压 aliyunpan 目录下的 amd|arm zip 到 /tmp/dolphinscheduler/build/aliyunpan/

TMP_DIR="/tmp/dolphinscheduler/build/aliyunpan"
echo "准备临时目录: $TMP_DIR"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# 在 workspace 根目录下的 aliyunpan 目录中查找包含 amd|arm 的 zip 文件
if [ ! -d "./aliyunpan" ]; then
    echo "错误: 工作区中找不到 ./aliyunpan 目录"
    exit 5
fi

ZIPFILE=$(find ./aliyunpan -maxdepth 1 -type f \( -iname "*$ARCH*.zip" -o -iname "*$ARCH*.zip" \) | head -n 1 || true)

if [ -z "$ZIPFILE" ]; then
    echo "错误: 未在 ./aliyunpan 目录中找到 $ARCH zip 文件 (匹配 *$ARCH*.zip 或 *$ARCH*.zip)"
    exit 6
fi

echo "找到 zip: $ZIPFILE"
if ! command -v unzip >/dev/null 2>&1; then
    echo "警告: unzip 未安装，尝试使用 apt-get 安装（需要 sudo 权限）"
    sudo apt-get update && sudo apt-get install -y unzip
fi

echo "解压到 $TMP_DIR ..."
unzip -o "$ZIPFILE" -d "$TMP_DIR"
echo "解压完成，列出解压目录内容:"
ls -la "$TMP_DIR"


# 构建 docker 镜像（以工作区根目录为构建上下文）
IMAGE_TAG="dolphinscheduler:${VERSION}-py-datax-aliyunpan-${ARCH}"
echo "开始构建镜像: $IMAGE_TAG 使用 Dockerfile: $DOCKERFILE"
docker build -t "$IMAGE_TAG" -f "$DOCKERFILE" .

echo "构建完成: $IMAGE_TAG"