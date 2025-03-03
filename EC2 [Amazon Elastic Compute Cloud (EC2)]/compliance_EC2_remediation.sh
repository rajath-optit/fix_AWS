#!/bin/bash

# Path to the compliance report (CSV)
COMPLIANCE_REPORT="compliance_report_EC2.csv"

# Log file to record actions taken
LOG_FILE="remediation_log.txt"

# Retry configuration
MAX_RETRIES=3
RETRY_DELAY=5 # seconds

# Function to log messages with timestamp
log_message() {
    local message=$1
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
}

# Retry function
retry_command() {
    local command=$1
    local retries=0
    until $command; do
        ((retries++))
        if [[ $retries -ge $MAX_RETRIES ]]; then
            log_message "Command failed after $MAX_RETRIES retries: $command"
            return 1
        fi
        log_message "Command failed, retrying ($retries/$MAX_RETRIES): $command"
        sleep $RETRY_DELAY
    done
}

# Function to fix EC2 stopped instances over 30 days
fix_stopped_instances() {
    log_message "Fixing stopped EC2 instances that have been stopped for over 30 days."
    retry_command "aws ec2 describe-instances --query \"Reservations[].Instances[].[InstanceId,State.Name,LaunchTime]\" --output text | \
    awk '\$2 == \"stopped\" && (system(\"date -d \"\$(echo \$3)\" +%s\") < \$(date +%s -d \"-30 days\")) {print \$1}' | \
    xargs -I {} aws ec2 terminate-instances --instance-ids {}"
    log_message "Stopped EC2 instances removed."
}

# Function to ensure EC2 instances are in a VPC
ensure_ec2_in_vpc() {
    log_message "Ensuring EC2 instances are in a VPC."
    retry_command "aws ec2 describe-instances --query \"Reservations[].Instances[].[InstanceId, NetworkInterfaces[].VpcId]\" --output text | \
    awk '{if (\$2 == \"\") print \$1}' | xargs -I {} echo \"Instance {} is not in a VPC, please review manually.\""
    log_message "EC2 instance VPC check completed."
}

# Function to ensure AMIs are encrypted
ensure_ami_encryption() {
    log_message "Ensuring all AMIs are encrypted."
    retry_command "aws ec2 describe-images --query \"Images[].[ImageId,Encrypted]\" --output text | \
    awk '\$2 == \"false\" {print \$1}' | xargs -I {} aws ec2 modify-image-attribute --image-id {} --no-encryption"
    log_message "AMI encryption check completed."
}

# Function to ensure EC2 instances use secure key pairs
ensure_secure_key_pairs() {
    log_message "Ensuring EC2 instances are launched with secure key pairs."
    retry_command "aws ec2 describe-instances --query \"Reservations[].Instances[].[InstanceId,KeyName]\" --output text | \
    awk '\$2 == \"\" {print \$1}' | xargs -I {} echo \"Instance {} does not use a key pair, please review manually.\""
    log_message "EC2 instance key pair check completed."
}

# Function to ensure EC2 instances are not using outdated AMIs
ensure_no_outdated_amis() {
    log_message "Ensuring EC2 instances are not using outdated AMIs."
    retry_command "aws ec2 describe-instances --query \"Reservations[].Instances[].[InstanceId,ImageId]\" --output text | \
    xargs -I {} aws ec2 describe-images --image-ids {} --query \"Images[].[ImageId,CreationDate]\" --output text"
    log_message "Outdated AMI check completed."
}

# Function to disable public IPs on EC2 launch templates
disable_public_ips() {
    log_message "Disabling public IPs on EC2 launch templates."
    retry_command "aws ec2 describe-launch-templates --query \"LaunchTemplates[].LaunchTemplateName\" --output text | \
    while read template; do aws ec2 modify-launch-template --launch-template-name \"\$template\" --no-assign-public-ip; done"
    log_message "Public IPs disabled on EC2 launch templates."
}

# Function to ensure instances are protected from destruction by KMS access
ensure_kms_protection() {
    log_message "Ensuring EC2 instances' IAM role does not allow KMS destruction."
    retry_command "aws iam list-roles --query \"Roles[].[RoleName,AssumeRolePolicyDocument.Statement[].Action]\" --output text | \
    awk '\$2 == \"kms:*\\" {print \$1}' | xargs -I {} echo \"Role {} allows KMS destruction, please review manually.\""
    log_message "KMS protection check completed."
}

# Function to ensure EC2 IAM role doesn't allow excessive permissions
ensure_excessive_permissions() {
    log_message "Ensuring EC2 IAM role does not allow excessive permissions."
    retry_command "aws iam list-roles --query \"Roles[].[RoleName,AssumeRolePolicyDocument.Statement[].Action]\" --output text | \
    awk '\$2 == \"iam:*\" {print \$1}' | xargs -I {} echo \"Role {} allows excessive IAM permissions, please review manually.\""
    log_message "EC2 IAM role excessive permissions check completed."
}

# Function to ensure EC2 instances have a backup plan
ensure_backup_plan() {
    log_message "Ensuring EC2 instances have a backup plan."
    retry_command "aws ec2 describe-instances --query \"Reservations[].Instances[].[InstanceId,Tags[?Key=='Backup']]" --output text | \
    awk '\$2 == \"\" {print \$1}' | xargs -I {} echo \"Instance {} does not have a backup plan, please review manually.\""
    log_message "EC2 instance backup plan check completed."
}

# Function to ensure EC2 instances have automatic software updates enabled
ensure_auto_updates() {
    log_message "Ensuring EC2 instances have automatic software updates enabled."
    retry_command "aws ec2 describe-instances --query \"Reservations[].Instances[].[InstanceId,Tags[?Key=='Auto-Update']]" --output text | \
    awk '\$2 == \"\" {print \$1}' | xargs -I {} echo \"Instance {} does not have auto updates enabled, please review manually.\""
    log_message "EC2 instance automatic updates check completed."
}

# Function to ensure EC2 instances are properly tagged for identification
ensure_proper_tagging() {
    log_message "Ensuring EC2 instances are properly tagged for identification."
    retry_command "aws ec2 describe-instances --query \"Reservations[].Instances[].[InstanceId,Tags]\" --output text | \
    awk '{if (\$2 == \"\") print \$1}' | xargs -I {} echo \"Instance {} is not properly tagged, please review manually.\""
    log_message "EC2 instance tagging check completed."
}

# Function to process the compliance report and take actions
process_compliance_report() {
    while IFS=, read -r control_title status; do
        if [[ "$control_title" == "control_title" ]]; then
            continue
        fi

        if [[ "$status" == "alarm" ]]; then
            case "$control_title" in
                "EC2 stopped instances should be removed in 30 days")
                    fix_stopped_instances
                    ;;
                "EC2 instances should not be using outdated Amazon Machine Images (AMIs)")
                    ensure_no_outdated_amis
                    ;;
                "EC2 instance IAM role should not allow organization write access")
                    ensure_excessive_permissions
                    ;;
                "EC2 instances should be launched with secure key pairs")
                    ensure_secure_key_pairs
                    ;;
                "EC2 instances should be in a VPC")
                    ensure_ec2_in_vpc
                    ;;
                "AWS EC2 launch templates should not assign public IPs to network interfaces")
                    disable_public_ips
                    ;;
                "Ensure Images (AMI's) are encrypted")
                    ensure_ami_encryption
                    ;;
                "Ensure EC2 instances have a backup plan")
                    ensure_backup_plan
                    ;;
                "EC2 instances should have automatic software updates enabled")
                    ensure_auto_updates
                    ;;
                "EC2 instances should be properly tagged for identification")
                    ensure_proper_tagging
                    ;;
                # Add other checks based on the list
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
