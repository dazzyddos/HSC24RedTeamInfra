// We will create one vpc
// We will then create two subnets (one we will make public and another private)
// to make subnet1 public we will make use of internet gateway
// we will allow outbound internet connection through subnet2 using nat gateway

// vpc in which we will create our subnets (inside subnets we will have our instances)

resource "aws_vpc" "myvpc" {
    cidr_block = "10.0.0.0/16"
}

// first subnet, we will make this subnet for bastion host
resource "aws_subnet" "subnet1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = var.avl_zone
}

// second subnet, we will make this subnet private(internal) for c2server, redelk, phishing server
resource "aws_subnet" "subnet2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = var.avl_zone
}

// we are creating internet gateway for our subnet1
resource "aws_internet_gateway" "myinternetgw" {
    vpc_id = aws_vpc.myvpc.id
}

// we are creating routetable for our subnet1 which will route the traffic to and fro from internet
resource "aws_route_table" "myroutetable" {
    vpc_id = aws_vpc.myvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myinternetgw.id
    } 
}

// associated routetable that we created above with our subnet1 
resource "aws_route_table_association" "awsrt-assoc" {
    subnet_id = aws_subnet.subnet1.id
    route_table_id = aws_route_table.myroutetable.id
}

resource "aws_route_table" "nat-route-table-subnet2" {
    depends_on = [aws_nat_gateway.nat-gw]
    vpc_id = aws_vpc.myvpc.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.nat-gw.id
    }
}

// from here on we will create elastic ip, nat gateway, route table for nat gateway and associate that route table to our subnet2(private subnet)
resource "aws_eip" "my-eip" {
    domain              = "vpc"
    public_ipv4_pool = "amazon"
}

resource "aws_nat_gateway" "nat-gw" {
    depends_on = [aws_eip.my-eip]
    allocation_id = aws_eip.my-eip.id
    subnet_id     = aws_subnet.subnet1.id
}

resource "aws_route_table_association" "subnet1-nat-route-table-association" {
    depends_on = [
      aws_route_table.nat-route-table-subnet2
    ]

    subnet_id = aws_subnet.subnet2.id
    route_table_id = aws_route_table.nat-route-table-subnet2.id
}
