################################################################################
# Deployment (Sonarqube, Jmeter, Nexus) 
################################################################################

resource "null_resource" "script_check" {

 provisioner "local-exec" {
    
    command = <<EOT
        bash script.sh
        kubectl expose service sonarqube-sonarqube -n sonarqube --type=NodePort --target-port=9000 --name=sonarqube
   EOT     
  }
}



