
resource "null_resource" "extract_outputs" {
    triggers = {
        # TODO: well this doesn't work, I get a different hash all the time... within a tf console, it works though... ?
        hash = sha1(join("", [for f in sort(fileset("${var.terragrunt_dir}/..", format("{%s}/**/.terragrunt-source-version",join(",",keys(var.modules))))): filesha1("${var.terragrunt_dir}/../${f}")]))
    }
    provisioner "local-exec" {
        on_failure  = fail
        when = create
        command = format("%s %s","python3 ${var.module_dir}/outputdumper.py", join(",",values(var.modules)))
        working_dir = var.terragrunt_dir
    }
}

# TODO: use secret manager more globally?
resource "aws_secretsmanager_secret" "outputs" {
  # can't use GPRN notation with colon, not allowedim ASM
  name = "gprn-${var.env}-artifactdb--secret-tfoutputs"
  # trying to match ADB instance's secrets format/tags
  tags = {
    gprn = "gprn:${var.env}:artifactdb:${lower(var.platform_name)}:secret:${var.olympus_secret_name}"
    env = var.env
    platform_name = var.platform_name
    platform_id = lower(var.platform_name)
  }
}


resource "aws_secretsmanager_secret_version" "outputs" {
  secret_id = aws_secretsmanager_secret.outputs.id
  secret_string = file("${var.terragrunt_dir}/outputs.json")
  depends_on = [null_resource.extract_outputs]
}


resource "null_resource" "store" {
    triggers = {
        hash = null_resource.extract_outputs.triggers.hash
    }
    depends_on = [aws_secretsmanager_secret_version.outputs]
    provisioner "local-exec" {
        on_failure  = fail
        when = create
        working_dir = var.terragrunt_dir
        interpreter = ["/bin/bash","-c"]
        command = <<EOT
            set -e
            kubectl get ns ${var.olympus_ns} || kubectl create ns ${var.olympus_ns}
            kubectl -n ${var.olympus_ns} create secret generic ${var.olympus_secret_name} --from-file=${var.olympus_secret_name}=outputs.json --save-config --dry-run=client -o yaml | kubectl apply -f -
            rm outputs.json
            
EOT
    }
}
