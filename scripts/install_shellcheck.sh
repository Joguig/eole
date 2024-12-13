#!/bin/bash 
set -e
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y git ghc cabal-install
cd || exit 1
git clone https://github.com/koalaman/shellcheck.git
cd shellcheck/
git checkout -b v0.7.1
cabal update
cabal install
"$HOME/.cabal/bin/shellcheck" -V