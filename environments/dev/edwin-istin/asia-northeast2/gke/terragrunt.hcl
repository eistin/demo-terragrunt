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
  source = "https://github.com/eistin/tf-module-gcp-gke.git"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
	# --- GLOBAL
	project_id 		= local.project_id
	name				 	= "demo"
	regional 			= false
	region 				= local.region_vars.locals.gcp_region
	zones 				= slice(local.region_vars.locals.gcp_zones, 0, 1)
	deletion_protection = false

	# --- SERVICE ACCOUNT
	create_service_account = false

	# --- KUBERNETES
	kubernetes_version = "1.28.7-gke.1026000"

	# --- NETWORK
	network = dependency.vpc.outputs.network_name
	network_project_id = dependency.vpc.outputs.project_id
  subnetwork = dependency.vpc.outputs.subnets_names[0]
	ip_range_services = dependency.vpc.outputs.subnets_secondary_ranges[0][0].range_name
	ip_range_pods = dependency.vpc.outputs.subnets_secondary_ranges[0][1].range_name

	# --- PRIVATE
  enable_private_endpoint = false
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "172.16.0.0/28"

	master_authorized_networks = [
		{
			cidr_block = local.ip
			display_name = "edwin"
		}
	]

	# --- NODEPOOLS
	node_pools = [
		{
			name 			= "demo"
			min_count 		= 1
			max_count 		= 3
			# Mandatory when release_channel REGULAR is set.
			auto_upgrade 	= true
			machine_type	= "e2-small"
		}
	]

	node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
	}

	node_pools_labels = {
		demo = {
			app = "demo"
		}
	}

	node_pools_tags = {
		demo = [
			"demo",
			"ingress"
		]
	}
}