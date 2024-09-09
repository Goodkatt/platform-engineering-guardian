variable "default-sg" {
    type = string
    default = "sg-019a505456832b844"
}

variable "db_password" {
    # Get from env TF_VAR_db_password
    type = string
}
variable "ubuntu-2204" {
    type = string
    default = "ami-0932dacac40965a65"
}