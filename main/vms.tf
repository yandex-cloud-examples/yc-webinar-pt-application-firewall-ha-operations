resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "pt_key.pem"
  file_permission = "0600"
}

data "template_file" "cloud_init_lin" {
  template = file("./cloud-init_lin.tpl.yaml")
   vars =  {
        ssh_key = "${chomp(tls_private_key.ssh.public_key_openssh)}"
    }
}

data "template_file" "cloud_init_lin0" {
  template = file("./cloud-init_lin.tpl_1.yaml")
   vars =  {
        ssh_key = "${chomp(tls_private_key.ssh.public_key_openssh)}"
    }
}

data "template_file" "cloud_init_lin1" {
  template = file("./cloud-init_lin.tpl_2.yaml")
   vars =  {
        ssh_key = "${chomp(tls_private_key.ssh.public_key_openssh)}"
    }
}

data "yandex_compute_image" "img_lin" {
  family = "ubuntu-2004-lts"
}


//Развертывание ssh broker машин
resource "yandex_compute_instance" "ssh" {
  count = 2
  name        = "ssh-${element(var.network_names, count.index)}"
  zone        = element(var.zones, count.index)
  hostname    = "ssh-${element(var.network_names, count.index)}"
  platform_id = "standard-v2"
  resources {
    cores  = 2
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.img_lin.id
      type     = "network-ssd"
      size     = 26
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.mgmgt-subnet[count.index].id
    ip_address = cidrhost(var.mgmt_cidrs[count.index], 9) 
    nat = true
    security_group_ids = [yandex_vpc_security_group.ssh-broker.id]
}

metadata = {
  user-data = "${data.template_file.cloud_init_lin.rendered}"
  serial-port-enable = 1
}
}



//Развертывание PTAF  машин
resource "yandex_compute_instance" "ptaf-a" {
  name        = "ptaf-a"
  zone        = "ru-central1-a"
  hostname    = "ptaf-a"
  resources {
    cores  = 4
    memory = 8
  }
  boot_disk {
    initialize_params {
      image_id = "fd8p1mmcim8jllgd7vuc"
      type     = "network-ssd"
      size     = 80
    }
    }


  network_interface {
    subnet_id  = yandex_vpc_subnet.ext-subnet[0].id
    ip_address = "192.168.2.10"
    nat = false
    security_group_ids = [yandex_vpc_security_group.ptaf-sg.id]
}

metadata = {
  user-data = "${data.template_file.cloud_init_lin0.rendered}"
  serial-port-enable = 1
}
}

resource "yandex_compute_instance" "ptaf-b" {
  name        = "ptaf-b"
  zone        = "ru-central1-b"
  hostname    = "ptaf-b"
  resources {
    cores  = 4
    memory = 8
  }
  boot_disk {
    initialize_params {
      image_id = "fd8p1mmcim8jllgd7vuc"
      type     = "network-ssd"
      size     = 80
    }
    }


  network_interface {
    subnet_id  = yandex_vpc_subnet.ext-subnet[1].id
    ip_address = "172.18.0.10"
    nat = false
    security_group_ids = [yandex_vpc_security_group.ptaf-sg.id]
}

metadata = {
  user-data = "${data.template_file.cloud_init_lin1.rendered}"
  serial-port-enable = 1
}
}