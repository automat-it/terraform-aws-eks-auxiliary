{{/*
Expand the name of the chart.
*/}}
{{- define "application.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "application.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "application.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "application.labels" -}}
helm.sh/chart: {{ include "application.chart" . }}
{{ include "application.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "application.selectorLabels" -}}
app.kubernetes.io/name: {{ include "application.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resolve upstream IP to forward to.
Order:
1) values.upstream.clusterIP if provided
2) lookup Service clusterIP for values.upstream.serviceName in values.upstream.namespace when useService=true
3) join values.upstream.ips when useService=false
Fail if none found.
*/}}
{{- define "nodelocal.resolveUpstream" -}}
{{- $ctx := . -}}
{{- $res := dict "ip" "" -}}
{{- if $ctx.Values.upstream.clusterIP -}}
  {{- $_ := set $res "ip" $ctx.Values.upstream.clusterIP -}}
{{- else if $ctx.Values.upstream.useService -}}
  {{- with (lookup "v1" "Service" $ctx.Values.upstream.namespace $ctx.Values.upstream.serviceName) -}}
    {{- $_ := set $res "ip" (index . "spec" "clusterIP") -}}
  {{- end -}}
{{- else -}}
  {{- $_ := set $res "ip" (join " " $ctx.Values.upstream.ips) -}}
{{- end -}}
{{- if not (get $res "ip") -}}
  {{- if and (not $ctx.Values.upstream.useService) ($ctx.Values.upstream.ips) -}}
    {{- $_ := set $res "ip" (join " " $ctx.Values.upstream.ips) -}}
  {{- else -}}
    {{- fail "node-local-dns: unable to resolve upstream IP; set values.upstream.clusterIP or set upstream.useService=false with upstream.ips" -}}
  {{- end -}}
{{- end -}}
{{- get $res "ip" -}}
{{- end -}}
