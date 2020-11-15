{{/*
Expand the name of the chart.
*/}}
{{- define "extension.name" -}}
{{- default .Chart.Name .Values.extension.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "extension.fullname" -}}
{{- if .Values.extension.fullnameOverride }}
{{- .Values.extension.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.extension.nameOverride }}
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
{{- define "extension.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "extension.labels" -}}
helm.sh/chart: {{ include "extension.chart" . }}
{{ include "extension.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "extension.selectorLabels" -}}
app.kubernetes.io/name: {{ include "extension.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "extension.serviceAccountName" -}}
{{- if .Values.extension.serviceAccount.create }}
{{- default (include "extension.fullname" .) .Values.extension.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.extension.serviceAccount.name }}
{{- end }}
{{- end }}
