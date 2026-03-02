CI/CD Pipeline with Container Security Scanning

Video walkthrough coming soon. A full step-by-step demo is in production. Check back in a few weeks.


A working CI/CD pipeline that builds containerized Python apps, generates SBOMs with Syft, scans for vulnerabilities with Grype, and pushes passing images to GitHub Container Registry.
Two apps demonstrate how security gates work in a real pipeline:

app-pass — Current base image, current dependencies. Passes scans. Image pushed to GHCR.
app-fail — End-of-life base image, vulnerable dependencies. Critical CVEs found. Pipeline blocked. Nothing deploys.

Same application code. The only difference is the Dockerfile and dependency versions.
Stack
ComponentPurposeGitHub ActionsCI/CD pipelineSyftSBOM generation (SPDX format)GrypeVulnerability scanning with severity gatesGHCRContainer image registryRocky Linux 9Dev and deploy environment
Reports
Every pipeline run produces downloadable artifacts:

SBOM — Complete inventory of packages inside the container (.spdx.json)
Vulnerability report — Every known CVE found by Grype (.json)

Reports are saved even when the pipeline fails. Download them from the Actions tab under each run.

Setup
Provisioning scripts and a full companion guide are included with the video release.

Built for cyber engineers who need to understand pipelines and scans.
