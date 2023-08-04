output "created_ecr_repositories" {
  description = "ECR repositories created"
  value = merge(
    {
      for key, value in module.docker_pull_push_ecr :
      key => {
        ecr_image_url = value.ecr_image_url
        image_tag     = value.image_tag
      }
    },
    {
      for key, value in module.docker_build_and_push :
      key => {
        ecr_image_url = value.ecr_image_url
        image_tag     = value.image_tag
      }
    },
  )
}