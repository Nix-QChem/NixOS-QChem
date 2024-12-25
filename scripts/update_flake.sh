#!/usr/bin/env nix-shell
#!nix-shell -i bash -p

nix --experimental-features 'nix-command flakes' flake update
git commit -m "update flake.lock" flake.lock
