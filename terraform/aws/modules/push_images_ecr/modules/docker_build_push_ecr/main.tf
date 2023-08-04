resource "aws_ecr_repository" "repository" {
  name = var.image_name # replace with your repository name
  lifecycle { ignore_changes = [tags] }
}

resource "null_resource" "docker_build_and_push" {
  triggers = {
    dockerfile_hash = sha1(file("${var.dockerfile_path}/Dockerfile"))
  }

  provisioner "local-exec" {
    command = <<EOF
      aws ecr get-login-password --region ${var.aws_region} --profile ${var.aws_profile} | docker login --username AWS --password-stdin ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
      docker build -t ${aws_ecr_repository.repository.repository_url}:${var.image_tag} ${var.dockerfile_path}
      docker push ${aws_ecr_repository.repository.repository_url}:${var.image_tag}
    EOF
  }
}