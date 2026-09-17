{{/*
Environment the analytics package reads, shared by the server and the init
container so they cannot drift apart.
*/}}
{{- define "honeypot-jupyter.env" -}}
- name: HONEYPOT_DATA_DIR
  value: {{ .Values.paths.data | quote }}
- name: HONEYPOT_B2_PREFIX
  value: {{ .Values.b2.prefix | quote }}
- name: HONEYPOT_B2_ENDPOINT
  value: {{ .Values.b2.endpoint | quote }}
- name: HONEYPOT_B2_REGION
  value: {{ .Values.b2.region | quote }}
{{- end -}}
