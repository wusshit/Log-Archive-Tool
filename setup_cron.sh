#!/bin/bash

# Helper script to generate a crontab entry for archive_logs.sh

echo "--- Cron Setup Helper for Log Archiver ---"
echo "This script will help you generate the crontab line to schedule log archiving."
echo "It requires the absolute paths to the script, source, and destination directories."
echo

# --- Get Required Paths ---
read -p "Enter the FULL absolute path to the archive_logs.sh script: " ARCHIVE_SCRIPT_PATH
if [[ ! -f "$ARCHIVE_SCRIPT_PATH" ]]; then
  echo "Error: Script file not found at '$ARCHIVE_SCRIPT_PATH'."
  exit 1
fi
if [[ "$ARCHIVE_SCRIPT_PATH" != /* ]]; then
    echo "Error: Script path must be absolute (start with '/')."
    exit 1
fi

read -p "Enter the FULL absolute path to the SOURCE log directory: " SOURCE_DIR
if [[ "$SOURCE_DIR" != /* ]]; then
    echo "Error: Source directory path must be absolute (start with '/')."
    exit 1
fi

read -p "Enter the FULL absolute path to the DESTINATION archive directory: " DEST_DIR
if [[ "$DEST_DIR" != /* ]]; then
    echo "Error: Destination directory path must be absolute (start with '/')."
    exit 1
fi

# --- Get Cron Schedule ---
echo
echo "Enter the cron schedule (e.g., '0 3 * * *' for 3:00 AM daily)."
echo "Format: MINUTE HOUR DAY_OF_MONTH MONTH DAY_OF_WEEK"
echo "Use '*' for any value. See 'man 5 crontab' for details."
read -p "Cron Schedule: " CRON_SCHEDULE

# --- Get Cron Log Path (Optional but recommended) ---
echo
DEFAULT_CRON_LOG="$HOME/log/archive_cron.log"
read -p "Enter path for cron job's own output log [${DEFAULT_CRON_LOG}]: " CRON_LOG_PATH
CRON_LOG_PATH="${CRON_LOG_PATH:-$DEFAULT_CRON_LOG}" # Use default if empty

CRON_LOG_DIR=$(dirname "$CRON_LOG_PATH")
echo "Info: Cron output will be redirected to '${CRON_LOG_PATH}'."
echo "Ensure the directory '${CRON_LOG_DIR}' exists and is writable by the user running cron."

# --- Generate Crontab Line ---
CRON_JOB_LINE="${CRON_SCHEDULE} ${ARCHIVE_SCRIPT_PATH} \"${SOURCE_DIR}\" \"${DEST_DIR}\" >> \"${CRON_LOG_PATH}\" 2>&1"

# --- Display Instructions ---
echo
echo "--- Configuration Complete ---"
echo
echo "To schedule the log archiving script using cron, follow these steps:"
echo
echo "1. Edit your user's crontab by running:"
echo "   crontab -e"
echo
echo "2. Add the following line to the end of the file:"
echo "   # Archive Logs Job (Added by setup_cron.sh)"
echo "   ${CRON_JOB_LINE}"
echo
echo "3. Save the file and exit the editor."
echo
echo "Important Considerations:"
echo " - Ensure the user whose crontab you edited has permissions to:"
echo "   - Read from '${SOURCE_DIR}' and its contents."
echo "   - Write to '${DEST_DIR}'."
echo "   - Write to the cron log file '${CRON_LOG_PATH}' (and its directory exists)."
echo "   - Execute the script '${ARCHIVE_SCRIPT_PATH}'."
echo " - Using absolute paths is crucial for cron jobs."
echo
echo "*** To REMOVE this cron job later ***" # Added Section
echo "Run 'crontab -e' again, find the line:"
echo "   ${CRON_JOB_LINE}"
echo "(Potentially preceded by '# Archive Logs Job...')."
echo "Delete that line (or comment it out with '#'). Then save and exit."
echo "You can also delete the log file: rm \"${CRON_LOG_PATH}\""

exit 0
