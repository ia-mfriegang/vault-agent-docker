#!/bin/bash
# add custom ca cert if the "CUSTOM_CERT" variable is set to true
if [[ $CUSTOM_CERT == 'True' ]] || [[ $CUSTOM_CERT == 'true' ]] && [ ! -f "/usr/share/ca-certificates/extra/$CUSTOM_CERT_NAME" ]
then
  mkdir -p /usr/share/ca-certificates/extra && echo extra/$CUSTOM_CERT_NAME | tee -a /etc/ca-certificates.conf
  cp /etc/vault.d/$CUSTOM_CERT_NAME /usr/share/ca-certificates/extra/$CUSTOM_CERT_NAME
  update-ca-certificates
fi
# Write a wrapped secret-id to the same file that the agent expects from its config
vault write -field=wrapping_token -wrap-ttl=200s -f auth/approle/role/approle_test/secret-id > /etc/vault.d/wrapped_secret_id
VAULT_TOKEN=`vault write -field=token auth/approle/login role_id=$(cat /etc/vault.d/rotate_roleid.txt) secret_id=$(cat /etc/vault.d/rotate_secretid.txt)` vault write -field=wrapping_token -wrap-ttl=200s -f auth/approle/role/$(cat /etc/vault.d/rolename.txt)/secret-id > /etc/vault.d/wrapped_secret_id
# Start the agent
vault agent -config /etc/vault.d/vault-agent.hcl