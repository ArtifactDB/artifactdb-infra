output "endpoint" {
  value = aws_opensearch_domain.opensearch.endpoint
}

output "dashboard_endpoint" {
  value = aws_opensearch_domain.opensearch.dashboard_endpoint
}

output "arn" {
  value = aws_opensearch_domain.opensearch.arn
}
