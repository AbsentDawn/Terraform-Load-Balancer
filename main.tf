provider "aws" {
	region="eu-central-1"
}

resource "aws_vpc" "main" {
	cidr_block   	= "10.1.0.0/16"
	tags {
		Name = "VPC-Kevin"
	}
}

resource "aws_internet_gateway" "gw" {
 vpc_id      = "${aws_vpc.main.id}"

 tags {
   Name = "Kevin-Gateway"
 }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Kevin Public"
  }
}

data "template_file" "app_init" {
  template = "${file("./scripts/app_user_data.sh")}"

  vars {
    priv = "${module.db-tier.db_private_ip}"
  }
}

module "app-tier" {
  name="app-kevin"
  source="./modules/tier"
  vpc_id="${aws_vpc.main.id}"
  machine_count = 2
  route_table_id = "${aws_route_table.public.id}"
  cidr_block="10.1.1.0/24"
  user_data=  "${data.template_file.app_init.rendered}"
  ami_id = "ami-e375128c"
  map_public_ip_on_launch = true

  ingress = [{
    from_port     = 80
    to_port       = 80
    protocol      = "tcp"
    cidr_blocks    = "0.0.0.0/0"
    }]
}

module "db-tier" {
  name= "db-kevin"
  source= "./modules/tier"
  vpc_id= "${aws_vpc.main.id}"
  machine_count = 1
  route_table_id = "${aws_vpc.main.main_route_table_id}"
  cidr_block= "10.1.2.0/24"
  user_data= ""
  ami_id = "ami-6175120e"

  ingress = [{
    from_port     = 27017
    to_port       = 27017
    protocol      = "tcp"
    cidr_blocks    = "${module.app-tier.subnet_cidr_block}"
    }]
  }


  # Create a new load balancer
resource "aws_elb" "app-kevin" {
  name               = "app-kevin-elb"
  
  // availability_zones = ["eu-central-1", "us-west-2b", "us-west-2c"]


  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }

  subnets                     = ["${module.app-tier.subnet}"]
  security_groups             = ["${module.app-tier.security_app}"]
  instances                   = ["${module.app-tier.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "app-kevin-terraform-elb"
  }
}