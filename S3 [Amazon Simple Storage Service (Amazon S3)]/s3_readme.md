# S3 Compliance Automation

This project automates S3 security controls to ensure compliance with best practices. The automation can be enforced using AWS CLI, shell scripts, and custom remediation functions.

## Files

- **security_controls_s3.yaml**: Defines the S3 security controls and corresponding remediation functions.
- **compliance_remediation_s3.sh**: The script that reads the compliance report and triggers remediation based on the control title.
- **compliance_report_s3.csv**: Input CSV file that lists control titles and their compliance statuses.
- **README.md**: Describes the setup and usage.

## Setup and Usage

1. Ensure AWS CLI is configured with the required permissions.
2. Update `compliance_report_s3.csv` with the current S3 compliance statuses.
3. Run the script:
   ```bash
   bash compliance_remediation_s3.sh
 
 The script will automatically remediate the controls flagged as "alarm" based on the security_controls_s3.yaml configurations.

Example Output

Logs of actions taken will be recorded in compliance_remediation_log.txt.
```
### Key Features:
- **Automated Remediation**: Many of the S3 security controls can be automated using AWS CLI and shell scripting.
- **Manual Review Requirements**: Some controls, such as data classification or versioning requirements, require manual review and intervention.
- **Comprehensive Logging**: Actions taken are logged for transparency and auditing.
```
---------------------------
Additional
