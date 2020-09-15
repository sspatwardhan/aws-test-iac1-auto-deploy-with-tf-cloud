variable "privateKey" {
    type = string
    default = "privateKey"
}

variable "publicKey" {
    type = string
    default = "publicKey"
}

variable "plans" {
    type = map
    default = {
        "5USD"   = "1xCPU-1GB"
        "10uSD"  = "1xCPU-2GB"
        "20USD"  = "2xCPU-4GB"
    }
}

variable "users" {
    type = list
    default = ["root", "user1", "user2"] 
}