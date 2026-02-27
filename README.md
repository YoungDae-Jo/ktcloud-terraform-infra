KTCloud Mini Project - Infrastructure (Terraform)
1. 담당 영역

조영대 – Infrastructure (IaC / AWS Architecture)

본 인프라 구성은 Terraform 기반 IaC(Infrastructure as Code) 방식으로 구축되었으며
운영 환경에서도 재현 가능한 AWS 인프라 자동화를 목표로 설계되었습니다.

주요 역할

AWS 인프라 아키텍처 설계

Terraform 기반 IaC 구축

Private 기반 보안 아키텍처 설계

NAT 기반 Outbound 통신 구조 구현

GitHub Actions Runner 자동화

Monitoring 연동 준비(node_exporter)

2. 전체 아키텍처
Internet
   │
   ▼
ALB (Public Subnet)
   │
   ▼
ASG Service EC2 (Private Subnet)
   │
   ▼
NAT Instance
   │
   ▼
Internet Outbound

운영/배포 관리 노드

Monitoring EC2 (Public)
 ├ Bastion SSH
 ├ GitHub Actions Runner
 ├ Ansible 실행 노드
 └ Prometheus/Grafana 설치 예정

핵심 설계 목표

Service 서버는 Private Subnet

외부 노출은 ALB만 허용

Service 서버는 인터넷 직접 접근 불가

Outbound는 NAT Instance 경유

IaC 기반 destroy → apply 재현성 확보

3. 인프라 구성 요소
VPC
VPC CIDR : 10.0.0.0/16

구성

Public Subnet
 - ALB
 - NAT Instance
 - Monitoring EC2

Private Subnet
 - Service EC2 (ASG)
4. Security Architecture

외부 접근 구조

Internet
   │
   ▼
ALB (80)
   │
   ▼
Service EC2 (8080)

보안 그룹 정책

Source	Destination	Port	설명
Internet	ALB	80	서비스 접근
ALB SG	Service SG	8080	애플리케이션
Monitoring SG	Service SG	22	SSH 관리
Monitoring SG	Service SG	9100	Prometheus
Service	NAT	ALL	Outbound
5. NAT Instance

Private 서버의 인터넷 접근을 위해 NAT Instance를 사용합니다.

설정

Source/Destination Check : Disabled

IP Forwarding : Enabled

iptables MASQUERADE 설정

확인 방법

Private EC2에서 실행

curl -4 ifconfig.me

결과

NAT Instance Public IP 출력
6. Monitoring EC2 역할

Monitoring EC2는 다음 역할을 수행합니다.

Monitoring EC2
 ├ Bastion (SSH 접속)
 ├ GitHub Actions Self-hosted Runner
 ├ Ansible 실행 노드
 └ Prometheus / Grafana 설치 예정
7. GitHub Actions Runner 자동화

Monitoring EC2의 userdata에서 다음 작업이 자동 수행됩니다.

AWS Region 자동 설정

SSM에서 GitHub PAT 조회

GitHub Org Runner 등록

systemd 서비스 등록

Runner 상태 확인

systemctl status actions.runner.*
8. Auto Scaling Group

Service 서버는 ASG로 구성되어 자동 확장이 가능합니다.

구성

Desired : 1
Min     : 1
Max     : 2
HealthCheck : ELB

HealthCheck

ALB Target Group
Port : 8080
Path : /
9. Prometheus Monitoring 준비

ASG Launch Template의 userdata에서
node_exporter가 자동 설치됩니다.

설치 내용

apt-get install prometheus-node-exporter
systemctl enable --now prometheus-node-exporter

확인

ss -tulnp | grep 9100

metrics 확인

curl localhost:9100/metrics

Monitoring 서버에서 확인

curl http://<SERVICE_PRIVATE_IP>:9100/metrics
10. Terraform 구조

프로젝트 구조

terraform
 ├ env
 │   └ dev
 │       ├ main.tf
 │       ├ terraform.tfvars
 │
 ├ modules
 │   ├ network
 │   ├ alb
 │   ├ asg
 │   ├ monitoring
 │   └ nat

설계 원칙

모듈 기반 구조

환경 분리(dev/prod 확장 가능)

변수 기반 인프라 구성

11. Terraform 실행 방법
1. 초기화
terraform init
2. 계획 확인
terraform plan
3. 인프라 생성
terraform apply
12. 인프라 검증 방법
NAT 검증

Private 서버에서

curl -4 ifconfig.me
Target Group 상태
aws elbv2 describe-target-health \
--target-group-arn <target_group_arn>
node_exporter 확인
curl localhost:9100/metrics
13. 종료
terraform destroy
14. 핵심 구현 포인트

이번 인프라 구현의 핵심 포인트는 다음과 같습니다.

Terraform 기반 IaC 운영 인프라 구축

Private 기반 보안 아키텍처

NAT Instance 기반 Outbound 설계

GitHub Runner 자동화

ASG 기반 확장 가능한 구조

Prometheus Monitoring 준비

## 15. 실행 방법 (Quick Start)

### 1. Repository Clone

```bash
git clone https://github.com/ktcloudmini/infra.git
cd infra
2. Terraform 변수 설정

예시 파일을 복사합니다.

cp env/dev/terraform.tfvars.example env/dev/terraform.tfvars

필요 시 값을 수정합니다.

nano env/dev/terraform.tfvars
3. Terraform 실행
cd env/dev
terraform init
terraform plan
terraform apply
4. 인프라 검증

NAT 확인

curl -4 ifconfig.me

Node Exporter 확인

ss -tulnp | grep 9100

ALB Target 상태 확인

aws elbv2 describe-target-health \
--target-group-arn <target_group_arn>
5. 인프라 삭제
terraform destroy
