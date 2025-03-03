#!/bin/bash

# Log function with timestamp
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> remediation_log.txt
}

# Retry loop with exponential backoff
retry_command() {
  local command=$1
  local retries=3
  local delay=5
  local count=0
  local success=0

  while [ $count -lt $retries ]; do
    $command && success=1 && break
    count=$((count + 1))
    log_message "Retrying $command (attempt $count)..."
    sleep $delay
    delay=$((delay * 2))  # Exponential backoff
  done

  if [ $success -eq 0 ]; then
    log_message "Command $command failed after $retries attempts"
  fi
}

# Define remediation functions based on control titles

# 1. EKS Clusters Endpoint Should Restrict Public Access
restrict_public_access() {
  log_message "Restricting public access to EKS endpoint."
  aws eks update-cluster-config --name "$EKS_CLUSTER_NAME" --resources-vpc-config endpointPublicAccess=false
}

# 2. EKS Clusters Should Enable Encryption at Rest for etcd
enable_etcd_encryption() {
  log_message "Enabling encryption at rest for etcd."
  aws eks update-cluster-config --name "$EKS_CLUSTER_NAME" --encryption-config '{"resources":["etcd"]}'
}

# 3. EKS Clusters Should Have Control Plane Audit Logging Enabled
enable_audit_logging() {
  log_message "Enabling Kubernetes audit logging."
  aws eks update-cluster-config --name "$EKS_CLUSTER_NAME" --logging '{"enabled":["api", "audit"]}'
}

# 4. EKS Clusters Should Restrict the Use of Outdated or Unsupported Kubernetes Versions
restrict_outdated_versions() {
  log_message "Restricting outdated Kubernetes versions."
  aws eks update-cluster-version --name "$EKS_CLUSTER_NAME" --kubernetes-version "$LATEST_SUPPORTED_VERSION"
}

# 5. EKS Clusters Should Use IAM Roles for Service Accounts (IRSA) for Fine-Grained Access Control
enable_irsa() {
  log_message "Enabling IAM Roles for Service Accounts (IRSA)."
  aws eks associate-iam-oidc-provider --cluster-name "$EKS_CLUSTER_NAME"
}

# 6. EKS Clusters Should Restrict Inbound Traffic to Only Necessary Services and Ports
restrict_inbound_traffic() {
  log_message "Restricting inbound traffic to necessary services and ports."
  aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 443 --cidr "$ALLOWED_CIDR"
}

# 7. EKS Clusters Should Implement Pod Security Policies (PSP) or OPA-Gatekeeper for Enforcing Security Policies
enable_psp_or_opa() {
  log_message "Implementing Pod Security Policies (PSP) or OPA-Gatekeeper."
  kubectl apply -f opa-gatekeeper-config.yaml
}

# 8. EKS Clusters Should Ensure Nodes Are Not Publicly Accessible
restrict_public_nodes() {
  log_message "Ensuring EKS nodes are not publicly accessible."
  aws ec2 modify-instance-attribute --instance-id "$INSTANCE_ID" --no-source-dest-check
}

# 9. EKS Clusters Should Enable Network Policies for Traffic Control
enable_network_policies() {
  log_message "Enabling network policies for traffic control."
  kubectl apply -f network-policy.yaml
}

# 10. EKS Clusters Should Use Security Groups for Pods (SGP)
enable_sgp() {
  log_message "Enabling Security Groups for Pods (SGP)."
  kubectl apply -f sgp-config.yaml
}

# 11. EKS Clusters Should Enable KMS Encryption for EBS Volumes
enable_ebs_encryption() {
  log_message "Enabling KMS encryption for EBS volumes."
  aws ec2 create-volume --size 10 --availability-zone "$AVAILABILITY_ZONE" --encrypted --kms-key-id "$KMS_KEY_ID"
}

# Process compliance report CSV
process_compliance_report() {
  while IFS=, read -r control_title status; do
    log_message "Processing control: $control_title with status $status"
    
    if [ "$status" == "alarm" ]; then
      case $control_title in
        "EKS Clusters Endpoint Should Restrict Public Access")
          retry_command restrict_public_access
          ;;
        "EKS Clusters Should Enable Encryption at Rest for etcd")
          retry_command enable_etcd_encryption
          ;;
        "EKS Clusters Should Have Control Plane Audit Logging Enabled")
          retry_command enable_audit_logging
          ;;
        "EKS Clusters Should Restrict the Use of Outdated or Unsupported Kubernetes Versions")
          retry_command restrict_outdated_versions
          ;;
        "EKS Clusters Should Use IAM Roles for Service Accounts (IRSA) for Fine-Grained Access Control")
          retry_command enable_irsa
          ;;
        "EKS Clusters Should Restrict Inbound Traffic to Only Necessary Services and Ports")
          retry_command restrict_inbound_traffic
          ;;
        "EKS Clusters Should Implement Pod Security Policies (PSP) or OPA-Gatekeeper for Enforcing Security Policies")
          retry_command enable_psp_or_opa
          ;;
        "EKS Clusters Should Ensure Nodes Are Not Publicly Accessible")
          retry_command restrict_public_nodes
          ;;
        "EKS Clusters Should Enable Network Policies for Traffic Control")
          retry_command enable_network_policies
          ;;
        "EKS Clusters Should Use Security Groups for Pods (SGP)")
          retry_command enable_sgp
          ;;
        "EKS Clusters Should Enable KMS Encryption for EBS Volumes")
          retry_command enable_ebs_encryption
          ;;
        # Add any other control titles here
        *)
          log_message "Manual check is best for the control: $control_title because it may require complex configurations or context-specific decisions."
          ;;
      esac
    fi
  done < compliance_report_EKS.csv
}

# Main Execution
log_message "Starting compliance remediation process."
process_compliance_report
log_message "Compliance remediation process completed."
