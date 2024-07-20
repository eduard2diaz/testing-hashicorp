ui = true
disable_mlock = true

storage "consul" {
  address = "http://consul:8500"
  path    = "vault/"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}