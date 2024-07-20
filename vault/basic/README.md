# Configuración de Vault con Docker Compose

Este documento proporciona instrucciones detalladas para configurar un servidor de Vault utilizando Docker Compose. Se incluyen las configuraciones necesarias para habilitar el motor de secretos KV, crear políticas y usuarios, y configurar la autenticación con nombre de usuario y contraseña.

## Estructura de Archivos

1. **docker-compose.yml**
2. **vault-config/vault-config.hcl**
3. **vault-config/kv-access.hcl**
4. **vault-config/list-secrets-engines.hcl**
5. **vault-config/init-vault.sh**

### `docker-compose.yml`

```yaml
version: '3.7'

services:
  vault:
    image: hashicorp/vault:latest
    container_name: vault
    environment:
      VAULT_ADDR: http://0.0.0.0:8200
      VAULT_DEV_ROOT_TOKEN_ID: root_token
    volumes:
      - ./vault-config:/vault/config
      - ./vault-data:/vault/data
    ports:
      - "8200:8200"
    entrypoint: ["vault", "server", "-config=/vault/config/vault-config.hcl"]
    cap_add:
      - IPC_LOCK

  vault-init:
    image: hashicorp/vault:latest
    container_name: vault-init
    depends_on:
      - vault
    entrypoint: ["/vault/config/init-vault.sh"]
    environment:
      VAULT_ADDR: http://vault:8200
    volumes:
      - ./vault-config:/vault/config
      - ./vault-data:/vault/data
```

### `vault-config/vault-config.hcl`
```hcl
disable_mlock = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

storage "file" {
  path = "/vault/data"
}
```

### `vault-config/kv-access.hcl`
```hcl
path "kv/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```

### `vault-config/list-secrets-engines.hcl`
```hcl
path "sys/mounts" {
  capabilities = ["read", "list"]
}

path "sys/mounts/*" {
  capabilities = ["read", "list"]
}
```

### `vault-config/init-vault.sh`
```sh
#!/bin/sh

# Esperar a que Vault esté listo
while ! nc -z vault 8200; do
  sleep 1
done

# Inicializar Vault
vault operator init > /vault/data/init.txt

# Desellarlo
vault operator unseal $(grep 'Key 1:' /vault/data/init.txt | awk '{print $NF}')
vault operator unseal $(grep 'Key 2:' /vault/data/init.txt | awk '{print $NF}')
vault operator unseal $(grep 'Key 3:' /vault/data/init.txt | awk '{print $NF}')

# Iniciar sesión con el token root
VAULT_TOKEN=$(grep 'Initial Root Token:' /vault/data/init.txt | awk '{print $NF}')
vault login $VAULT_TOKEN

# Habilitar el motor de secretos KV
vault secrets enable -path=kv kv

# Escribir las políticas
vault policy write kv-access /vault/config/kv-access.hcl
vault policy write list-secrets-engines /vault/config/list-secrets-engines.hcl

# Habilitar autenticación userpass y crear un usuario
vault auth enable userpass
vault write auth/userpass/users/my-username password=my-password policies=default,list-secrets-engines,kv-access
```

## Instrucciones para ejecutar
1. Crea la estructura de directorios para la configuración de Vault y los datos persistentes:
```sh
mkdir -p vault-config vault-data
```

2. Guarda los archivos vault-config.hcl, kv-access.hcl, list-secrets-engines.hcl, y init-vault.sh en el directorio vault-config.

3. Asegúrate de que el script de inicialización init-vault.sh tenga permisos de ejecución:
```sh
chmod +x vault-config/init-vault.sh
```
4. Guarda el archivo docker-compose.yml en el directorio raíz de tu proyecto.
5. Ejecuta el contenedor de Vault con Docker Compose:
```sh
docker-compose up --build
```

Por defecto el usuario y contrasenha es tomando del fichero .env
```env
VAULT_USER=admin
VAULT_PASSWORD=hkusxpq1*
```

Pero puedes definir dichos parametros tambien de la sig forma:
```sh
VAULT_USER=new-username VAULT_PASSWORD=new-password docker-compose up --build
```

Asimismo, para cambiar el nombre del contendor bastaria con:
```sh
VAULT_CONTAINER_NAME=my-vault docker-compose up --build
```

y si queremos cambiar el nombre del contenedor a la vez del usuario y el password seria:
```sh
VAULT_CONTAINER_NAME=my-vault VAULT_USER=new-username VAULT_PASSWORD=new-password docker-compose up --build
```

Finalmente, para cambiar el puerto externo por el que corre seria:

```sh
VAULT_EXTERNAL_PORT=8300 docker-compose up --build
```

**IMPORTANTE:** Note que cuando corre el contenedor, una carpeta llamada vault-data se llena con los ficheros de la configuracion asociados a la ejecucion.
Entonces, cualquier cambio que vaya a hacer en la definicion del contenedor, que requiera iniciar uno nuevo, verifique que la carpeta vault-data este vacia o no exista. Sino, obtendra un error relacionado al sellado (sealed) de los datos.

## Descripcion
* Vault Service: Inicia un contenedor de Vault con los archivos de configuración proporcionados.
* Vault Init Service: Este servicio depende del contenedor vault y ejecuta un script de inicialización para:
    * Inicializar Vault.
    * Desellarlo.
    * Habilitar el motor de secretos en kv.
    * Crear y aplicar las políticas kv-access y list-secrets-engines.
    * Habilitar la autenticación userpass y crear un usuario con las políticas asignadas.

Este setup asegura que Vault esté correctamente configurado y que los usuarios puedan interactuar con los secretos en la ruta kv/ con los permisos adecuados.