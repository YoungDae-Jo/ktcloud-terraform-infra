KTCloud Mini Project - Infrastructure (Terraform)
Project Overview

본 프로젝트는 Terraform 기반 IaC(Infrastructure as Code) 로 AWS 인프라를 구축하고
운영 환경에서도 재현 가능한 클라우드 아키텍처를 구현하는 것을 목표로 합니다.

서비스 인프라는 Private Subnet 기반 보안 아키텍처로 설계되었으며
외부 접근은 Application Load Balancer(ALB) 를 통해서만 허용됩니다.

또한 Auto Scaling 구조와 Monitoring을 고려한 인프라 환경을 구축하여
플랫폼팀과 관제팀이 바로 활용할 수 있는 환경을 제공합니다.

Role

조영대 – Infrastructure Engineer

담당 영역

AWS 인프라 아키텍처 설계

Terraform 기반 IaC 구현

Private Subnet 보안 아키텍처 구축

NAT Instance 기반 Outbound 설계

Auto Scaling Group 구성

GitHub Actions Self-hosted Runner 자동화

Prometheus Monitoring 연동 준비

Architecture
Architecture Design Goals

본 인프라는 다음 목표를 기반으로 설계되었습니다.

1. Private 기반 보안 구조

서비스 서버는 Private Subnet에만 배치됩니다.

외부에서 접근 가능한 리소스는 ALB만 존재합니다.

Internet → ALB → Service EC2
2. Outbound 통신 제어

Private EC2는 인터넷에 직접 접근하지 않습니다.

Outbound 트래픽은 NAT Instance를 통해서만 가능합니다.

Service EC2 → NAT Instance → Internet
3. Auto Scaling 기반 확장 구조

서비스 서버는 ASG(Auto Scaling Group) 로 구성되어
트래픽 증가 시 자동 확장이 가능합니다.

4. IaC 기반 재현 가능한 인프라

모든 인프라는 Terraform으로 관리됩니다.

terraform destroy
terraform apply

실행 시 동일한 인프라 환경을 다시 생성할 수 있습니다.

AWS Infrastructure Components
VPC
CIDR : 10.0.0.0/16

구성

Public Subnet

Application Load Balancer

NAT Instance

Monitoring EC2

Private Subnet

Service EC2 (Auto Scaling Group)

Security Architecture

외부 접근 구조

Internet
   │
   ▼
ALB (80)
   │
   ▼
Service EC2 (8080)

보안 그룹 정책

Source	Destination	Port	Description
Internet	ALB	80	서비스 접근
ALB SG	Service SG	8080	애플리케이션
Monitoring SG	Service SG	22	SSH 관리
Monitoring SG	Service SG	9100	Prometheus
Service	NAT	ALL	Outbound
NAT Instance

Private 서버의 인터넷 접근을 위해 NAT Instance를 사용합니다.

설정

Source / Destination Check Disabled

IP Forwarding Enabled

iptables MASQUERADE 설정

검증

Private EC2에서 실행

curl -4 ifconfig.me

출력 결과

NAT Instance Public IP
Monitoring EC2

Monitoring 서버는 다음 역할을 수행합니다.

Monitoring EC2
 ├ Bastion SSH
 ├ GitHub Actions Runner
 ├ Ansible Control Node
 └ Prometheus / Grafana 예정
GitHub Actions Runner Automation

Monitoring EC2의 UserData 스크립트에서 자동으로 수행됩니다.

자동 설정

AWS Region 자동 설정

AWS SSM Parameter에서 GitHub PAT 조회

GitHub Organization Runner 등록

systemd 서비스 등록

Runner 상태 확인

systemctl status actions.runner.*
Auto Scaling Group

서비스 서버는 ASG 기반으로 구성됩니다.

설정

Desired Capacity : 1
Min Size         : 1
Max Size         : 2
HealthCheck      : ELB

Target Group

Port : 8080
Path : /
Monitoring Integration

ASG Launch Template의 UserData에서
node_exporter가 자동 설치됩니다.

설치

apt-get install prometheus-node-exporter
systemctl enable --now prometheus-node-exporter

확인

ss -tulnp | grep 9100

metrics 확인

curl localhost:9100/metrics

Monitoring 서버에서 확인

curl http://<SERVICE_PRIVATE_IP>:9100/metrics
Terraform Project Structure
terraform
 ├ env
 │   └ dev
 │       ├ main.tf
 │       ├ terraform.tfvars
 │       └ terraform.tfvars.example
 │
 ├ modules
 │   ├ network
 │   ├ alb
 │   ├ asg
 │   ├ monitoring
 │   └ nat
 │
 ├ README.md
 └ .gitignore
Terraform Usage

초기화

terraform init

실행 계획 확인

terraform plan

인프라 생성

terraform apply

인프라 삭제

terraform destroy
Infrastructure Validation

NAT 확인

curl -4 ifconfig.me

Target Group 상태

aws elbv2 describe-target-health \
--target-group-arn <target_group_arn>

Node Exporter 확인

curl localhost:9100/metrics
Key Implementation Points

본 인프라 구현의 핵심 포인트

Terraform 기반 IaC 인프라 구축

Private 기반 보안 아키텍처

NAT Instance 기반 Outbound 통신 구조

Auto Scaling 기반 확장 구조

GitHub Actions Self-hosted Runner 자동화

Prometheus Monitoring 연동 준비

Repository

Project Repository

https://github.com/ktcloudmini/infra
Summary

Terraform 기반 IaC를 활용하여

Private 기반 보안 아키텍처

ALB + ASG 기반 확장 구조

NAT 기반 Outbound 통신

CI/CD 및 Monitoring 연동 환경

을 갖춘 운영 가능한 AWS 인프라 환경을 구축하였다.
