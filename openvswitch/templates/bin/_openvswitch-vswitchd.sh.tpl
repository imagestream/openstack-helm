#!/bin/bash

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

set -ex

# load tunnel kernel modules we may use and gre/vxlan
modprobe openvswitch

modprobe gre
modprobe vxlan

sock="/var/run/openvswitch/db.sock"
t=0
while [ ! -e "${sock}" ] ; do
    echo "waiting for ovs socket $sock"
    sleep 1
    t=$(($t+1))
    if [ $t -ge 10 ] ; then
        echo "no ovs socket, giving up"
        exit 1
    fi
done

ovs-vsctl --no-wait show

external_bridge="{{- .Values.network.external_bridge -}}"
external_interface="{{- .Values.network.interface.external -}}"
if [ -n "${external_bridge}" ] ; then
    # create bridge device
    ovs-vsctl --no-wait --may-exist add-br $external_bridge
    if [ -n "$external_interface" ] ; then
        # add external interface to the bridge
        ovs-vsctl --no-wait --may-exist add-port $external_bridge $external_interface
        ip link set dev $external_interface up
# This is horribly broken - relies on ovs-vswitchd to already be running! Scott 11-09-2017
#        ip link set dev $external_bridge up
#        # move ip address from physical interface to the bridge
#        for IP in $(ip addr show dev $external_interface | grep ' inet ' | awk '{print $2}'); do
#            ip addr add $IP dev $external_bridge
#            ip addr del $IP dev $external_interface
#        done
    fi
fi

# handle any bridge mappings
{{- range $br, $phys := .Values.network.auto_bridge_add }}
if [ -n "{{- $br -}}" ] ; then
    # create {{ $br }}{{ if $phys }} and add port {{ $phys }}{{ end }}
    ovs-vsctl --no-wait --may-exist add-br "{{ $br }}"
    if [ -n "{{- $phys -}}" ] ; then
        ovs-vsctl --no-wait --may-exist add-port "{{ $br }}" "{{ $phys }}"
        ip link set dev "{{ $phys }}" up
# This is horribly broken - relies on ovs-vswitchd to already be running! Scott 11-09-2017
#        ip link set dev "{{ $br }}" up
#        # move ip address from physical interface to the bridge
#        for IP in $(ip addr show dev "{{ $phys }}" | grep ' inet ' | awk '{print $2}'); do
#            ip addr add $IP dev "{{ $br }}"
#            ip addr del $IP dev "{{ $phys }}"
#        done
    fi
fi
{{- end }}

exec /usr/sbin/ovs-vswitchd unix:/run/openvswitch/db.sock \
        -vconsole:emer \
        -vconsole:err \
        -vconsole:info \
        --mlockall
