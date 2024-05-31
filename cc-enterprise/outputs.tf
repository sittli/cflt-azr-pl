output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${data.confluent_environment.cc_env.id}
  Kafka Cluster ID: ${confluent_kafka_cluster.private_cluster.id}
  EOT

  sensitive = true
}