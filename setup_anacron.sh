#!/bin/bash

# Helper script to generate an Anacron wrapper script for archive_logs.sh

echo "--- Anacron Setup Helper for Log Archiver ---"
echo "This script helps create a wrapper to run the log archiver via Anacron (typically daily, weekly, or monthly)."
echo "This usually requires placing a script in /etc/cron.{daily|weekly|monthly}, which often needs root privileges."
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

# --- Get Anacron Details ---
echo
PS3="Select frequency (which directory to place the script in): "
options=("daily" "weekly" "monthly" "Quit")
select freq in "${options[@]}"; do
    case $freq in
        "daily"|"weekly"|"monthly")
            ANACRON_DIR="/etc/cron.${freq}"
            break
            ;;
        "Quit")
            echo "Setup aborted."
            exit 1
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

DEFAULT_WRAPPER_NAME="0anacron-log-archive" # Start with 0 to potentially run early
read -p "Enter a name for the wrapper script in ${ANACRON_DIR} [${DEFAULT_WRAPPER_NAME}]: " WRAPPER_NAME
WRAPPER_NAME="${WRAPPER_NAME:-$DEFAULT_WRAPPER_NAME}"
WRAPPER_PATH="${ANACRON_DIR}/${WRAPPER_NAME}"

DEFAULT_ANACRON_LOG="/var/log/anacron_log_archive.log"
read -p "Enter path for Anacron job's own output log [${DEFAULT_ANACRON_LOG}]: " ANACRON_LOG_PATH
ANACRON_LOG_PATH="${ANACRON_LOG_PATH:-$DEFAULT_ANACRON_LOG}"

# --- Generate Wrapper Script Content ---
read -r -d '' WRAPPER_CONTENT <<EOF
#!/bin/bash
# Wrapper script for Anacron to execute the log archiver.

LOG_ARCHIVER_SCRIPT="${ARCHIVE_SCRIPT_PATH}"
SOURCE_DIR="${SOURCE_DIR}"
DEST_DIR="${DEST_DIR}"
ANACRON_LOG="${ANACRON_LOG_PATH}"
TIMESTAMP=\$(date +'%Y-%m-%d %H:%M:%S')

echo "[\$TIMESTAMP] Anacron job '${WRAPPER_NAME}' starting." >> "\${ANACRON_LOG}"

# Execute the main script, redirecting its stdout/stderr to the Anacron log
"\${LOG_ARCHIVER_SCRIPT}" "\${SOURCE_DIR}" "\${DEST_DIR}" >> "\${ANACRON_LOG}" 2>&1
EXIT_CODE=\$?

TIMESTAMP=\$(date +'%Y-%m-%d %H:%M:%S')
if [ \$EXIT_CODE -eq 0 ]; then
  echo "[\$TIMESTAMP] Anacron job '${WRAPPER_NAME}' finished successfully." >> "\${ANACRON_LOG}"
else
  echo "[\$TIMESTAMP] Anacron job '${WRAPPER_NAME}' finished with error (Exit Code: \$EXIT_CODE)." >> "\${ANACRON_LOG}"
fi

exit 0 # Ensure this wrapper always exits 0 for anacron unless something critical failed here
EOF

# --- Display Instructions ---
echo
echo "--- Configuration Complete ---"
echo
echo "To schedule the log archiving script using Anacron (running as root by default), follow these steps:"
echo
echo "1. Create the wrapper script file '${WRAPPER_PATH}' using sudo:"
echo "   sudo nano ${WRAPPER_PATH}"
echo
echo "2. Paste the following content into the file:"
echo "--------------------------------------------------"
echo "${WRAPPER_CONTENT}"
echo "--------------------------------------------------"
echo
echo "3. Save the file and make it executable:"
echo "   sudo chmod +x ${WRAPPER_PATH}"
echo
echo "4. Ensure the Anacron log directory exists and is writable by root:"
echo "   sudo mkdir -p \"\$(dirname ${ANACRON_LOG_PATH})\""
echo "   sudo touch \"${ANACRON_LOG_PATH}\""
echo "   sudo chown root:root \"${ANACRON_LOG_PATH}\" # Or appropriate owner/group"
echo "   sudo chmod 644 \"${ANACRON_LOG_PATH}\"      # Or appropriate permissions"
echo
echo "Important Considerations:"
echo " - Scripts in ${ANACRON_DIR} typically run as root."
echo " - Root needs read access to '${SOURCE_DIR}' and write access to '${DEST_DIR}'."
echo " - If the archive or its contents need specific user ownership, the main script"
echo "   might need modification, or you might run the script via 'sudo -u <user> ...'"
echo "   within the wrapper script above (adjust permissions accordingly)."
echo " - Anacron runs jobs based on timestamps in /var/spool/anacron, not precise times."
# --- Display Instructions ---
echo
echo "--- Configuration Complete ---"
# ... (existing instructions) ...
echo
echo "*** To REMOVE this anacron job later ***"
echo "You will need to remove the wrapper script you created:"
echo "   sudo rm ${WRAPPER_PATH}"
echo "You may also remove the anacron log file '${ANACRON_LOG_PATH}'."


exit 0
