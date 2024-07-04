#!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#gnugrep --command bash

# diffs each derivation

set -x
set -v
set -e

if [ "$#" -ne 2 ]; then
    echo "$0 (pre|post)"
fi

script_path=$(dirname "$(readlink -f $0)")
parent_path=$(dirname "$script_path")
out_path="$parent_path/$1-drv"


drv=$(nix flake check --verbose 2> >(grep -P -o "derivation evaluated to (/nix/store/.*\.drv)" | grep -P -o "/nix/store/.*\.drv"))

echo "$drv" > "$out_path"
