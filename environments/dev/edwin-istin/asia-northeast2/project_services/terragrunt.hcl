locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  project_vars = read_terragrunt_config(find_in_parent_folders("project.hcl"))

  # Extract out common variables for reuse
  project_id = local.project_vars.locals.project_id
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "https://github.com/eistin/tf-module-gcp-project-services.git"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
	project_id                  = local.project_id
  enable_apis                 = true
  disable_services_on_destroy = false

  activate_apis = [
    "compute.googleapis.com",
		"container.googleapis.com",
		"servicenetworking.googleapis.com",
		"iap.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com"
  ]
}