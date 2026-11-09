#!/bin/sh
# Split View Pro 本地构建脚本
# 用法: ./build.sh [roothide|rootless]
set -e

SCHEME="${1:-roothide}"
export THEOS="${THEOS:-$HOME/theos}"
export THEOS_PACKAGE_SCHEME="$SCHEME"
export BUILD_PREFS="${BUILD_PREFS:-0}"

if [ ! -d "$THEOS" ]; then
  echo "THEOS 不存在: $THEOS"
  echo "请先安装 roothide/theos："
  echo 'bash -c "$(curl -fsSL https://raw.githubusercontent.com/roothide/theos/master/bin/install-theos)"'
  exit 1
fi

make package FINALPACKAGE=1
echo "构建完成："
ls -lh packages/
