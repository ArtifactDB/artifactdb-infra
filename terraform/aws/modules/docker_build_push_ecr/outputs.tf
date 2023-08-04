output "ecr_image_url" {
  value = aws_ecr_repository.repository.repository_url
}

output "image_name" {
  value = var.image_name
}

output "image_tag" {
  value = var.image_tag
}