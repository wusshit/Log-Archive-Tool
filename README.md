# Simple Bash Log Archiver

A robust Bash script to compress log files from a specified directory into a timestamped `.tar.gz` archive and store it in a destination directory. Includes action logging and error handling.

## Overview

This script automates the process of archiving log files. It takes a source directory containing logs and a destination directory as input. It then creates a compressed archive (`.tar.gz`) of the source directory's contents within the destination directory. The archive filename includes a timestamp and the source directory's base name for easy identification. The script also logs its own actions to a file (`archive_run.log` by default) within the destination directory.

## Features

*   **Log Compression:** Uses `tar` and `gzip` to create compressed archives (`.tar.gz`).
*   **Timestamped Archives:** Generates archives with filenames like `SourceBaseName_archive_YYYY-MM-DD_HH:MM:EpochSeconds.tar.gz` for easy tracking. (Note: The timestamp format uses epoch seconds `%s` as per the script - you might prefer `%S` for standard seconds).
*   **Command-Line Arguments:** Requires source and destination directories, making it flexible.
*   **Robust Path Handling:** Uses `realpath` to resolve absolute paths, preventing issues with relative paths, especially when scheduled.
*   **Error Handling:**
    *   Uses `set -e`, `set -u`, `set -o pipefail` for script robustness.
    *   Checks for missing arguments.
    *   Validates if the source directory exists.
    *   Handles errors during destination directory creation (`mkdir -p`).
    *   Checks for permissions or disk space issues during archive creation.
    *   Exits gracefully with a message if the source directory is empty.
*   **Action Logging:** Logs key steps (start, source/destination, archive creation attempt, success/failure) with timestamps to a log file (`archive_run.log` by default) in the destination directory using the `log_message` function.
*   **Correct Archiving:** Uses `tar -C /path/to/source .` to archive only the contents of the source directory without including parent directory paths in the archive structure.
*   **Idempotent Destination Creation:** Safely creates the destination directory using `mkdir -p`, which doesn't error if the directory already exists.

## Prerequisites

*   **Bash:** The script interpreter.
*   **GNU Coreutils:** Standard utilities like `tar`, `gzip` (implicitly used by `tar -z`), `date`, `mkdir`, `realpath`, `tee`, `ls`, `basename`. These are typically available on most Linux distributions and macOS.

## Setup

1.  **Clone the repository (or download the script):**
    ```bash
    git clone <your_repo_url>
    cd <repository_directory>
    ```
    Or simply download the script file (e.g., `archive_logs.sh`).

2.  **Make the script executable:**
    ```bash
    chmod +x archive_logs.sh # Use your script's actual filename
    ```

## Usage (Manual Execution)

Run the script from your terminal, providing the source log directory and the destination archive directory as arguments.

**Syntax:**

```bash
/full/path/to/archive_logs.sh <source_log_directory> <destination_archive_directory>
