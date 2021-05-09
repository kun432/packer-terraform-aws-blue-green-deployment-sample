terraform {
  backend "s3" {
    bucket = "my-pkr-tf-bg-deploy-sample"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}