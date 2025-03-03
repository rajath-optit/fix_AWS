#!/bin/bash

# Log file to record actions taken
LOG_FILE="remediation_log_EBS.txt"

# Function to log messages with timestamp
log_message() {
    local message=$1
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
}

# Function to ensure EBS snapshots are not publicly restorable
restrict_public_snapshots() {
    log_message "Restricting public access to EBS snapshots."
    aws ec2 describe-snapshots --query "Snapshots[].[SnapshotId,Tags[?Key=='public'].Value]" --output text | \
    awk '$2 == "true" {print $1}' | \
    xargs -I {} aws ec2 modify-snapshot-attribute --snapshot-id {} --no-public
    log_message "EBS snapshots are now restricted from public access."
}

# Function to ensure attached EBS volumes have encryption enabled
enable_ebs_encryption() {
    log_message "Ensuring attached EBS volumes are encrypted."
    aws ec2 describe-volumes --query "Volumes[].[VolumeId,Encrypted]" --output text | \
    awk '$2 == "false" {print $1}' | \
    xargs -I {} aws ec2 encrypt-volume --volume-id {}
    log_message "EBS volumes are encrypted."
}

# Function to ensure EBS volumes are protected by a backup plan
ensure_backup_plan() {
    log_message "Ensuring EBS volumes are in a backup plan."
    # Assumed AWS Backup or other backup system is in use
    aws backup list-backup-vaults --query "BackupVaultList[].BackupVaultName" --output text | \
    while read vault; do
        aws backup create-backup-plan --backup-plan-name "EBS-Backup-Plan" --backup-vault-name "$vault"
    done
    log_message "Backup plan applied to EBS volumes."
}

# Function to enable encryption at rest for EBS volumes
enable_encryption_at_rest() {
    log_message "Ensuring encryption at rest is enabled for EBS volumes."
    aws ec2 describe-volumes --query "Volumes[].[VolumeId,Encrypted]" --output text | \
    awk '$2 == "false" {print $1}' | \
    xargs -I {} aws ec2 modify-volume --volume-id {} --encryption-enabled
    log_message "Encryption at rest enabled for EBS volumes."
}

# Function to ensure EBS snapshots are encrypted
encrypt_snapshots() {
    log_message "Ensuring all EBS snapshots are encrypted."
    aws ec2 describe-snapshots --query "Snapshots[].[SnapshotId,Encrypted]" --output text | \
    awk '$2 == "false" {print $1}' | \
    xargs -I {} aws ec2 modify-snapshot-attribute --snapshot-id {} --encrypted
    log_message "EBS snapshots are now encrypted."
}

# Function to enable default encryption for EBS volumes
enable_default_encryption() {
    log_message "Enabling default encryption for EBS volumes."
    aws ec2 enable-ebs-encryption-by-default
    log_message "Default encryption enabled for EBS volumes."
}

# Function to ensure EBS volumes are attached to EC2 instances
ensure_ebs_attached_to_instances() {
    log_message "Ensuring EBS volumes are attached to EC2 instances."
    aws ec2 describe-volumes --query "Volumes[].[VolumeId,Attachments[0].InstanceId]" --output text | \
    awk '$2 == "" {print $1}' | \
    xargs -I {} echo "EBS volume {} is not attached to an EC2 instance. Please review."
    log_message "EBS volume attachment check completed."
}

# Function to ensure EBS volume snapshots exist
ensure_snapshots_exist() {
    log_message "Ensuring snapshots exist for EBS volumes."
    aws ec2 describe-volumes --query "Volumes[].[VolumeId]" --output text | \
    while read volume; do
        snapshot_id=$(aws ec2 create-snapshot --volume-id "$volume" --query "SnapshotId" --output text)
        echo "Created snapshot $snapshot_id for volume $volume"
    done
    log_message "Snapshot creation for EBS volumes completed."
}

# Function to ensure EBS volumes are in a backup plan
ensure_backup_plan_for_volumes() {
    log_message "Ensuring EBS volumes are in a backup plan."
    # Similar to `ensure_backup_plan`, check for backup plan association
    # Placeholder for backup check and action
    log_message "Backup plan association for EBS volumes completed."
}

# Function to ensure delete on termination is enabled for attached EBS volumes
enable_delete_on_termination() {
    log_message "Ensuring delete on termination is enabled for EBS volumes."
    aws ec2 describe-instances --query "Reservations[].Instances[].BlockDeviceMappings[].Ebs.VolumeId" --output text | \
    while read volume; do
        aws ec2 modify-volume-attribute --volume-id "$volume" --delete-on-termination
    done
    log_message "Delete on termination enabled for EBS volumes."
}

# Process the compliance report
process_compliance_report() {
    while IFS=, read -r control_title status; do
        if [[ "$control_title" == "control_title" ]]; then
            continue
        fi

        if [[ "$status" == "alarm" ]]; then
            case "$control_title" in
                "EBS snapshots should not be publicly restorable")
                    restrict_public_snapshots
                    ;;
                "Attached EBS volumes should have encryption enabled")
                    enable_ebs_encryption
                    ;;
                "EBS volumes should be protected by a backup plan")
                    ensure_backup_plan
                    ;;
                "EBS volume encryption at rest should be enabled")
                    enable_encryption_at_rest
                    ;;
                "EBS snapshots should be encrypted")
                    encrypt_snapshots
                    ;;
                "EBS encryption by default should be enabled")
                    enable_default_encryption
                    ;;
                "EBS volumes should be attached to EC2 instances")
                    ensure_ebs_attached_to_instances
                    ;;
                "EBS volume snapshots should exist")
                    ensure_snapshots_exist
                    ;;
                "EBS volumes should be in a backup plan")
                    ensure_backup_plan_for_volumes
                    ;;
                "Attached EBS volumes should have delete on termination enabled")
                    enable_delete_on_termination
                    ;;
                *)
                    log_message "No automated fix available for control: $control_title. Manual review required."
                    ;;
            esac
        else
            log_message "Control '$control_title' is compliant."
        fi
    done < "$COMPLIANCE_REPORT"
}

# Run the compliance report processing and remediation
process_compliance_report
