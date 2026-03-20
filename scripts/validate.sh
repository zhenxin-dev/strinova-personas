#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

check_file_exists() {
  local rel="$1"
  [[ -f "$repo_root/$rel" ]] || fail "缺少文件 $rel"
}

check_heading() {
  local file="$1"
  local heading="$2"
  rg -qxF -- "$heading" "$file" >/dev/null || fail "$(basename "$file") 缺少标题：$heading"
}

printf '检查基础文件...\n'
check_file_exists "README.md"
check_file_exists "AGENTS.md"
check_file_exists "CLAUDE.md"
check_file_exists "SOURCES.md"
check_file_exists "personas/TEMPLATE.md"
check_file_exists "examples/组合示例.md"
check_file_exists "world/人物关系索引.md"

grep -qx '@AGENTS.md' "$repo_root/CLAUDE.md" || fail "CLAUDE.md 必须只包含 @AGENTS.md"

printf '检查角色文件结构...\n'
while IFS= read -r file; do
  base="$(basename "$file")"
  [[ "$base" == "TEMPLATE.md" ]] && continue

  check_heading "$file" "## 任务"
  check_heading "$file" "## 设定基准"
  check_heading "$file" "## 角色档案"
  check_heading "$file" "## 角色核心"
  check_heading "$file" "## 与用户的默认关系"
  check_heading "$file" "## 语言风格"
  check_heading "$file" "## 角色口吻要点"
  check_heading "$file" "## 战斗与游戏设定"
  check_heading "$file" "## 示例对话风格"
  check_heading "$file" "## 时装参考"
  check_heading "$file" "## 禁止事项"
  check_heading "$file" "## 最终执行准则"

  rg -n '^(## 官方口吻参考|## 语感参考)$' "$file" >/dev/null || fail "$base 缺少口吻参考标题"
  rg -n '^## 适合.+提及的细节$' "$file" >/dev/null || fail "$base 缺少“适合角色提及的细节”标题"
done < <(find "$repo_root/personas" -maxdepth 1 -type f -name '*.md' | sort)

printf '检查 README 索引...\n'
while IFS= read -r file; do
  base="$(basename "$file")"
  [[ "$base" == "TEMPLATE.md" ]] && continue
  grep -Fq "(personas/$base)" "$repo_root/README.md" || fail "README.md 未收录 personas/$base"
  grep -Fq "personas/$base" "$repo_root/SOURCES.md" || fail "SOURCES.md 未登记 personas/$base"
done < <(find "$repo_root/personas" -maxdepth 1 -type f -name '*.md' | sort)

while IFS= read -r file; do
  base="$(basename "$file")"
  [[ "$base" == "README.md" ]] && continue
  grep -Fq "(world/$base)" "$repo_root/README.md" || fail "README.md 未收录 world/$base"
  grep -Fq "($base)" "$repo_root/world/README.md" || fail "world/README.md 未收录 $base"
  grep -Fq "world/$base" "$repo_root/SOURCES.md" || fail "SOURCES.md 未登记 world/$base"
done < <(find "$repo_root/world" -maxdepth 1 -type f -name '*.md' | sort)

grep -Fq "(personas/TEMPLATE.md)" "$repo_root/README.md" || fail "README.md 未收录 personas/TEMPLATE.md"
grep -Fq "(examples/组合示例.md)" "$repo_root/README.md" || fail "README.md 未收录 examples/组合示例.md"
grep -Fq "(SOURCES.md)" "$repo_root/README.md" || fail "README.md 未收录 SOURCES.md"

printf '全部检查通过。\n'
