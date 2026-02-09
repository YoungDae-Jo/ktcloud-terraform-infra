# KT Cloud Infra Project (Terraform 기반 운영 인프라)

##  Project Overview

Terraform 기반 IaC(Infrastructure as Code)로  
운영 가능한 AWS 인프라 아키텍처를 설계 및 구축.

###  설계 목표

- Public 노출은 ALB만 허용
- Service 서버는 Private Subnet 고정
- Outbound는 NAT Instance 경유만 허용
- Monitoring EC2를 통한 Bastion / CD / Ansible 실행
- destroy → apply 재현성 보장
- Prometheus 연동을 위한 자동 모니터링 기반 구축

---

#  전체 아키텍처

```mermaid
flowchart TB
  Internet((Internet))

  subgraph Public Subnet
    ALB[ALB]
    NAT[NAT Instance]
    MON[Monitoring EC2\n(Bastion + Runner + Ansible)]
  end

  subgraph Private Subnet
    ASG[ASG Service Instances\n(Node Exporter :9100)]
  end

  Internet --> ALB
  ALB --> ASG

  ASG -->|Outbound Only| NAT
  NAT --> Internet

  MON -->|SSH 22| ASG
  MON -->|Node Exporter 9100| ASG

  %% Prometheus (관제팀 설치 예정)
  MON -. EC2 Service Discovery .-> ASG
```

---

#  인프라 구성 요소

## 1 Network

- VPC
- Public / Private Subnet 분리
- IGW 연결
- Private Route → NAT Instance
# KTCloud INFRA PROJECT (Terraform)

## 0. Goal
Terraform 기반으로 AWS 인프라를 IaC로 구축하고, 아래 목표를 충족한다.

- 구조: ALB (Public) → ASG(Service EC2, Private Subnet)
- Monitoring EC2 (Public) 제공
- Private Subnet 인스턴스는 NAT을 통해서만 외부 통신
- destroy → apply 재현성 확보
- Day5 성공 기준:
  - NAT 전용 EC2 분리
  - Private EC2 인터넷 통신 성공
  - nginx 자동 설치 성공
  - Target Group Healthy
  - ALB DNS 200 응답
  - ASG Scale-out 정상

---

## 1. Architecture

Internet
|
v
[ ALB (Public Subnets) ]
|
v
[ Target Group ]
|
v
[ ASG Service EC2 (Private Subnets) ] ---> outbound ---> [ NAT Instance (Public) ] ---> Internet

[ Monitoring EC2 (Public) ] : 운영/점검(관제팀 설치 가능)

검증 완료:
- Public → Internet OK
- Private → NAT 경유 Outbound OK

---

## 2 NAT Instance

- Source/Dest Check 비활성화
- IP Forwarding 활성화
- iptables MASQUERADE 설정
- Private Route Table 연결

검증:
- Private EC2 → GitHub API OK
- Private EC2 → apt install OK

---

## 3 Monitoring EC2

역할:

- Bastion (SSH 진입)
- GitHub Actions Runner
- Ansible 실행 노드
- Prometheus 설치 대상 (관제팀 작업)

IAM Instance Profile 적용:

- ec2:DescribeInstances
- ec2:DescribeTags
- ssm:GetParameter

검증:

```bash
aws ec2 describe-instances --max-results 5 >/dev/null && echo OK
aws ec2 describe-tags --max-results 5 >/dev/null && echo OK
```

---

## 4 ASG (Service)

- Private Subnet 배치
- Launch Template 사용
- ALB Target Group 연결
- Desired / Min / Max 설정

---

## 5 Node Exporter 자동화

ASG user_data에 포함:

- node_exporter 설치
- systemd 등록
- 자동 실행

검증:

```bash
curl localhost:9100/metrics | head
systemctl is-active node_exporter
```

---

#  Security Group 설계 (SG → SG)

## ALB SG
- 80 from 0.0.0.0/0

## Service SG (ASG)
- 8080 from ALB SG
- 9100 from Monitoring SG
- 8080 from Monitoring SG (옵션)
- 22 from Monitoring SG

## Monitoring SG
- 22 / 3000 / 9090 from allowed CIDR
- outbound all

---

#  Tag 규칙 (Prometheus Discovery 기준)

- Role = monitoring | asg | nat
- PrometheusScrape = true (ASG)

IMDS 확인:

```bash
curl http://169.254.169.254/latest/meta-data/tags/instance/Role
```

---

#  Prometheus 연동 준비 상태

- Monitoring → ASG :9100 접근 성공
- IAM EC2 SD 권한 적용 완료
- Tag 기반 Discovery 가능
- 신규 ASG 인스턴스 자동 node_exporter 실행

관제팀은 Prometheus 설치 후  
EC2 Service Discovery 설정만 추가하면 자동 수집 가능.

---

#  재현성 보장

Terraform 기준:

```bash
terraform destroy
terraform apply
```

동일 아키텍처 재생성 가능.

---

# 현재 프로젝트 상태

| 영역 | 상태 |
|------|------|
| IaC 구조 | 완료 |
| Network | 완료 |
| NAT | 완료 |
| Monitoring EC2 | 완료 |
| Runner | 완료 |
| IAM | 완료 |
| ALB | 완료 |
| ASG | 완료 |
| Node Exporter | 완료 |
| Prometheus 연동 준비 | 완료 |
| 서비스 배포 | 타팀 대기 |

---

#  담당 역할 (Infra Team)

- Terraform 기반 아키텍처 설계
- 네트워크 보안 구조 구현
- NAT 설계 및 검증
- CD 실행 기반 구축
- 모니터링 연동 기반 자동화
- Source of Truth를 코드로 유지

---
## 2. Important Outputs (Terraform)
아래 값들은 `terraform output`으로 즉시 확인 가능

- ALB DNS: `KTCloud-INFRA-PROJECT-alb-1517593667.ap-northeast-2.elb.amazonaws.com`
- ASG Name: `KTCloud-INFRA-PROJECT-asg`
- Monitoring Public IP: `3.39.69.234`
- VPC: `vpc-0eeeed360e240799b`
- Public Subnets:
  - `subnet-0b0447649e98c83fd`
  - `subnet-0539cdb71ae7d6ee8`
- Private Subnets:
  - `subnet-004c77fa3c9130963`
  - `subnet-0df896ce34c8a40e8`
- Target Group ARN:  
  `arn:aws:elasticloadbalancing:ap-northeast-2:762233736868:targetgroup/KTCloud-INFRA-PROJECT-tg/393edd3c073e776f`

---

## 3. Repository Structure

terraform/
├─ modules/
│ ├─ network/ (VPC, Subnet, IGW, RouteTable)
│ ├─ alb/ (ALB, Listener, TargetGroup)
│ ├─ asg/ (LaunchTemplate, ASG, user_data)
│ └─ monitoring/ (Monitoring EC2, SG)
└─ env/
└─ dev/
├─ main.tf
├─ variables.tf
├─ outputs.tf
├─ terraform.tfvars
├─ backend.tf
└─ provider.tf


---

## 4. Backend (Remote State)
- S3 backend + DynamoDB Lock 사용
- State path: `s3://ktcloud-tfstate-762233736868-apne2/env/dev/terraform.tfstate`

---

## 5. How to Run

### 5.1 Init / Plan / Apply
```bash
cd terraform/env/dev
terraform init
terraform plan
terraform apply
5.2 Outputs
cd terraform/env/dev
terraform output
5.3 Destroy
cd terraform/env/dev
terraform destroy
6. Verification Guide (Day5)
6.1 ALB 200 OK (Windows PowerShell)
curl.exe -I http://KTCloud-INFRA-PROJECT-alb-1517593667.ap-northeast-2.elb.amazonaws.com
Expected: HTTP/1.1 200 OK

6.2 Target Group Healthy
AWS Console → EC2 → Target Groups → Targets 상태가 Healthy

6.3 nginx Auto Install (Service EC2 내부)
systemctl status nginx --no-pager
curl -I http://localhost
cat /var/www/html/index.html
6.4 Private EC2 Outbound (NAT)
sudo apt-get update -y
curl -4 ifconfig.me
6.5 ASG Scale-out
ASG Desired Capacity를 1 → 2로 변경 후:

신규 인스턴스가 Target Group에 등록

상태 Healthy 확인

7. Troubleshooting (NAT)
NAT와 Monitoring을 1대에 겸용 시도했으나 NAT 개조 후 SSH 불가/불안정 이슈 발생

결론: NAT 전용 EC2 분리 후 안정화

주요 점검 포인트:

NAT 인스턴스 Source/Destination Check 비활성화

net.ipv4.ip_forward=1

iptables -t nat -A POSTROUTING ... -j MASQUERADE

Private Route Table: 0.0.0.0/0 → NAT ENI

SG: NAT inbound (10.0.0.0/16), outbound (0.0.0.0/0)


### 1-4) 저장 종료
`ESC :wq`

---

## 2) 주간보고 문서 분리해서 저장 (README에 넣지 않기)

### 2-1) 파일 생성
```bash
cd ~/terraform
mkdir -p docs/daily-log
vi docs/daily-log/week1-summary.md
2-2) 아래 내용 붙여넣기 → 저장(ESC :wq)
# 1주차 주간보고 (KTCloud INFRA - IaC)

## 1) 목표
- Terraform 기반 AWS 인프라 IaC 구축
- ALB → ASG(Service Private) 구조
- Monitoring EC2 제공
- NAT 통해 Private Outbound 구성
- destroy → apply 재현성 확인

---

## 2) 이번 주 완료 내용 (Done)
- [x] VPC/Subnet/IGW/RouteTable 구성 (Terraform)
- [x] ALB/TargetGroup/Listener 구성
- [x] ASG 구성 + user_data로 nginx 자동 설치
- [x] NAT 인스턴스 분리 구성 + Private 라우팅 연결
- [x] Target Group Healthy 달성
- [x] ALB DNS 200 응답 확인
- [x] Backend 구성 (S3 tfstate + DynamoDB Lock) 및 state migrate 완료
- [x] outputs.tf 구성으로 접속/검증 정보 자동 노출

---

## 3) 핵심 산출물(Outputs)
- ALB DNS: KTCloud-INFRA-PROJECT-alb-1517593667.ap-northeast-2.elb.amazonaws.com
- ASG Name: KTCloud-INFRA-PROJECT-asg
- Monitoring Public IP: 3.39.69.234
- VPC: vpc-0eeeed360e240799b
- Public Subnets: subnet-0b0447649e98c83fd, subnet-0539cdb71ae7d6ee8
- Private Subnets: subnet-004c77fa3c9130963, subnet-0df896ce34c8a40e8

---

## 4) 이슈/트러블슈팅
### NAT+Monitoring 겸용 시도 실패
- 증상: NAT 개조 후 SSH 접속 불가, 네트워크 불안정
- 조치: NAT/Monitoring 분리, NAT 전용 EC2 구성
- 교훈: 운영 안정성을 위해 역할 분리 필요

---

## 5) 검증 결과
- [x] TG Healthy
- [x] ALB DNS 200 응답
- [x] nginx 자동 설치 동작
- [x] Private Outbound (NAT) 통신 확인
- [x] Remote State (S3) 적용 + Lock(DDB) 구성

---

