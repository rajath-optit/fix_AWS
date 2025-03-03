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
---------------------------------------------------------------------

ADDITIONAL:
Here's the complete list of **EC2 controls** that can be automated or reviewed manually, including Terraform and Boto3 examples:

---

### **Automated EC2 Controls Using AWS CLI, Boto3, or Terraform**

#### 1. **EC2 stopped instances should be removed in 30 days**
- **Lambda/CloudWatch:** Schedule Lambda to terminate stopped instances after 30 days.
- **Boto3**:
```python
import boto3
import datetime

ec2 = boto3.client('ec2')

def terminate_stopped_instances():
    instances = ec2.describe_instances(Filters=[{'Name': 'instance-state-name', 'Values': ['stopped']}])
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            launch_time = instance['LaunchTime']
            if (datetime.datetime.now() - launch_time).days > 30:
                ec2.terminate_instances(InstanceIds=[instance['InstanceId']])

terminate_stopped_instances()
```
- **Terraform**:
```hcl
resource "aws_cloudwatch_event_rule" "ec2_stop_rule" {
  name        = "ec2-stop-rule"
  schedule_expression = "rate(1 day)"
}

resource "aws_lambda_function" "terminate_stopped_ec2" {
  filename = "terminate_stopped_ec2.zip"
  function_name = "terminate_stopped_ec2"
  role        = aws_iam_role.lambda_role.arn
  handler     = "index.handler"
  runtime     = "python3.8"
}

resource "aws_cloudwatch_event_target" "ec2_stop_target" {
  rule = aws_cloudwatch_event_rule.ec2_stop_rule.name
  target_id = "terminate_ec2"
  arn = aws_lambda_function.terminate_stopped_ec2.arn
}
```

#### 2. **EC2 instances should be in a VPC**
- **Boto3**:
```python
instances = ec2.describe_instances()
for reservation in instances['Reservations']:
    for instance in reservation['Instances']:
        if 'VpcId' not in instance:
            print(f"Instance {instance['InstanceId']} is not in a VPC")
```
- **Terraform**:
```hcl
resource "aws_security_group" "default" {
  name        = "default"
  vpc_id      = aws_vpc.default.id
}
```

#### 3. **Ensure EC2 instances have IAM profile attached**
- **Boto3**:
```python
for reservation in instances['Reservations']:
    for instance in reservation['Instances']:
        if 'IamInstanceProfile' not in instance:
            print(f"Instance {instance['InstanceId']} does not have an IAM profile attached")
```
- **Terraform**:
```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  iam_instance_profile = "my-iam-role"
}
```

#### 4. **EC2 launch templates should not assign public IPs to network interfaces**
- **Boto3**:
```python
response = ec2.describe_launch_templates()
for template in response['LaunchTemplates']:
    if template['NetworkInterfaces'][0]['AssociatePublicIpAddress']:
        print(f"Launch template {template['LaunchTemplateName']} assigns a public IP")
```
- **Terraform**:
```hcl
resource "aws_launch_template" "example" {
  name_prefix     = "example-"
  associate_public_ip_address = false
  network_interfaces {
    associate_public_ip_address = false
  }
}
```

#### 5. **Ensure EBS volumes attached to an EC2 instance are marked for deletion upon instance termination**
- **Boto3**:
```python
response = ec2.describe_instances()
for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        for volume in instance.get('BlockDeviceMappings', []):
            volume_id = volume['Ebs']['VolumeId']
            ec2.modify_volume_attribute(VolumeId=volume_id, DeleteOnTermination=True)
```
- **Terraform**:
```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  block_device {
    device_name = "/dev/sda1"
    delete_on_termination = true
  }
}
```

#### 6. **Ensure EC2 instances are not using key pairs in the running state**
- **Boto3**:
```python
for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        if instance.get('KeyName'):
            print(f"Instance {instance['InstanceId']} is using a key pair")
```
- **Terraform**:
```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = null
}
```

#### 7. **Ensure EC2 instances are not older than 180 days**
- **Boto3**:
```python
for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        launch_time = instance['LaunchTime']
        if (datetime.datetime.now() - launch_time).days > 180:
            print(f"Instance {instance['InstanceId']} is older than 180 days")
```
- **Terraform**: Use Lambda or CloudWatch to trigger the termination of old instances.

#### 8. **Ensure unused ENIs are removed**
- **Boto3**:
```python
eni_response = ec2.describe_network_interfaces()
for eni in eni_response['NetworkInterfaces']:
    if eni['Status'] == 'available':
        ec2.delete_network_interface(NetworkInterfaceId=eni['NetworkInterfaceId'])
```
- **Terraform**:
```hcl
resource "aws_network_interface" "example" {
  subnet_id = aws_subnet.example.id
  private_ips = ["10.0.0.100"]
}
```

#### 9. **Ensure EC2 instances have AMIs encrypted**
- **Boto3**:
```python
for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        if not instance['EbsOptimized']:
            print(f"Instance {instance['InstanceId']} AMI is not encrypted")
```
- **Terraform**:
```hcl
resource "aws_ami" "example" {
  name             = "example-ami"
  encrypted        = true
  root_device_name = "/dev/sda1"
}
```

#### 10. **Ensure EC2 instances are protected by a backup plan**
- **Boto3**:
```python
backup = boto3.client('backup')
for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        backup_plan = backup.describe_backup_plan(BackupPlanId=instance['InstanceId'])
        if not backup_plan:
            print(f"Instance {instance['InstanceId']} is not backed up")
```
- **Terraform**:
```hcl
resource "aws_backup_plan" "example" {
  name = "example-backup-plan"
}
```

---

### **Controls Not Best Suited for Automation (Manual Review or Context-Specific)**

- EC2 instance IAM role should not allow credentials exposure access
- EC2 instance IAM role should not allow defense evasion impact of AWS security services access
- EC2 instances should not use multiple ENIs
- Public EC2 instances should have IAM profile attached
- EC2 instance IAM role should not allow destruction KMS access
- EC2 instance IAM role should not allow to alter critical S3 permissions configuration
- EC2 instance IAM role should not allow write-level access
- EC2 instances should not be attached to 'launch wizard' security groups
- EC2 instances should have IAM profile attached
- EC2 instance IAM role should not allow new user creation with attached policy access

These controls require careful manual verification, business decisions, and role evaluations, and thus are not fully suited for automation.

---

### **README**

#### EC2 Automation Script

This repository provides scripts to automate various EC2 security and configuration checks using AWS CLI, Boto3, and Terraform.

##### Prerequisites:
- Python 3.x
- Boto3 (`pip install boto3`)
- AWS CLI (`pip install awscli`)
- Terraform

##### How to Use:
1. **Configure AWS CLI**:
   - Run `aws configure` and provide your AWS Access Key, Secret Key, region, and output format.
   
2. **Run Boto3 Script**:
   - Clone this repo.
   - Execute Python scripts for various automation tasks.
   
3. **Run Terraform**:
   - Initialize Terraform: `terraform init`
   - Apply the configuration: `terraform apply`

##### Controls Automated:
- Terminate stopped EC2 instances after 30 days.
- Ensure EC2 instances are always in a VPC.
- Ensure EC2 instances are not using key pairs in the running state.
- Check and enforce IAM roles for EC2 instances.

---

Feel free to integrate these controls into your infrastructure to help automate your AWS EC2 security management.
