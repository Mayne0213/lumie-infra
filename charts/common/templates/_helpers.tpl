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

{{/*
Component image - builds image string from component's image config
*/}}
{{- define "web-app.componentImage" -}}
{{- $comp := .comp -}}
{{- if $comp.image.registry -}}
{{- printf "%s/%s:%s" $comp.image.registry $comp.image.repository (toString $comp.image.tag) }}
{{- else -}}
{{- printf "%s:%s" $comp.image.repository (toString $comp.image.tag) }}
{{- end -}}
{{- end }}

{{/*
Build components list - supports both legacy (common.name) and new (common.components) format
Returns a list of component objects with standardized structure
*/}}
{{- define "web-app.buildComponents" -}}
{{- $components := list -}}
{{- if .Values.common.components -}}
  {{/* New components format */}}
  {{- $components = .Values.common.components -}}
{{- else if .Values.common.name -}}
  {{/* Legacy format - build component from top-level common values */}}
  {{- $legacyComponent := dict
      "name" .Values.common.name
      "image" .Values.common.image
      "replicaCount" (.Values.common.replicaCount | default 1)
      "containerPort" (.Values.common.containerPort | default 3000)
      "service" .Values.common.service
      "ingress" .Values.common.ingress
      "resources" .Values.common.resources
      "healthCheck" .Values.common.healthCheck
      "env" .Values.common.env
      "envFrom" .Values.common.envFrom
      "strategy" .Values.common.strategy
      "affinity" .Values.common.affinity
      "nodeSelector" .Values.common.nodeSelector
      "tolerations" .Values.common.tolerations
      "podAnnotations" .Values.common.podAnnotations
      "initContainers" .Values.common.initContainers
      "rbac" .Values.common.rbac
  -}}
  {{- $components = list $legacyComponent -}}
  {{/* Add additionalDeployments if present */}}
  {{- if .Values.common.additionalDeployments -}}
    {{- range .Values.common.additionalDeployments -}}
      {{- $components = append $components . -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $components | toJson -}}
{{- end }}
