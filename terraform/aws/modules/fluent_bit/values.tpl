image:
  repository: ${docker_repo}
  tag: 2.28.4
  pullPolicy: IfNotPresent

cloudWatch:
  region: ${region}
  logGroupName: ${log_group_name}
  logGroupTemplate: ${log_group_template}
  logRetentionDays: 7

cloudWatchLogs:
  region: ${region}
  logGroupName: ${log_group_name}
  logGroupTemplate: ${log_group_template}
  logRetentionDays: 7

serviceAccount:
  create: true
  name: ${service_account_name}
  annotations: {eks.amazonaws.com/role-arn = ${service_account_role_arn}}


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