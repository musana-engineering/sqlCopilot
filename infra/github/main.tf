locals {
  region = "eastus2"
  tags = {
    provisioner = "terraform"
  }
}

resource "github_repository" "repository" {
  name        = "sqlCopilot"
  description = "Conversational Analytics on SQL Server with Azure OpenAI"

  visibility         = "public"
  gitignore_template = "Terraform"
  has_issues         = true
  has_discussions    = true
  auto_init          = true
  license_template   = "mit"
}