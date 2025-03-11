provider aws {
  region = ap-south-1
}

# Fetch the existing IAM roles you created manually
data aws_iam_role eks_cluster_role {
  name = eks-cluster-role
}

data aws_iam_role eks_node_role {
  name = eks-node-group-role
}

# Create VPC for EKS
resource aws_vpc eks_vpc {
  cidr_block           = 10.0.0.016
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = eks-vpc
  }
}

# Create Public Subnets
resource aws_subnet subnet_1 {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = 10.0.1.024
  availability_zone       = ap-south-1a
  map_public_ip_on_launch = true  # ✅ Enable auto-assign public IPs

  tags = {
    Name = eks-subnet-1
  }
}

resource aws_subnet subnet_2 {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = 10.0.2.024
  availability_zone       = ap-south-1b
  map_public_ip_on_launch = true  # ✅ Enable auto-assign public IPs

  tags = {
    Name = eks-subnet-2
  }
}

# Create an Internet Gateway
resource aws_internet_gateway eks_igw {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = eks-igw
  }
}

# Create a Route Table
resource aws_route_table eks_route_table {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = eks-route-table
  }
}

# Create a Default Route in the Route Table
resource aws_route default_route {
  route_table_id         = aws_route_table.eks_route_table.id
  destination_cidr_block = 0.0.0.00
  gateway_id             = aws_internet_gateway.eks_igw.id
}

# Associate Subnets with the Route Table
resource aws_route_table_association subnet_1_assoc {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.eks_route_table.id
}

resource aws_route_table_association subnet_2_assoc {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.eks_route_table.id
}

# Security Group for EKS
resource aws_security_group eks_sg {
  vpc_id = aws_vpc.eks_vpc.id
  name   = eks-security-group

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = tcp
    cidr_blocks = [0.0.0.00] # Allow all traffic (Adjust based on your needs)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [0.0.0.00]
  }

  tags = {
    Name = eks-sg
  }
}

# Create the EKS Cluster
resource aws_eks_cluster my_eks_cluster {
  name     = my-cluster
  role_arn = data.aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
    security_group_ids = [aws_security_group.eks_sg.id]
  }

  tags = {
    Name = my-eks-cluster
  }
}

# Create EKS Node Group (Worker Nodes)
resource aws_eks_node_group my_node_group {
  cluster_name    = aws_eks_cluster.my_eks_cluster.name
  node_group_name = my-node-group
  node_role_arn   = data.aws_iam_role.eks_node_role.arn

  subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = [t3.medium]

  tags = {
    Name = eks-node-group
  }
}
