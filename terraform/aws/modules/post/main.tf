data "aws_ssm_parameters_by_path" "secrets" {
  path = var.parameter_path
}

data "aws_ssm_parameters_by_path" "parameters" {
  path = var.parameter_path
}

locals {
  parsed_parameters = jsonencode({
    gprn = "gprn:${var.environment}:platform:${var.platform_id}"
    outputs = {
      for idx, name in data.aws_ssm_parameters_by_path.parameters.names :
      element(split("/", name), length(split("/", name)) - 1) => jsondecode(data.aws_ssm_parameters_by_path.parameters.values[idx])
    }
  })
}

resource "null_resource" "store" {
  triggers = { always = timestamp() }
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    working_dir = var.terragrunt_dir
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
            set -e
            aws eks update-kubeconfig --name "${var.cluster_name}" --profile ${var.aws_profile} --region ${var.aws_region}
            kubectl get ns ${var.olympus_ns} || kubectl create ns ${var.olympus_ns}
            echo '${local.parsed_parameters}' > temp.json
            kubectl -n ${var.olympus_ns} create secret generic ${var.olympus_secret_name} --from-file=${var.olympus_secret_name}=temp.json --save-config --dry-run=client -o yaml | kubectl apply -f -
            rm temp.json
EOT
  }
}
