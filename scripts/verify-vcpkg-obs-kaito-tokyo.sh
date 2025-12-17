#!/bin/bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "No status files provided. Usage: $0 <status_file1> [<status_file2> ...]" >&2
  exit 1
fi

if [[ ! -d "$VCPKG_ROOT" ]]; then
  echo "Error: Vcpkg root does not exist: $VCPKG_ROOT" >&2
  exit 1
fi
echo "📂 Using cache dir: $VCPKG_ROOT"

ID="vcpkg-obs-kaito-tokyo"
SIGSTORE_FILE="sigstore-${ID}.jsonl"
REPO="kaito-tokyo/vcpkg-obs-kaito-tokyo"

mkdir -p "sigstore-$ID"
cd "sigstore-$ID"
rm -f ./*.jsonl
curl -fsSL "https://readwrite.vcpkg-obs.kaito.tokyo/sigstore/curl" | curl -Z -K -

cat "sigstore-$ID"/*.jsonl > "$SIGSTORE_FILE"

echo "Loading subjects..."
subjects=()
while IFS= read -r line; do
  subjects+=("$line")
done < <(jq -r '.dsseEnvelope.payload | @base64d | fromjson | .subject[].name' "$SIGSTORE_FILE")

echo "Loaded ${#subjects[@]} subjects from attestation bundle."

verify_packages() {
  local status_file="$1"

  if [[ ! -f "$status_file" ]]; then
    echo "⚠️  Status file not found: $status_file"
    return
  fi

  echo "Processing status file: $status_file"

  tr -d '\r' < "$status_file" | awk -v RS="" -F"\n" '{
    pkg=""; ver=""; arch=""; abi=""
    for(i=1; i<=NF; i++) {
      if ($i ~ /^Package: /) pkg = substr($i, 10)
      if ($i ~ /^Version: /) version = substr($i, 10)
      if ($i ~ /^Architecture: /) arch = substr($i, 15)
      if ($i ~ /^Abi: /) abi = substr($i, 6)
    }
    if (pkg && arch && abi) print pkg, ver, arch, abi
  }' | while read -r pkg ver arch abi; do
    if !curl -fsSLO "https:://vcpkg-obs.kaito.tokyo/$pkg/$ver/$abi"; then
      echo "⚠️  Package file not found for: $pkg (ABI: $abi)"
    fi

    if gh attestation verify "$abi" --repo "$REPO" --bundle "$SIGSTORE_FILE"; then
      echo "✅ Verified: $pkg"
    else
      echo "❌ Verification FAILED: $pkg" >&2
      exit 1
    fi
  done
}

for status_file in "$@"; do
  verify_packages $status_file
done

echo "🎉 All verifications completed."
