#!/bin/sh
sleep 5s
echo "Initializing Vault..."
export VAULT_ADDR=http://localhost:8200
vault login vaultroot

cat <<EOF | vault kv put -mount=secret IdentityDatabaseConnectionString -
{
  "ConnectionString": "Host=localhost;Port=5432;Database=StoreIdentity;Username=postgres;Password=postgresspassword;Include Error Detail=true"
}
EOF

cat <<EOF | vault kv put -mount=secret CatalogDatabaseConnectionString -
{
  "ConnectionString": "Host=localhost;Port=5432;Database=StoreCatalog;Username=postgres;Password=postgresspassword;Include Error Detail=true"
}
EOF

cat <<EOF | vault kv put -mount=secret InventoryDatabaseConnectionString -
{
  "ConnectionString": "Host=localhost;Port=5432;Database=StoreInventory;Username=postgres;Password=postgresspassword;Include Error Detail=true"
}
EOF

cat <<EOF | vault kv put -mount=secret JwtOptions -
{
  "Lifetime": 30,
  "SecretKey": "HL#6j=4;5H{5qZ#M=6J!1[W<YvWdbzEif|M]:ZB<6<{ap^K!@Tg{];OD0E",
  "ValidAudience": "storeApp",
  "ValidIssuer": "identity",
  "ValidateAudience": true,
  "ValidateIssuer": true,
  "ValidateLifetime": false
}
EOF

cat <<EOF | vault kv put -mount=secret RabbitMqSettings -
{
  "Password": "storeUserPass",
  "UseSsl": true,
  "UserName": "storeUser",
  "VirtualHost": "/"
}
EOF

cat <<EOF | vault kv put -mount=secret DefaultUser -
{
  "email": "joseco48@gmail.com",
  "firstName": "Jose Carlos",
  "lastName": "Gutierrez",
  "password": "admin@123",
  "user": "joseco48@gmail.com"
}
EOF

