#!/bin/sh

# Wait for Vault to be ready
while ! nc -z vault 8200; do
  sleep 1
done

# Initialize Vault
init () {
vault operator init > /vault/data/init.txt
}

# Unseal Vault
unseal () {
# Imprimir las claves de des-sellado y el token de root
echo "Claves de des-sellado y token de root:"
cat /vault/data/init.txt

vault operator unseal $(grep 'Key 1:' /vault/data/init.txt | awk '{print $NF}')
vault operator unseal $(grep 'Key 2:' /vault/data/init.txt | awk '{print $NF}')
vault operator unseal $(grep 'Key 3:' /vault/data/init.txt | awk '{print $NF}')
}

# Log in with the root token
log_in () {
VAULT_TOKEN=$(grep 'Initial Root Token:' /vault/data/init.txt | awk '{print $NF}')
vault login $VAULT_TOKEN
}

create_default_token () {
  if [ ! -z "$VAULT_DEFAULT_TOKEN" ]; then
    echo "Creando default token"
    vault token create -id $VAULT_DEFAULT_TOKEN
  fi
}

enable_secrets () {
# Enable the KV secrets engine
#vault secrets enable -path=kv kv

# Enable the KV secrets engine for 'secret/' path (using v2, which is compatible with spring boot)
vault secrets enable -path=secret kv-v2

# Write the policies
vault policy write user-policy /vault/config/user-policy.hcl
vault policy write kv-access /vault/config/kv-access.hcl
vault policy write list-secrets-engines /vault/config/list-secrets-engines.hcl

# Enable userpass authentication and create a user
vault auth enable userpass
vault write auth/userpass/users/$VAULT_USER password=$VAULT_PASSWORD policies=default,list-secrets-engines,kv-access,user-policy
}

if [ -s /vault/data/init.txt ]; then
   unseal
else
   init
   unseal
   log_in
   create_default_token
   enable_secrets
fi

vault status > /vault/file/status