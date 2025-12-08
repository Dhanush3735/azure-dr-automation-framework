variable "name" {
  type = string
}
variable "location" {
  type = string
}

variable "managed_by" {
  type = string
}

variable "tags" {
  type = map(string)
}