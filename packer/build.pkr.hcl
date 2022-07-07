build {
  sources = [
    "source.amazon-ebs.webserver"
  ]
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install -y epel",
      "sudo yum install -y @development jq git",
      "sudo yum install httpd -y",
      "sudo sed -i -e 's/^Listen 80$/Listen 8080/g' /etc/httpd/conf/httpd.conf",
      "echo 'version 2' | sudo tee /var/www/html/index.html",
      "sudo systemctl enable httpd",
      "sudo yum install -y amazon-cloudwatch-agent collectd",
      "sudo systemctl enable collectd",
    ]
  }
  provisioner "file" {
    source = "collectdctl.conf"
    destination = "/tmp/collectdctl.conf"
  }
  provisioner "file" {
    source = "mailq.conf"
    destination = "/tmp/mailq.conf"
  }
  provisioner "file" {
    source = "mailq.sh"
    destination = "/tmp/mailq.sh"
  }
  provisioner "file" {
    source = "auth_file"
    destination = "/tmp/auth_file"
  }
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/collectdctl.conf /etc/collectd.d/.",
      "sudo mv /tmp/mailq.conf /etc/collectd.d/.",
      "sudo mv /tmp/auth_file /etc/collectd.d/.",
      "sudo mv /tmp/mailq.sh /usr/lib64/collectd/.",
      "sudo chmod 644 /etc/collectd.d/collectdctl.conf",
      "sudo chmod 644 /etc/collectd.d/mailq.conf",
      "sudo chmod 644 /etc/collectd.d/auth_file",
      "sudo chmod 755 /usr/lib64/collectd/mailq.sh"
    ]
  }
  post-processor "amazon-ami-management" {
    regions = [var.region]
    identifier = local.prj_name
    keep_releases = 3
  }
}
