{{/*
Copyright 2017 The Openstack-Helm Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

RABBITMQ_LOGS=-
RABBITMQ_SASL_LOGS=-
AUTOCLUSTER_TYPE=etcd
AUTOCLUSTER_DELAY={{ .Values.autocluster.delay }}
RABBITMQ_USE_LONGNAME=true
AUTOCLUSTER_LOG_LEVEL={{ .Values.autocluster.log_level }}
NODENAME="rabbit@${RABBITMQ_POD_IP}"
RABBITMQ_NODE_TYPE={{ .Values.autocluster.node_type }}
