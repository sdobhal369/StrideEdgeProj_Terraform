resource "aws_vpc" "main" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "starterkit-vpc"
  }
}
################################################################################
# internet gateway  
################################################################################

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "starterkit-internetgw"
  }
}

################################################################################
# Public Subnet1  
################################################################################

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.5.0/24"
  availability_zone = "us-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "starterkit-public1"
  }
}
################################################################################
# Public Subnet2  
################################################################################

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.6.0/24"
  availability_zone = "us-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "starterkit-public2"
  }
}

################################################################################
# Private Subnet1  
################################################################################

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.7.0/24"
  availability_zone = "us-west-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "starterkit-private1"
  }
}
################################################################################
# private Subnet2  
################################################################################

resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.8.0/24"
  availability_zone = "us-west-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "starterkit-private2"
  }
}

################################################################################
# Elastic Ip1  
################################################################################
resource "aws_eip" "eip1" {

  vpc = true

  tags = {
    Name = "starterkit-eip1"
  }
}

################################################################################
# Elastic Ip2  
################################################################################
resource "aws_eip" "eip2" {

  vpc = true

  tags = {
    Name = "starterkit-eip2"
  }
}

################################################################################
# Nategateway
################################################################################

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "starterkit-gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}


################################################################################
# public route Table1 
################################################################################
resource "aws_route_table" "publicroutetable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "staterkit-publicroutetable"
  }
}

################################################################################
# Private route Table2 
################################################################################
resource "aws_route_table" "Privateroutetable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }


  tags = {
    Name = "staterkit-privateroutetable2"
  }
}
################################################################################
# Public subnet1 associate to the route table 
################################################################################

resource "aws_route_table_association" "publicSubnet1RouteTableAssociation" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.publicroutetable.id
}

################################################################################
# Public subnet2 associate to the route table 
################################################################################

resource "aws_route_table_association" "publicSubnet2RouteTableAssociation" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.publicroutetable.id
}
################################################################################
# Private subnet1 associate to the route table 
################################################################################

resource "aws_route_table_association" "privateSubnet1RouteTableAssociation" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.Privateroutetable.id
}

################################################################################
# Private subnet2 associate to the route table 
################################################################################

resource "aws_route_table_association" "privateSubnet2RouteTableAssociation" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.Privateroutetable.id
}

################################################################################
# security group 
################################################################################

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Starterkit-sg"
  }
}

################################################################################
# Jenkins role 
################################################################################

resource "aws_iam_role" "Jenkins-role" {
  name = "Jenkins_role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "full-policy" {
  name        = "ecr-policy"
  description = "ecr full policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
   "ec2:AcceptVpcPeeringConnection",
   "ec2:AcceptVpcEndpointConnections",
   "ec2:AllocateAddress",
   "ec2:AssignIpv6Addresses",
   "ec2:AssignPrivateIpAddresses",
   "ec2:AssociateAddress",
   "ec2:AssociateDhcpOptions",
   "ec2:AssociateRouteTable",
   "ec2:AssociateSubnetCidrBlock",
   "ec2:AssociateVpcCidrBlock",
   "ec2:AttachClassicLinkVpc",
   "ec2:AttachInternetGateway",
   "ec2:AttachNetworkInterface",
   "ec2:AttachVpnGateway",
   "ec2:AuthorizeSecurityGroupEgress",
   "ec2:AuthorizeSecurityGroupIngress",
   "ec2:CreateCarrierGateway",
   "ec2:CreateCustomerGateway",
   "ec2:CreateDefaultSubnet",
   "ec2:CreateDefaultVpc",
   "ec2:CreateDhcpOptions",
   "ec2:CreateEgressOnlyInternetGateway",
   "ec2:CreateFlowLogs",
   "ec2:CreateInternetGateway",
   "ec2:CreateLocalGatewayRouteTableVpcAssociation",
   "ec2:CreateNatGateway",
   "ec2:CreateNetworkAcl",
   "ec2:CreateNetworkAclEntry",
   "ec2:CreateNetworkInterface",
   "ec2:CreateNetworkInterfacePermission",
   "ec2:CreateRoute",
   "ec2:CreateRouteTable",
   "ec2:CreateSecurityGroup",
   "ec2:CreateSubnet",
   "ec2:CreateTags",
   "ec2:CreateVpc",
   "ec2:CreateVpcEndpoint",
   "ec2:CreateVpcEndpointConnectionNotification",
   "ec2:CreateVpcEndpointServiceConfiguration",
   "ec2:CreateVpcPeeringConnection",
   "ec2:CreateVpnConnection",
   "ec2:CreateVpnConnectionRoute",
   "ec2:CreateVpnGateway",
   "ec2:DescribeVpcAttribute",
   "ec2:DescribeVpcClassicLink",
   "ec2:DescribeVpcClassicLinkDnsSupport",
   "ec2:DescribeVpcEndpointConnectionNotifications",
   "ec2:DescribeVpcEndpointConnections",
   "ec2:DescribeVpcEndpoints",
   "ec2:DescribeVpcEndpointServiceConfigurations",
   "ec2:DescribeVpcEndpointServicePermissions",
   "ec2:DescribeVpcEndpointServices",
   "ec2:DescribeVpcPeeringConnections",
   "ec2:DescribeVpcs",
   "ec2:DescribeVpnConnections",
   "ec2:DescribeVpnGateways",
   "ec2:DetachClassicLinkVpc",
   "ec2:DetachInternetGateway",
   "ec2:DetachNetworkInterface",
   "ec2:DetachVpnGateway",
   "ec2:DisableVgwRoutePropagation",
   "ec2:DisableVpcClassicLink",
   "ec2:DisableVpcClassicLinkDnsSupport",
   "ec2:DisassociateAddress",
   "ec2:DisassociateRouteTable",
   "ec2:DisassociateSubnetCidrBlock",
   "ec2:DisassociateVpcCidrBlock",
   "ec2:EnableVgwRoutePropagation",
   "ec2:EnableVpcClassicLink",
   "ec2:EnableVpcClassicLinkDnsSupport",
   "ec2:ModifyNetworkInterfaceAttribute",
   "ec2:ModifySecurityGroupRules",
   "ec2:ModifySubnetAttribute",
   "ec2:ModifyVpcAttribute",
   "ec2:ModifyVpcEndpoint",
   "ec2:ModifyVpcEndpointConnectionNotification",
   "ec2:ModifyVpcEndpointServiceConfiguration",
   "ec2:ModifyVpcEndpointServicePermissions",
   "ec2:ModifyVpcPeeringConnectionOptions",
   "ec2:ModifyVpcTenancy",
   "ec2:MoveAddressToVpc",
   "ec2:RejectVpcEndpointConnections",
   "ec2:RejectVpcPeeringConnection",
   "ec2:ReleaseAddress",
   "ec2:ReplaceNetworkAclAssociation",
   "ec2:ReplaceNetworkAclEntry",
   "ec2:ReplaceRoute",
   "ec2:ReplaceRouteTableAssociation",
   "ec2:ResetNetworkInterfaceAttribute",
   "ec2:RestoreAddressToClassic",
   "ec2:RevokeSecurityGroupEgress",
   "ec2:RevokeSecurityGroupIngress",
   "ec2:UnassignIpv6Addresses",
   "ec2:UnassignPrivateIpAddresses",
   "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
   "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
   "logs:CreateLogGroup",
   "logs:CreateLogStream'",
   "logs:PutLogEvents'",
   "ec2:CreateNetworkInterface'",
   "ec2:DescribeDhcpOptions'",
   "ec2:DescribeNetworkInterfaces'",
   "ec2:DeleteNetworkInterface'",
   "ec2:DescribeSubnets'",
   "ec2:DescribeSecurityGroups'",
   "ec2:DescribeVpcs'",
   "ec2:CreateNetworkInterfacePermission'",
   "ecr:GetAuthorizationToken",
   "ecr:BatchCheckLayerAvailability",
   "ecr:GetDownloadUrlForLayer",
   "ecr:GetRepositoryPolicy",
   "ecr:DescribeRepositories",
   "ecr:ListImages",
   "ecr:DescribeImages",
   "ecr:BatchGetImage",
   "ecr:GetLifecyclePolicy",
   "ecr:GetLifecyclePolicyPreview",
   "ecr:ListTagsForResource",
   "ecr:DescribeImageScanFindings",
   "ecr:InitiateLayerUpload",
   "ecr:UploadLayerPart",
   "ecr:CompleteLayerUpload",
   "ecr:PutImage",
   "eks:*",
   "ecr:*",
   "cloudformation:*",
   "iam:*"
],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.Jenkins-role.name
  policy_arn = aws_iam_policy.full-policy.arn
}

resource "aws_iam_instance_profile" "Jenkins_profile" {
  name = "Jenkins_profile"
  role = aws_iam_role.Jenkins-role.name
}

################################################################################
# Jenkins Instance 
################################################################################
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "Starterkit-Jenkins-sg"
  }
}

resource "aws_instance" "Jenkins" {
  count                  = 1
  subnet_id              = aws_subnet.public1.id
  ami                    = "ami-01f87c43e618bf8f0"
  instance_type          = "t2.micro"
  key_name               = "starterkit"
  availability_zone      = "us-west-1a"
  iam_instance_profile   = aws_iam_instance_profile.Jenkins_profile.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  monitoring             = true
  user_data              = <<-EOF
          #!/bin/bash
          sudo apt-get update -y
          sudo apt install openjdk-8-jdk -y
          sudo apt install wget -y
          wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add
          sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
          sudo apt update -y
          sudo apt-get install jenkins -y
          sudo apt install jenkins -y
          sudo apt update -y 
          EOF
  #volume_id   = aws_ebs_volume.jenkins-volume.id

  depends_on = [
    aws_security_group.jenkins_sg
  ]

  tags = {
    "Name" = "jenkins-starterkit"
  }
}
resource "aws_ebs_volume" "jenkins-volume" {
  availability_zone = "us-west-1a"
  size              = 30
  tags = {
    Name = "Jenkins-volume"
  }
}


################################################################################
# ECR 
################################################################################
resource "aws_ecr_repository" "ECR-node" {
  name                 = "ecr-node"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
resource "aws_ecr_repository_policy" "ECR-node-policy" {
  repository = aws_ecr_repository.ECR-node.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

################################################################################
# EKS Role
################################################################################

resource "aws_iam_role" "node-eks_cluster" {
  name = "eks-node-clusterrole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
################################################################################
# Eks plicy
################################################################################
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.node-eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.node-eks_cluster.name
}
################################################################################
# Eks cluster
################################################################################
resource "aws_eks_cluster" "aws_eks" {
  name     = "eks_cluster_node"
  version  = "1.22"
  role_arn = aws_iam_role.node-eks_cluster.arn


  vpc_config {
    subnet_ids         = [aws_subnet.public1.id, aws_subnet.public2.id]
    security_group_ids = [aws_security_group.eks_sg.id]
  }

  timeouts {
    delete = "30m"
  }

  tags = {
    Name = "EKS_Node"
  }
}
################################################################################
# Eks node role 
################################################################################
resource "aws_iam_role" "eks_nodesrole" {
  name = "eks-node-group-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
################################################################################
# Eks node policy 
################################################################################

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodesrole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodesrole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodesrole.name
}
################################################################################
# Eks node group
################################################################################

resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.aws_eks.name
  node_group_name = "node_group"
  node_role_arn   = aws_iam_role.eks_nodesrole.arn
  subnet_ids      = [aws_subnet.public1.id]
  instance_types  = ["t2.micro"]
  ami_type        = "AL2_x86_64"
  capacity_type   = "ON_DEMAND"
  disk_size       = 20

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}
resource "aws_security_group" "eks_sg" {
  name        = "eks-allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "Starterkit-eks-sg"
  }
}


################################################################################
# Jmeter
################################################################################

resource "kubectl_manifest" "jmeter_master" {
    yaml_body = file("${path.module}/jmeter_master_deploy.yaml")
}

resource "kubectl_manifest" "jmeter_slave" {
    yaml_body = file("${path.module}/jmeter_slaves_deploy.yaml")
}

resource "kubectl_manifest" "jmeter_configmap" {
    yaml_body = file("${path.module}/jmeter_master_configmap.yaml")
}

resource "kubectl_manifest" "jmeter_service" {
    yaml_body = file("${path.module}/jmeter_slaves_svc.yaml")
}



################################################################################
# Sonarqube
################################################################################

// Random string generator for Grafana password
resource "random_string" "sonar" {
  length      = 8
  special     = false
  min_upper   = 3
  number      = false
}


resource "helm_release" "sonar" {
  name       = "sonarqube"
  repository = var.sonar_repository
  chart      = var.sonar_chart
  version    = var.sonar_chart_version
  namespace  = var.sonar_namespace
  atomic     = true

  values = [
    file("${path.module}/values.yaml"),
  <<-EOF
  ingress:
    enabled: true
    hosts:
      - name: sonar.dev01.podiumfive.tech    
        path: / 
    annotations:
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: "true"
      cert-manager.io/cluster-issuer: letsencrypt-prod
      ingress.kubernetes.io/rewrite-target: /
      ingress.kubernetes.io/ssl-redirect: "true"  
EOF
]
  set {
    name  = "image.repository"
    value = "mc1arke/sonarqube-with-community-branch-plugin"
  }
  set {
    name  = "image.tag"
    value = "latest"
  }  
  set {
    name = "jdbcOverwrite.jdbcPassword"
    value = random_string.sonar.result
  }
  set {
    name = "postgresql.postgresqlPassword"
    value = random_string.sonar.result
  }  
  
}
