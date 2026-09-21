{{/*
The probe command, shared by the startup, readiness and liveness probes so they
cannot drift apart. Over TCP rather than the unix socket: on a first boot the
entrypoint runs a temporary server with listen_addresses empty to finish
initialization, and a socket probe reports ready while nothing is listening on
5432 yet.
*/}}
{{- define "honeypot-postgres.pgIsReady" -}}
- pg_isready
- -h
- 127.0.0.1
- -U
- {{ .Values.postgres.user | quote }}
- -d
- {{ .Values.postgres.database | quote }}
{{- end -}}
