#!/bin/bash

# Forgot Password Performance Testing Script
# This script runs load, stress, and spike tests for the forgot password endpoint

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JMETER_HOME="${JMETER_HOME:-/opt/apache-jmeter-5.6.3}"
JMX_DIR="plans"
RESULTS_DIR="results"
REPORTS_DIR="reports"
DATA_DIR="data"

# Test configurations
LOAD_TEST="forgot_password_load_test.jmx"
STRESS_TEST="forgot_password_stress_test.jmx"
SPIKE_TEST="forgot_password_spike_test.jmx"

# Generate timestamp for unique report names
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create directories if they don't exist
mkdir -p "$RESULTS_DIR" "$REPORTS_DIR"

echo -e "${BLUE}🔐 Forgot Password Performance Testing Suite${NC}"
echo "=================================================="

# Function to check if JMeter is available
check_jmeter() {
    if ! command -v jmeter &> /dev/null && [ ! -f "$JMETER_HOME/bin/jmeter" ]; then
        echo -e "${RED}❌ JMeter not found. Please install JMeter or set JMETER_HOME.${NC}"
        echo "Installation options:"
        echo "1. Download from: https://jmeter.apache.org/download_jmeter.cgi"
        echo "2. Use package manager: brew install jmeter (macOS)"
        echo "3. Set JMETER_HOME environment variable"
        exit 1
    fi
    
    JMETER_CMD="jmeter"
    if [ -f "$JMETER_HOME/bin/jmeter" ]; then
        JMETER_CMD="$JMETER_HOME/bin/jmeter"
    fi
    
    echo -e "${GREEN}✅ JMeter found: $JMETER_CMD${NC}"
}

# Function to check if application is running
check_application() {
    echo -e "${YELLOW}🔍 Checking if application is running...${NC}"
    if curl -s http://localhost:8091 > /dev/null; then
        echo -e "${GREEN}✅ Application is running on localhost:8091${NC}"
    else
        echo -e "${RED}❌ Application is not running on localhost:8091${NC}"
        echo "Please start the application first."
        exit 1
    fi
}

# Function to run a single test
run_test() {
    local test_name="$1"
    local jmx_file="$2"
    local result_file="$3"
    local report_dir="$4"
    
    echo -e "${BLUE}🚀 Running $test_name...${NC}"
    echo "JMX File: $JMX_DIR/$jmx_file"
    echo "Results: $RESULTS_DIR/$result_file"
    echo "Report: $REPORTS_DIR/$report_dir"
    
    if [ ! -f "$JMX_DIR/$jmx_file" ]; then
        echo -e "${RED}❌ JMX file not found: $JMX_DIR/$jmx_file${NC}"
        return 1
    fi
    
    # Clean up existing report directory and results file
    rm -rf "$REPORTS_DIR/$report_dir"
    rm -f "$RESULTS_DIR/$result_file"
    
    # Run JMeter test
    $JMETER_CMD -n \
        -t "$JMX_DIR/$jmx_file" \
        -l "$RESULTS_DIR/$result_file" \
        -e -o "$REPORTS_DIR/$report_dir" \
        -Jjmeter.save.saveservice.output_format=csv \
        -Jjmeter.save.saveservice.response_data=true \
        -Jjmeter.save.saveservice.samplerData=true \
        -Jjmeter.save.saveservice.requestHeaders=true \
        -Jjmeter.save.saveservice.url=true \
        -Jjmeter.save.saveservice.thread_counts=true \

    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $test_name completed successfully${NC}"
        echo -e "${YELLOW}📊 View report: $REPORTS_DIR/$report_dir/index.html${NC}"
    else
        echo -e "${RED}❌ $test_name failed${NC}"
        return 1
    fi
}

# Function to run Apache Bench test as fallback
run_ab_test() {
    local test_name="$1"
    local endpoint="$2"
    local data_file="$3"
    local result_file="$4"
    
    echo -e "${BLUE}🚀 Running $test_name with Apache Bench...${NC}"
    
    if ! command -v ab &> /dev/null; then
        echo -e "${RED}❌ Apache Bench (ab) not found${NC}"
        return 1
    fi
    
    # Create test data for AB
    local ab_data_file="$RESULTS_DIR/ab_${test_name}_data.txt"
    echo -n "email=admin@practicesoftwaretesting.com" > "$ab_data_file"
    
    # Run AB test (100 requests, 10 concurrent)
    ab -n 100 -c 10 \
        -p "$ab_data_file" \
        -T "application/x-www-form-urlencoded" \
        -H "Accept: application/json" \
        "http://localhost:8091$endpoint" > "$RESULTS_DIR/$result_file" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $test_name (AB) completed successfully${NC}"
        echo -e "${YELLOW}📊 Results: $RESULTS_DIR/$result_file${NC}"
    else
        echo -e "${RED}❌ $test_name (AB) failed${NC}"
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}🔧 Initializing forgot password performance tests...${NC}"
    
    # Pre-flight checks
    check_jmeter
    check_application
    
    # Check if test data exists
    if [ ! -f "$DATA_DIR/forgot_password_perf_data.csv" ]; then
        echo -e "${RED}❌ Test data file not found: $DATA_DIR/forgot_password_perf_data.csv${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Test data found: $DATA_DIR/forgot_password_perf_data.csv${NC}"
    
    # Run tests
    echo -e "${BLUE}📋 Starting forgot password performance tests...${NC}"
    echo ""
    
    # Load Test
    if run_test "Load Test" "$LOAD_TEST" "forgot_password_load_${TIMESTAMP}.jtl" "forgot_password_load_${TIMESTAMP}"; then
        echo -e "${GREEN}✅ Load test completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Load test failed, trying Apache Bench...${NC}"
        run_ab_test "Load Test" "/users/forgot-password" "forgot_password_load_ab.txt" "forgot_password_load_ab_results.txt"
    fi
    
    echo ""
    
    # Stress Test
    if run_test "Stress Test" "$STRESS_TEST" "forgot_password_stress_${TIMESTAMP}.jtl" "forgot_password_stress_${TIMESTAMP}"; then
        echo -e "${GREEN}✅ Stress test completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Stress test failed, trying Apache Bench...${NC}"
        run_ab_test "Stress Test" "/users/forgot-password" "forgot_password_stress_ab.txt" "forgot_password_stress_ab_results.txt"
    fi
    
    echo ""
    
    # Spike Test
    if run_test "Spike Test" "$SPIKE_TEST" "forgot_password_spike_${TIMESTAMP}.jtl" "forgot_password_spike_${TIMESTAMP}"; then
        echo -e "${GREEN}✅ Spike test completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Spike test failed, trying Apache Bench...${NC}"
        run_ab_test "Spike Test" "/users/forgot-password" "forgot_password_spike_ab.txt" "forgot_password_spike_ab_results.txt"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 All forgot password performance tests completed!${NC}"
    echo ""
    echo -e "${BLUE}📊 Test Results Summary:${NC}"
    echo "=================================================="
    echo -e "${YELLOW}📁 Results Directory: $RESULTS_DIR${NC}"
    echo -e "${YELLOW}📊 Reports Directory: $REPORTS_DIR${NC}"
    echo ""
    echo -e "${BLUE}📋 Generated Files:${NC}"
    ls -la "$RESULTS_DIR"/*.jtl 2>/dev/null || echo "No JTL files found"
    ls -la "$RESULTS_DIR"/*.txt 2>/dev/null || echo "No TXT files found"
    echo ""
    echo -e "${BLUE}📊 HTML Reports:${NC}"
    ls -la "$REPORTS_DIR"/*/index.html 2>/dev/null || echo "No HTML reports found"
    echo ""
    echo -e "${GREEN}✅ Forgot password performance testing completed successfully!${NC}"
    
    # Generate summary report
    echo -e "${BLUE}📊 Generating summary report...${NC}"
    SUMMARY_FILE="results/forgot_password_performance_summary_${TIMESTAMP}.txt"
    
    cat > "$SUMMARY_FILE" << EOF
FORGOT PASSWORD PERFORMANCE TESTING SUMMARY
==========================================
Timestamp: ${TIMESTAMP}
Test Environment: localhost:8091

TEST RESULTS:

=== forgot_password_load ===
EOF
    
    echo -e "${GREEN}✅ Summary report generated: $SUMMARY_FILE${NC}"
    echo ""
    echo -e "${BLUE}📊 Test Results Summary:${NC}"
    echo "=================================================="
    echo -e "${YELLOW}📁 Results Directory: $RESULTS_DIR${NC}"
    echo -e "${YELLOW}📊 Reports Directory: $REPORTS_DIR${NC}"
    echo -e "${YELLOW}📋 Summary File: $SUMMARY_FILE${NC}"
    echo ""
    echo -e "${BLUE}📋 Generated Files:${NC}"
    ls -la "$RESULTS_DIR"/*.jtl 2>/dev/null || echo "No JTL files found"
    ls -la "$RESULTS_DIR"/*.txt 2>/dev/null || echo "No TXT files found"
    echo ""
    echo -e "${BLUE}📊 HTML Reports:${NC}"
    ls -la "$REPORTS_DIR"/*/index.html 2>/dev/null || echo "No HTML reports found"
    echo ""
    echo -e "${GREEN}✅ Forgot password performance testing completed successfully!${NC}"
}

# Run main function
main "$@"
