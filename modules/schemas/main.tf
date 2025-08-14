resource "confluent_schema" "schemas" {
  for_each = var.schemas

  schema_registry_cluster {
    id = var.schema_registry_id
  }
  
  subject_name = each.key
  format       = lookup(each.value, "format", "AVRO")
  schema       = file(each.value.schema_file)
  
  lifecycle {
    prevent_destroy = true
  }
} 