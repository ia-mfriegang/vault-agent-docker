provider "vault" {
}

/*
Approle Roles
*/
resource "vault_approle_auth_backend_role" "example" {
  backend        = vault_auth_backend.approle.path
  role_name      = "example"
  token_policies = ["default", "example"]
}

resource "vault_approle_auth_backend_role" "example-rotate" {
  backend               = vault_auth_backend.approle.path
  role_name             = "example-rotate"
  #secret_id_bound_cidrs = var.example_approle_cidr
  token_policies        = ["default", "example-rotate"]
}


resource "vault_approle_auth_backend_role_secret_id" "example-rotate" {
  backend        = vault_auth_backend.approle.path
  role_name      = "example-rotate"
  depends_on = [vault_approle_auth_backend_role.example-rotate]
}

resource "local_file" "example-rotate_role-id" {
    content     = "${vault_approle_auth_backend_role.example-rotate.role_id}"
    filename = "${path.module}/approle_creds/example-rotate-role_id"
}

resource "vault_kv_secret_v2" "example-approle" {
  mount                      = vault_mount.kvv2.path
  name                       = "approle/example-rotate"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode (
  {
   rotate-secret_id = (vault_approle_auth_backend_role_secret_id.example-rotate.secret_id)
   rotate-role_id   = (vault_approle_auth_backend_role.example-rotate.role_id)
   role-id          = (vault_approle_auth_backend_role.example.role_id)

  }
  )
}


#### Policy
/*
example Approle Rotation Policy
  This is used to rotate the secret ID for the auto-snapshot role
*/

resource "vault_policy" "example-rotate" {
  name = "example-rotate"

  policy = <<EOT

path "auth/approle/role/example/secret-id" {
  capabilities = [ "create", "read", "update" ]
}
EOT
}

/*
example Policy
*/
resource "vault_policy" "example" {
  name = "example"

  policy = <<EOT
path "secret/data/example/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/data/example"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}


# Allow deletion of any secret version
path "secret/delete/example/*"
{
  capabilities = ["update"]
}

path "secret/delete/example"
{
  capabilities = ["update"]
}

# Allow un-deletion of any secret version
path "secret/undelete/example/*"
{
  capabilities = ["update"]
}

path "secret/undelete/example"
{
  capabilities = ["update"]
}

# Allow destroy of any secret version
path "secret/destroy/example/*"
{
  capabilities = ["update"]
}

path "secret/destroy/example"
{
  capabilities = ["update"]
}
# Allow list and view of metadata and to delete all versions and metadata for a key
path "secret/metadata/example/*"
{
  capabilities = ["list", "read", "delete"]
}

path "secret/metadata/example"
{
  capabilities = ["list", "read", "delete"]
}
EOT
}