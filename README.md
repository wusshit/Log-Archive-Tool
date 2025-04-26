# Log Archive Tool

A Bash script to automate log file compression into timestamped `.tar.gz` archives, featuring error handling, detailed action logging, optional synchronized external email notifications of run status, and authored companion scripts for scheduling guidance.

## Overview

This script archives the contents of a specified source directory into a timestamped `.tar.gz` file within a destination directory. It meticulously logs its actions to a file (`archive_run.log` by default) within the destination and can optionally email this log upon completion for remote monitoring.

## Features

*   **Compression:** Creates standard `.tar.gz` archives.
*   **Timestamping:** Archives are named `SourceBaseName_archive_YYYY-MM-DD_HH-MM-SS.tar.gz` for easy identification.
*   **Robust Paths:** Uses `realpath` for consistent absolute path handling.
*   **Detailed Logging:** Records actions (start, paths, attempts, success/failure) with timestamps to both a log file and standard output.
*   **Comprehensive Error Handling:** Includes checks for arguments, path validity, permissions, empty source directories, and command failures (`set -e -u -o pipefail`).
*   **Email Notifications:** Optionally sends the execution log via email if a recipient address is configured in the script. Captures and includes email sending errors in the main log.
*   **Scheduling Support:** Includes helper scripts providing examples for automation via `cron`, `anacron`, and `systemd` timers.

## Prerequisites

*   **Bash:** The script interpreter.
*   **GNU Coreutils:** `tar`, `gzip` (via `tar -z`), `date`, `mkdir`, `realpath`, `tee`, `ls`, `basename`. (Standard on most Linux/macOS).
*   **(Optional) Email:** A configured Mail Transfer Agent (MTA) like `postfix` installed and correctly set up to send external email **if using the email notification feature**.
*   **(Optional) Scheduling:** `cron`, `anacron`, or `systemd` available **if automating the script**.

## Setup

1.  **Clone or Download:**
    ```bash
    git clone https://github.com/wusshit/Log-Archive-Tool.git
    cd Log-Archive-Tool
    ```
    Or download the script files directly.

2.  **Make Scripts Executable:**
    ```bash
    # Check actual filename if different
    chmod +x archive_log.sh
    chmod +x setup_crontab.sh
    chmod +x setup_anacron.sh 
    chmod +x systemd_timer.sh 
    ```
3.  **(If using email) Configure `EMAIL_RECIPIENT`:** Edit the `archive_log.sh` script and set the `EMAIL_RECIPIENT` variable to your desired address.
4.  **(If using postfix as MTA) Configure `main.cf`:** Add/Modify relayhost, SASL, TLS and (Optional) Sender Rewriting

## Usage (Manual Execution)

Provide the source log directory and the destination archive directory as arguments. Use the full path to the script, especially if running non-interactively.

**Syntax:**

```bash
/full/path/to/archive_log.sh <source_log_directory> <destination_archive_directory>
