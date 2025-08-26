#!/bin/bash

# Forgot Password Performance Tests Runner
# This script runs all forgot password performance tests: load, stress, and spike

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLANS_DIR="$BASE_DIR/plans"
RESULTS_DIR="$BASE_DIR/results"
REPORTS_DIR="$BASE_DIR/reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create directories if they don't exist
mkdir -p "$RESULTS_DIR"
mkdir -p "$REPORTS_DIR"

echo -e "${BLUE}=== Forgot Password Performance Tests Runner ===${NC}"
echo -e "${YELLOW}Timestamp: $TIMESTAMP${NC}"
echo -e "${YELLOW}Base Directory: $BASE_DIR${NC}"
echo ""

# Function to run a test
run_test() {
    local test_name="$1"
    local plan_file="$2"
    local result_file="$3"
    local report_dir="$4"
    
    echo -e "${BLUE}Running $test_name test...${NC}"
    echo -e "${YELLOW}Plan: $plan_file${NC}"
    echo -e "${YELLOW}Results: $result_file${NC}"
    echo -e "${YELLOW}Report: $report_dir${NC}"
    
    # Check if JMeter is installed
    if ! command -v jmeter &> /dev/null; then
        echo -e "${RED}Error: JMeter is not installed or not in PATH${NC}"
        echo -e "${YELLOW}Please install JMeter: brew install jmeter${NC}"
        exit 1
    fi
    
    # Check if plan file exists
    if [ ! -f "$plan_file" ]; then
        echo -e "${RED}Error: Test plan file not found: $plan_file${NC}"
        exit 1
    fi
    
    # Run JMeter test
    echo -e "${GREEN}Starting JMeter test...${NC}"
    jmeter -n -t "$plan_file" -l "$result_file" -e -o "$report_dir"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $test_name test completed successfully${NC}"
    else
        echo -e "${RED}✗ $test_name test failed${NC}"
        return 1
    fi
    
    echo ""
}

# Function to generate summary
generate_summary() {
    local summary_file="$1"
    
    echo -e "${BLUE}Generating performance summary...${NC}"
    
    cat > "$summary_file" << EOF
# Forgot Password Performance Tests Summary
Generated: $(date)
Timestamp: $TIMESTAMP

## Test Results Overview

### Load Test
- Plan: forgot_password_load_test.jmx
- Configuration: 20 users, 10s ramp-up, 10 loops
- Results: $RESULTS_DIR/forgot_password_load_results_$TIMESTAMP.jtl
- Report: $REPORTS_DIR/forgot_password_load_report_$TIMESTAMP/

### Stress Test  
- Plan: forgot_password_stress_test.jmx
- Configuration: 100 users, 30s ramp-up, 5 loops
- Results: $RESULTS_DIR/forgot_password_stress_results_$TIMESTAMP.jtl
- Report: $REPORTS_DIR/forgot_password_stress_report_$TIMESTAMP/

### Spike Test
- Plan: forgot_password_spike_test.jmx
- Configuration: 50→200→50 users, 3 phases
- Results: $RESULTS_DIR/forgot_password_spike_results_$TIMESTAMP.jtl
- Report: $REPORTS_DIR/forgot_password_spike_report_$TIMESTAMP/

## Expected KPIs (Local Environment)
- Load: p95 < 300ms; error rate < 1%; throughput stable
- Stress: p95 < 800ms; error rate < 5%; graceful degradation
- Spike: p95 and error rate may increase in Phase B but must recover in Phase C

## View Reports
Open the HTML reports in your browser:
- Load: file://$REPORTS_DIR/forgot_password_load_report_$TIMESTAMP/index.html
- Stress: file://$REPORTS_DIR/forgot_password_stress_report_$TIMESTAMP/index.html  
- Spike: file://$REPORTS_DIR/forgot_password_spike_report_$TIMESTAMP/index.html

EOF

    echo -e "${GREEN}✓ Summary generated: $summary_file${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting Forgot Password Performance Tests...${NC}"
    echo ""
    
    # Run Load Test
    run_test "Forgot Password Load" \
        "$PLANS_DIR/forgot_password_load_test.jmx" \
        "$RESULTS_DIR/forgot_password_load_results_$TIMESTAMP.jtl" \
        "$REPORTS_DIR/forgot_password_load_report_$TIMESTAMP"
    
    # Run Stress Test
    run_test "Forgot Password Stress" \
        "$PLANS_DIR/forgot_password_stress_test.jmx" \
        "$RESULTS_DIR/forgot_password_stress_results_$TIMESTAMP.jtl" \
        "$REPORTS_DIR/forgot_password_stress_report_$TIMESTAMP"
    
    # Run Spike Test
    run_test "Forgot Password Spike" \
        "$PLANS_DIR/forgot_password_spike_test.jmx" \
        "$RESULTS_DIR/forgot_password_spike_results_$TIMESTAMP.jtl" \
        "$REPORTS_DIR/forgot_password_spike_report_$TIMESTAMP"
    
    # Generate summary
    generate_summary "$RESULTS_DIR/forgot_password_performance_summary_$TIMESTAMP.txt"
    
    echo -e "${GREEN}=== All Forgot Password Performance Tests Completed ===${NC}"
    echo -e "${YELLOW}Results Directory: $RESULTS_DIR${NC}"
    echo -e "${YELLOW}Reports Directory: $REPORTS_DIR${NC}"
    echo -e "${YELLOW}Summary: $RESULTS_DIR/forgot_password_performance_summary_$TIMESTAMP.txt${NC}"
    echo ""
    echo -e "${BLUE}To view reports, open the HTML files in your browser:${NC}"
    echo -e "${YELLOW}open $REPORTS_DIR/*/index.html${NC}"
}

# Run main function
main "$@"
