# Langfuse-Terraform-GCP Fork Changes

This document describes the modifications made to the upstream langfuse-terraform-gcp module to support additional use cases.

## Overview

The changes enable:
1. using an external PostgreSQL instance instead of creating a new one
2. using an existing VPC network instead of creating a new one
3. applying consistent labels to all GCP resources
4. upgrading to Google provider version 7.x

## Detailed Changes

### 1. External PostgreSQL Support

**Motivation**: Allow the module to use an existing PostgreSQL instance (e.g., shared CloudSQL instance) instead of always creating a new dedicated instance.

**Files Modified**:
- `variables.tf`: added `create_postgres_instance`, `external_postgres_host`, `external_postgres_password` variables
- `postgres.tf`: made all postgres resources conditional using `count` based on `create_postgres_instance`
- `langfuse.tf`: added locals `postgres_host` and `postgres_password` that conditionally reference created or external postgres
- `outputs.tf`: added `postgres_password` output that returns the appropriate password

**Behavior**:
- when `create_postgres_instance = true` (default): creates CloudSQL postgres instance as before
- when `create_postgres_instance = false`: uses `external_postgres_host` and `external_postgres_password` variables
- Kubernetes secrets and Helm values automatically use the correct host/password via locals

### 2. External VPC Support

**Motivation**: Allow the module to deploy into an existing VPC network to share VPC peering connections (e.g., CloudSQL private service connection shared between CloudRun and GKE).

**Files Modified**:
- `variables.tf`: added `create_vpc`, `existing_network_name`, `existing_subnetwork_name` variables
- `vpc.tf`:
  - added data sources for existing VPC/subnet
  - made all VPC resources conditional using `count` based on `create_vpc`
  - added locals (`network_name`, `network_id`, `subnetwork_name`) that reference either created or existing resources
- `gke.tf`: updated to use locals instead of direct resource references
- `redis.tf`: updated `authorized_network` to use `local.network_id`
- `postgres.tf`: updated `private_network` to conditionally reference created or existing VPC
- `outputs.tf`: added VPC-related outputs (`network_id`, `network_name`, `network_self_link`, `subnetwork_self_link`)

**Behavior**:
- when `create_vpc = true` (default): creates VPC, subnet, router, NAT, firewall rules, and service connection as before
- when `create_vpc = false`: uses existing VPC/subnet specified by `existing_network_name` and `existing_subnetwork_name`
- implicit dependencies via network references replace explicit `depends_on` for service connections

**Note**: When using an existing VPC, the VPC must already have a service networking connection configured for CloudSQL/Redis private service access.

### 3. Resource Labeling Support

**Motivation**: Apply consistent GCP labels to all resources for cost tracking, organization, and compliance.

**Files Modified**:
- `variables.tf`: added `labels` variable (map of strings)
- `gke.tf`: added `resource_labels = var.labels`
- `redis.tf`: added `labels = var.labels`
- `storage.tf`: added `labels = var.labels`
- `postgres.tf`: added `user_labels = var.labels` to settings block
- `vpc.tf`: added commented placeholder `# labels = var.labels` (network resources have limited label support)

**Behavior**:
- all supported resources now accept labels via the `labels` variable
- labels default to empty map if not specified

### 4. Google Provider Version Upgrade

**Files Modified**:
- `versions.tf`: updated Google provider constraint from `~> 6.0` to `~> 7.0`

**Motivation**: Align with newer provider versions that may have bug fixes or required features.

## Suggested Commit Structure

To organize these changes into logical commits:

### Commit 1: Add Support for External PostgreSQL Instance
```
Add support for external PostgreSQL instance

- add create_postgres_instance, external_postgres_host, external_postgres_password variables
- make postgres resources conditional based on create_postgres_instance
- add locals in langfuse.tf to handle postgres host/password selection
- add postgres_password output
- update kubernetes secrets and helm values to use conditional postgres settings

This allows the module to use an existing CloudSQL instance instead of
always creating a new one, enabling database sharing across services.
```

**Files**: `variables.tf`, `postgres.tf`, `langfuse.tf`, `outputs.tf`

### Commit 2: Add Support for Existing VPC Network
```
Add support for existing VPC network

- add create_vpc, existing_network_name, existing_subnetwork_name variables
- make all vpc resources conditional based on create_vpc
- add data sources to reference existing vpc/subnet when create_vpc is false
- add locals (network_name, network_id, subnetwork_name) to abstract resource references
- update gke, redis, and postgres to use network locals
- add vpc-related outputs
- replace explicit depends_on with implicit dependencies via network references

This enables deploying GKE into an existing VPC to share VPC peering
connections (e.g., CloudSQL private service connection) with other services
like CloudRun.
```

**Files**: `variables.tf`, `vpc.tf`, `gke.tf`, `redis.tf`, `postgres.tf`, `outputs.tf`

### Commit 3: Add Resource Labeling Support
```
Add resource labeling support

- add labels variable to accept map of label key-value pairs
- apply labels to gke cluster, redis instance, storage bucket, and postgres instance
- add commented label placeholders for network resources (limited support)

This enables consistent labeling across all GCP resources for cost tracking,
organization, and compliance purposes.
```

**Files**: `variables.tf`, `gke.tf`, `redis.tf`, `storage.tf`, `postgres.tf`, `vpc.tf`

### Commit 4: Upgrade Google Provider to Version 7.x
```
Upgrade Google provider to version 7.x

Update required Google provider version constraint from ~> 6.0 to ~> 7.0
to align with newer provider versions.
```

**Files**: `versions.tf`

## Testing Recommendations

When testing these changes:

1. **External Postgres**: test with both `create_postgres_instance = true` and `false`
2. **External VPC**: test with both `create_vpc = true` and `false`
3. **VPC Peering**: verify that CloudSQL private service connection works when using existing VPC
4. **Labels**: verify labels appear on all resources in GCP console
5. **Two-Stage Deployment**: test the recommended two-stage apply workflow still works

## Backward Compatibility

All changes are backward compatible:
- default values maintain original behavior (create postgres, create VPC)
- new variables are optional
- existing module users can upgrade without changing their configuration
