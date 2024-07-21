storage "consul" {
  address = "http://haproxyconsul:8500"
  path    = "vault/"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

service_registration "consul" {
  address = "vault2"
}

api_addr = "http://vault2:8200"
cluster_addr = "http://vault2:8201"

disable_mlock = true
ui = true
