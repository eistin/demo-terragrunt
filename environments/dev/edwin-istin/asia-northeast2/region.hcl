# Set common variables for the region. This is automatically pulled in in the root terragrunt.hcl configuration to
# configure the remote state bucket and pass forward to the child modules as inputs.
locals {
  gcp_region = "asia-northeast2"
  gcp_zones = [
    "asia-northeast2-a",
    "asia-northeast2-b",
    "asia-northeast2-c"
  ]
}