# 1주차 2일차 (2026-02-03)

##  오늘 목표
- [x] Monitoring EC2 SSH 접속 환경 구성
- [x] EC2 기본 보안 업데이트 및 SSH 서비스 확인
- [x] 관제팀(Grafana/Prometheus) 설치를 위한 사전 준비 완료

---

##  오늘 한 일 (Timeline)
- 14:00 ~ 14:30  
  - EC2 Key Pair 생성 (ktcloud-key.pem)
  - Windows 로컬 환경에서 SSH 접속 시도

- 14:30 ~ 15:10  
  - SSH 접속 오류 트러블슈팅  
  - 보안그룹, 퍼블릭 IP, 포트(22) 확인

- 15:10 ~ 15:40  
  - EC2 정상 접속 확인 (ubuntu 계정)
  - SSH 서비스 상태 확인

- 15:40 ~ 16:10  
  - OS 패키지 업데이트 및 보안 패치 적용
  - 서비스 재시작 확인

- 16:10 ~ 17:00  
  - 포트 리스닝 상태 점검
  - 관제팀 공유용 접속 정보 정리

- 17:00 ~ 17:50  
  - 하루 작업 정리
  - GitHub 문서 정리 및 커밋 준비

---

##  작업 상세 (증적 / 명령어 / 결과)

###  EC2 접속 환경 구성
- 인스턴스 유형: **t3.micro**
- OS: **Ubuntu 22.04 LTS**
- Public IP: **43.203.248.209**
- User: `ubuntu`
- Key: `ktcloud-key.pem`

#### 사용 명령어
```bash
ssh -i ktcloud-key.pem ubuntu@43.203.248.209

