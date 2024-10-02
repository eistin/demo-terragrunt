locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  project_vars = read_terragrunt_config(find_in_parent_folders("project.hcl"))
  myip = read_terragrunt_config("${dirname(find_in_parent_folders())}/_envcommon/myip.hcl")

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
  project_id = local.project_vars.locals.project_id
  ip = local.myip.locals.myip
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "https://github.com/eistin/tf-module-gcp-cloudsql.git?ref=v1.2.3"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "secret" {
  config_path = "../secrets"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
	# --- GLOBAL
	project_id						= local.project_id
	name									= "demo"
	database_version  		= "MYSQL_5_6"
	zone                 	= "asia-northeast2-a"
  region               	= "asia-northeast2"
  tier                 	= "db-n1-standard-1"
	deletion_protection		= false
	availability_type 		= "ZONAL"

	db_name 							= "counter_db"
	user_name         		= "user"
  user_password 				= dependency.secret.outputs.secret_data

	ip_configuration = {
    ipv4_enabled        = true
    private_network     = dependency.vpc.outputs.network_self_link
    authorized_networks = [
			{
				name = "edwin"
				value = local.ip
			}
		]
  }

}