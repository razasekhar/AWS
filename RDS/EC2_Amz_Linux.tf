# Specify the AWS provider and region
provider "aws" {
  region = "us-east-2"  # Replace with your desired region
}

# VPC (optional) - If not using an existing VPC, this creates one with a subnet
resource "aws_vpc" "Raj_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Internet Gateway for the VPC
resource "aws_internet_gateway" "Raj_igw" {
  vpc_id = aws_vpc.Raj_vpc.id
}

# Route Table for public subnets
resource "aws_route_table" "Raj_route_table" {
  vpc_id = aws_vpc.Raj_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Raj_igw.id
  }
}

# Associate the route table with each public subnet
resource "aws_route_table_association" "subnet_az1_association" {
  subnet_id      = aws_subnet.Raj_subnet1.id
  route_table_id = aws_route_table.Raj_route_table.id
}

resource "aws_route_table_association" "subnet_az2_association" {
  subnet_id      = aws_subnet.Raj_subnet2.id
  route_table_id = aws_route_table.Raj_route_table.id
}

resource "aws_subnet" "Raj_subnet1" {
  vpc_id                  = aws_vpc.Raj_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"  # Adjust for your region
  map_public_ip_on_launch = true          # Enable public IP for instances
}
resource "aws_subnet" "Raj_subnet2" {
  vpc_id                  = aws_vpc.Raj_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"  # Adjust for your region
  map_public_ip_on_launch = true          # Enable public IP for instances
}

# Security group for EC2 with port 22 open
resource "aws_security_group" "Raj_ec2_sg" {
  vpc_id = aws_vpc.Raj_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0","3.16.146.0/29"]  # Open to all IPs; restrict as needed
  }
  ingress  {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress  {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to all (use specific IPs in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for RDS (allowing connections on PostgreSQL default port)
resource "aws_security_group" "Raj_rds_sg" {
  vpc_id = aws_vpc.Raj_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to all IPs; restrict as needed
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to all (use specific IPs in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "Raj_Amz_Linux" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI for us-east-2
  instance_type          = "t2.micro"              # Choose instance type
  subnet_id              = aws_subnet.Raj_subnet1.id
  vpc_security_group_ids = [aws_security_group.Raj_ec2_sg.id]

  associate_public_ip_address = true               # Enable public IP
  key_name                    = "New_Keypair"      # Replace with your key pair name

  tags = {
    Name = "RajRDSEC2Instance"
  }
}

# PostgreSQL RDS Instance
resource "aws_db_instance" "Raj_postgres" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "17.1"                  # Choose PostgreSQL version
  instance_class         = "db.t3.micro"  
  username               = "Raja"                 # Master username
  password               = "password"            # Master password (replace with strong password)
  publicly_accessible    = true                    # Make it publicly accessible
  vpc_security_group_ids = [aws_security_group.Raj_rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.Raj_db_subnet_group.name
  
  skip_final_snapshot = true

  tags = {
    Name = "RajPostgresDB"
  }
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "Raj_db_subnet_group" {
  name       = "raj-db-subnet-group"
  subnet_ids = [aws_subnet.Raj_subnet1.id, aws_subnet.Raj_subnet2.id]

  tags = {
    Name = "RajDBSubnetGroup"
  }
}

output "public_ip" {

 value = aws_instance.Raj_Amz_Linux.public_ip
  
}

output "DB_identifier" {

  value = aws_db_instance.Raj_postgres.identifier
    
}

output "DB_endpoint" {
  value = aws_db_instance.Raj_postgres.endpoint
  
}
