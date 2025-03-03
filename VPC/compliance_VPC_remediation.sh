#!/bin/bash

LOG_FILE="compliance_remediation.log"
SECURITY_CONTROLS="security_controls.yaml"
COMPLIANCE_REPORT="compliance_report_VPC.csv"

# Logging function
log_message() {
    echo "$(date) - $1" | tee -a "$LOG_FILE"
}

# Extract security group IDs from the compliance report
get_sg_ids_from_report() {
    awk -F',' '/^sg-/ {print $1}' "$COMPLIANCE_REPORT"
}

# Function to revoke and authorize security group ingress rules
restrict_sg_ingress() {
    local sg_id=$1
    local ports=($2)  # Space-separated list of ports
    local protocol=$3
    log_message "Restricting ingress for SG: $sg_id"

    for port in "${ports[@]}"; do
        log_message "Revoking public access to port $port on $sg_id"
        aws ec2 revoke-security-group-ingress --group-id "$sg_id" --protocol "$protocol" --port "$port" --cidr 0.0.0.0/0
        
        log_message "Authorizing restricted access to port $port on $sg_id"
        aws ec2 authorize-security-group-ingress --group-id "$sg_id" --protocol "$protocol" --port "$port" --cidr <your-trusted-ip>/32
    done
}

# Function to enforce AMI encryption
ensure_ami_encryption() {
    log_message "Checking AMI encryption"
    ami_ids=$(aws ec2 describe-images --owners self --query 'Images[?Encrypted==`false`].ImageId' --output text)

    for ami_id in $ami_ids; do
        log_message "Encrypting AMI: $ami_id"
        aws ec2 copy-image --source-image-id "$ami_id" --source-region "$(aws configure get region)" --name "Encrypted-$ami_id" --encrypted
    done
}

# Function to ensure instances are inside a VPC
ensure_ec2_in_vpc() {
    log_message "Checking if all EC2 instances are inside a VPC"
    instance_ids=$(aws ec2 describe-instances --query 'Reservations[*].Instances[?VpcId==null].InstanceId' --output text)

    for instance_id in $instance_ids; do
        log_message "Instance $instance_id is outside VPC! Investigate and migrate."
    done
}

# Function to disable public IPs
disable_public_ips() {
    log_message "Disabling public IP assignment in launch templates"
    template_ids=$(aws ec2 describe-launch-templates --query 'LaunchTemplates[*].LaunchTemplateId' --output text)

    for template_id in $template_ids; do
        log_message "Updating launch template $template_id to disable public IPs"
        aws ec2 modify-launch-template --launch-template-id "$template_id" --default-version-number 1 \
            --launch-template-data '{"NetworkInterfaces":[{"AssociatePublicIpAddress": false}]}'
    done
}

# Function to process compliance report
process_compliance_report() {
    log_message "Processing compliance report..."
    
    while IFS=',' read -r sg_id control status; do
        if [[ "$status" == "alarm" ]]; then
            case "$control" in
                "Restrict MongoDB Port")
                    restrict_sg_ingress "$sg_id" "27017 27018" "tcp"
                    ;;
                "Restrict Oracle Port")
                    restrict_sg_ingress "$sg_id" "1521 2483" "tcp"
                    ;;
                "Ensure AMI Encryption")
                    ensure_ami_encryption
                    ;;
                "Ensure Instances in VPC")
                    ensure_ec2_in_vpc
                    ;;
                "Disable Public IPs")
                    disable_public_ips
                    ;;
                *)
                    log_message "No remediation defined for control: $control"
                    ;;
            esac
        fi
    done < "$COMPLIANCE_REPORT"
}

# Main execution
log_message "Starting Compliance Remediation..."
process_compliance_report
log_message "Compliance Remediation Completed!"
