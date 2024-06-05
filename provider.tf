provider "aws" {
  region = var.eu_central_region
}

provider "aws" {
  alias  = "eu_west"
  region = var.eu_west_region
}