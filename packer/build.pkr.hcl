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
      "sudo yum install -y amazon-cloudwatch-agent collectd"
    ]
  }
  provisioner "file" {
    source = "files/cwa_config.json"
    destination = "/tmp/cwa_config.json"
  }
  provisioner "shell" {
    inline = [
      "sudo cp /tmp/cwa_config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
      "sudo systemctl enable collectd"
      "sudo systemctl enable amazon-cloudwatch-agent"
    ]
  }
  post-processor "amazon-ami-management" {
    regions = [var.region]
    identifier = local.prj_name
    keep_releases = 3
  }
}
