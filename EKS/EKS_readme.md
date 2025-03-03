# EKS Compliance Remediation Script

## Overview
This repository contains a set of automation scripts for ensuring that Amazon EKS clusters comply with security best practices. The main script (`compliance_remediation.sh`) automates the remediation of security controls for EKS clusters based on a CSV report. The script reads the `compliance_report.csv` and triggers the appropriate remediation function if the control status is flagged as "alarm."

The remediation actions are logged, and if any issues are detected that require manual intervention, they are flagged for further attention.

## Prerequisites
Before using the script, ensure you have the following:
- **AWS CLI**: Ensure you have configured the AWS CLI with appropriate permissions to manage EKS resources.
- **Bash**: The script is written in Bash, so ensure you're running it in an environment that supports Bash (Linux, macOS, or WSL for Windows).
- **Terraform (Optional)**: For infrastructure as code automation.
- **Python (Optional)**: Python with `boto3` for interacting with AWS services.

### Prerequisite Installations

1. **Install AWS CLI**:
   - Follow the [official AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) to install AWS CLI.
   - Configure AWS CLI by running:
     ```bash
     aws configure
     ```

2. **Clone the Repository** or download the script:
   ```bash
   git clone https://github.com/yourrepo/eks-compliance-remediation.git
   ```

3. **Install Terraform (Optional)**:
   - Install Terraform by following the [official installation guide](https://learn.hashicorp.com/tutorials/terraform/install-cli).

4. **Install Python and `boto3`** (Optional for Python users):
   - Install Python 3 and `boto3`:
     ```bash
     pip install boto3
     ```

## Setup Instructions

1. **Prepare the Compliance Report CSV**
   The `compliance_report.csv` should contain a list of control titles and their status, like so:
   ```csv
   Control Title, Status
   EKS Clusters Endpoint Should Restrict Public Access, alarm
   EKS Clusters Should Enable Encryption at Rest for etcd, alarm
   EKS Clusters Should Have Control Plane Audit Logging Enabled, alarm
   ```

2. **Run the Script**
   To run the compliance remediation script, execute the following command:
   ```bash
   ./compliance_remediation.sh
   ```

The script will process the `compliance_report.csv` file and automatically attempt to remediate any controls flagged as "alarm". It will log all actions taken in `remediation_log.txt`.

### Example of Output:

```plaintext
2025-03-03 14:05:02 - Starting compliance remediation process.
2025-03-03 14:05:02 - Processing control: EKS Clusters Endpoint Should Restrict Public Access with status alarm
2025-03-03 14:05:02 - Restricting public access to EKS endpoint.
2025-03-03 14:05:03 - Command restrict_public_access succeeded.
2025-03-03 14:05:03 - Processing control: EKS Clusters Should Enable Encryption at Rest for etcd with status alarm
2025-03-03 14:05:03 - Enabling encryption at rest for etcd.
2025-03-03 14:05:04 - Command enable_etcd_encryption succeeded.
2025-03-03 14:05:04 - Processing control: EKS Clusters Should Have Control Plane Audit Logging Enabled with status alarm
2025-03-03 14:05:04 - Enabling Kubernetes audit logging.
2025-03-03 14:05:06 - Retry 1: Enabling Kubernetes audit logging failed.
2025-03-03 14:05:08 - Retry 2: Enabling Kubernetes audit logging failed.
2025-03-03 14:05:10 - Retry 3: Enabling Kubernetes audit logging succeeded.
2025-03-03 14:05:10 - Processing control: EKS Clusters Should Restrict the Use of Outdated or Unsupported Kubernetes Versions with status compliant
2025-03-03 14:05:10 - No action needed for control: EKS Clusters Should Restrict the Use of Outdated or Unsupported Kubernetes Versions.
2025-03-03 14:05:11 - Processing control: EKS Clusters Should Use IAM Roles for Service Accounts (IRSA) for Fine-Grained Access Control with status alarm
2025-03-03 14:05:11 - Enabling IAM Roles for Service Accounts (IRSA).
2025-03-03 14:05:12 - Command enable_irsa succeeded.
2025-03-03 14:05:12 - Compliance remediation process completed.
```

## Manual Check Recommendations
If any control is flagged for manual check, the script will display the following message:
```plaintext
Manual check is best for this control because it requires contextual decisions or more complex configurations.
```

---

## EKS Control Remediation Scripts (AWS CLI, Terraform, and `boto3`)

### Control 1: EKS Clusters Endpoint Should Restrict Public Access
- **AWS CLI**:
  ```bash
  aws eks update-cluster-config \
      --name your-cluster-name \
      --resources-vpc-config endpointPublicAccess=false
  ```

- **Terraform**:
  ```hcl
  resource "aws_eks_cluster" "example" {
    name     = "your-cluster-name"
    role_arn = aws_iam_role.example.arn
    vpc_config {
      subnet_ids = aws_subnet.example.*.id
      endpoint_public_access = false
    }
  }
  ```

- **boto3 (Python)**:
  ```python
  import boto3

  eks = boto3.client('eks')

  def restrict_public_access(cluster_name):
      response = eks.update_cluster_config(
          name=cluster_name,
          resourcesVpcConfig={
              'endpointPublicAccess': False
          }
      )
      print(f"Public access restricted for cluster {cluster_name}")

  restrict_public_access('your-cluster-name')
  ```

### Control 2: EKS Clusters Should Enable Encryption at Rest for etcd
- **AWS CLI**:
  ```bash
  aws eks update-cluster-config \
      --name your-cluster-name \
      --resources-vpc-config encryptionConfig='[{ "resources": ["etcd"], "provider": { "keyArn": "your-kms-key-arn" } }]'
  ```

- **Terraform**:
  ```hcl
  resource "aws_eks_cluster" "example" {
    name     = "your-cluster-name"
    role_arn = aws_iam_role.example.arn
    vpc_config {
      subnet_ids = aws_subnet.example.*.id
    }
    encryption_config {
      resources = ["etcd"]
      provider {
        key_arn = "your-kms-key-arn"
      }
    }
  }
  ```

- **boto3 (Python)**:
  ```python
  import boto3

  eks = boto3.client('eks')

  def enable_etcd_encryption(cluster_name, kms_key_arn):
      response = eks.update_cluster_config(
          name=cluster_name,
          encryptionConfig=[
              {
                  'resources': ['etcd'],
                  'provider': {
                      'keyArn': kms_key_arn
                  }
              }
          ]
      )
      print(f"Encryption enabled for etcd in cluster {cluster_name} with key {kms_key_arn}")

  enable_etcd_encryption('your-cluster-name', 'your-kms-key-arn')
  ```

### Control 3: EKS Clusters Should Have Control Plane Audit Logging Enabled
- **AWS CLI**:
  ```bash
  aws eks update-cluster-config \
      --name your-cluster-name \
      --logging '{"clusterLogging":[{"types":["api", "audit"],"enabled":true}]}'
  ```

- **Terraform**:
  ```hcl
  resource "aws_eks_cluster" "example" {
    name     = "your-cluster-name"
    role_arn = aws_iam_role.example.arn
    logging {
      cluster_logging {
        types = ["api", "audit"]
        enabled = true
      }
    }
  }
  ```

- **boto3 (Python)**:
  ```python
  import boto3

  eks = boto3.client('eks')

  def enable_audit_logging(cluster_name):
      response = eks.update_cluster_config(
          name=cluster_name,
          logging={
              'clusterLogging': [
                  {'types': ['api', 'audit'], 'enabled': True}
              ]
          }
      )
      print(f"Audit logging enabled for cluster {cluster_name}")

  enable_audit_logging('your-cluster-name')
  ```

---

## Conclusion

This script simplifies ensuring that your EKS clusters comply with security best practices. It automates remediation where possible and logs actions taken. You can also apply the same configurations using **AWS CLI**, **Terraform**, or **Python `boto3`**, depending on your preferred tool for infrastructure management.

For further automation, integrate this solution into your CI/CD pipeline.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```

---

### **Explanation of the README**:
1. **Overview**: The `README.md` starts with a general description of the project's purpose.
2. **Setup Instructions**: Includes installation steps for AWS CLI, Terraform, and Python.
3. **Usage**: Explains how to prepare the CSV report, run the script, and understand the output.
4. **Manual Check**: Mentions when manual intervention is required.
5. **Remediation Scripts for Each Control**:
   - **AWS CLI**: Commands to apply security best practices for each control.
   - **Terraform**: Infrastructure as code to apply security controls.
   - **boto3 (Python)**: Python code to interact with AWS and apply configurations.
6. **Conclusion**: Summarizes the functionality and automation.

This structure helps ensure that the user knows how to implement the controls with different methods, whether they prefer CLI commands, infrastructure as code with Terraform, or programming with Python.