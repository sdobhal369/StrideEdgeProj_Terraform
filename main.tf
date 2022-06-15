
################################################################################
# Jmeter
################################################################################

resource "null_resource" "script_check" {

 provisioner "local-exec" {
    
    command = "/bin/bash script.sh"
  }
}



