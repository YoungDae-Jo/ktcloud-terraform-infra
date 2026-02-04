# Week 1 - Day 3

## 오늘 목표
- ALB 아키텍처 설계
- Terraform ALB 모듈 구조 설계

## 수행 내용
- Internet-facing ALB 구조 확정
- Public Subnet에 ALB 배치
- Listener(HTTP:80), Target Group 설계
- Terraform ALB 모듈 skeleton 생성
  - main.tf / variables.tf / outputs.tf
- ASG 연동을 고려한 output(target_group_arn) 정의
- Monitoring EC2는 단일 서버로 유지

## 결정 사항
- 외부 트래픽은 ALB만 허용
- 서비스 EC2는 ASG를 통해 Private Subnet에 자동 생성
- ASG 실제 구현은 2주차에 진행
- Monitoring EC2는 1주차 4일차에 NAT Instance로 개조 예정

## 다음 작업
- ASG 구조 설계 및 Terraform 모듈 skeleton
- Monitoring EC2 NAT Instance 개조

