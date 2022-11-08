# Vault Agent Docker
This repo contains a Dockerfile that creates an image with the following:
- hashicorp vault agent running under the docker-entrypoint script
   - agent uses 2 approle roles to rotate its token sink
   - agent can use a custom root CA if your Vault uses a private CA for TLS

## Prereqs and Background

- 2 Vault Approle Roles:
  - One role that contains the secrets you want to Vault. We will refer to this as the "regular role"
  - One role that can rotate the secret ID for the role that contains the secrets. We will refer to this as the "rotate role"

- 2 Vault Policies (see examples)
  - one policy for the regular role. This policy can access the path containing the secrets.
  - one policy for the rotate role. This policy can only generate new secret IDs for the regular role.
## Diagram


<img src="https://raw.githubusercontent.com/ia-mfriegang/vault-agent-docker/main/example/docker-agent_diagram.drawio.png)" />

## Getting Started
1. Create the Vault roles and approle roles (see examples), make note of the approle role id for both roles, as well as the secret id for the rotate role.
2. Build the image locally `docker built -t vault_agent_test .`
3. Create a docker-compose.yml file (see examples)
4. Create one of each of the files in the `example/config-examples` directory. You will need the following:
   - `rolename.txt` - this should contain the name of the regular role.
   - `rotate_roleid.txt` - this should contain the role id for the rotate role.
   - `rotate_secretid.txt` - this should contain the secret id for the rotate role.
   - `vault-agent.hcl` - this is the Vault agent config file. Make sure that the address points to your Vault, and that the `example` in `secret_id_response_wrapping_path      = "auth/approle/role/example/secret-id"` gets replaced by the name of the regular role.
   - `yourrootca.pem` - this is optional if you want to use a custom root CA. Make sure to set the environment variables section in the docker-compose file if using this.
5. Run with `docker-compose up -d`
6. Check the logs `docker logs vault-agent`, a working container's logs should look something like this:
```
2022-11-08T19:34:22.009Z [INFO]  template.server: starting template server
2022-11-08T19:34:22.010Z [INFO]  template.server: no templates found
2022-11-08T19:34:22.010Z [INFO]  auth.handler: starting auth handler
2022-11-08T19:34:22.010Z [INFO]  auth.handler: authenticating
2022-11-08T19:34:22.010Z [INFO]  sink.server: starting sink server
2022-11-08T19:34:22.912Z [INFO]  auth.handler: authentication successful, sending token to sinks
2022-11-08T19:34:22.912Z [INFO]  auth.handler: starting renewal process
2022-11-08T19:34:22.912Z [INFO]  sink.file: token written: path=/etc/vault.d/sink
2022-11-08T19:34:23.092Z [INFO]  auth.handler: renewed auth token
```

## Troubleshooting
1. exec into container `docker exec -it vault-agent bash`
2. Run this command to see if the entrypoint script can write tokens:
 ```
VAULT_TOKEN=`vault write -field=token auth/approle/login role_id=$(cat /etc/vault.d/rotate_roleid.txt) secret_id=$(cat /etc/vault.d/rotate_secretid.txt)` vault write -field=wrapping_token \
-wrap-ttl=200s -f auth/approle/role/docker/secret-id > /etc/vault.d/wrapped_secret_id
```
3. If you can't, try looking up the token, see which policies it has.
```
VAULT_TOKEN=`vault write -field=token auth/approle/login role_id=$(cat /etc/vault.d/rotate_roleid.txt) secret_id=$(cat /etc/vault.d/rotate_secretid.txt)`  vault token lookup
```