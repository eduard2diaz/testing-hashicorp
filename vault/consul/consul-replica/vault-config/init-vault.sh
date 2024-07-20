#!/bin/sh

# Wait for Vault to be ready
while ! nc -z vault1 8200; do
  sleep 1
done

# Function to initialize Vault
init() {
  echo "Initializing Vault..."
  vault operator init > /vault/data/init.txt
}

# Function to unseal Vault
unseal() {
  echo "Unsealing Vault..."
  # Print unseal keys and root token
  echo "Unseal keys and root token:"
  cat /vault/data/init.txt

  vault operator unseal $(grep 'Unseal Key 1:' /vault/data/init.txt | awk '{print $NF}')
  vault operator unseal $(grep 'Unseal Key 2:' /vault/data/init.txt | awk '{print $NF}')
  vault operator unseal $(grep 'Unseal Key 3:' /vault/data/init.txt | awk '{print $NF}')
}

# Function to log in with the root token
log_in() {
  VAULT_TOKEN=$(grep 'Initial Root Token:' /vault/data/init.txt | awk '{print $NF}')
  export VAULT_TOKEN
  vault login $VAULT_TOKEN
}

# Function to create the default token
create_default_token() {
  if [ ! -z "$VAULT_DEFAULT_TOKEN" ]; then
    echo "Creating default token..."
    vault token create -id $VAULT_DEFAULT_TOKEN
  fi
}

# Function to enable secrets engines and set up policies
enable_secrets() {
  echo "Enabling secrets engines and setting up policies..."
  # Enable the KV secrets engine for the 'secret/' path (using v2, which is compatible with Spring Boot)
  vault secrets enable -path=secret kv-v2

  # Write the policies
  vault policy write user-policy /vault/config/user-policy.hcl
  vault policy write kv-access /vault/config/kv-access.hcl
  vault policy write list-secrets-engines /vault/config/list-secrets-engines.hcl

  # Enable userpass authentication and create a user
  vault auth enable userpass
  vault write auth/userpass/users/$VAULT_USER password=$VAULT_PASSWORD policies=default,list-secrets-engines,kv-access,user-policy
}

# Function to join a standby node to the active cluster
join_standby() {
  echo "Joining standby node to the active cluster..."
  vault operator raft join http://vault1:8200
}

# Initialize Vault only if it has not been initialized already
if vault status | grep -q 'Initialized.*false'; then
  init
  unseal
  log_in
  create_default_token
  enable_secrets
else
  unseal
  log_in
  if vault status | grep -q 'Standby.*true'; then
    join_standby
  fi
fi

vault status > /vault/file/status
