#!/bin/bash

# Performance Tests Cleanup Script
# This script removes all test results, reports, and temporary files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$BASE_DIR/results"
REPORTS_DIR="$BASE_DIR/reports"

echo -e "${BLUE}=== Performance Tests Cleanup ===${NC}"
echo -e "${YELLOW}Base Directory: $BASE_DIR${NC}"
echo ""

# Function to confirm cleanup
confirm_cleanup() {
    echo -e "${YELLOW}This will remove all test results and reports.${NC}"
    echo -e "${YELLOW}The following directories will be cleaned:${NC}"
    echo -e "${YELLOW}  - $RESULTS_DIR${NC}"
    echo -e "${YELLOW}  - $REPORTS_DIR${NC}"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleanup cancelled.${NC}"
        exit 0
    fi
}

# Function to clean directory
clean_directory() {
    local dir="$1"
    local dir_name="$2"
    
    if [ -d "$dir" ]; then
        echo -e "${BLUE}Cleaning $dir_name directory...${NC}"
        rm -rf "$dir"/*
        echo -e "${GREEN}✓ $dir_name directory cleaned${NC}"
    else
        echo -e "${YELLOW}$dir_name directory does not exist, skipping${NC}"
    fi
}

# Function to clean JMeter temporary files
clean_jmeter_temp() {
    echo -e "${BLUE}Cleaning JMeter temporary files...${NC}"
    
    # Remove JMeter log files
    if [ -f "jmeter.log" ]; then
        rm -f jmeter.log
        echo -e "${GREEN}✓ Removed jmeter.log${NC}"
    fi
    
    # Remove temporary files
    if [ -f "*.tmp" ]; then
        rm -f *.tmp
        echo -e "${GREEN}✓ Removed temporary files${NC}"
    fi
    
    # Remove JTL files in current directory
    if ls *.jtl 1> /dev/null 2>&1; then
        rm -f *.jtl
        echo -e "${GREEN}✓ Removed JTL files from current directory${NC}"
    fi
    
    # Remove HTML report directories in current directory
    if ls *_report 1> /dev/null 2>&1; then
        rm -rf *_report
        echo -e "${GREEN}✓ Removed HTML report directories from current directory${NC}"
    fi
    
    if ls *_html_report 1> /dev/null 2>&1; then
        rm -rf *_html_report
        echo -e "${GREEN}✓ Removed alternative HTML report directories from current directory${NC}"
    fi
}

# Main execution
main() {
    # Confirm cleanup
    confirm_cleanup
    
    echo -e "${BLUE}Starting cleanup...${NC}"
    echo ""
    
    # Clean results directory
    clean_directory "$RESULTS_DIR" "Results"
    
    # Clean reports directory
    clean_directory "$REPORTS_DIR" "Reports"
    
    # Clean JMeter temporary files
    clean_jmeter_temp
    
    echo ""
    echo -e "${GREEN}=== Cleanup Completed Successfully ===${NC}"
    echo -e "${YELLOW}All test results and reports have been removed.${NC}"
    echo -e "${YELLOW}You can now run fresh performance tests.${NC}"
}

# Run main function
main "$@"
