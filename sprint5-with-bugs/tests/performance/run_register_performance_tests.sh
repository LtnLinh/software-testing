#!/bin/bash

# Register Performance Testing Script
# This script runs comprehensive performance tests for the register API endpoint

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
JMX_DIR="plans"
RESULTS_DIR="results"
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create directories if they don't exist
mkdir -p "$RESULTS_DIR"
mkdir -p "$REPORTS_DIR"

print_status "Starting Register Performance Testing Suite"
print_status "Timestamp: $TIMESTAMP"
echo ""

# Check if JMeter is installed
if ! command -v jmeter &> /dev/null; then
    print_error "JMeter is not installed. Please install JMeter first."
    exit 1
fi

print_success "JMeter found: $(jmeter --version | head -1)"
echo ""

# Check if API is running
print_status "Checking if API is accessible..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8091/users/register | grep -q "404\|405"; then
    print_success "API endpoint is accessible"
else
    print_warning "API might not be running. Tests may fail."
fi
echo ""

# Function to run JMeter test
run_jmeter_test() {
    local test_name=$1
    local jmx_file=$2
    local result_file="$RESULTS_DIR/${test_name}_${TIMESTAMP}.jtl"
    local report_dir="$REPORTS_DIR/${test_name}_${TIMESTAMP}"
    
    print_status "Running $test_name test..."
    print_status "JMX File: $jmx_file"
    print_status "Results: $result_file"
    print_status "Report: $report_dir"
    
    if jmeter -n -t "$jmx_file" -l "$result_file" -e -o "$report_dir" 2>/dev/null; then
        print_success "$test_name test completed successfully"
        
        # Extract key metrics
        local avg_time=$(grep "summary =" "$result_file" | tail -1 | awk '{print $7}' | sed 's/,//')
        local error_rate=$(grep "summary =" "$result_file" | tail -1 | awk '{print $10}' | sed 's/(//' | sed 's/%)//')
        local throughput=$(grep "summary =" "$result_file" | tail -1 | awk '{print $5}' | sed 's/,//')
        
        echo "  Average Response Time: ${avg_time}ms"
        echo "  Error Rate: ${error_rate}%"
        echo "  Throughput: ${throughput} req/s"
        echo ""
        
        return 0
    else
        print_error "$test_name test failed"
        return 1
    fi
}

# Function to run Apache Bench test
run_ab_test() {
    local test_name=$1
    local concurrency=$2
    local requests=$3
    local result_file="$RESULTS_DIR/${test_name}_ab_${TIMESTAMP}.txt"
    
    print_status "Running $test_name Apache Bench test..."
    print_status "Concurrency: $concurrency, Requests: $requests"
    
    # Create request body file with unique email
    local timestamp=$(date +%s)
    cat > register_request.txt << EOF
{"first_name":"Test","last_name":"User","email":"testuser${timestamp}@example.com","password":"Password123!","password_confirmation":"Password123!"}
EOF
    
    if ab -n "$requests" -c "$concurrency" -p register_request.txt -T "application/json" \
        -H "Accept: application/json" \
        http://localhost:8091/users/register > "$result_file" 2>&1; then
        
        print_success "$test_name Apache Bench test completed"
        
        # Extract key metrics
        local avg_time=$(grep "Time per request" "$result_file" | head -1 | awk '{print $4}')
        local requests_per_sec=$(grep "Requests per second" "$result_file" | awk '{print $4}')
        local failed_requests=$(grep "Failed requests" "$result_file" | awk '{print $3}')
        
        echo "  Average Response Time: ${avg_time}ms"
        echo "  Requests per second: ${requests_per_sec}"
        echo "  Failed requests: ${failed_requests}"
        echo ""
        
        rm -f register_request.txt
        return 0
    else
        print_error "$test_name Apache Bench test failed"
        rm -f register_request.txt
        return 1
    fi
}

# Test 1: Load Test
print_status "=== TEST 1: LOAD TEST ==="
print_status "Configuration: 20 users, 10 loops, 10 second ramp-up"
echo ""

# JMeter Register Load Test
if run_jmeter_test "register_load" "$JMX_DIR/register_load_test.jmx"; then
    print_success "Load test completed"
else
    print_warning "Load test failed - trying Apache Bench alternative"
    run_ab_test "register_load" 20 200
fi

echo ""

# Test 2: Stress Test
print_status "=== TEST 2: STRESS TEST ==="
print_status "Configuration: 100 users, 5 loops, 30 second ramp-up"
echo ""

# JMeter Register Stress Test
if run_jmeter_test "register_stress" "$JMX_DIR/register_stress_test.jmx"; then
    print_success "Stress test completed"
else
    print_warning "Stress test failed - trying Apache Bench alternative"
    run_ab_test "register_stress" 100 500
fi

echo ""

# Test 3: Spike Test
print_status "=== TEST 3: SPIKE TEST ==="
print_status "Configuration: 50→200→50 users across 3 phases"
echo ""

# JMeter Register Spike Test
if run_jmeter_test "register_spike" "$JMX_DIR/register_spike_test.jmx"; then
    print_success "Spike test completed"
else
    print_warning "Spike test failed - trying Apache Bench alternative"
    run_ab_test "register_spike" 50 300
fi

echo ""

# Generate summary report
print_status "=== GENERATING SUMMARY REPORT ==="
SUMMARY_FILE="$RESULTS_DIR/register_performance_summary_${TIMESTAMP}.txt"

cat > "$SUMMARY_FILE" << EOF
REGISTER PERFORMANCE TESTING SUMMARY
===================================
Timestamp: $TIMESTAMP
Test Environment: localhost:8091

TEST RESULTS:
EOF

# Add JMeter results to summary
for result_file in "$RESULTS_DIR"/register_*_"$TIMESTAMP".jtl; do
    if [ -f "$result_file" ]; then
        test_name=$(basename "$result_file" .jtl | sed 's/_'$TIMESTAMP'//')
        echo "" >> "$SUMMARY_FILE"
        echo "=== $test_name ===" >> "$SUMMARY_FILE"
        grep "summary =" "$result_file" | tail -1 >> "$SUMMARY_FILE"
    fi
done

# Add Apache Bench results to summary
for result_file in "$RESULTS_DIR"/register_*_ab_"$TIMESTAMP".txt; do
    if [ -f "$result_file" ]; then
        test_name=$(basename "$result_file" .txt | sed 's/_ab_'$TIMESTAMP'//')
        echo "" >> "$SUMMARY_FILE"
        echo "=== $test_name (Apache Bench) ===" >> "$SUMMARY_FILE"
        grep -E "(Requests per second|Time per request|Failed requests)" "$result_file" >> "$SUMMARY_FILE"
    fi
done

print_success "Summary report generated: $SUMMARY_FILE"

echo ""
print_status "=== CLEANUP ==="
print_status "Removing temporary files..."

# Clean up temporary files
rm -f register_request.txt 2>/dev/null || true

print_status "Register Performance Testing completed!"
print_status "Results directory: $RESULTS_DIR"
print_status "Reports directory: $REPORTS_DIR"
print_status "Summary file: $SUMMARY_FILE"

echo ""
print_success "All register performance tests completed successfully!"
