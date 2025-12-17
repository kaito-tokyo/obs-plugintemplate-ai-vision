#!/bin/bash
set -euo pipefail

# Configuration
ID="vcpkg-obs-kaito-tokyo"
REPO="kaito-tokyo/vcpkg-obs-kaito-tokyo"
OBS_BASE_URL="https://vcpkg-obs.kaito.tokyo"

# Argument check
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <status_file1> [<status_file2> ...]" >&2
  exit 1
fi

# Convert status file paths to absolute paths to handle 'cd' command later
STATUS_FILES=()
for f in "$@"; do
  if [[ -f "$f" ]]; then
    # Use realpath or fallback to python/pwd logic if realpath is missing on old macOS
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

# Create and move to workspace directory
rm -rf "sigstore-$ID"
mkdir -p "sigstore-$ID"
pushd "sigstore-$ID" > /dev/null

# 1. Fetch attestation bundle
echo "📥 Fetching attestation bundle..."
rm -f ./*.jsonl
# Download in parallel using curl config format piped from the URL
curl -fsSL "https://readwrite.vcpkg-obs.kaito.tokyo/sigstore/curl" | curl -s -Z -K -
cat *.jsonl > bundle.jsonl

# 2. Load subject list from the bundle
echo "📂 Loading subjects..."
subjects=()
# Load subjects as ABI hashes (without extensions)
if [ -s "bundle.jsonl" ]; then
  while IFS= read -r line; do
    subjects+=("$line")
  done < <(jq -r '.dsseEnvelope.payload | @base64d | fromjson | .subject[].name' "bundle.jsonl")
fi
echo "✅ Loaded ${#subjects[@]} subjects."

# Helper function to check if a subject exists in the array
has_subject() {
  local target="$1"
  for s in "${subjects[@]}"; do
    if [[ "$s" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

# 3. Extract package info and generate download list
echo "🔍 Analyzing status files..."
mkdir -p downloads

# Process all provided status files
for status_file in "${STATUS_FILES[@]}"; do
  echo "   Processing: $status_file" >&2

  # Parse status file to extract Package, Version, and ABI
  tr -d '\r' < "$status_file" | awk -v RS="" -F"\n" '{
    pkg=""; ver=""; abi=""
    for(i=1; i<=NF; i++) {
      if ($i ~ /^Package: /) pkg = substr($i, 10)
      if ($i ~ /^Version: /) ver = substr($i, 10)
      if ($i ~ /^Abi: /) abi = substr($i, 6)
    }
    if (pkg && ver && abi) print pkg, ver, abi
  }' | while read -r pkg ver abi; do

    # [Optimization] Check if the ABI exists in the Subject list first
    # If not in the subject list, verification will fail anyway, so skip downloading.
    if has_subject "$abi"; then
      url="${OBS_BASE_URL}/${pkg}/${ver}/${abi}"

      # Output in curl config file format
      # Specify output to 'downloads' directory explicitly
      printf 'url = "%s"\n' "$url"
      printf 'output = "downloads/%s"\n' "$abi"
    else
      # Optional: Log skipped packages
      # echo "⏭️  Skipping $pkg: No attestation found." >&2
      true
    fi
  done
done > curl_config.txt

# 4. Batch parallel download
echo "⬇️  Downloading artifacts..."
if [ -s curl_config.txt ]; then
  # -f: Fail silently on HTTP errors (e.g., 404)
  # -Z: Parallel download
  curl -f -s -Z -K curl_config.txt
else
  echo "⚠️  No artifacts to download (or all were filtered out)."
fi

# 5. Verify attestations
echo "🔐 Verifying attestations..."
verified_count=0
failed_count=0

# Process files in the downloads directory
if [ -d "downloads" ]; then
  for artifact in downloads/*; do
    # Handle case where glob matches nothing
    [ -e "$artifact" ] || continue

    filename=$(basename "$artifact")

    # Verify using gh attestation
    # Note: Subject Name is expected to match the Filename (ABI Hash)
    if gh attestation verify "$artifact" --repo "$REPO" --bundle "bundle.jsonl" >/dev/null 2>&1; then
      echo "✅ Verified: $filename"
      ((verified_count++))
    else
      echo "❌ FAILED: $filename"
      ((failed_count++))
    fi
  done
fi

# Exit the workspace directory
popd > /dev/null

echo "----------------------------------------"
echo "🎉 Result: Success: $verified_count, Failed: $failed_count"

# Exit with error if any verification failed
if [[ $failed_count -gt 0 ]]; then
  exit 1
fi
