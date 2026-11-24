mock_provider "alz" {}
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000001"
      subscription_id = "00000000-0000-0000-0000-000000000002"
    }
  }
}
mock_provider "azurerm" {
  alias = "connectivity"
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000001"
      subscription_id = "00000000-0000-0000-0000-000000000003"
    }
  }
}
mock_provider "azurerm" {
  alias = "management"
}
mock_provider "azapi" {}
mock_provider "azapi" {
  alias = "connectivity"
}
mock_provider "local" {}
mock_provider "random" {}
mock_provider "time" {}

override_module {
  target = module.hub_and_spoke_vnet[0].module.regions[0]
  outputs = {
    regions_by_name = {
      saudiarabiaeast = {
        zones = []
      }
    }
  }
}

override_module {
  target = module.config.module.regions
  outputs = {
    regions_by_name = {
      saudiarabiaeast = {
        geo_code   = null
        short_name = "sae"
      }
    }
  }
}

override_module {
  target = module.hub_and_spoke_vnet[0].module.private_dns_zones["primary"].module.regions
  outputs = {
    regions_by_name_or_display_name = {
      saudiarabiaeast = {
        name     = "saudiarabiaeast"
        geo_code = null
      }
    }
  }
}

variables {
  root_parent_management_group_id = "synthetic-validation-parent"
  subscription_ids = {
    management   = "00000000-0000-0000-0000-000000000002"
    identity     = "00000000-0000-0000-0000-000000000004"
    connectivity = "00000000-0000-0000-0000-000000000003"
    security     = "00000000-0000-0000-0000-000000000005"
  }
  management_groups_enabled = false
  enable_telemetry          = false
}


run "sdb_policy_templating" {
  command = plan
  assert {
    condition = (
      jsondecode(local.policy_assignments_to_modify.sdb.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForServers).value == "DeployIfNotExists" &&
      contains(["Disabled", "DeployIfNotExists"], jsondecode(local.policy_assignments_to_modify.sdb.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForArm).value) &&
      contains(["Disabled", "DeployIfNotExists"], jsondecode(local.policy_assignments_to_modify.sdb.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForContainers).value) &&
      jsondecode(local.policy_assignments_to_modify.sdb.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForKeyVault).value == "Disabled"
    )
    error_message = "Approved/deferred Defender parameters must survive real starter encoding without nested value wrappers."
  }
  assert {
    condition = (
      local.policy_assignments_to_modify.platform.policy_assignments["Enforce-GR-Compute0"].enforcement_mode == "DoNotEnforce" &&
      jsondecode(local.policy_assignments_to_modify.platform.policy_assignments["Enforce-GR-Compute0"].parameters.autoHotPatch).value == "Audit" &&
      local.policy_assignments_to_modify.landingzones.policy_assignments["Enforce-GR-PostgreSQL0"].enforcement_mode == "DoNotEnforce" &&
      local.policy_assignments_to_modify.sdb.policy_assignments["Deploy-MDFC-SqlAtp"].enforcement_mode == "DoNotEnforce"
    )
    error_message = "Supported audit effects and ancestor/non-audit effects must retain the approved non-enforcing semantics."
  }
}
