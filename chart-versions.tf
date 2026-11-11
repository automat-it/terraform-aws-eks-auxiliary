### Default Helm chart versions
# Read from the tracking chart chart-versions/Chart.yaml, which Dependabot (helm ecosystem) keeps up to date.
# Override per service with services.<key>.helm_version.
locals {
  chart_versions = { for d in yamldecode(file("${path.module}/chart-versions/Chart.yaml")).dependencies : d.name => d.version }
}
