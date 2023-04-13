#!/bin/bash

# https://unix.stackexchange.com/questions/702023/
readarray -d '' -t APP_FOLDERS < <(find . -mindepth 1 -maxdepth 1 -type d -not -name ".*" -print0 || true)

COPY_FILES=(".shellcheckrc" "Makefile" ".pre-commit-config.yaml")

for cf in "${COPY_FILES[@]}"; do
	for af in "${!APP_FOLDERS[@]}"; do
		echo "copying ""${cf}"" ""${af}""=> ${APP_FOLDERS[af]}";
		cp "${cf}" "${APP_FOLDERS[af]}";
	done
done
