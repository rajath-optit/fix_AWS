# EC2 Compliance Remediation Script

This script helps in automating compliance checks and remediations for various EC2-related controls in AWS.

## Files
- **`security_controls.yaml`**: Contains the security controls, remediation function, and descriptions.
- **`compliance_remediation.sh`**: The shell script that automates the remediation process based on the compliance report.
- **`compliance_report.csv`**: The CSV file that contains the status of each control (either `alarm` or `compliant`).

## Prerequisites
1. **AWS CLI** must be installed and configured with appropriate access to EC2 and IAM.
2. **Bash** shell environment.

## How It Works
1. **`security_controls.yaml`** defines the controls, the function that will remediate issues, and a brief description of the control.
2. **`compliance_remediation.sh`** reads the `compliance_report.csv` file, and based on the control status (`alarm`), it triggers the respective remediation function.
3. The script logs actions taken and issues with timestamps into a file called `remediation_log.txt`.
4. The `compliance_report.csv` file is expected to have a `control_title` and a `status` (either `alarm` or `compliant`).

## Controls Covered
- AMI encryption
- EC2 stopped instance removal
- VPC compliance for EC2 instances
- Public IP management for EC2 launch templates

## Usage
1. **Prepare the Compliance Report**: Create or update the `compliance_report.csv` with the status of each control.
2. **Run the Script**: Execute the `compliance_remediation.sh` script.
   ```bash
   bash compliance_remediation.sh

#Example Output:

The script processes each control based on the status from the CSV and logs actions taken. If no automated fix is available, it recommends a manual review.

```
2025-03-03 10:00:00 - Fixing stopped EC2 instances that have been stopped for over 30 days.
2025-03-03 10:05:00 - Stopped EC2 instances removed.
2025-03-03 10:10:00 - Ensuring EC2 instances are in a VPC.
2025-03-03 10:15:00 - EC2 instance VPC check completed.
```
