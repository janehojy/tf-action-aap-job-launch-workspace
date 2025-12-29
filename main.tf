terraform {
  required_providers {
    aap = {
      source  = "ansible/aap"
      version = "1.4.0"
    }
  }
}


provider "aap" {
}

locals {
  organization_name = "Default"
}

data "aap_inventory" "this" {
  name              = "localhost-inventory"
  organization_name = local.organization_name
}

data "aap_job_template" "this" {
  name              = "basic-template"
  organization_name = local.organization_name
}

locals {
  valid_var_from_tf_aap_job_launch = ["success", "fail"]
}

variable "var_from_tf_aap_job_launch" {
  description = "Variable to pass to the AAP Job and this determines whether the playbook succeeds or fails"
  type        = string

  validation {
    condition     = contains(local.valid_var_from_tf_aap_job_launch, var.var_from_tf_aap_job_launch)
    error_message = "Valid values for var: var_from_tf_aap_job_launch are (${jsonencode(local.valid_var_from_tf_aap_job_launch)})."
  }
}

variable "aap_job_launch_wait_for_completion" {
  description = "When this is set to true, Terraform will wait until this aap_job resource is created, reaches any final status and then, proceeds with the following resource operation"
  type        = bool
}

resource "terraform_data" "trigger" {
  input = var.var_from_tf_aap_job_launch

  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.aap_job_launch.this]
    }
  }
}

action "aap_job_launch" "this" {
  config {
    extra_vars          = jsonencode({ "var_from_tf_aap_job_launch" : var.var_from_tf_aap_job_launch })
    job_template_id     = data.aap_job_template.this.id
    wait_for_completion = var.aap_job_launch_wait_for_completion
  }
}
