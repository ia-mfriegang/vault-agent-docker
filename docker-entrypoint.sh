#!/bin/bash
# add custom ca cert if the "CUSTOM_CERT" variable is set to true
if [[ $CUSTOM_CERT == 'True' ]] || [[ $CUSTOM_CERT == 'true' ]] && [ ! -f "/usr/share/ca-certificates/extra/$CUSTOM_CERT_NAME" ]
then
  mkdir -p /usr/share/ca-certificates/extra && echo extra/$CUSTOM_CERT_NAME | tee -a /etc/ca-certificates.conf
  cp /etc/vault.d/$CUSTOM_CERT_NAME /usr/share/ca-certificates/extra/$CUSTOM_CERT_NAME
  update-ca-certificates
fi
## check if docker secrets are being used
if [ -f "/run/secrets/vault-rotate-roleid" ] && [ -f "/run/secrets/vault-rotate-secretid" ] 
# Write a wrapped secret-id to the same file that the agent expects from its config
then
  VAULT_TOKEN=`vault write -field=token auth/approle/login role_id=$(cat /run/secrets/vault-rotate-roleid) secret_id=$(cat /run/secrets/vault-rotate-secretid)` vault write -field=wrapping_token -wrap-ttl=200s -f auth/approle/role/$VAULT_ROLE_NAME/secret-id > /etc/vault.d/wrapped_secret_id
  # make sure roleID is correct
  rm /etc/vault.d/roleid.txt || true && echo $(cat /run/secrets/vault-roleid)  | tee -a /etc/vault.d/roleid.txt
# otherwise read them from .txt files in /etc/vault.d
else
# Write a wrapped secret-id to the same file that the agent expects from its config
VAULT_TOKEN=`vault write -field=token auth/approle/login role_id=$(cat /etc/vault.d/rotate_roleid.txt) secret_id=$(cat /etc/vault.d/rotate_secretid.txt)` vault write -field=wrapping_token -wrap-ttl=200s -f auth/approle/role/$VAULT_ROLE_NAME/secret-id > /etc/vault.d/wrapped_secret_id  
fi
# Start the agent

  #chown $SINK_UID:$SINK_GID /sink/vault_sink
vault agent -config /etc/vault.d/vault-agent.hcl
