# ------------------------------------------------------------------------------------------------
# adf - RBAC para Managed Identity
# ------------------------------------------------------------------------------------------------

resource "azurerm_role_assignment" "adf_to_kv" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.adf_principal_id
}



# ------------------------------------------------------------------------------------------------
# adf - linked services - Managed Private Endpoints
# ------------------------------------------------------------------------------------------------

resource "azurerm_data_factory_managed_private_endpoint" "mpe" {
  for_each = {
    kv     = { id = var.key_vault_id,     sub = "vault" }
    storage = { id = var.storage_account_id, sub = "dfs" }
  }

  name               = "pe-${each.key}-to-adf"
  data_factory_id    = var.adf_id
  target_resource_id = each.value.id
  subresource_name   = each.value.sub
  
}


# ------------------------------------------------------------------------------------------------
# adf - linked services - Resources
# ------------------------------------------------------------------------------------------------

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "ls_storage" {
  name                = "ls-storage"
  data_factory_id     = var.adf_id
  url                 = var.storage_account_primary_dfs_endpoint
  use_managed_identity = true
  integration_runtime_name = var.integration_runtime_name

  depends_on = [
    azurerm_data_factory_managed_private_endpoint.mpe["storage"]
  ]

}


resource "azurerm_data_factory_linked_service_key_vault" "ls_kv" {
  name                     = "ls-keyvault"
  data_factory_id          = var.adf_id
  key_vault_id             = var.key_vault_id
  integration_runtime_name = var.integration_runtime_name

  depends_on = [
    azurerm_data_factory_managed_private_endpoint.mpe["kv"],
    azurerm_role_assignment.adf_to_kv
  ]
}


resource "azurerm_data_factory_linked_custom_service" "ls_mongo_onprem" {
  count = var.enable_mongo_linked_service ? 1 : 0

  name            = "ls-mongo-onprem"
  data_factory_id = var.adf_id
  type            = "MongoDbV2"
  description     = "Linked service para MongoDB On-Premise"

  type_properties_json = jsonencode({
    connectionString = {
      type = "AzureKeyVaultSecret"
      store = {
        referenceName = "ls-keyvault" # El nombre de un LS hacia el Key Vault
        type          = "LinkedServiceReference"
      }
      secretName = "mongo-connection-string"
    }
    database = "ecommerce_suscripciones"
  })

  depends_on = [azurerm_data_factory_linked_service_key_vault.ls_kv]

  integration_runtime {
    name = var.integration_runtime_name_local
  }

  annotations = [
    "on-premise",
    "mongodb",
    "production"
  ]
}


# --------------------------------------------------------------------------------
# Datasets
# --------------------------------------------------------------------------------

resource "azurerm_data_factory_custom_dataset" "ds_adls_sink" {
  count = var.enable_mongo_linked_service ? 1 : 0

  name            = "ds_adls_sink_generic"
  data_factory_id = var.adf_id
  type            = "Json"

  linked_service {
    name = azurerm_data_factory_linked_service_data_lake_storage_gen2.ls_storage.name
  }

  parameters = {
    fileName = "String"
  }

  type_properties_json = jsonencode({
    location = {
      type       = "AzureBlobFSLocation"
      fileSystem = "bronze"
      folderPath = "mongodb"
      fileName   = "@dataset().fileName"
    }
    encodingName = "UTF-8"
  })
}


resource "azurerm_data_factory_custom_dataset" "ds_mongo_source" {
  count = var.enable_mongo_linked_service ? 1 : 0

  name            = "ds_mongo_generic"
  data_factory_id = var.adf_id
  type            = "MongoDbV2Collection"

  linked_service {
    name = azurerm_data_factory_linked_custom_service.ls_mongo_onprem[0].name
  }

  parameters = {
    collectionName = "String"
  }

  type_properties_json = jsonencode({
    collection = "@dataset().collectionName"
  })
}

resource "azurerm_data_factory_dataset_json" "ds_watermark" {
  count = var.enable_mongo_linked_service ? 1 : 0

  name                = "ds_watermark_control"
  data_factory_id     = var.adf_id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.ls_storage.name

  azure_blob_storage_location {
    container = "control"
    path      = ""
    filename  = "watermark.json"
  }

  encoding = "UTF-8"
}





# Pipeline

resource "azurerm_data_factory_pipeline" "pl_mongo_incremental" {
  count           = var.enable_mongo_linked_service ? 1 : 0
  name            = "pl-mongo-incremental"
  data_factory_id = var.adf_id
  description     = "Copia incremental de MongoDB hacia Bronze usando watermark por colección"

  parameters = {
    collections = jsonencode(var.mongo_collections)
  }

  variables = {
    vRunStart = "String"
  }

  activities_json = jsonencode([
    {
      name = "Set_RunStart"
      type = "SetVariable"
      typeProperties = {
        variableName = "vRunStart"
        value = {
          value = "@utcnow()"
          type  = "Expression"
        }
      }
    },
    {
      name = "Lookup_Watermark"
      type = "Lookup"
      dependsOn = [
        { activity = "Set_RunStart", dependencyConditions = ["Succeeded"] }
      ]
      typeProperties = {
        source  = { type = "JsonSource" }
        dataset = {
          referenceName = "ds_watermark_control"
          type          = "DatasetReference"
        }
      }
    },
    {
      name = "ForEach_Collection"
      type = "ForEach"
      dependsOn = [
        { activity = "Lookup_Watermark", dependencyConditions = ["Succeeded"] }
      ]
      typeProperties = {
        items        = { value = "@pipeline().parameters.collections", type = "Expression" }
        isSequential = false
        activities = [
          {
            name = "Copy_Incremental"
            type = "Copy"
            typeProperties = {
              source = {
                type   = "MongoDbV2Source"
                filter = "@concat('{ \"created_at\": { \"$gt\": { \"$date\": \"', activity('Lookup_Watermark').output.firstRow[item()], '\" } } }')"
              }
              sink = {
                type = "JsonSink"
                storeSettings = {
                  type         = "AzureBlobFSWriteSettings"
                  copyBehavior = "MergeFiles"
                }
                formatSettings = { type = "JsonWriteSettings" }
              }
            }
            inputs = [
              {
                referenceName = "ds_mongo_generic"
                type          = "DatasetReference"
                parameters    = { collectionName = "@item()" }
              }
            ]
            outputs = [
              {
                referenceName = "ds_adls_sink_generic"
                type          = "DatasetReference"
                parameters    = { fileName = "@concat(item(), '_incr_', '.json')" }
              }
            ]
          }
        ]
      }
    },
    {
      name = "Update_Watermark"
      type = "WebActivity"
      dependsOn = [
        { activity = "ForEach_Collection", dependencyConditions = ["Succeeded"] }
      ]
      typeProperties = {
        url    = "https://${var.storage_account_name}.dfs.core.windows.net/control/watermark.json"
        method = "PUT"
        headers = {
          "x-ms-version"   = "2021-08-06"
          "x-ms-blob-type" = "BlockBlob"
          "Content-Type"   = "application/json"
        }
        body = jsonencode({
          for coll in var.mongo_collections : coll => "@{variables('vRunStart')}"
        })
        authentication = {
          type     = "MSI"
          resource = "https://storage.azure.com/"
        }
      }
    }
  ])

  depends_on = [
    azurerm_data_factory_custom_dataset.ds_mongo_source,
    azurerm_data_factory_custom_dataset.ds_adls_sink,
    azurerm_data_factory_dataset_json.ds_watermark
  ]
}

