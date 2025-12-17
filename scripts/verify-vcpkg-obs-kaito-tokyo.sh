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

echo "📥 Fetching attestation bundle..."
rm -f ./*.jsonl
curl -fsSL "https://readwrite.vcpkg-obs.kaito.tokyo/sigstore/curl" | curl -s -Z -K -
cat *.jsonl > bundle.jsonl

echo "📂 Loading subjects..."
subjects=()
if [ -s "bundle.jsonl" ]; then
    while IFS= read -r line; do
      subjects+=("$line")
    done < <(jq -r '.dsseEnvelope.payload | @base64d | fromjson | .subject[].name' "bundle.jsonl")
fi
echo "✅ Loaded ${#subjects[@]} subjects."

# Function to check if ABI hash exists in the subject list
has_subject() {
  local target="$1"
  for s in "${subjects[@]}"; do
    [[ "$s" == "$target" ]] && return 0
  done
  return 1
}

echo "🔍 Analyzing status files..."
mkdir -p downloads

total_packages_found=0
skipped_count=0

for status_file in "${STATUS_FILES[@]}"; do
  echo "   Processing: $status_file"

  # Parse status file
  # Added debug logic to output raw ABI for inspection
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

    total_packages_found=$((total_packages_found + 1))

    if has_subject "$abi"; then
      # echo "   [MATCH] $pkg ($abi)"
      url="${OBS_BASE_URL}/${pkg}/${ver}/${abi}"
      printf 'url = "%s"\n' "$url"
      printf 'output = "downloads/%s"\n' "$abi"
    else
      # デバッグ用: なぜスキップされたか表示
      echo "   [SKIP]  $pkg"
      echo "           Local ABI:  $abi"
      echo "           (Not found in signed subjects list)"
      skipped_count=$((skipped_count + 1))
    fi
  done
done > curl_config.txt

echo "📊 Analysis Result: Found $total_packages_found packages in status file."
echo "                    Skipped $skipped_count packages (ABI mismatch)."

echo "⬇️  Downloading artifacts..."
if [ -s curl_config.txt ]; then
    curl -f -s -Z -K curl_config.txt
else
    echo "⚠️  No artifacts to download."
fi

echo "🔐 Verifying attestations..."
verified_count=0
failed_count=0

if [ -d "downloads" ]; then
    shopt -s nullglob
    for artifact in downloads/*; do
        filename=$(basename "$artifact")

        if gh attestation verify "$artifact" --repo "$REPO" --bundle "bundle.jsonl" >/dev/null 2>&1; then
            echo "✅ Verified: $filename"
            verified_count=$((verified_count + 1))
        else
            echo "❌ FAILED: $filename"
            failed_count=$((failed_count + 1))
        fi
    done
    shopt -u nullglob
fi

popd > /dev/null

echo "----------------------------------------"
echo "🎉 Result: Success: $verified_count, Failed: $failed_count"
echo "📝 Debug files are preserved in: ./$WORK_DIR"

if [[ $failed_count -gt 0 ]]; then
    exit 1
fi
