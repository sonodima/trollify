#!/bin/bash

# project: trollify - stop the crash, troll the app
# author: github.com/sonodima

if ! command -v ldid &>/dev/null; then
  echo "error: 'ldid' is not installed"
  echo "install it by running: brew install ldid"
  exit 1
fi

if ! command -v unar &>/dev/null; then
  echo "error: 'unar' is not installed"
  echo "install it by running: brew install unar"
  exit 1
fi

usage() {
  echo "usage: $0 <input_file> <output_file>"
  exit 1
}

if [ "$#" -ne 2 ]; then
  echo "error: invalid number of parameters"
  usage
fi

input_path="$1"
output_path="$2"

if [ ! -f "$input_path" ]; then
  echo "error: input file does not exist"
  exit 1
fi

extraction_dir=$(mktemp -d)

unar -o "$extraction_dir" "$input_path" >/dev/null
if [ "$?" -ne 0 ]; then
  echo "error: failed to extract the archive"
  rm -rf "$extraction_dir"
  exit 1
fi

app_bundle=$(find "$extraction_dir/Payload" -name "*.app" -maxdepth 1)
if [ -z "$app_bundle" ]; then
  echo "error: failed to find the application bundle"
  rm -rf "$extraction_dir"
  exit 1
fi

find "$app_bundle" -type f -exec sh -c 'file -b "$1" | grep -q "Mach-O"' sh {} \; -print0 | while IFS= read -r -d '' macho_file; do
  macho_file_name=$(basename "$macho_file")
  entitlements=$(mktemp -t "tl_entitlements")

  ldid -e "$macho_file" >"$entitlements"
  if [ "$?" -ne 0 ]; then
    echo "warning: failed to extract entitlements for '$macho_file_name'"
    rm -f "$entitlements"
    continue
  fi

  disallowed_entitlements=(
    "com.apple.private.cs.debugger"
    "dynamic-codesigning"
    "com.apple.private.skip-library-validation"
  )

  for entitlement in "${disallowed_entitlements[@]}"; do
    /usr/libexec/PlistBuddy -c "Delete :$entitlement" "$entitlements" >/dev/null 2>&1
    if [ "$?" -eq 0 ]; then
      echo "removed $entitlement from '$macho_file_name'"
    fi
  done

  ldid -S"$entitlements" "$macho_file"
  if [ "$?" -ne 0 ]; then
    echo "warning: failed to sign '$macho_file_name'"
  fi

  rm -f "$entitlements"
done

ditto -c -k --sequesterRsrc --keepParent "$extraction_dir/Payload" "$output_path"
if [ "$?" -ne 0 ]; then
  echo "error: failed to create the archive"
  rm -rf "$extraction_dir"
  exit 1
fi

rm -rf "$extraction_dir"
