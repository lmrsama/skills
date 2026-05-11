#!/usr/bin/env bash
# lmrsama / skills · 一行命令安装器
#
# 用法：
#   curl -fsSL https://lmrsama.github.io/skills/install.sh | bash -s html-deploy-github
#   curl -fsSL https://lmrsama.github.io/skills/install.sh | bash -s html-deploy-comments
#   curl -fsSL https://lmrsama.github.io/skills/install.sh | bash -s html-deploy-ai-edit
#   curl -fsSL https://lmrsama.github.io/skills/install.sh | bash -s html-report-publisher
#
# 也可以一次装多个：
#   curl -fsSL https://lmrsama.github.io/skills/install.sh | bash -s html-deploy-github html-deploy-comments
#
# 装到哪里：~/.workbuddy/skills/<skill-name>/

set -e

REPO_BASE="https://lmrsama.github.io/skills"
TARGET_DIR="${HOME}/.workbuddy/skills"

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

log()  { echo -e "${BLUE}▸${NC} $1"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }

# 已知 skill 列表（用于校验输入）
KNOWN_SKILLS=(
  "html-deploy-github"
  "html-deploy-comments"
  "html-deploy-ai-edit"
  "html-report-publisher"
)

is_known() {
  local skill="$1"
  for s in "${KNOWN_SKILLS[@]}"; do
    [ "$s" = "$skill" ] && return 0
  done
  return 1
}

print_usage() {
  echo "lmrsama / skills 安装器"
  echo ""
  echo "用法："
  echo "  curl -fsSL ${REPO_BASE}/install.sh | bash -s <skill-name>"
  echo ""
  echo "可用的 skill："
  for s in "${KNOWN_SKILLS[@]}"; do
    echo "  - $s"
  done
}

install_one() {
  local skill="$1"

  if ! is_known "$skill"; then
    err "未知 skill: $skill"
    print_usage
    return 1
  fi

  local zip_url="${REPO_BASE}/packages/${skill}.zip"
  local tmp_zip="$(mktemp -t skill-XXXXXX).zip"
  local target="${TARGET_DIR}/${skill}"

  log "下载 ${skill} ..."
  if ! curl -fsSL -o "$tmp_zip" "$zip_url"; then
    err "下载失败：$zip_url"
    return 1
  fi
  ok "已下载 $(du -h "$tmp_zip" | awk '{print $1}')"

  # 备份现有
  if [ -d "$target" ]; then
    local backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    warn "已存在 ${target}，备份到 ${backup}"
    mv "$target" "$backup"
  fi

  mkdir -p "$TARGET_DIR"
  log "解压到 $TARGET_DIR ..."
  if ! unzip -q "$tmp_zip" -d "$TARGET_DIR"; then
    err "解压失败"
    rm -f "$tmp_zip"
    return 1
  fi
  rm -f "$tmp_zip"

  # 给所有 .py 加可执行权限
  find "$target" -name "*.py" -type f -exec chmod +x {} \; 2>/dev/null || true

  ok "安装完成: $target"
  echo -e "${DIM}  下一步：阅读 ${target}/SKILL.md 开始使用${NC}"

  # 提示首次配置
  case "$skill" in
    html-deploy-github)
      echo ""
      echo "  💡 首次使用前先跑引导："
      echo "     python3 ${target}/scripts/setup.py"
      ;;
    html-deploy-comments)
      echo ""
      echo "  💡 依赖 html-deploy-github。如果还没装："
      echo "     curl -fsSL ${REPO_BASE}/install.sh | bash -s html-deploy-github"
      echo "  💡 创建评论 Gist："
      echo "     python3 ${target}/scripts/inject.py --setup-gist"
      ;;
    html-deploy-ai-edit)
      echo ""
      echo "  💡 这是引导层 skill，实际能力在 html-report-publisher 完整版"
      echo "  💡 还需准备：DeepSeek API Key（platform.deepseek.com）"
      ;;
    html-report-publisher)
      echo ""
      echo "  💡 配置示例：${target}/config.example.json"
      echo "  💡 复制为 config.json 并填入你的 token / gist_id / api_key"
      ;;
  esac
}

# 主流程
main() {
  if [ $# -eq 0 ]; then
    print_usage
    exit 0
  fi

  echo ""
  echo -e "${BLUE}====================================${NC}"
  echo -e "${BLUE}  lmrsama / skills 一键安装器${NC}"
  echo -e "${BLUE}====================================${NC}"
  echo ""

  # 依赖检查
  for cmd in curl unzip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      err "缺少必需命令：$cmd"
      exit 1
    fi
  done

  # 安装每个
  local failed=0
  for skill in "$@"; do
    install_one "$skill" || failed=$((failed + 1))
    echo ""
  done

  if [ "$failed" -gt 0 ]; then
    err "${failed} 个 skill 安装失败"
    exit 1
  fi

  ok "全部完成"
  echo ""
  echo "📍 已安装的 skill 位置：${TARGET_DIR}/"
  echo "📖 官网：${REPO_BASE}/"
}

main "$@"
