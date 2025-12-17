#!/bin/bash
set -euo pipefail

ID="vcpkg-obs-kaito-tokyo"
REPO="kaito-tokyo/vcpkg-obs-kaito-tokyo"

if [[ $# -lt 1 ]]; then
  echo "No status files provided. Usage: $0 <status_file1> [<status_file2> ...]" >&2
  exit 1
fi

if [[ ! -d "$VCPKG_ROOT" ]]; then
  echo "Error: Vcpkg root does not exist: $VCPKG_ROOT" >&2
  exit 1
fi
echo "📂 Using cache dir: $VCPKG_ROOT"

extract_packages() {
  tr -d '\r' < "$1" | awk -v RS="" -F"\n" '{
    pkg=""; ver=""; arch=""; abi=""
    for(i=1; i<=NF; i++) {
      if ($i ~ /^Package: /) pkg = substr($i, 10)
      if ($i ~ /^Version: /) ver = substr($i, 10)
      if ($i ~ /^Architecture: /) arch = substr($i, 15)
      if ($i ~ /^Abi: /) abi = substr($i, 6)
    }
    if (pkg && arch && abi) print pkg, ver, arch, abi
  }'
}

generate_curl_script_to_download() {
  while read -r pkg ver arch abi; do
    url="https://vcpkg-obs.kaito.tokyo/${pkg}/${ver}/${abi}"
    printf 'url = "%s"\n' "$url"
    printf 'output = /dev/null\n'
    printf 'write-out = "%%{http_code} %%{url_effective}\\n"\n'
  done | curl -s -I -Z -K - | awk '
  {
    code = $1
    url = $2

    if (code == "200") {
      print "url = \"" url "\""
    } else if (code == "404") {
      print "⚠️  Warning: Package not found at " url > "/dev/stderr"
    } else {
      print "❌ Error: Unexpected status " code " for " url > "/dev/stderr"
      exit 1
    }
  }'
}

download_binary_artifacts() {
  while read -r pkg ver arch abi; do
    url="https://vcpkg-obs.kaito.tokyo/${pkg}/${ver}/${abi}"
    printf 'url = "%s"\n' "$url"
    printf 'output = "%s"\n' "$abi"
  done | curl -fsSL -Z -K -
}

mkdir -p "sigstore-$ID"
cd "sigstore-$ID"
rm -f ./*.jsonl
curl -fsSL "https://readwrite.vcpkg-obs.kaito.tokyo/sigstore/curl" | curl -Z -K -

cat *.jsonl > bundle.jsonl

echo "Loading subjects..."
subjects=()
while IFS= read -r line; do
  subjects+=("$line")
done < <(jq -r '.dsseEnvelope.payload | @base64d | fromjson | .subject[].name' "bundle.jsonl")

echo "Loaded ${#subjects[@]} subjects from attestation bundle."

for status_file in "$@"; do
  extract_packages "../$status_file" | generate_curl_script_to_download | curl -Z -O -K -
  rm -rf downloads
  pushd downloads
  for subject in *; do
    gh attestation verify "$subject" --repo "$REPO" --bundle "../bundle.jsonl"
  done
  popd
done

echo "🎉 All verifications completed."
