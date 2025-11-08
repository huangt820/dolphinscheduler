#!/bin/bash
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

# 解压 aliyunpan 目录下的 amd|arm zip 到 ./tmp/aliyunpan/

TMP_DIR="./tmp/aliyunpan"
echo "准备临时目录: $TMP_DIR"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
chmod 755 $TMP_DIR

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

# 先解压到临时目录，再把 zip 包中第一级目录下的所有文件/目录平移（移动）到 $TMP_DIR 下，
# 以去掉 zip 包的根目录层级。
EXTRACT_TMP="$(mktemp -d)"
trap 'rm -rf "$EXTRACT_TMP"' EXIT

echo "解压到临时目录: $EXTRACT_TMP ..."
unzip -q -o "$ZIPFILE" -d "$EXTRACT_TMP"

# 如果存在单一顶级目录，则把该目录下的内容移到 TMP_DIR；
# 否则将 EXTRACT_TMP 下的所有顶级条目移动到 TMP_DIR（达到去掉根目录的效果）。
shopt -s dotglob nullglob
entries=( "$EXTRACT_TMP"/* )
if [ ${#entries[@]} -eq 1 ] && [ -d "${entries[0]}" ]; then
    src="${entries[0]}"
    echo "检测到单一顶级目录: ${src##*/}，将其内容移动到 $TMP_DIR"
    for item in "$src"/* "$src"/.[!.]* "$src"/..?*; do
        [ -e "$item" ] || continue
        mv -f "$item" "$TMP_DIR"/
    done
else
    echo "存在多个顶级条目或直接文件，移动解压临时目录下的所有顶级条目到 $TMP_DIR"
    for item in "$EXTRACT_TMP"/* "$EXTRACT_TMP"/.[!.]* "$EXTRACT_TMP"/..?*; do
        [ -e "$item" ] || continue
        mv -f "$item" "$TMP_DIR"/
    done
fi
shopt -u dotglob nullglob

rm -rf "$EXTRACT_TMP"
echo "解压并平移完成，列出 $TMP_DIR 内容:"
ls -la "$TMP_DIR"
chmod -R 755 "$TMP_DIR"

# 构建 docker 镜像（以工作区根目录为构建上下文）
IMAGE_TAG="dolphinscheduler:${VERSION}-standalone-py-datax-aliyunpan-${ARCH}"
echo "开始构建镜像: $IMAGE_TAG 使用 Dockerfile: $DOCKERFILE"
sudo docker build -t "$IMAGE_TAG" -f "$DOCKERFILE" .

echo "构建完成: $IMAGE_TAG"