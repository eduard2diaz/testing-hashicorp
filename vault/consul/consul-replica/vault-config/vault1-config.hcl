storage "consul" {
  address = "http://consul1:8500"
  path    = "vault/"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

service_registration "consul" {
  address = "vault1"
}

api_addr = "http://vault1:8200"
cluster_addr = "http://vault1:8201"

disable_mlock = true
ui = true
