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
