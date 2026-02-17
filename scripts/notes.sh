#!/bin/sh
set -e

grep -v '^#' ./notes.packages | xargs sudo dnf install -y
