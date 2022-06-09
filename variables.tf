variable "sonar_repository" {
 description = "Repository URL where to locate the requested chart." 
 type = string
 default = ""
 }

 variable "sonar_chart" {
 description = "Chart name to be installed" 
 type = string
 default = ""
 }

 variable "sonar_namespace" {
 description = "The namespace to install the release into." 
 type = string
 default = ""
 }

 variable "sonar_chart_version" {
 description = "The namespace to install the release into." 
 type = string
 default = ""
 }


variable "access_key" {
    type = string
    default = ""
}

variable "secret_key" {
  type = string
  default = ""
}

variable "region" {
  type = string
  default = ""
}

