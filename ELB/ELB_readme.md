### Overview

THE setup includes a modular solution for automating compliance checks and remediations for **ELB (Elastic Load Balancer)** security controls. The **compliance_remediation.sh** script, which leverages the **AWS CLI**, works together with a CSV file (**compliance_report.csv**) to handle the controls.

Here’s an organized flow of the files and their functions:

1. **security_controls.yaml**:
   Defines each control and its remediation function, outlining a description and the script or automation for fixing that control.

2. **compliance_remediation.sh**:
   The automation script that processes the **compliance_report.csv** and triggers remediation actions for any control marked as “alarm”.

3. **compliance_report.csv**:
   Input file where each security control’s compliance status is marked as either “alarm” (non-compliant) or “compliant”.

4. **README.md**:
   Documentation that explains the setup, usage, and additional examples of **Boto3**, **AWS CLI**, and **Terraform** implementations for each security control.

# EC2 & ELB Security Compliance Automation

## Purpose
This project automates security compliance checks and remediation for EC2 instances and Elastic Load Balancers (ELB) in AWS. The **compliance_remediation.sh** script takes an input CSV file (**compliance_report.csv**) to check and fix controls.

## Files Overview:
1. **security_controls.yaml**: Contains the list of controls and corresponding remediation functions.
2. **compliance_remediation.sh**: Main script to process the compliance report and perform remediations.
3. **compliance_report.csv**: Input file where controls are marked as "alarm" or "compliant".
4. **remediation_log.txt**: Logs all actions taken by the script.

## How It Works
- The **compliance_remediation.sh** script processes the **compliance_report.csv** file, and for every "alarm" control, it runs the associated remediation function.
- If a control cannot be automated, it logs a message indicating that manual intervention is required.

## Example Output

```bash
2025-03-03 15:30:22 - Enabling strict desync mitigation mode for ELB classic load balancers
2025-03-03 15:31:15 - Enabling WAF for ELB application load balancer
2025-03-03 15:32:12 - Enabling HTTP to HTTPS redirect for ALB
2025-03-03 15:35:10 - Manual check required for ELB classic load balancers should only use SSL or HTTPS listeners because it's not automated.
```

## AWS CLI, Boto3, and Terraform Example Code

### AWS CLI

```bash
# Enable strict desync mitigation mode for classic load balancer
aws elb modify-load-balancer-attributes --load-balancer-name my-load-balancer --attributes "desyncMitigationMode=strictest"
```

### Boto3 (Python)

```python
import boto3

def enable_strict_desync_mitigation(load_balancer_name):
    elb = boto3.client('elb')
    elb.modify_load_balancer_attributes(
        LoadBalancerName=load_balancer_name,
        Attributes=[{
            'Key': 'desyncMitigationMode',
            'Value': 'strictest'
        }]
    )
```

### Terraform

```hcl
resource "aws_lb" "example" {
  name               = "example"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.example.id]
  subnets            = [aws_subnet.example.id]

  enable_deletion_protection = true
  enable_strict_desync_mitigation_mode = true
}
```

## How to Run
1. Install AWS CLI and configure it with `aws configure`.
2. Download or clone this repository.
3. Prepare your **compliance_report.csv**.
4. Run the script with `./compliance_remediation.sh`.

## Conclusion
This solution automates EC2 and ELB compliance checks and remediations, making it easier to maintain security standards and ensure best practices in your AWS environment.
```

---

### Notes

- This setup allows easy addition of new controls and remediations.
- The output example clearly logs actions and flags manual checks.
- Additional **AWS CLI**, **Boto3**, and **Terraform** examples for every control are included for flexibility.
