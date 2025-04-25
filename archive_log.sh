#!/bin/bash

# Exit immediately if a command exits with a non-zero value status
set -e

# Treat unset variable as an error when substituting
set -u

# show the exit status of the rightmost command in the pipeline that exited with a mom-zero status, if none then successfully exit with a zero value 
set -o pipefail

# -- Configuration ---

DEFAULT_LOG_FILENAME="archive_run.log" # set the name for this script's action record file
EMAIL_RECIPIENT="your_email@example.com" # <--- SET YOUR EMAIL ADDRESS HERE
EMAIL_SUBJECT="Log Archive Script Report $(date +'%Y-%m:%d %H:%M:%S')"


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
	echo "Error: Can not create destination directory '${TEMP_DEST_DIR}', please check the permission and available disk spacei..."
	echo
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

if [ -n "$EMAIL_RECIPIENT" ]; then
    log_message "Attempting to email log file to ${EMAIL_RECIPIENT}" "${SCRIPT_LOG_FILE}"
    # Create a temporary file ONLY if we are actually going to send mail
    MAIL_ERROR_TMP_FILE=$(mktemp)
    # Attempt to send mail and redirect stderr
    mail -s "${EMAIL_SUBJECT}" "${EMAIL_RECIPIENT}" < "${SCRIPT_LOG_FILE}" 2> "${MAIL_ERROR_TMP_FILE}"
    mail_exit_status=$? 

    # Check the status AND log the result right here
    if [ $mail_exit_status -ne 0 ]; then
        # Failure - read the actual error message from the temp file
        mail_error_message=$(cat "$MAIL_ERROR_TMP_FILE")
        # Include the specific error in the log
        log_message "Warning: Failed to send email to ${EMAIL_RECIPIENT} (Exit Status: $mail_exit_status). Mail Error: ${mail_error_message}" "${SCRIPT_LOG_FILE}"
    else
        # Success
        log_message "Successfully sent email to ${EMAIL_RECIPIENT}." "${SCRIPT_LOG_FILE}"
    fi

    # Clean up the temporary file used for this attempt
    rm -f "$MAIL_ERROR_TMP_FILE"

else
    # Log that email was skipped because no recipient was provided
    log_message "Skipping email notification: EMAIL_RECIPIENT variable is not set." "${SCRIPT_LOG_FILE}"
fi
