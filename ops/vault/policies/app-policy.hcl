# Policy for application secrets
path "secret/data/app/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/app/*" {
  capabilities = ["list", "read"]
}

# Policy for database credentials
path "secret/data/database/*" {
  capabilities = ["read", "list"]
}

# Policy for API keys
path "secret/data/api-keys/*" {
  capabilities = ["read", "list"]
}

# Allow token renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}