#!/bin/bash

set -euo pipefail

detect_cache_dir() {
    if [[ -n "${VCPKG_DEFAULT_BINARY_CACHE:-}" ]]; then
        echo "$VCPKG_DEFAULT_BINARY_CACHE"
        return
    fi

    case "$OSTYPE" in
        msys*|cygwin*)
            echo "$(cygpath -u "$LOCALAPPDATA")/vcpkg/archives"
            ;;
        darwin*)
            echo "$HOME/.cache/vcpkg/archives"
            ;;
        *)
            echo "$HOME/.cache/vcpkg/archives"
            ;;
    esac
}

if [[ $# -lt 1 ]]; then
  echo "No status files provided. Usage: $0 <status_file1> [<status_file2> ...]" >&2
  exit 1
fi

VCPKG_CACHE_DIR=$(detect_cache_dir)
echo "📂 Using cache dir: $VCPKG_CACHE_DIR"

ID="vcpkg-obs-kaito-tokyo"
SIGSTORE_FILE="sigstore-${ID}.jsonl"
REPO="kaito-tokyo/vcpkg-obs-kaito-tokyo"

mkdir -p "sigstore-$ID"
pushd "sigstore-$ID" > /dev/null
rm -f ./*.jsonl
curl -fsSL "https://readwrite.vcpkg-obs.kaito.tokyo/sigstore/curl" | curl -Z -K -
popd > /dev/null

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
      pkg=""; arch=""; abi=""
      for(i=1; i<=NF; i++) {
        if ($i ~ /^Package: /) pkg = substr($i, 10)
        if ($i ~ /^Architecture: /) arch = substr($i, 15)
        if ($i ~ /^Abi: /) abi = substr($i, 6)
      }
      if (pkg && arch && abi) print pkg, arch, abi
    }' | while read -r pkg arch abi; do
      target_files=("$VCPKG_CACHE_DIR"/*/"$abi.zip")

      if [[ ${#target_files[@]} -ne 1 ]] || [[ ! -f ${target_files[0]} ]] ; then
        continue
      fi

      local zip_file="${target_files[0]}"

      local found=false
      for s in "${subjects[@]}"; do
        if [[ "$s" == "$abi" ]]; then
          found=true
          break
        fi
      done

      if "$found"; then
        if gh attestation verify "$zip_file" --repo "$REPO" --bundle "$SIGSTORE_FILE" >/dev/null 2>&1; then
          echo "✅ Verified: $pkg"
        else
          echo "❌ Verification FAILED: $pkg" >&2
          exit 1
        fi
      else
        echo "⚠️  No attestation found for: $pkg"
      fi
    done
}

for status_file in "$@"; do
  verify_packages $status_file
done

echo "🎉 All verifications completed."
