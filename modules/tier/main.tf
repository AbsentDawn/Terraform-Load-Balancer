resource "aws_subnet" "app" {
  vpc_id     = "${var.vpc_id}"
  cidr_block = "${var.cidr_block}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"
  tags {
    Name = "${var.name}"
  }
}

resource "aws_route_table_association" "public-kevin" {
  subnet_id      = "${aws_subnet.app.id}"
  route_table_id = "${var.route_table_id}"
}

resource "aws_security_group" "kevin-app" {
  name        = "${var.name}"
  description = "Allow all inbound traffic"
  vpc_id      = "${var.vpc_id}"


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
   Name = "${var.name}"
 }
}

resource "aws_instance" "app" {
	ami 			= "${var.ami_id}"
	instance_type	= "t2.micro"
	user_data = "${var.user_data}"
  count = "${var.machine_count}"
	subnet_id      = "${aws_subnet.app.id}"
	security_groups = ["${aws_security_group.kevin-app.id}"]
	tags {
		Name = "${var.name}"
	}
}

resource "aws_security_group_rule" "rule-kevin" {
  count             = "${length(var.ingress)}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "${lookup(var.ingress[count.index], "from_port")}"
  to_port           = "${lookup(var.ingress[count.index], "to_port")}"
  cidr_blocks        = ["${lookup(var.ingress[count.index], "cidr_blocks")}"]
  security_group_id = "${aws_security_group.kevin-app.id}"
}