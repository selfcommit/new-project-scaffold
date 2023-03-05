#!/bin/bash

APP_FOLDERS=$(find . -mindepth 1 -maxdepth 1 -type d -not -name ".*")
COPY_FILES=(".shellcheckrc" "Makefile" ".pre-commit-config.yaml")

for cf in "${COPY_FILES[@]}"; do
	for af in "${APP_FOLDERS[@]}"; do
		cp "${cf}" "${af}"
	done
done
