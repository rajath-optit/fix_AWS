#!/bin/bash

# Function to log messages
log_message() {
    echo "$(date): $1" >> compliance_remediation_log.txt
}

# Function to check and fix the compliance control (retry mechanism)
retry_compliance_fix() {
    local fix_function=$1
    local retries=3
    local count=0
    local success=0

    # Try up to 3 times to apply the fix
    while [ $count -lt $retries ]; do
        $fix_function
        if [ $? -eq 0 ]; then
            success=1
            break
        else
            count=$((count + 1))
            log_message "Attempt $count failed for $fix_function. Retrying..."
            sleep 5 # Wait 5 seconds before retrying
        fi
    done

    if [ $success -eq 1 ]; then
        log_message "$fix_function applied successfully."
    else
        log_message "$fix_function failed after $retries attempts."
    fi
}

# Functions for S3 compliance checks

# Block public access at account level
block_public_access_account_level() {
    aws s3api put-bucket-public-access-block --bucket $bucket_name --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    log_message "Public access blocked at account level for bucket $bucket_name"
}

# Enable default encryption with KMS
enable_s3_default_encryption() {
    aws s3api put-bucket-encryption --bucket $bucket_name --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'
    log_message "Default encryption enabled with KMS for bucket $bucket_name"
}

# Enable bucket logging
enable_bucket_logging() {
    aws s3api put-bucket-logging --bucket $bucket_name --bucket-logging-status '{"LoggingEnabled":{"TargetBucket":"log-bucket-name","TargetPrefix":"logs/"}}'
    log_message "Logging enabled for bucket $bucket_name"
}

# Enable versioning
enable_versioning() {
    aws s3api put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Enabled
    log_message "Versioning enabled for bucket $bucket_name"
}

# Enable object logging
enable_object_logging() {
    aws s3api put-bucket-object-lock --bucket $bucket_name --object-lock-configuration "ObjectLockEnabled=Enabled,Rule={DefaultRetention={Mode=GOVERNANCE,Days=365}}"
    log_message "Object-level logging enabled for bucket $bucket_name"
}

# Block public read access
block_public_read_access() {
    aws s3api put-bucket-policy --bucket $bucket_name --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::'$bucket_name'/*","Condition":{"StringEquals":{"aws:PrincipalType":"AWS"}}}]}'
    log_message "Public read access blocked for bucket $bucket_name"
}

# Remove ACL usage for access control
remove_acl_usage() {
    aws s3api put-bucket-acl --bucket $bucket_name --acl private
    log_message "Access Control List (ACL) removed for bucket $bucket_name"
}

# Prohibit public access through bucket policy
prohibit_public_access() {
    aws s3api put-bucket-policy --bucket $bucket_name --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Principal":"*","Action":"s3:*","Resource":"arn:aws:s3:::'$bucket_name'/*","Condition":{"StringEquals":{"aws:PrincipalType":"AWS"}}}]}'
    log_message "Public access prohibited by bucket policy for $bucket_name"
}

# Block public access on access points
block_public_access_on_access_points() {
    aws s3control put-public-access-block --account-id $account_id --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    log_message "Public access blocked for access points in account $account_id"
}

# Configure lifecycle policies
configure_lifecycle_policies() {
    aws s3api put-bucket-lifecycle-configuration --bucket $bucket_name --lifecycle-configuration '{"Rules":[{"ID":"DeleteOldFiles","Filter":{"Prefix":""},"Status":"Enabled","Expiration":{"Days":365}}]}'
    log_message "Lifecycle policies configured for bucket $bucket_name"
}

# Prohibit public write access
prohibit_public_write_access() {
    aws s3api put-bucket-policy --bucket $bucket_name --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Principal":"*","Action":"s3:PutObject","Resource":"arn:aws:s3:::'$bucket_name'/*"}]}'
    log_message "Public write access prohibited for bucket $bucket_name"
}

# Ensure ACLs are not accessible to all authenticated users
ensure_acl_not_accessible() {
    aws s3api put-bucket-acl --bucket $bucket_name --acl private
    log_message "ACLs not accessible to all authenticated users for bucket $bucket_name"
}

# Disable static website hosting
disable_static_website_hosting() {
    aws s3api delete-bucket-website --bucket $bucket_name
    log_message "Static website hosting disabled for bucket $bucket_name"
}

# Enable cross-region replication
enable_cross_region_replication() {
    aws s3api put-bucket-replication --bucket $bucket_name --replication-configuration '{"Role":"arn:aws:iam::123456789012:role/replication-role","Rules":[{"Status":"Enabled","Prefix":"","Destination":{"Bucket":"arn:aws:s3:::destination-bucket"}}]}'
    log_message "Cross-region replication enabled for bucket $bucket_name"
}

# Enforce SSL on all S3 endpoints
enforce_ssl() {
    aws s3api put-bucket-policy --bucket $bucket_name --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Principal":"*","Action":"s3:*","Resource":"arn:aws:s3:::'$bucket_name'/*","Condition":{"Bool":{"aws:SecureTransport":"false"}}}]}'
    log_message "SSL enforced for bucket $bucket_name"
}

# Enable MFA delete
enable_mfa_delete() {
    aws s3api put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Enabled,MFADelete=Enabled
    log_message "MFA delete enabled for bucket $bucket_name"
}

# Enable object lock
enable_object_lock() {
    aws s3api put-bucket-object-lock --bucket $bucket_name --object-lock-configuration "ObjectLockEnabled=Enabled,Rule={DefaultRetention={Mode=GOVERNANCE,Days=365}}"
    log_message "Object lock enabled for bucket $bucket_name"
}

# Ensure lifecycle rules for versioned buckets
ensure_lifecycle_rules_for_versioned_buckets() {
    aws s3api put-bucket-lifecycle-configuration --bucket $bucket_name --lifecycle-configuration '{"Rules":[{"ID":"VersionedData","Filter":{"Prefix":""},"Status":"Enabled","Transition":{"Days":30,"StorageClass":"GLACIER"}},{"Expiration":{"Days":365}}]}'
    log_message "Lifecycle rules configured for versioned bucket $bucket_name"
}

# Process the compliance report CSV
process_compliance_report() {
    while IFS=, read -r control_title status; do
        if [ "$status" == "alarm" ]; then
            remediation_function=$(grep "$control_title" security_controls_s3.yaml | awk '{print $2}')
            retry_compliance_fix $remediation_function
        fi
    done < compliance_report_s3.csv
}

# Start processing compliance report
process_compliance_report
