#!/bin/bash

# Path to the compliance report (CSV)
COMPLIANCE_REPORT="compliance_report.csv"

# Log file to record actions taken
LOG_FILE="remediation_log.txt"

# Function to log messages with timestamp
log_message() {
    local message=$1
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
}

# Function to fix EC2 stopped instances
fix_stopped_instances() {
    log_message "Fixing stopped EC2 instances that have been stopped for over 30 days."
    aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name,LaunchTime]" --output text | \
    awk '$2 == "stopped" && (system("date -d \"$(echo $3)\" +%s") < $(date +%s -d "-30 days")) {print $1}' | \
    xargs -I {} aws ec2 terminate-instances --instance-ids {}
    log_message "Stopped EC2 instances removed."
}

# Function to ensure EC2 instances are in a VPC
ensure_ec2_in_vpc() {
    log_message "Ensuring EC2 instances are in a VPC."
    aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId, NetworkInterfaces[].VpcId]" --output text | \
    awk '{if ($2 == "") print $1}' | \
    xargs -I {} echo "Instance {} is not in a VPC, please review manually."
    log_message "EC2 instance VPC check completed."
}

# Function to disable public IPs on EC2 launch templates
disable_public_ips() {
    log_message "Disabling public IPs on EC2 launch templates."
    aws ec2 describe-launch-templates --query "LaunchTemplates[].LaunchTemplateName" --output text | \
    while read template; do
        aws ec2 modify-launch-template --launch-template-name "$template" --no-assign-public-ip
    done
    log_message "Public IPs disabled on EC2 launch templates."
}

# Function to ensure AMIs are encrypted
ensure_ami_encryption() {
    log_message "Ensuring all AMIs are encrypted."
    aws ec2 describe-images --query "Images[].[ImageId,Encrypted]" --output text | \
    awk '$2 == "false" {print $1}' | \
    xargs -I {} aws ec2 modify-image-attribute --image-id {} --no-encryption
    log_message "AMI encryption check completed."
}

# Function to process the compliance report
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
                "EC2 instances should be in a VPC")
                    ensure_ec2_in_vpc
                    ;;
                "AWS EC2 launch templates should not assign public IPs to network interfaces")
                    disable_public_ips
                    ;;
                "Ensure Images (AMI's) are encrypted")
                    ensure_ami_encryption
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
