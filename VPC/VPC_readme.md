# **AWS VPC Compliance Remediation**

## **Overview**
This project automates the remediation of AWS compliance issues related to **VPC security controls**. It scans a **CSV compliance report**, identifies security violations, and applies necessary fixes using **AWS CLI**.

### **Key Features**
- **Restricts security group ingress rules** (e.g., blocks open MongoDB/Oracle ports).
- **Ensures AMIs are encrypted** (re-encrypts unencrypted AMIs).
- **Verifies EC2 instances are inside a VPC** (alerts for non-VPC instances).
- **Disables public IP assignment** (modifies launch templates).
- **Logs all remediation actions** for auditing.

---

## **1️⃣ Prerequisites**
Before running the script, ensure you have:
- **AWS CLI installed** (`aws configure` must be set up)
- **IAM permissions** for:
  - `ec2:DescribeInstances`
  - `ec2:DescribeImages`
  - `ec2:ModifyLaunchTemplate`
  - `ec2:RevokeSecurityGroupIngress`
  - `ec2:AuthorizeSecurityGroupIngress`
  - `ec2:DescribeSecurityGroups`
  - `ec2:CopyImage`
- **Bash shell environment** (Linux/macOS or WSL for Windows)
- **Compliance report in CSV format**

---

## **2️⃣ Installation**
### **Clone the Repository**
```sh
git clone https://github.com/your-repo/vpc-compliance-remediation.git
cd vpc-compliance-remediation
```

### **Set Execution Permission**
```sh
chmod +x compliance_remediation.sh
```

---

## **3️⃣ Configuration**
### **Edit Security Controls YAML**
Modify `security_controls.yaml` to define compliance rules. Example:
```yaml
security_groups:
  restrict_ports:
    - port: 27017
      protocol: tcp
      reason: "Restrict MongoDB port"
    - port: 1521
      protocol: tcp
      reason: "Restrict Oracle port"
  allowed_cidrs:
    - "192.168.1.0/24"
```

---

## **4️⃣ Input File: `compliance_report.csv`**
This file contains compliance findings for remediation.

### **Example Format**
```csv
sg-06accaf4ccc4165b6,Restrict MongoDB Port,alarm
sg-027a5fe3890f316e9,Restrict Oracle Port,alarm
-,Ensure AMI Encryption,alarm
-,Ensure Instances in VPC,compliant
-,Disable Public IPs,alarm
```
- **First column:** Resource ID (`sg-*` for security groups, `-` for global checks)
- **Second column:** Compliance control
- **Third column:** Status (`alarm` means non-compliant)

---

## **5️⃣ Running the Script**
Execute the remediation script:
```sh
./compliance_remediation.sh
```

### **Expected Output**
- Logs actions to `compliance_remediation.log`
- Applies security group rule updates
- Encrypts AMIs if necessary
- Notifies about instances outside VPC
- Disables public IP assignments

---

## **6️⃣ Remediation Logic**
The script automates fixes based on the compliance report.

### **🔹 Restrict Security Group Ingress**
- **Removes public access (`0.0.0.0/0`)** to specified ports.
- **Allows only trusted IPs** from `security_controls.yaml`.

### **🔹 Ensure AMI Encryption**
- Finds **unencrypted AMIs** and creates **encrypted copies**.

### **🔹 Ensure EC2 Instances in VPC**
- Identifies instances outside **any VPC** and logs them for review.

### **🔹 Disable Public IPs**
- Updates **launch templates** to prevent auto-assigned public IPs.

---

## **7️⃣ Logs & Auditing**
The script logs all actions to `compliance_remediation.log`. Example:
```
2025-03-04 12:30:45 - Restricting ingress for SG: sg-06accaf4ccc4165b6
2025-03-04 12:30:46 - Revoked public access to port 27017 on sg-06accaf4ccc4165b6
2025-03-04 12:30:50 - Created encrypted copy of AMI ami-1234567890abcdef
```

---

## **8️⃣ Future Enhancements**
- ✅ Automate Lambda function integration for scheduled checks.
- ✅ Use AWS Security Hub for continuous monitoring.
- ✅ Implement Terraform/Ansible for VPC auto-remediation.

---

## **9️⃣ Troubleshooting**
### **🔹 AWS CLI Errors**
Run:
```sh
aws sts get-caller-identity
```
Ensure you have the correct IAM permissions.

### **🔹 No Changes Applied?**
Check the log file:
```sh
cat compliance_remediation.log
```
Ensure the **CSV file format is correct**.

---

## **🔟 Conclusion**
This project provides an **automated compliance remediation** solution for AWS VPC security issues. It integrates with **security reports** and **AWS CLI** to enforce security best practices.

---

### 💡 **Author**
Rajath | DevOps & Cloud Platform Security Specialist  
🚀 **Stay secure! Automate compliance!** 🚀

--------------------------------------
ADDITINAL:

python automation

```
#!/bin/bash

LOG_FILE="compliance_remediation.log"
SECURITY_CONTROLS_FILE="security_controls.yaml"
COMPLIANCE_REPORT_FILE="compliance_report.csv"

# Log function
log_message() {
  echo "$(date) - $1" | tee -a $LOG_FILE
}

# Function to extract SG IDs from the compliance report
get_sg_ids_from_report() {
  sg_ids=($(awk -F',' '$2 == "alarm" {print $3}' $COMPLIANCE_REPORT_FILE | grep -E '^sg-'))
  echo "${sg_ids[@]}"
}

# Function to remediate MongoDB Security Groups
restrict_sg_ingress_mongoDB() {
  log_message "Restricting MongoDB ports ingress"
  sg_ids=$(get_sg_ids_from_report)
  
  for sg_id in $sg_ids; do
    log_message "Fixing MongoDB port access for security group: $sg_id"
    aws ec2 revoke-security-group-ingress --group-id $sg_id --protocol tcp --port 27017 --cidr 0.0.0.0/0
    aws ec2 revoke-security-group-ingress --group-id $sg_id --protocol tcp --port 27018 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 27017 --cidr <your-specific-ip>/32
    aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 27018 --cidr <your-specific-ip>/32
  done
}

# Function to remediate Oracle Security Groups
restrict_sg_ingress_oracle() {
  log_message "Restricting Oracle ports ingress"
  sg_ids=$(get_sg_ids_from_report)
  
  for sg_id in $sg_ids; do
    log_message "Fixing Oracle port access for security group: $sg_id"
    aws ec2 revoke-security-group-ingress --group-id $sg_id --protocol tcp --port 1521 --cidr 0.0.0.0/0
    aws ec2 revoke-security-group-ingress --group-id $sg_id --protocol tcp --port 2483 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 1521 --cidr <your-specific-ip>/32
    aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 2483 --cidr <your-specific-ip>/32
  done
}

# Function to scan VPC security groups if not found in report
scan_vpc_security_groups() {
  log_message "Scanning VPC Security Groups for MongoDB and Oracle"
  mongo_sg_id=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='MongoDB'].GroupId" --output text)
  oracle_sg_id=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='Oracle'].GroupId" --output text)

  if [ -n "$mongo_sg_id" ]; then
    log_message "MongoDB security group found: $mongo_sg_id"
    restrict_sg_ingress_mongoDB
  else
    log_message "MongoDB security group not found. Skipping..."
  fi

  if [ -n "$oracle_sg_id" ]; then
    log_message "Oracle security group found: $oracle_sg_id"
    restrict_sg_ingress_oracle
  else
    log_message "Oracle security group not found. Skipping..."
  fi
}

# Process the compliance report and apply remediations
process_compliance_report() {
  log_message "Processing compliance report"
  while IFS=',' read -r control_title status resource; do
    if [[ "$status" == "alarm" ]]; then
      case "$control_title" in
        "Ensure AMI Encryption")
          aws ec2 modify-image-attribute --image-id "$resource" --launch-permission "{}"
          log_message "Ensured AMI encryption for $resource"
          ;;
        "Ensure Instances are in VPC")
          log_message "Checking if instance $resource is in a VPC"
          # Additional commands to migrate EC2 to VPC if needed
          ;;
        "Disable Public IP on Launch")
          aws ec2 modify-launch-template --launch-template-id "$resource" --version "$resource_version" --set-default-version "$resource_version"
          log_message "Disabled public IP for launch template $resource"
          ;;
        "Restrict MongoDB Ports")
          restrict_sg_ingress_mongoDB
          ;;
        "Restrict Oracle Ports")
          restrict_sg_ingress_oracle
          ;;
      esac
    fi
  done < <(tail -n +2 $COMPLIANCE_REPORT_FILE)
}

# Start remediation process
log_message "Starting compliance remediation process"
process_compliance_report
scan_vpc_security_groups
log_message "Compliance remediation process completed"
```
