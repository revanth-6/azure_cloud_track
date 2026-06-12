locals {
  # Shared configuration variables and metadata tags
  jwt_secret = "medishift_jwt_secret_key_2026_confidential_compute"
  
  default_tags = merge(
    var.tags,
    {
      DeploymentType = "Terraform-NonContainerized"
      Project        = "MediShift-Healthcare"
      Confidential   = "Intel-SGX-DC1ds"
    }
  )
}
