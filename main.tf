data "template_file" "cloud_init_script" {
  template = file("${path.module}/cloud_init.sh")
}

resource "oci_core_instance" "Ubuntu_vm" {
  availability_domain = var.availability_domain
  shape = "VM.Standard.E3.Flex"
  compartment_id = var.compartment_ocid
  display_name = "ubuntu-docker-vm"

  shape_config {
    ocpus         = 2
    memory_in_gbs = 16
  }

  source_details {
    source_type = "image"
    source_id = var.ubuntu_2204_image_ocid
  }

  create_vnic_details {
    subnet_id = var.subnet_id
    assign_public_ip = true
    display_name = "ubuntu-docker-vm-vnic"
    # hostname_label removed to avoid conflicts on redeployment
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(data.template_file.cloud_init_script.rendered)
  }
}

output "public_ip" {
  value = oci_core_instance.Ubuntu_vm.public_ip
}
