provider "aws" {
  region     = "ap-south-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true


  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"


  tags = {
    Name = "private-subnet"
  }
}

resource "aws_eip" "eip" {
  vpc      = true
  tags = {
    Name = "eip"
  }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet1.id


  tags = {
    Name = "nat-gateway"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id


  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.myvpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt1"
  }
}


resource "aws_route_table_association" "associate1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt1.id
}







resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.myvpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "rt2"
  }
}


resource "aws_route_table_association" "associate2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt2.id
}

provider "tls" {}
resource "tls_private_key" "t" {
    algorithm = "RSA"
}
resource "aws_key_pair" "test" {
    key_name   = "mykey123"
    public_key = tls_private_key.t.public_key_openssh
}
provider "local" {}
resource "local_file" "key" {
    content  = tls_private_key.t.private_key_pem
    filename = "mykey123.pem"
       
}


resource "aws_security_group" "wp_sg" {
  name        = "wp"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id


 ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


 ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "wp_sg"
  }
}

resource "aws_instance" "wp_os" {
  ami           = "ami-7e257211"
  instance_type = "t2.micro"
  key_name      = "mykey123"
  subnet_id =  aws_subnet.subnet1.id
  vpc_security_group_ids = [ aws_security_group.wp_sg.id ]
  tags = {
    Name = "wp_os"
  }
}


resource "aws_security_group" "mysql_sg" {
  name        = "basic"
  description = "Allow MySQL"
  vpc_id      = aws_vpc.myvpc.id


  ingress {
    description = "mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ aws_security_group.wp_sg.id ]
  }

  tags = {
    Name = "mysql_sg"
  }
}


resource "aws_instance" "mysql_os" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name      = "mykey123"
  subnet_id =  aws_subnet.subnet2.id
  vpc_security_group_ids = [ aws_security_group.mysql_sg.id ]
  tags = {
    Name = "mysql_os"
  }
}





