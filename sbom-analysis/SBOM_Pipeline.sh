#!/bin/bash
#
# Automated SBOM Analysis Pipeline
# Runs Syft, Grype, and Trivy on target directory
# Generates all output files for analysis and transfer
#

set -e

# Configuration
TARGET_DIR="${1:-.}"  # Use provided directory or current directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_PREFIX="sbom_analysis_${TIMESTAMP}"

echo "=== SBOM Analysis Pipeline ==="
echo "Target: $TARGET_DIR"
echo "Timestamp: $TIMESTAMP"
echo

# Create output directory for organized results
mkdir -p "${OUTPUT_PREFIX}_results"
cd "${OUTPUT_PREFIX}_results"

echo "Step 1: Syft - Software Inventory Generation"
echo "=============================================="

# Syft: Generate SBOM in multiple formats
echo "Generating software bill of materials..."
syft "$TARGET_DIR" -o table > "${OUTPUT_PREFIX}_syft_inventory.txt"
syft "$TARGET_DIR" -o json="${OUTPUT_PREFIX}_sbom.json"
syft "$TARGET_DIR" -o spdx-json="${OUTPUT_PREFIX}_sbom_spdx.json"

echo "✓ SBOM files generated:"
echo "  - ${OUTPUT_PREFIX}_syft_inventory.txt (human readable)"
echo "  - ${OUTPUT_PREFIX}_sbom.json (machine readable)"
echo "  - ${OUTPUT_PREFIX}_sbom_spdx.json (SPDX format)"
echo

echo "Step 2: Grype - Vulnerability Scanning"
echo "======================================="

# Grype: Scan for vulnerabilities using the SBOM
echo "Scanning for vulnerabilities..."
grype "${OUTPUT_PREFIX}_sbom.json" > "${OUTPUT_PREFIX}_grype_vulnerabilities.txt"
grype "${OUTPUT_PREFIX}_sbom.json" -o json > "${OUTPUT_PREFIX}_grype_vulnerabilities.json"

echo "✓ Vulnerability scan files generated:"
echo "  - ${OUTPUT_PREFIX}_grype_vulnerabilities.txt (human readable)"
echo "  - ${OUTPUT_PREFIX}_grype_vulnerabilities.json (machine readable)"
echo

echo "Step 3: Trivy - Comprehensive Security Analysis"
echo "==============================================="

# Trivy: Comprehensive scanning (vulnerabilities + licenses)
echo "Running comprehensive security and license analysis..."
trivy fs --scanners vuln,license "$TARGET_DIR" > "${OUTPUT_PREFIX}_trivy_comprehensive.txt"
trivy fs --scanners vuln,license "$TARGET_DIR" -f json > "${OUTPUT_PREFIX}_trivy_comprehensive.json"

# Trivy: Separate license scan for clarity
trivy fs --scanners license "$TARGET_DIR" > "${OUTPUT_PREFIX}_trivy_licenses.txt"
trivy fs --scanners license "$TARGET_DIR" -f json > "${OUTPUT_PREFIX}_trivy_licenses.json"

echo "✓ Trivy analysis files generated:"
echo "  - ${OUTPUT_PREFIX}_trivy_comprehensive.txt (vulnerabilities + licenses)"
echo "  - ${OUTPUT_PREFIX}_trivy_comprehensive.json (machine readable)"
echo "  - ${OUTPUT_PREFIX}_trivy_licenses.txt (licenses only)"
echo "  - ${OUTPUT_PREFIX}_trivy_licenses.json (licenses JSON)"
echo

echo "Step 4: Generate Summary Report"
echo "==============================="

# Create a summary report
cat > "${OUTPUT_PREFIX}_SUMMARY.txt" << EOF
SBOM Analysis Summary Report
Generated: $(date)
Target: $TARGET_DIR

=== Files Generated ===

SYFT (Software Inventory):
- ${OUTPUT_PREFIX}_syft_inventory.txt - Human-readable component list
- ${OUTPUT_PREFIX}_sbom.json - Machine-readable SBOM
- ${OUTPUT_PREFIX}_sbom_spdx.json - SPDX format SBOM

GRYPE (Vulnerability Analysis):
- ${OUTPUT_PREFIX}_grype_vulnerabilities.txt - Human-readable vulnerability report
- ${OUTPUT_PREFIX}_grype_vulnerabilities.json - Machine-readable vulnerability data

TRIVY (Comprehensive Analysis):
- ${OUTPUT_PREFIX}_trivy_comprehensive.txt - Combined security and license report
- ${OUTPUT_PREFIX}_trivy_comprehensive.json - Combined analysis in JSON
- ${OUTPUT_PREFIX}_trivy_licenses.txt - License compliance report
- ${OUTPUT_PREFIX}_trivy_licenses.json - License data in JSON

=== Quick Stats ===
EOF

# Add quick statistics to summary
echo "Components found: $(jq '.artifacts | length' "${OUTPUT_PREFIX}_sbom.json" 2>/dev/null || echo "N/A")" >> "${OUTPUT_PREFIX}_SUMMARY.txt"
echo "Vulnerabilities found: $(jq '.matches | length' "${OUTPUT_PREFIX}_grype_vulnerabilities.json" 2>/dev/null || echo "N/A")" >> "${OUTPUT_PREFIX}_SUMMARY.txt"

echo "✓ Summary report generated: ${OUTPUT_PREFIX}_SUMMARY.txt"
echo

echo "=== Analysis Complete ==="
echo "Results directory: ${OUTPUT_PREFIX}_results/"
echo "All files ready for SCP transfer:"
ls -la

echo
echo "To transfer all files:"
echo "scp -r ${OUTPUT_PREFIX}_results/ user@host:/destination/"
echo
echo "Defense in depth analysis complete!"
echo "- Software inventory: ✓"
echo "- Vulnerability assessment: ✓" 
echo "- License compliance: ✓"