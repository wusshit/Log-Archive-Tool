#!/bin/bash

# Exit immediately if a command exits with a non-zero value status
set -e

# Treat unset variable as an error when substituting
set -u

# show the exit status of the rightmost command in the pipeline that exited with a mom-zero status, if none then successfully exit with a zero value 
set -o pipefail

# -- Configuration ---

DEFAULT_LOG_FILENAME="archive_run.log" # set the name for this script's action record file

# --- functions for instructions and action log---
usage(){
	echo "Usage: $0 <source_log_directory> [destination_archive_directory]"
	echo "compresses logs from <souce_log_directory> into a timestamped .tar.gz file"
	echo "The archive is stored in [destination_archive_directory]"
	exit 1
}

log_message(){
	local message="$1"
	local log_file="$2"
	local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
	echo "[$timestamp] $message" | tee -a "$log_file"
}

# --- Argument Parsing ---

USER_SOURCE_DIR="${1:-}"
USER_DEST_DIR="${2:-}"

if [ -z "${USER_SOURCE_DIR}" ]; then
	echo "Error: Source log directory not specified."
	usage
fi

TEMP_SOURCE_DIR="${USER_SOURCE_DIR}"

if [ ! -d "${TEMP_SOURCE_DIR}" ]; then
	echo "Error: Source directory '${TEMP_SOURCE_DIR}' does not exist or is not a directory."
	exit 1
fi

SOURCE_DIR=$(realpath "${TEMP_SOURCE_DIR}")

if [ $? -ne 0 ] || [ -z ${SOURCE_DIR} ]; then
	echo "Error: cannot resolve to absolute path for souce directory '${USER_SOURCE_DIR}'"
	exit 1
fi

if [ -z "${USER_DEST_DIR}" ]; then
	echo "Error: Destination archive directory not specified"
	usage
fi

TEMP_DEST_DIR="${USER_DEST_DIR}"

# ---Main Logic ----

mkdir -p "${TEMP_DEST_DIR}" # allow existing and new directory to be destination but not existing file

if [ $? -ne 0 ]; then
	echo "Error: Can not create destination directory '${TEMP_DEST_DIR}', please check the permission and available disk space"
	exit 1
fi

DEST_DIR=$(realpath "${TEMP_DEST_DIR}")

SCRIPT_LOG_FILE="${DEST_DIR}/${DEFAULT_LOG_FILENAME}"

if [ -z "$(ls -A "${SOURCE_DIR}")" ]; then
	log_message "Source directory '${SOURCE_DIR}' is empty, nothing to archive" "${SCRIPT_LOG_FILE}"
	log_message "--- Log Archiving Finished (No Action) ---" "${SCRIPT_LOG_FILE}"
	exit 0
fi

TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')
SOURCE_BASENAME=$(basename "${SOURCE_DIR}")
ARCHIVE_FILENAME="${SOURCE_BASENAME}_archive_${TIMESTAMP}.tar.gz"
ARCHIVE_FULL_PATH="${DEST_DIR}/${ARCHIVE_FILENAME}"

log_message "Source directory: ${SOURCE_DIR}" "${SCRIPT_LOG_FILE}"
log_message "Destination directory: ${DEST_DIR}" "${SCRIPT_LOG_FILE}"
log_message "Attempting to create archive: ${ARCHIVE_FULL_PATH}" "${SCRIPT_LOG_FILE}"

if tar -czvf "${ARCHIVE_FULL_PATH}" -C "${SOURCE_DIR}" . ; then
	log_message "Successfully created a compressed archive: ${ARCHIVE_FULL_PATH}" "${SCRIPT_LOG_FILE}"
else
	log_message "Error: Failed to create a compressed archive '${ARCHIVE_FULL_PATH}', check the permission or available disk space" "${SCRIPT_LOG_FILE}"
	exit 1
fi
