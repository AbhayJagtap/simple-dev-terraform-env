resource "aws_vpc" "zgc_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "zgc_public_subnet" {
  vpc_id                  = aws_vpc.zgc_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"
  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "zgc_igw" {
  vpc_id = aws_vpc.zgc_vpc.id
  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "zgc-rt" {
  vpc_id = aws_vpc.zgc_vpc.id
  tags = {
    Name = "zgc-route-table"
  }
}
resource "aws_route" "default" {
  route_table_id         = aws_route_table.zgc-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.zgc_igw.id

}

resource "aws_route_table_association" "zgc_association" {

  subnet_id      = aws_subnet.zgc_public_subnet.id
  route_table_id = aws_route_table.zgc-rt.id
}

resource "aws_security_group" "zgc-sg" {
  name        = "dev-sg"
  description = "dev security group"
  vpc_id         = aws_vpc.zgc_vpc.id

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["115.160.212.34/32"]
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "zgc_auth" {
  key_name   = "zgckey"
  public_key = file("~/.ssh/zgckey.pub")
}

resource "aws_instance" "dev-node" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.server-ami.id
  key_name               = aws_key_pair.zgc_auth.id
  vpc_security_group_ids = [aws_security_group.zgc-sg.id]
  subnet_id              = aws_subnet.zgc_public_subnet.id
  root_block_device {
    volume_size = 10
  }
 user_data = file("userdata.tpl")
  tags = {
    Name = "dev-node"
  }

}