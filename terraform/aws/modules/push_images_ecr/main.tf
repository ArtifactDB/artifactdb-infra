locals {
  images = [
    {
      image_name_to_pull = "public.ecr.aws/aws-observability/aws-for-fluent-bit"
      image_tag_to_pull  = "2.28.4"
      image_name_to_push = "${var.ecr_repository_name}/fluent-bit"
      image_tag_to_push  = "2.28.4"
    },
    {
      image_name_to_pull = "traefik"
      image_tag_to_pull  = "v2.9.8"
      image_name_to_push = "${var.ecr_repository_name}/traefik"
      image_tag_to_push  = "v2.9.8"
    },
    {
      image_name_to_pull = "bitnami/sealed-secrets-controller"
      image_tag_to_pull  = "v0.17.1"
      image_name_to_push = "${var.ecr_repository_name}/sealed-secrets-controller"
      image_tag_to_push  = "v0.17.1"
    }
  ]
  images_to_build = [
    {
      image_name      = "logstash"
      image_tag       = "opensearch"
      dockerfile_path = "./logstash"
    }
  ]
}

module "docker_pull_push_ecr" {
  for_each           = { for image in local.images : image.image_name_to_pull => image }
  source             = "./modules/docker_pull_push_ecr"
  image_name_to_pull = each.value.image_name_to_pull
  image_tag_to_pull  = each.value.image_tag_to_pull
  image_name_to_push = each.value.image_name_to_push
  image_tag_to_push  = each.value.image_tag_to_push
  aws_account_id     = var.aws_account_id
  aws_region         = var.aws_region
}

module "docker_build_and_push" {
  for_each        = { for image_to_build in local.images_to_build : image_to_build.image_name => image_to_build }
  source          = "./modules/docker_build_push_ecr"
  aws_region      = var.aws_region
  aws_account_id  = var.aws_account_id
  aws_profile     = var.aws_profile
  image_name      = "${var.ecr_repository_name}/${each.value.image_name}"
  image_tag       = each.value.image_tag
  dockerfile_path = each.value.dockerfile_path
}
