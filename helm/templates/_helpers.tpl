{{/*
Expand the name of the chart.
*/}}
{{- define "apex-os-iam-pam.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "apex-os-iam-pam.fullname" -}}
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
{{- define "apex-os-iam-pam.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "apex-os-iam-pam.labels" -}}
helm.sh/chart: {{ include "apex-os-iam-pam.chart" . }}
{{ include "apex-os-iam-pam.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.global.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "apex-os-iam-pam.selectorLabels" -}}
app.kubernetes.io/name: {{ include "apex-os-iam-pam.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "apex-os-iam-pam.serviceAccountName" -}}
{{- if .Values.security.serviceAccount.create }}
{{- default (include "apex-os-iam-pam.fullname" .) .Values.security.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.security.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image pull secrets
*/}}
{{- define "apex-os-iam-pam.imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Generate image repository
*/}}
{{- define "apex-os-iam-pam.image" -}}
{{- $registry := .Values.image.registry -}}
{{- $repository := index .Values.image.repository .component -}}
{{- $tag := .Values.image.tag -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end }}
