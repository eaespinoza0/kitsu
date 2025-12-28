#!/bin/bash

# Create secrets directory
mkdir -p secrets

# Generate secrets if they don't exist
if [ ! -f secrets/postgres_password ]; then
  openssl rand -hex 16 > secrets/postgres_password
  echo "Generated postgres_password"
fi

if [ ! -f secrets/secret_key ]; then
  openssl rand -hex 32 > secrets/secret_key
  echo "Generated secret_key"
fi

# Lock down permissions
chmod 600 secrets/*

echo "Secrets generated in ./secrets/"
echo "Make sure to backup these securely!"
