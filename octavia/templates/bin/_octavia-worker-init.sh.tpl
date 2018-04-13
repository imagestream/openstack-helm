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
  [ ! -d /key/certs ] && mkdir /key/certs
  cd /key/certs
  mkdir -p newcerts private
  chmod 700 private
  touch index.txt
  [ ! -f serial ] && echo 01 > serial
  cat << 'EOM' > openssl.cnf
[ default ]
ca                      =  root_ca              # CA name
dir                     = .                     # Top dir

[ ca ]
default_ca              = root_ca

[ root_ca ]
certificate             = /key/root-ca.crt      # The CA cert
private_key             = /key/root-ca.key      # CA private key
new_certs_dir           = $dir/                 # Certificate archive
serial                  = $dir/serial           # Serial number file
crlnumber               = $dir/crl              # CRL number file
database                = $dir/index.txt        # Index file
unique_subject          = no                    # Require unique subject
default_days            = 3652                  # How long to certify for
default_md              = sha1                  # MD to use
policy                  = match_pol             # Default naming policy
email_in_dn             = no                    # Add email to cert DN
preserve                = no                    # Keep passed DN ordering
name_opt                = ca_default            # Subject DN display options
cert_opt                = ca_default            # Certificate display options
copy_extensions         = none                  # Copy extensions from CSR
x509_extensions         = usr_cert              # Default cert extensions
default_crl_days        = 365                   # How long before next CRL

# Naming policies control which parts of a DN end up in the certificate and
# under what circumstances certification should be denied.

[ match_pol ]
domainComponent         = optional              # Must match 'simple.org'
organizationName        = optional              # Must match 'Simple Inc'
organizationalUnitName  = optional              # Included if present
commonName              = supplied              # Must be present

[ any_pol ]
domainComponent         = optional
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = optional
emailAddress            = optional

[ req ]
default_bits            = 2048
x509_extensions         = v3_ca	

[ usr_cert ]
basicConstraints=CA:FALSE
# PKIX recommendations harmless if included in all certificates.
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer

[ v3_ca ]
# Extensions for a typical CA


# PKIX recommendation.

subjectKeyIdentifier=hash

authorityKeyIdentifier=keyid:always,issuer

# This is what PKIX recommends but some broken software chokes on critical
# extensions.
#basicConstraints = critical,CA:true
# So we do this instead.
basicConstraints = CA:true
EOM

  if [ ! -f ${OCTAVIA_CERT_FILE} ]; then
    if [ -f ${OCTAVIA_KEY_FILE} ]; then
      openssl req -out ${OCTAVIA_CERT_FILE} -key ${OCTAVIA_KEY_FILE} \
              -passin env:OCTAVIA_KEY_PASSPHRASE \
              -subj "/CN=Octavia CA" -x509 -days ${OCTAVIA_CERT_VALID_DAYS}
    else
      openssl req -out ${OCTAVIA_CERT_FILE} -newkey rsa:4096 \
              -keyout ${OCTAVIA_KEY_FILE} -sha256 \
              -passout env:OCTAVIA_KEY_PASSPHRASE \
              -subj "/CN=Octavia CA" -x509 -days ${OCTAVIA_CERT_VALID_DAYS}
      chmod 0400 ${OCTAVIA_KEY_FILE}
    fi
  fi
  if [ ! -f ${OCTAVIA_CLIENT_CERT_FILE} ]; then
      openssl req -out /tmp/o-client-csr -newkey rsa:4096 \
              -keyout /tmp/o-client-key -nodes \
              -subj "/CN=Octavia Client"
      openssl ca -out /tmp/o-client-crt -in /tmp/o-client-csr \
              -cert ${OCTAVIA_CERT_FILE} -batch -outdir /key/certs \
              -keyfile ${OCTAVIA_KEY_FILE} -key ${OCTAVIA_KEY_PASSPHRASE} \
              -days ${OCTAVIA_CERT_VALID_DAYS} -config openssl.cnf
      cat /tmp/o-client-crt /tmp/o-client-key > ${OCTAVIA_CLIENT_CERT_FILE}
      rm -f /tmp/o-client-key
      rm -f /tmp/o-client-csr
      rm -f /tmp/o-client-crt
  fi
  chown -R octavia: /key
}

function stop () {
  kill -TERM 1
}

$COMMAND
