locals {
  # Automatically load environment-level variables
  environment_vars  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars       = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  project_vars      = read_terragrunt_config(find_in_parent_folders("project.hcl"))

  # Extract out common variables for reuse
  env         = local.environment_vars.locals.environment
  project_id  = local.project_vars.locals.project_id
  subnet_name = "gke"
}

dependency "project_services" {
  config_path = "../project_services"
}
# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "https://github.com/eistin/tf-module-gcp-network.git"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  project_id = local.project_id
  network_name = "demo-vpc"
  subnets = [
    {
      subnet_name   = local.subnet_name
      subnet_ip     = "10.30.0.0/20"
      subnet_region = local.region_vars.locals.gcp_region
      subnet_private_access = "true"
    }
  ]

  secondary_ranges = {
    (local.subnet_name) = [
      {
        range_name    = "ip-range-svc"
        ip_cidr_range = "10.30.16.0/20"
      },
      {
        range_name    = "ip-range-pods"
        ip_cidr_range = "10.31.0.0/16"
      },
    ]
  }

  create_nat_gateway = true

  private_services_networks = [
    {
      name = "cloudsql"
      prefix_length = 24
    }
  ]
}