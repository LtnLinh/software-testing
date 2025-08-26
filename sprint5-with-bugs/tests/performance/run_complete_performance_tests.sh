#!/bin/bash

# Complete Performance Tests Runner
# This script runs all performance tests for all features: login, register, and forgot password

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${BLUE}=== Complete Performance Tests Runner ===${NC}"
echo -e "${YELLOW}Timestamp: $TIMESTAMP${NC}"
echo -e "${YELLOW}Base Directory: $BASE_DIR${NC}"
echo ""

# Function to run feature tests
run_feature_tests() {
    local feature="$1"
    local script_name="$2"
    
    echo -e "${BLUE}=== Running $feature Performance Tests ===${NC}"
    echo ""
    
    if [ -f "$BASE_DIR/$script_name" ]; then
        chmod +x "$BASE_DIR/$script_name"
        "$BASE_DIR/$script_name"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ $feature tests completed successfully${NC}"
        else
            echo -e "${RED}✗ $feature tests failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}Error: Script not found: $script_name${NC}"
        return 1
    fi
    
    echo ""
}

# Function to generate master summary
generate_master_summary() {
    local summary_file="$1"
    
    echo -e "${BLUE}Generating master performance summary...${NC}"
    
    cat > "$summary_file" << EOF
# Complete Performance Tests Summary
Generated: $(date)
Timestamp: $TIMESTAMP

## Test Coverage Overview

### Login API Tests
- Load Test: 50 users, 10s ramp-up, 10 loops
- Stress Test: 500 users, 100s ramp-up, 5 loops  
- Spike Test: 50→600→50 users, 3 phases
- Endpoint: POST /users/login

### Register API Tests
- Load Test: 20 users, 10s ramp-up, 10 loops
- Stress Test: 100 users, 30s ramp-up, 5 loops
- Spike Test: 50→200→50 users, 3 phases
- Endpoint: POST /users/register

### Forgot Password API Tests
- Load Test: 20 users, 10s ramp-up, 10 loops
- Stress Test: 100 users, 30s ramp-up, 5 loops
- Spike Test: 50→200→50 users, 3 phases
- Endpoint: POST /users/forgot-password

## Expected KPIs (Local Environment)
- Load: p95 < 300ms; error rate < 1%; throughput stable
- Stress: p95 < 800ms; error rate < 5%; graceful degradation
- Spike: p95 and error rate may increase in Phase B but must recover in Phase C

## Test Results Location
- Results: $BASE_DIR/results/
- Reports: $BASE_DIR/reports/
- Individual summaries: $BASE_DIR/results/*_performance_summary_$TIMESTAMP.txt

## View All Reports
Open the HTML reports in your browser:
\`\`\`bash
open $BASE_DIR/reports/*/index.html
\`\`\`

## Individual Test Scripts
- Login: ./run_login_performance_tests.sh
- Register: ./run_register_performance_tests.sh
- Forgot Password: ./run_forgot_password_performance_tests.sh

EOF

    echo -e "${GREEN}✓ Master summary generated: $summary_file${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting Complete Performance Tests Suite...${NC}"
    echo ""
    
    # Check if JMeter is installed
    if ! command -v jmeter &> /dev/null; then
        echo -e "${RED}Error: JMeter is not installed or not in PATH${NC}"
        echo -e "${YELLOW}Please install JMeter: brew install jmeter${NC}"
        exit 1
    fi
    
    # Check if application is running
    echo -e "${BLUE}Checking if application is running on localhost:8091...${NC}"
    if ! curl -s http://localhost:8091/status > /dev/null; then
        echo -e "${YELLOW}Warning: Application may not be running on localhost:8091${NC}"
        echo -e "${YELLOW}Please ensure the application is started before running tests${NC}"
        echo ""
    else
        echo -e "${GREEN}✓ Application is running on localhost:8091${NC}"
        echo ""
    fi
    
    # Run Login Tests
    run_feature_tests "Login" "run_login_performance_tests.sh"
    
    # Run Register Tests
    run_feature_tests "Register" "run_register_performance_tests.sh"
    
    # Run Forgot Password Tests
    run_feature_tests "Forgot Password" "run_forgot_password_performance_tests.sh"
    
    # Generate master summary
    generate_master_summary "$BASE_DIR/results/complete_performance_summary_$TIMESTAMP.txt"
    
    echo -e "${GREEN}=== All Performance Tests Completed Successfully ===${NC}"
    echo -e "${YELLOW}Results Directory: $BASE_DIR/results${NC}"
    echo -e "${YELLOW}Reports Directory: $BASE_DIR/reports${NC}"
    echo -e "${YELLOW}Master Summary: $BASE_DIR/results/complete_performance_summary_$TIMESTAMP.txt${NC}"
    echo ""
    echo -e "${BLUE}To view all reports, run:${NC}"
    echo -e "${YELLOW}open $BASE_DIR/reports/*/index.html${NC}"
    echo ""
    echo -e "${BLUE}To view individual summaries:${NC}"
    echo -e "${YELLOW}cat $BASE_DIR/results/*_performance_summary_$TIMESTAMP.txt${NC}"
}

# Run main function
main "$@"
