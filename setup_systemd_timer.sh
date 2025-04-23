#!/bin/bash

# Helper script to generate Systemd .service and .timer files for archive_logs.sh

echo "--- Systemd Timer Setup Helper for Log Archiver ---"
echo "This script helps create the .service and .timer files needed to schedule the log archiver using Systemd."
echo "This typically requires placing files in /etc/systemd/system/ and using sudo."
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

# --- Get Systemd Details ---
echo
DEFAULT_UNIT_NAME="log-archive"
read -p "Enter a base name for the systemd units [${DEFAULT_UNIT_NAME}]: " UNIT_NAME
UNIT_NAME="${UNIT_NAME:-$DEFAULT_UNIT_NAME}"
SERVICE_FILE="/etc/systemd/system/${UNIT_NAME}.service"
TIMER_FILE="/etc/systemd/system/${UNIT_NAME}.timer"

DEFAULT_USER="root" # Common for system-wide log management
read -p "Enter the User to run the script as [${DEFAULT_USER}]: " SERVICE_USER
SERVICE_USER="${SERVICE_USER:-$DEFAULT_USER}"

DEFAULT_GROUP="root"
read -p "Enter the Group to run the script as [${DEFAULT_GROUP}]: " SERVICE_GROUP
SERVICE_GROUP="${SERVICE_GROUP:-$DEFAULT_GROUP}"


echo
echo "Enter the timer schedule (OnCalendar format, e.g., 'daily', 'weekly', '*-*-* 03:00:00')."
echo "See 'man systemd.time' for syntax. 'daily' runs at 00:00:00."
DEFAULT_SCHEDULE="daily"
read -p "Systemd Timer Schedule [${DEFAULT_SCHEDULE}]: " TIMER_SCHEDULE
TIMER_SCHEDULE="${TIMER_SCHEDULE:-$DEFAULT_SCHEDULE}"

# --- Generate .service File Content ---
read -r -d '' SERVICE_CONTENT <<EOF
[Unit]
Description=Archive log files from ${SOURCE_DIR} using ${UNIT_NAME} service
Documentation=file://${ARCHIVE_SCRIPT_PATH}
# Add After=network.target if needed

[Service]
Type=oneshot
ExecStart=${ARCHIVE_SCRIPT_PATH} "${SOURCE_DIR}" "${DEST_DIR}"
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
# Optional: Set WorkingDirectory if the script relies on it, but absolute paths are better
# WorkingDirectory=/some/path
# Optional: Add environment variables if needed
# Environment="VAR=value"

[Install]
# Usually not needed for a service only triggered by a timer
# WantedBy=multi-user.target
EOF

# --- Generate .timer File Content ---
read -r -d '' TIMER_CONTENT <<EOF
[Unit]
Description=Run ${UNIT_NAME}.service ${TIMER_SCHEDULE}
Documentation=file://${ARCHIVE_SCRIPT_PATH}
# Optional: Add Requires=${UNIT_NAME}.service if timer should fail if service is masked
# Requires=${UNIT_NAME}.service

[Timer]
OnCalendar=${TIMER_SCHEDULE}
Persistent=true  # Run on boot if the last scheduled time was missed
Unit=${UNIT_NAME}.service # Specifies the service unit to activate

[Install]
WantedBy=timers.target
EOF


# --- Display Instructions ---
echo
echo "--- Configuration Complete ---"
echo
echo "To schedule the log archiving script using Systemd, follow these steps:"
echo
echo "1. Create the service file '${SERVICE_FILE}' using sudo:"
echo "   (Ensure the following block is pasted correctly, including EOF lines)"
echo "   sudo bash -c 'cat > ${SERVICE_FILE}' << EOF"
echo "${SERVICE_CONTENT}"
echo "EOF"
echo
echo "2. Create the timer file '${TIMER_FILE}' using sudo:"
echo "   (Ensure the following block is pasted correctly, including EOF lines)"
echo "   sudo bash -c 'cat > ${TIMER_FILE}' << EOF"
echo "${TIMER_CONTENT}"
echo "EOF"
echo
echo "3. Reload Systemd, then enable and start the timer:"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable --now ${UNIT_NAME}.timer"
echo
echo "4. Verify the timer is active and scheduled:"
echo "   systemctl list-timers --all | grep ${UNIT_NAME}"
echo
echo "5. Check the service status after it should have run:"
echo "   systemctl status ${UNIT_NAME}.service"
echo "   # View logs for the service (including script output):"
echo "   journalctl -u ${UNIT_NAME}.service"
echo
echo "Important Considerations:"
echo " - Ensure the specified User ('${SERVICE_USER}') and Group ('${SERVICE_GROUP}') have:"
echo "   - Read permissions for '${SOURCE_DIR}'."
echo "   - Write permissions for '${DEST_DIR}'."
echo "   - Execute permissions for '${ARCHIVE_SCRIPT_PATH}'."
echo " - Systemd provides robust logging via 'journalctl'."
echo
echo "*** To STOP and DISABLE this systemd job later ***" # Added Section
echo "Run the following commands:"
echo "   sudo systemctl stop ${UNIT_NAME}.timer"
echo "   sudo systemctl disable ${UNIT_NAME}.timer"
echo "   # The service (${UNIT_NAME}.service) will no longer be triggered by the timer."
echo "   # To completely remove the configuration files (optional):"
echo "   sudo systemctl stop ${UNIT_NAME}.service  # Stop if running independently"
echo "   sudo rm ${SERVICE_FILE}"
echo "   sudo rm ${TIMER_FILE}"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl reset-failed # Clean up potential failed state"


exit 0
