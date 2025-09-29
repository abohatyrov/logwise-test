variable "project_id" { 
  type    = string  
  default = ""
}

variable "region" { 
  type    = string  
  default = "us-central1"
}

variable "service_name" { 
  type    = string
  default = ""
}

variable "github_repo" { 
  type = string
  default = ""
}

variable "env" { 
  type    = string
  default = ""
}

variable "env_prefix" { 
  type    = string
  default = ""
}

variable "repo_id" { 
  type    = string
  default = ""
}

variable "image" { 
  type    = string
  default = ""
}

variable "wif_pool_id" { 
  type    = string
  default = ""
}

variable "wif_provider_id" { 
  type    = string
  default = ""
}

variable "app_envs" { 
  type    = map(any)
  default = {}
}

variable "tfstate_bucket" {
  type    = string
  default = ""
}