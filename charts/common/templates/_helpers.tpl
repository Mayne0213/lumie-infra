{{/*
Expand the name of the chart.
*/}}
{{- define "web-app.name" -}}
{{- default .Chart.Name .Values.common.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "web-app.fullname" -}}
{{- if .Values.common.name }}
{{- .Values.common.name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "web-app.labels" -}}
app: {{ include "web-app.fullname" . }}
app.kubernetes.io/name: {{ include "web-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "web-app.selectorLabels" -}}
app: {{ include "web-app.fullname" . }}
{{- end }}

{{/*
Image name
*/}}
{{- define "web-app.image" -}}
{{- printf "%s/%s:%s" .Values.common.image.registry .Values.common.image.repository (toString .Values.common.image.tag) }}
{{- end }}
