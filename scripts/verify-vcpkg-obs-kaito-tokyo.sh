#!/bin/bash
set -euo pipefail

# Configuration
ID="vcpkg-obs-kaito-tokyo"
REPO="kaito-tokyo/vcpkg-obs-kaito-tokyo"
OBS_BASE_URL="https://vcpkg-obs.kaito.tokyo"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <status_file1> [<status_file2> ...]" >&2
  exit 1
fi

# Convert status file paths to absolute paths
STATUS_FILES=()
for f in "$@"; do
  if [[ -f "$f" ]]; then
    if command -v realpath >/dev/null 2>&1; then
      STATUS_FILES+=("$(realpath "$f")")
    else
      STATUS_FILES+=("$(cd "$(dirname "$f")" && pwd)/$(basename "$f")")
    fi
  else
    echo "Error: Status file not found: $f" >&2
    exit 1
  fi
done

# Create workspace
WORK_DIR="sigstore-$ID"
mkdir -p "$WORK_DIR"
pushd "$WORK_DIR" > /dev/null

echo "📥 Fetching attestation bundle..." >&2
rm -f ./*.jsonl
curl -fsSL "https://readwrite.vcpkg-obs.kaito.tokyo/sigstore/curl" | curl -s -Z -K -
cat *.jsonl > bundle.jsonl

echo "📂 Loading subjects..." >&2
subjects=()
if [ -s "bundle.jsonl" ]; then
  while IFS= read -r line; do
    subjects+=("$line")
  done < <(jq -r '.dsseEnvelope.payload | @base64d | fromjson | .subject[].name' "bundle.jsonl")
fi
echo "✅ Loaded ${#subjects[@]} subjects." >&2

has_subject() {
  local target="$1"
  for s in "${subjects[@]}"; do
    [[ "$s" == "$target" ]] && return 0
  done
  return 1
}

echo "🔍 Analyzing status files..." >&2
mkdir -p downloads

total_packages_found=0
skipped_count=0

# --- 修正箇所: ここから ---
# ループ全体の標準出力(stdout)は curl_config.txt に書き込まれます。
# したがって、ログメッセージは必ず >&2 (stderr) に逃がす必要があります。

for status_file in "${STATUS_FILES[@]}"; do
  echo "   Processing: $status_file" >&2

  tr -d '\r' < "$status_file" | awk -v RS="" -F"\n" '{
    pkg=""; ver=""; abi=""
    for(i=1; i<=NF; i++) {
      if ($i ~ /^Package:/) { split($i, a, ":"); pkg = a[2]; gsub(/^[ \t]+|[ \t]+$/, "", pkg); }
      if ($i ~ /^Version:/) { split($i, a, ":"); ver = a[2]; gsub(/^[ \t]+|[ \t]+$/, "", ver); }
      if ($i ~ /^Abi:/)     { split($i, a, ":"); abi = a[2]; gsub(/^[ \t]+|[ \t]+$/, "", abi); }
    }
    if (pkg != "" && ver != "" && abi != "") {
      print pkg, ver, abi
    }
  }' | while read -r pkg ver abi; do

    # set -e 対策のため算術式展開を変更
    total_packages_found=$((total_packages_found + 1))

    if has_subject "$abi"; then
      # 【重要】ここだけが標準出力(stdout)に出る = ファイルに書き込まれる
      url="${OBS_BASE_URL}/${pkg}/${ver}/${abi}"
      printf 'url = "%s"\n' "$url"
      printf 'output = "downloads/%s"\n' "$abi"
    else
      # ログなので標準エラー出力(stderr)へ
      echo "   [SKIP]  $pkg ($abi)" >&2
      skipped_count=$((skipped_count + 1))
    fi
  done
done > curl_config.txt

# --- 修正箇所: ここまで ---

echo "📊 Analysis Result: Found $total_packages_found packages in status file." >&2
echo "                    Skipped $skipped_count packages (ABI mismatch)." >&2

echo "⬇️  Downloading artifacts..." >&2
if [ -s curl_config.txt ]; then
  # curlの設定ファイルが正しく作られているかデバッグしたい場合は以下のコメントを解除
  # head -n 5 curl_config.txt >&2

  curl -f -s -Z -K curl_config.txt
else
  echo "⚠️  No artifacts to download." >&2
fi

echo "🔐 Verifying attestations..." >&2
verified_count=0
failed_count=0

if [ -d "downloads" ]; then
  shopt -s nullglob
  for artifact in downloads/*; do
    filename=$(basename "$artifact")

    if gh attestation verify "$artifact" --repo "$REPO" --bundle "bundle.jsonl" >/dev/null 2>&1; then
      echo "✅ Verified: $filename" >&2
      verified_count=$((verified_count + 1))
    else
      echo "❌ FAILED: $filename" >&2
      failed_count=$((failed_count + 1))
    fi
  done
  shopt -u nullglob
fi

popd > /dev/null

echo "----------------------------------------" >&2
echo "🎉 Result: Success: $verified_count, Failed: $failed_count" >&2
echo "📝 Debug files are preserved in: ./$WORK_DIR" >&2

if [[ $failed_count -gt 0 ]]; then
  exit 1
fi
