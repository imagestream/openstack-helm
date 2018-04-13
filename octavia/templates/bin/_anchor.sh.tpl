#!/bin/bash

# Copyright 2017 The Openstack-Helm Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex
COMMAND="${@:-start}"

function start () {
  if [ ! -f ${ANCHOR_CERT_FILE} ]; then
    if [ -f ${ANCHOR_KEY_FILE} ]; then
      openssl req -out ${ANCHOR_CERT_FILE} -key ${ANCHOR_KEY_FILE} \
              -subj "/CN=Anchor CA" -nodes -x509 -days ${ANCHOR_CERT_VALID_DAYS}
    else
      openssl req -out ${ANCHOR_CERT_FILE} -newkey rsa:4096 \
              -keyout ${ANCHOR_KEY_FILE} -sha256 \
              -subj "/CN=Anchor CA" -nodes -x509 -days ${ANCHOR_CERT_VALID_DAYS}
      chmod 0400 ${ANCHOR_KEY_FILE}
    fi
  fi
  cp /config/config.json /code/config.json
  [ ! -d /key/certs ] && mkdir /key/certs
  exec pecan serve config.py
}

function stop () {
  kill -TERM 1
}

$COMMAND

