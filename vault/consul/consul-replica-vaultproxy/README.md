
# Respaldo
Crear un backup
```sh
docker exec -it consul1 consul snapshot save /vault/backup/consul-backup.snap
```

Guardar el backup en el local
```sh
docker cp consul1:/vault/backup/consul-backup.snap .
```

Restaurar
```sh
docker exec -it consul1 consul snapshot restore /vault/backup/consul-backup.snap
```
