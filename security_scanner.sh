#!/bin/bash

#####################################################
# Lab 10: File Permission Security Scanner
# Description: Find files with insecure permissions
#####################################################

# Configuration
TEST_DIR="./test_files"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#####################################################
# Setup Function (FULLY PROVIDED - DO NOT MODIFY)
#####################################################

setup_test_environment() {
    echo "Setting up test environment..."

    # Remove old test directory if exists
    rm -rf "$TEST_DIR"

    # Create directory structure
    mkdir -p "$TEST_DIR"/{web,config,scripts,data,uploads}

    # Create web files with permission issues
    touch "$TEST_DIR/web/index.html"
    chmod 777 "$TEST_DIR/web/index.html"  # INSECURE: world-writable AND executable

    touch "$TEST_DIR/web/style.css"
    chmod 755 "$TEST_DIR/web/style.css"   # INSECURE: shouldn't be executable

    touch "$TEST_DIR/web/script.js"
    chmod 644 "$TEST_DIR/web/script.js"   # SECURE

    # Create config files with permission issues
    touch "$TEST_DIR/config/database.conf"
    chmod 666 "$TEST_DIR/config/database.conf"  # INSECURE: world-writable

    touch "$TEST_DIR/config/api_keys.conf"
    chmod 644 "$TEST_DIR/config/api_keys.conf"  # SECURE

    touch "$TEST_DIR/config/settings.conf"
    chmod 755 "$TEST_DIR/config/settings.conf"  # INSECURE: executable config

    # Create scripts (these SHOULD be executable)
    echo "#!/bin/bash" > "$TEST_DIR/scripts/deploy.sh"
    chmod 755 "$TEST_DIR/scripts/deploy.sh"  # SECURE: scripts should be executable

    echo "#!/bin/bash" > "$TEST_DIR/scripts/backup.sh"
    chmod 777 "$TEST_DIR/scripts/backup.sh"  # INSECURE: world-writable

    # Create data files
    touch "$TEST_DIR/data/users.txt"
    chmod 666 "$TEST_DIR/data/users.txt"  # INSECURE: world-writable

    touch "$TEST_DIR/data/logs.txt"
    chmod 640 "$TEST_DIR/data/logs.txt"  # SECURE

    # Create insecure directory
    chmod 777 "$TEST_DIR/uploads"  # INSECURE: world-writable directory

    echo "Test files created in: $TEST_DIR"
    echo ""
}

#####################################################
# TODO SECTIONS - IMPLEMENT THESE
#####################################################

find_world_writable() {
    echo "--- World-Writable Files & Directories ---"

    local count=0

    # TODO 1: Find all world-writable files and directories
    #
    # Instructions:
    # 1. Use 'find' to search $TEST_DIR for items with world-write permission
    #    Hint: find "$TEST_DIR" -perm -002
    #
    # 2. For each item found, you need to:
    #    a. Determine if it's a file or directory using: [ -f "$item" ]
    #    b. Get permissions using: stat -c "%a" "$item"
    #    c. Print formatted output (see example below)
    #    d. Increment the count variable
    #
    # 3. Use a while loop with process substitution to process results:
    #    while IFS= read -r item; do
    #        # your code here
    #    done < <(find ...)
    #
    #    NOTE: Use "< <(find ...)" NOT "find ... |" to avoid subshell issues!
    #
    # Output format examples:
    #   [FILE] /path/to/file.txt (666)
    #   [DIR]  /path/to/directory (777)
    #
    # Example implementation structure:
    # while IFS= read -r item; do
    #     perms=$(stat -c "%a" "$item")
    #
    #     if [ -f "$item" ]; then
    #         echo -e "${RED}[FILE]${NC} $item ($perms)"
    #     elif [ -d "$item" ]; then
    #         echo -e "${RED}[DIR] ${NC} $item ($perms)"
    #     fi
    #
    #     ((count++))
    # done < <(find "$TEST_DIR" -perm -002)

    while IFS= read -r item; do
        perms=$(stat -c "%a" "$item")

        if [ -f "$item" ]; then
            echo -e "${RED}[FILE]${NC} $item ($perms)"
        elif [ -d "$item" ]; then
            echo -e "${RED}[DIR] ${NC} $item ($perms)"
        fi

        ((count++))
    done < <(find "$TEST_DIR" -perm -002)

    echo ""
    echo "Found $count world-writable items"
    echo ""
    return $count
}

find_executable_non_scripts() {
    echo "--- Executable Non-Script Files ---"

    local count=0

    # TODO 2: Find files that shouldn't be executable
    #
    # Instructions:
    # 1. Use 'find' to locate .html, .css, .txt, and .conf files that are executable
    #    Hint: find "$TEST_DIR" -type f \( -name "*.html" -o -name "*.css" -o -name "*.txt" -o -name "*.conf" \) -perm /111
    #
    #    Explanation:
    #    -type f              = files only
    #    \( ... \)            = group conditions
    #    -name "*.html"       = HTML files
    #    -o                   = OR operator
    #    -perm /111           = any execute bit set
    #
    # 2. For each file found:
    #    a. Get permissions using: stat -c "%a" "$file"
    #    b. Print formatted output: [EXEC] /path/to/file (permissions)
    #    c. Increment count
    #
    # 3. Use process substitution (NOT pipe) to preserve count:
    #    while IFS= read -r file; do
    #        # your code
    #    done < <(find ...)
    #
    # Example implementation structure:
    # while IFS= read -r file; do
    #     perms=$(stat -c "%a" "$file")
    #     echo -e "${YELLOW}[EXEC]${NC} $file ($perms)"
    #     ((count++))
    # done < <(find "$TEST_DIR" -type f \( -name "*.html" -o -name "*.css" -o -name "*.txt" -o -name "*.conf" \) -perm /111)

    while IFS= read -r file; do
        perms=$(stat -c "%a" "$file")
        echo -e "${YELLOW}[EXEC]${NC} $file ($perms)"
        ((count++))
    done < <(find "$TEST_DIR" -type f \( -name "*.html" -o -name "*.css" -o -name "*.txt" -o -name "*.conf" \) -perm /111)

    echo ""
    echo "Found $count files that shouldn't be executable"
    echo ""
    return $count
}

#####################################################
# Main Execution (FULLY PROVIDED - DO NOT MODIFY)
#####################################################

main() {
    echo "========================================"
    echo "File Permission Security Scanner"
    echo "========================================"

    # Setup test environment
    setup_test_environment

    echo "========================================"
    echo "Scanning for INSECURE Files/Directories"
    echo "========================================"
    echo ""

    # Run scans
    find_world_writable
    world_writable_count=$?

    find_executable_non_scripts
    executable_count=$?

    # Calculate total issues
    total_issues=$((world_writable_count + executable_count))

    # Display summary
    echo "========================================"
    echo "Security Scan Complete"
    echo "========================================"
    echo "Summary:"
    echo "- World-writable items found: $world_writable_count"
    echo "- Improperly executable files found: $executable_count"
    echo "- Total security issues: $total_issues"
    echo ""

    if [ $total_issues -gt 0 ]; then
        echo -e "${RED}⚠️  SECURITY ALERT: $total_issues permission vulnerabilities detected!${NC}"
        echo "These files need immediate attention."
    else
        echo -e "${GREEN}✓ No security issues found. All permissions are secure.${NC}"
    fi

    echo "========================================"
}

# Run the script
main