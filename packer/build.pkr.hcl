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
  post-processor "amazon-ami-management" {
    regions = [var.region]
    identifier = local.prj_name
    keep_releases = 3
  }
}
