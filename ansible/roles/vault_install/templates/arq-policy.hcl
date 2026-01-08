# Permitir que leiam e escrevam em um caminho específico de segredos
path "secret/data/arq/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Permitir que criem tokens filhos (se necessário)
path "auth/token/create" {
  capabilities = ["update"]
}
