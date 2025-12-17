#!/bin/bash

set -euo pipefail

VCPKG_CACHE_DIR="$HOME/.cache/vcpkg/archives"
ID=vcpkg-obs-kaito-tokyo

mkdir -p "sigstore-$ID"
pushd "sigstore-$ID"
curl -fsSL "https://readwrite.vcpkg-obs.kaito.tokyo/sigstore/curl" | curl -Z -K -
popd
cat "sigstore-$ID"/*.jsonl > "sigstore-$ID.jsonl"

subjects=($(jq -r '.dsseEnvelope.payload | @base64d | fromjson | .subject[].name' "sigstore-$ID.jsonl"))

awk -v RS="" -F"\n" '{
  pkg=""; arch=""; abi=""
  for(i=1; i<=NF; i++) {
    if ($i ~ /^Package: /) pkg = substr($i, 10)
    if ($i ~ /^Architecture: /) arch = substr($i, 15)
    if ($i ~ /^Abi: /) abi = substr($i, 6)
  }
  if (pkg && arch && abi) print pkg, arch, abi
}' vcpkg_installed/arm64-osx-obs/vcpkg/status | while read -r pkg arch abi; do
  files=("$VCPKG_CACHE_DIR"/*/$abi.zip)

  if [[ ${#files[@]} -ne 1 ]] || [[ ! -f ${files[0]} ]] ; then
    echo "Error: Missing vcpkg cache file for package '$pkg' with ABI '$abi'" >&2
    exit 1
  fi

  if printf '%s\n' "${subjects[@]}" | grep -Fxq "$abi"; then
    gh attestation verify "${files[0]}" --repo kaito-tokyo/vcpkg-obs-kaito-tokyo --bundle "sigstore-$ID.jsonl"
  else
    echo "No matching subject found for package '$pkg' with ABI '$abi', skipping verification." >&2
  fi
done

awk -v RS="" -F"\n" '{
  pkg=""; arch=""; abi=""
  for(i=1; i<=NF; i++) {
    if ($i ~ /^Package: /) pkg = substr($i, 10)
    if ($i ~ /^Architecture: /) arch = substr($i, 15)
    if ($i ~ /^Abi: /) abi = substr($i, 6)
  }
  if (pkg && arch && abi) print pkg, arch, abi
}' vcpkg_installed/x64-osx-obs/vcpkg/status | while read -r pkg arch abi; do
  files=("$VCPKG_CACHE_DIR"/*/$abi.zip)

  if [[ ${#files[@]} -ne 1 ]] || [[ ! -f ${files[0]} ]] ; then
    echo "Error: Missing vcpkg cache file for package '$pkg' with ABI '$abi'" >&2
    exit 1
  fi

  if printf '%s\n' "${subjects[@]}" | grep -Fxq "$abi"; then
    gh attestation verify "${files[0]}" --repo kaito-tokyo/vcpkg-obs-kaito-tokyo --bundle "sigstore-$ID.jsonl"
  else
    echo "No matching subject found for package '$pkg' with ABI '$abi', skipping verification." >&2
  fi
done
