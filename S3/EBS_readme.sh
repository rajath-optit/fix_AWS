# EBS Compliance Remediation Script

This script automates the remediation of EBS-related compliance checks in AWS.

## Files
- **`security_controls.yaml`**: Contains security controls, remediation functions, and descriptions for EBS.
- **`compliance_remediation.sh`**: The script that performs compliance checks and remediation.
- **`compliance_report.csv`**: A sample compliance report file containing controls and statuses (alarm or compliant).

## Features
- Remediates EBS compliance issues such as encryption, backups, and attachment to EC2 instances.
- Logs all actions taken during remediation.

## How to Use
1. Download or clone the repository.
2. Modify the `compliance_report.csv` with the results of your compliance check.
3. Run the remediation script:

```bash
./compliance_remediation.sh

----------------------------------------------------------
ADDITIONAL:
Below is how you can automate the EBS compliance checks using AWS CLI, Boto3, and Terraform:

### 1. **EBS snapshots should not be publicly restorable**

- **AWS CLI**
```bash
aws ec2 describe-snapshots --query "Snapshots[].[SnapshotId,Tags[?Key=='public'].Value]" --output text | \
awk '$2 == "true" {print $1}' | \
xargs -I {} aws ec2 modify-snapshot-attribute --snapshot-id {} --no-public
```

- **Boto3**
```python
import boto3

ec2 = boto3.client('ec2')

snapshots = ec2.describe_snapshots(OwnerIds=['self'])

for snapshot in snapshots['Snapshots']:
    if 'public' in snapshot['Tags']:
        snapshot_id = snapshot['SnapshotId']
        ec2.modify_snapshot_attribute(
            SnapshotId=snapshot_id,
            Attribute='createVolumePermission',
            OperationType='remove',
            UserGroups=['all']
        )
```

- **Terraform**
```hcl
resource "aws_ebs_snapshot" "example" {
  snapshot_id = "snap-12345678"
  attribute   = "createVolumePermission"
  operation   = "remove"
  user_groups = ["all"]
}
```

### 2. **Attached EBS volumes should have encryption enabled**

- **AWS CLI**
```bash
aws ec2 describe-volumes --query "Volumes[].[VolumeId,Encrypted]" --output text | \
awk '$2 == "false" {print $1}' | \
xargs -I {} aws ec2 encrypt-volume --volume-id {}
```

- **Boto3**
```python
volumes = ec2.describe_volumes()

for volume in volumes['Volumes']:
    if not volume['Encrypted']:
        volume_id = volume['VolumeId']
        ec2.modify_volume(
            VolumeId=volume_id,
            Encrypted=True
        )
```

- **Terraform**
```hcl
resource "aws_ebs_volume" "example" {
  size = 8
  encrypted = true
  availability_zone = "us-west-2a"
}
```

### 3. **EBS volumes should be protected by a backup plan**

- **AWS CLI**
```bash
aws backup create-backup-plan --backup-plan-name "EBS-Backup-Plan" --rules '[{
    "RuleName": "DailyBackup",
    "TargetBackupVaultName": "Default",
    "ScheduleExpression": "cron(0 5 ? * * *)",
    "StartWindowMinutes": 60,
    "CompletionWindowMinutes": 180,
    "Lifecycle": {
        "MoveToColdStorageAfterDays": 30,
        "DeleteAfterDays": 365
    }
}]'
```

- **Boto3**
```python
backup = boto3.client('backup')

response = backup.create_backup_plan(
    BackupPlan={
        'BackupPlanName': 'EBS-Backup-Plan',
        'Rules': [{
            'RuleName': 'DailyBackup',
            'TargetBackupVaultName': 'Default',
            'ScheduleExpression': 'cron(0 5 ? * * *)',
            'StartWindowMinutes': 60,
            'CompletionWindowMinutes': 180,
            'Lifecycle': {
                'MoveToColdStorageAfterDays': 30,
                'DeleteAfterDays': 365
            }
        }]
    }
)
```

- **Terraform**
```hcl
resource "aws_backup_plan" "example" {
  name = "EBS-Backup-Plan"

  rule {
    rule_name         = "DailyBackup"
    target_vault_name = "Default"
    schedule          = "cron(0 5 ? * * *)"
    start_window      = 60
    completion_window = 180

    lifecycle {
      move_to_cold_storage_after_days = 30
      delete_after_days                = 365
    }
  }
}
```

### 4. **EBS volume encryption at rest should be enabled**

- **AWS CLI**
```bash
aws ec2 describe-volumes --query "Volumes[].[VolumeId,Encrypted]" --output text | \
awk '$2 == "false" {print $1}' | \
xargs -I {} aws ec2 modify-volume --volume-id {} --encryption-enabled
```

- **Boto3**
```python
for volume in volumes['Volumes']:
    if not volume['Encrypted']:
        volume_id = volume['VolumeId']
        ec2.modify_volume(
            VolumeId=volume_id,
            Encrypted=True
        )
```

- **Terraform**
```hcl
resource "aws_ebs_volume" "example" {
  size        = 8
  encrypted   = true
  availability_zone = "us-west-2a"
}
```

### 5. **EBS snapshots should be encrypted**

- **AWS CLI**
```bash
aws ec2 describe-snapshots --query "Snapshots[].[SnapshotId,Encrypted]" --output text | \
awk '$2 == "false" {print $1}' | \
xargs -I {} aws ec2 modify-snapshot-attribute --snapshot-id {} --encrypted
```

- **Boto3**
```python
snapshots = ec2.describe_snapshots(OwnerIds=['self'])

for snapshot in snapshots['Snapshots']:
    if not snapshot['Encrypted']:
        snapshot_id = snapshot['SnapshotId']
        ec2.modify_snapshot_attribute(
            SnapshotId=snapshot_id,
            Attribute='createVolumePermission',
            OperationType='remove',
            UserGroups=['all'],
            Encrypted=True
        )
```

- **Terraform**
```hcl
resource "aws_ebs_snapshot" "example" {
  snapshot_id = "snap-12345678"
  encrypted   = true
}
```

### 6. **EBS encryption by default should be enabled**

- **AWS CLI**
```bash
aws ec2 enable-ebs-encryption-by-default
```

- **Boto3**
```python
ec2.enable_ebs_encryption_by_default()
```

- **Terraform**
```hcl
resource "aws_ebs_encryption_by_default" "example" {
  enabled = true
}
```

### 7. **EBS volumes should be attached to EC2 instances**

- **AWS CLI**
```bash
aws ec2 describe-volumes --query "Volumes[].[VolumeId,Attachments[0].InstanceId]" --output text | \
awk '$2 == "" {print $1}' | \
xargs -I {} echo "EBS volume {} is not attached to an EC2 instance. Please review."
```

- **Boto3**
```python
volumes = ec2.describe_volumes()

for volume in volumes['Volumes']:
    if not volume['Attachments']:
        print(f"EBS volume {volume['VolumeId']} is not attached to an EC2 instance.")
```

- **Terraform**
```hcl
resource "aws_ebs_volume" "example" {
  size                  = 8
  availability_zone     = "us-west-2a"
  attach_to_instance_id = "i-1234567890abcdef0"
}
```

### 8. **EBS volume snapshots should exist**

- **AWS CLI**
```bash
aws ec2 describe-volumes --query "Volumes[].[VolumeId]" --output text | \
while read volume; do
    snapshot_id=$(aws ec2 create-snapshot --volume-id "$volume" --query "SnapshotId" --output text)
    echo "Created snapshot $snapshot_id for volume $volume"
done
```

- **Boto3**
```python
for volume in volumes['Volumes']:
    snapshot_id = ec2.create_snapshot(VolumeId=volume['VolumeId'])
    print(f"Created snapshot {snapshot_id['SnapshotId']} for volume {volume['VolumeId']}")
```

- **Terraform**
```hcl
resource "aws_ebs_snapshot" "example" {
  volume_id = "vol-12345678"
}
```

### 9. **EBS volumes should be in a backup plan**

- **AWS CLI**
```bash
aws backup create-backup-plan --backup-plan-name "EBS-Backup-Plan" --rules '[{
    "RuleName": "DailyBackup",
    "TargetBackupVaultName": "Default",
    "ScheduleExpression": "cron(0 5 ? * * *)",
    "StartWindowMinutes": 60,
    "CompletionWindowMinutes": 180,
    "Lifecycle": {
        "MoveToColdStorageAfterDays": 30,
        "DeleteAfterDays": 365
    }
}]'
```

- **Boto3**
```python
backup = boto3.client('backup')

response = backup.create_backup_plan(
    BackupPlan={
        'BackupPlanName': 'EBS-Backup-Plan',
        'Rules': [{
            'RuleName': 'DailyBackup',
            'TargetBackupVaultName': 'Default',
            'ScheduleExpression': 'cron(0 5 ? * * *)',
            'StartWindowMinutes': 60,
            'CompletionWindowMinutes': 180,
            'Lifecycle': {
                'MoveToColdStorageAfterDays': 30,
                'DeleteAfterDays': 365
            }
        }]
    }
)
```

- **Terraform**
```hcl
resource "aws_backup_plan" "example" {
  name = "EBS-Backup-Plan"

  rule {
    rule_name         = "DailyBackup"
    target_vault_name = "Default"
    schedule          = "cron(0 5 ? * * *)"
    start_window      = 60
    completion_window = 180

    lifecycle {
      move_to_cold_storage_after_days = 30
      delete_after_days                = 365
    }
  }
}
```

### 10. **Attached EBS volumes should have delete on termination enabled**

- **AWS CLI**
```bash
aws ec

2 describe-volumes --query "Volumes[].[VolumeId,Attachments[0].DeleteOnTermination]" --output text | \
awk '$2 == "false" {print $1}' | \
xargs -I {} aws ec2 modify-volume-attachment --volume-id {} --delete-on-termination
```

- **Boto3**
```python
for volume in volumes['Volumes']:
    if not volume['Attachments'][0].get('DeleteOnTermination', False):
        volume_id = volume['VolumeId']
        ec2.modify_volume(
            VolumeId=volume_id,
            DeleteOnTermination=True
        )
```

- **Terraform**
```hcl
resource "aws_ebs_volume" "example" {
  size = 8
  availability_zone = "us-west-2a"

  lifecycle {
    prevent_destroy = true
  }

  volume {
    delete_on_termination = true
  }
}
```

These examples can be expanded into fully integrated scripts or used within your existing cloud infrastructure management processes.
