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

SOURCE_DIR="${1:-}"
DEST_DIR="${2:-}"

if [ -z "$SOURCE_DIR" ]; then
	echo "Error: Source log directory not specified."
	usage
fi

if [ ! -d "$SOURCE_DIR" ]; then
	echo "Error: Source directory '$SOURCE_DIR' does not exist or is not a directory."
	exit 1
fi

if [ -z "$DEST_DIR" ]; then
	echo "Error: Destination archive directory not specified"
	usage
fi

# ---Main Logic ----

mkdir -p "$DEST_DIR" # allow existing directory to be DEST_DIR but not existing file

if [ $? -ne 0 ]; then
	echo "Error: Can not create destination directory '$DEST_DIR', please check the permission and available disk space"
	exit 1
fi

SCRIPT_LOG_FILE="${DEST_DIR}/${DEFAULT_LOG_FILENAME}"

if [ -z "$(ls -A "${SOURCE_DIR}")" ]; then
	log_message "Source directory '${SOURCE_DIR}' is empty, nothing to archive" "$SCRIPT_LOG_FILE"
	log_message "--- Log Archiving Finished (No Action) ---" "$SCRIPT_LOG_FILE"
	exit 0
fi

TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%s')
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

fi
