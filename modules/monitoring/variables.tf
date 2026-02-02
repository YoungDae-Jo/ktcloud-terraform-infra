variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍용)"
  type        = string
}

variable "vpc_id" {
  description = "모니터링 서버가 생성될 VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "모니터링 서버가 생성될 Subnet ID"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "SSH 접속을 허용할 CIDR 목록 (예: [본인 공인 IP/32, 조원 IP/32])"
  type        = list(string)
variable "allowed_ssh_cidr" {
  description = "SSH 접속을 허용할 CIDR (예: 본인 공인 IP /32)"
  type        = string
}

variable "instance_type" {
  description = "모니터링 서버 EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 SSH 접속용 Key Pair 이름"
  type        = string
  default     = null
}
############################################
# GitHub Actions Runner bootstrap vars
############################################

variable "github_org" {
  description = "GitHub organization name for org-level self-hosted runner registration"
  type        = string
  default     = "ktcloudmini"
}

variable "ssm_pat_param_name" {
  description = "SSM Parameter Store name (SecureString) that holds GitHub PAT"
  type        = string
  default     = "/cicd/github/pat"
}

variable "ssm_kms_key_arn" {
  description = "Optional CMK ARN for decrypting SecureString. Leave empty if using default key."
  type        = string
  default     = ""
}

