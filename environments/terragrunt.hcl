locals {
  # Automatically load account-level variables
  project_vars = read_terragrunt_config(find_in_parent_folders("project.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract the variables we need for easy access
  gcp_region   = local.region_vars.locals.gcp_region
  project_id = local.project_vars.locals.project_id
}

# Generate a GCP provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "google" {
  region = "${local.gcp_region}"
  project = "${local.project_id}"
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in a GCS bucket

remote_state {
  backend = "gcs"

  config = {
    project  = local.project_id # The GCP project where the bucket will be created.
    location = local.gcp_region # The GCP location where the bucket will be created.
    bucket = "ei-test-tfstate" # (Required) The name of the GCS bucket. This name must be globally unique. For more information, see Bucket Naming Guidelines.
    prefix = "${path_relative_to_include()}/terraform.tfstate" #- (Optional) GCS prefix inside the bucket. Named states for workspaces are stored in an object called <prefix>/<name>.tfstate.
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  local.project_vars.locals,
  local.region_vars.locals,
  local.environment_vars.locals,
)