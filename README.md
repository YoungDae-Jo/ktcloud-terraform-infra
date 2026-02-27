# KTCloud Mini Project - Infrastructure (Terraform)

## Project Overview

본 프로젝트는 **Terraform 기반 IaC(Infrastructure as Code)** 로 AWS 인프라를 구축하고  
운영 환경에서도 **재현 가능한 클라우드 아키텍처**를 구현하는 것을 목표로 합니다.

서비스 인프라는 **Private Subnet 기반 보안 아키텍처**로 설계되었으며  
외부 접근은 **Application Load Balancer(ALB)** 를 통해서만 허용됩니다.

또한 **Auto Scaling 구조와 Monitoring 환경**을 고려한 인프라를 구축하여  
플랫폼팀과 관제팀이 바로 사용할 수 있는 인프라 환경을 제공합니다.

---

# Role

**조영대 – Infrastructure Engineer**

주요 담당 영역

- AWS 인프라 아키텍처 설계
- Terraform 기반 IaC 구현
- Private Subnet 보안 아키텍처 구축
- NAT Instance 기반 Outbound 설계
- Auto Scaling Group 구성
- GitHub Actions Self-hosted Runner 자동화
- Prometheus Monitoring 연동 준비 (node_exporter)

---

# Architecture

```mermaid
flowchart TB

Internet((Internet))

ALB[Application Load Balancer<br>Public Subnet]

ASG[Service EC2 (ASG)<br>Private Subnet]

NAT[NAT Instance<br>Public Subnet]

MON[Monitoring EC2<br>Bastion / Runner / Ansible]

Internet --> ALB
ALB --> ASG
ASG --> NAT
NAT --> Internet
MON --> ASG
Architecture Design Goals
1. Private 기반 보안 아키텍처

Service 서버는 Private Subnet에만 배치됩니다.
외부에서 접근 가능한 리소스는 ALB만 존재합니다.

Internet
   |
   v
ALB
   |
   v
Service EC2 (Private)
2. Outbound 통신 제어

Private EC2는 인터넷에 직접 접근하지 않으며
Outbound 트래픽은 NAT Instance를 통해서만 통신합니다.

Service EC2
     |
     v
NAT Instance
     |
     v
Internet
3. Auto Scaling 기반 확장 구조

서비스 서버는 Auto Scaling Group 으로 구성되어
트래픽 증가 시 자동 확장이 가능합니다.

Min     : 1
Desired : 1
Max     : 2
4. IaC 기반 인프라 재현성

모든 인프라는 Terraform 코드로 관리됩니다.

동일한 환경을 언제든 재현할 수 있습니다.

terraform destroy
terraform apply
AWS Infrastructure Components
VPC

CIDR

10.0.0.0/16
Subnet 구성
Public Subnet

ALB

NAT Instance

Monitoring EC2

Private Subnet

Service EC2 (Auto Scaling Group)

Security Architecture
External Access Flow
Internet
   |
   v
ALB (80)
   |
   v
Service EC2 (8080)
Security Group Rules
Source	Destination	Port	Description
Internet	ALB	80	서비스 접근
ALB SG	Service SG	8080	애플리케이션
Monitoring SG	Service SG	22	SSH 관리
Monitoring SG	Service SG	9100	Prometheus
Service	NAT	ALL	Outbound
NAT Instance

Private 서버의 인터넷 접근을 위해 NAT Instance를 사용합니다.

설정

Source/Destination Check : Disabled

IP Forwarding : Enabled

iptables MASQUERADE 설정

NAT 검증 방법

Private EC2에서 실행

curl -4 ifconfig.me

결과

NAT Instance Public IP 출력
Monitoring EC2

Monitoring 서버는 다음 역할을 수행합니다.

Monitoring EC2
 ├ Bastion SSH
 ├ GitHub Actions Runner
 ├ Ansible Control Node
 └ Prometheus / Grafana (Planned)
GitHub Actions Runner Automation

Monitoring EC2의 UserData에서 자동 수행됩니다.

자동 설정 항목

AWS Region 자동 설정

SSM Parameter에서 GitHub PAT 조회

GitHub Organization Runner 등록

systemd 서비스 등록

Runner 상태 확인

systemctl status actions.runner.*
Auto Scaling Group

Service 서버는 ASG 기반으로 운영됩니다

Desired Capacity : 1
Min Size         : 1
Max Size         : 2
Health Check     : ELB
Target Group 설정
Port : 8080
Path : /
Prometheus Monitoring 준비

ASG Launch Template의 UserData에서
node_exporter가 자동 설치됩니다.

설치 내용

apt-get update -y
apt-get install -y prometheus-node-exporter

systemctl enable --now prometheus-node-exporter
node_exporter 확인

Service EC2에서 실행

ss -tulnp | grep 9100

metrics 확인

curl localhost:9100/metrics
Monitoring 서버에서 확인
curl http://<SERVICE_PRIVATE_IP>:9100/metrics
Terraform Project Structure
terraform
├── env
│   └── dev
│       ├── main.tf
│       ├── terraform.tfvars
│       └── terraform.tfvars.example
│
├── modules
│   ├── network
│   ├── alb
│   ├── asg
│   ├── monitoring
│   └── nat
Terraform Usage
초기화
cd env/dev
terraform init
실행 계획 확인
terraform plan
인프라 생성
terraform apply
Infrastructure Validation
NAT 확인
curl -4 ifconfig.me
Target Group 상태 확인
aws elbv2 describe-target-health \
--target-group-arn <target_group_arn>
node_exporter 확인
curl localhost:9100/metrics
Infrastructure Destroy
terraform destroy
Key Implementation Points

이번 인프라 구축의 핵심 포인트

Terraform 기반 IaC 인프라 구축

Private Subnet 기반 보안 아키텍처

NAT Instance 기반 Outbound 설계

GitHub Actions Runner 자동화

Auto Scaling 기반 확장 구조

Prometheus Monitoring 준비

Repository
https://github.com/YoungDae-Jo/ktcloud-terraform-infra
