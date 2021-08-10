terraform {
  backend "s3" {
    bucket                      = "terrastate"
    key                         = "example.tfstate"
    endpoint                    = "s3.dbl.cloud.syseleven.net"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

