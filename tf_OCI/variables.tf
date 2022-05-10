#OPC Provider's variables
variable "user" {}
variable "password" {}

variable "identity_domain" {
    default = "596086526"
}

variable "site" {
    default = "usdc6"
}

# define map of site /endpoint realtions
variable "endpoint" {
    type = "map"
    default = [
        "usdc6"  = "https://api-255.compute.us6.oraclecloud.com"
        "other"  = "https://other.other.com/"
    ]
}

#other variables
variable "tags" {
    default = ["DEMO","SANDBOX"]
}

