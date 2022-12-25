client {
  enabled = true
  servers = ["10.8.0.1"]
  node_class = "storage"
  network_interface = "tun0"
  options {
    docker.privileged.enabled = "true"
    docker.volumes.enabled = "true"
  }
}
advertise {
  # Defaults to the first private IP address.
  http = "{{ GetInterfaceIP \"tun0\" }}"
  rpc  = "{{ GetInterfaceIP \"tun0\" }}"
  serf = "{{ GetInterfaceIP \"tun0\" }}:5648" # non-default ports may be specified
}

