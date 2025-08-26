#!/bin/bash

# Performance Testing Cleanup Script
# This script cleans up JMeter test results and temporary files

echo "🧹 Cleaning up performance testing artifacts..."

# Remove JTL result files from results directory
echo "📁 Removing JTL result files..."
rm -f results/*.jtl 2>/dev/null || true
rm -f *.jtl 2>/dev/null || true

# Remove HTML report directories
echo "📊 Removing HTML report directories..."
rm -rf reports/* 2>/dev/null || true
rm -rf *_report 2>/dev/null || true
rm -rf *_html_report 2>/dev/null || true

# Remove JMeter temporary files
echo "🗂️ Removing JMeter temporary files..."
rm -f jmeter.log
rm -f *.tmp
rm -f plans/*.tmp 2>/dev/null || true

# Remove any JMeter backup files
echo "💾 Removing JMeter backup files..."
rm -f *.bak
rm -f *.backup
rm -f plans/*.bak 2>/dev/null || true
rm -f plans/*.backup 2>/dev/null || true

# Clean up any empty directories
echo "📂 Cleaning up empty directories..."
find . -type d -empty -delete 2>/dev/null || true

echo "✅ Cleanup completed successfully!"
echo ""
echo "📋 Summary of cleaned files:"
echo "   - JTL result files (*.jtl)"
echo "   - HTML report directories (*_report, *_html_report)"
echo "   - JMeter log files (jmeter.log)"
echo "   - Temporary files (*.tmp, *.bak, *.backup)"
echo ""