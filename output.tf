output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}


output "db_password"{
    description = "password"
    value       = random_string.sonar.result
    sensitive =  true
}

