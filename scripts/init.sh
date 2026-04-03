#!/bin/bash
# cclaw 初始化脚本
# 用法：bash scripts/init.sh [目标目录]
# 示例：bash scripts/init.sh ~/my-openclaw-project
# 如不传参数，在当前目录初始化

set -e

TARGET="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "cclaw 初始化脚本 v1.0.0"
echo "目标目录：$TARGET"
echo "---"

# 创建目录结构
echo "[1/5] 创建目录结构..."
mkdir -p "$TARGET/skills/dream"
mkdir -p "$TARGET/skills/wiki"
mkdir -p "$TARGET/skills/verify"
mkdir -p "$TARGET/skills/extract"
mkdir -p "$TARGET/topics/archive"
mkdir -p "$TARGET/transcripts"
echo "      ✓ 目录结构创建完成"

# 复制 Skills
echo "[2/5] 安装 Skills..."
for skill in dream wiki verify extract; do
  if [ -f "$REPO_ROOT/skills/$skill/SKILL.md" ]; then
    cp "$REPO_ROOT/skills/$skill/SKILL.md" "$TARGET/skills/$skill/SKILL.md"
    echo "      ✓ $skill/SKILL.md"
  else
    echo "      ! $skill/SKILL.md 不存在，跳过"
  fi
done

# 复制模板
echo "[3/5] 复制配置模板..."

# MEMORY.md — 如已存在则跳过
if [ -f "$TARGET/MEMORY.md" ]; then
  echo "      ! MEMORY.md 已存在，跳过（保留现有记忆）"
else
  cp "$REPO_ROOT/templates/MEMORY.md" "$TARGET/MEMORY.md"
  echo "      ✓ MEMORY.md"
fi

# AGENTS.md — 如已存在则追加而非覆盖
if [ -f "$TARGET/AGENTS.md" ]; then
  echo "      ! AGENTS.md 已存在，将 cclaw 内容追加到末尾..."
  echo "" >> "$TARGET/AGENTS.md"
  echo "---" >> "$TARGET/AGENTS.md"
  echo "# cclaw 增强协议（自动追加，来源：Wanglaisi/cclaw v1.0.0）" >> "$TARGET/AGENTS.md"
  echo "" >> "$TARGET/AGENTS.md"
  cat "$REPO_ROOT/templates/AGENTS.md" >> "$TARGET/AGENTS.md"
  echo "      ✓ AGENTS.md（追加模式）"
else
  cp "$REPO_ROOT/templates/AGENTS.md" "$TARGET/AGENTS.md"
  echo "      ✓ AGENTS.md"
fi

# 创建首个 transcript 文件
echo "[4/5] 初始化 transcripts..."
TODAY=$(date +%Y-%m-%d)
TRANSCRIPT_FILE="$TARGET/transcripts/$TODAY.md"
if [ ! -f "$TRANSCRIPT_FILE" ]; then
  cat > "$TRANSCRIPT_FILE" << EOF
# Transcript: $TODAY
# 由 cclaw init.sh 自动创建

## 初始化记录

- 时间：$(date '+%Y-%m-%d %H:%M:%S')
- 来源：Wanglaisi/cclaw v1.0.0
- 状态：初始化完成，等待首次会话
EOF
  echo "      ✓ transcripts/$TODAY.md"
else
  echo "      ! transcripts/$TODAY.md 已存在，跳过"
fi

# 完成
echo "[5/5] 验证安装..."
ERRORS=0
for f in "MEMORY.md" "AGENTS.md" "skills/dream/SKILL.md" "transcripts/$TODAY.md"; do
  if [ -f "$TARGET/$f" ]; then
    echo "      ✓ $f"
  else
    echo "      ✗ $f 缺失"
    ERRORS=$((ERRORS + 1))
  fi
done

echo "---"
if [ $ERRORS -eq 0 ]; then
  echo "初始化完成。目标目录：$TARGET"
  echo "下一步：将 AGENTS.md 内容确认无误后，在 OpenClaw 中加载项目。"
else
  echo "初始化完成，但有 $ERRORS 个文件缺失，请检查上方输出。"
fi
