image:
  repository: ${docker_repo}
  tag: ${image_tag}
  pullPolicy: IfNotPresent


cloudWatchLogs:
  region: ${region}
  logGroupName: ${log_group_name}
  logGroupTemplate: ${log_group_template}
  logRetentionDays: ${log_retention_days}

serviceAccount:
  create: true
  name: ${service_account_name}
  annotations: {'eks.amazonaws.com/role-arn': '${service_account_role_arn}'}


service:
  extraParsers: |
    [PARSER]
        Name   logfmt
        Format logfmt
# extra filter to exclude debug logs
additionalFilters: |
  [FILTER]
      Name    grep
      Match   *
      Exclude log lvl=debug*
firehose:
  enabled: false
kinesis:
  enabled: false
elasticsearch:
  enabled: false