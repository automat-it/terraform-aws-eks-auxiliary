variable "name" {
  type    = string
  default = "aws-for-fluent-bit-es"
}

variable "helm_version" {
  type    = string
  default = "0.1.27"
}

variable "fluentbit_tag" {
  type    = string
  default = "2.31.2"
}

variable "helm_namespace" {
  type    = string
  default = "logging"
}

variable "elk_host" {
  type = string
}

variable "elk_region" {
  type = string
}

variable "elk_http_user" {
  type    = string
  default = ""
}

variable "elk_http_password" {
  type    = string
  default = ""
}

variable "elk_index" {
  type    = string
  default = ""
}

variable "elk_logstash_prefix" {
  type    = string
  default = ""
}
