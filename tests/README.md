# Tests README

## 1. 개요
본 디렉토리는 **스크립트 기반으로 AWS 인프라를 검증**하고, 동작을 **관찰/분석**하기 위한 테스트 코드 모음입니다.

- **Pytest + Boto3**: 인프라 리소스 상태/동작 자동 검증
- **Locust**: 정밀한 성능·부하 측정(확장 예정)
- **Terraform**: 테스트용 샘플 인프라(`fixtures/`) 구성

### 목적 및 기대효과
- 인프라가 의도대로 구성되고 동작하는지 스크립트를 통한 자동 검증
- 인프라 구조와 동작을 정량적으로 측정하고, 적용된 정책의 적절성 분석
- 측정 데이터를 기반으로 인프라 안정성·성능·비용 최적화 방향 도출

---

## 2. `fixtures/` 샘플 인프라 소개 (테스트 스크립트 검증용)
> **`fixtures/`는 테스트 스크립트가 잘 동작하는지 확인하기 위한 최소 환경입니다.**  
> 프로젝트의 메인 인프라와는 **독립적**입니다.

### 인프라 구성 요약
- VPC: NAT Gateway 없이 Public Subnet만 사용
- 접근 정책
  - App은 ALB로부터만 8080 포트 접근 허용
  - 외부 사용자는 ALB(80) 를 통해서만 App 접근 가능
- Launch Template
  - Ubuntu 22.04 AMI
  - `user_data.sh`로 웹서버 설치/실행
  - systemd 서비스로 구동
- Auto Scaling Group
  - Multi-AZ
  - min/desired: 2, max: 4
  - Target Tracking 정책(ASG 평균 CPU 사용률 기반)

### 웹 서버(테스트용) 엔드포인트
- `/` : Hostname 포함 기본 응답
- `/health` : ALB 헬스체크용
- `/kill` : 애플리케이션 Zombie 모드 전환(장애 시뮬레이션)
- `/work` : CPU 부하 유발(스케일링 테스트용)

---

## 3. 다른 AWS 인프라에서도 사용하기
본 테스트 코드는 `fixtures/` 샘플 환경뿐 아니라 **다른 AWS 인프라에서도 재사용**할 것을 염두하여 작성되었습니다.

### 3.1 요구 조건
인프라에 로드밸런싱, 오토스케일링이 구현되어있고, 웹서비스가 아래 조건을 만족해야 합니다.

- 엔드포인트 존재: `/`, `/health`, `/kill`, `/work`
- 네트워크/보안 정책상 테스트 트래픽이 차단되지 않아야 함

### 3.2 필요한 입력 값 3가지
테스트는 아래 3개 값만 알면 실행 가능합니다.

- `ALB_URL` : ALB 접속 URL (예: `http://xxxx.ap-northeast-2.elb.amazonaws.com`)
- `ASG_NAME` : Auto Scaling Group 이름
- `TG_ARN` : Target Group ARN

### 3.3 설정 방법 (둘 중 하나만 하면 됨)

#### 방법 A) `.env`로 직접 지정
`tests/.env` 파일을 만들고 아래를 채웁니다.

```ini
ALB_URL=
ASG_NAME=
TG_ARN=
```

#### 방법 B) Terraform output JSON 사용(권장)
Terraform으로 만들었거나 output을 뽑을 수 있다면 이 방식이 가장 간단합니다.

```bash
terraform output -json > tests/infra_config.json
```

> Terraform을 쓰지 않는 인프라라면, 콘솔/CLI에서 위 값 3개를 확인해 `.env`로 넣어도 됩니다.

---

## 4. 기술 스택
- **Language**: Python 3.13+ (3.10+도 가능)
- **Test Framework**: Pytest
- **AWS SDK**: Boto3
- **Load Test**: Locust (추후 고도화)
- **IaC**: Terraform

---

## 5. 디렉토리 구조
```plaintext
.
├── tests/
│   ├── functional/                 # 기능/시나리오 기반 테스트
│   │   ├── test_connectivity.py    # [기본] 연결/등록/분산 확인
│   │   ├── test_recovery.py        # [분석] 장애 후 복구 측정
│   │   └── test_scaling.py         # [분석] 스케일링 동작 관찰/측정
│   ├── performance/                # 성능 metric 등 측정
│   │   └── locustfile.py           # (구현 예정)
│   ├── fixtures/                   # 샘플 인프라 (Terraform)
│   │   ├── *.tf
│   │   ├── user_data.sh
│   │   └── outputs.tf
│   ├── conftest.py                 # AWS 연결/terraform output 연동 등
│   ├── __init__.py
│   ├── utils.py
│   ├── .env                        # (선택) 인프라 값 직접 지정
│   └── infra_config.json           # (선택) terraform output 값
├── pytest.ini                   # pytest 설정
├── requirements.txt             # 의존성
└── README.md                    # 본 문서
```

---

## 6. 시작하기 (Getting Started)

### 6.1 사전 준비
- Python 3.10+ (권장: 3.13)
- AWS CLI 인증 설정 (`aws configure`)
  - 본 테스트는 `boto3`로 AWS API를 호출하므로, **테스트 대상 인프라에 접근 가능한 자격증명**이 필요합니다.

### 6.2 의존성 설치
프로젝트 루트(※ `tests/` 폴더가 아니라 프로젝트 최상단)에서 실행:

```bash
pip install -r requirements.txt
```

---

## 7. (선택) 샘플 인프라 생성 (`tests/fixtures`)
샘플 인프라로 테스트 스크립트 동작을 확인할 수 있습니다.

```bash
cd tests/fixtures
terraform init
terraform apply
terraform output -json > ../infra_config.json
```

> `fixtures/`는 임시 인프라이므로 테스트 종료 후 `terraform destroy`를 권장합니다.
> `backend` 설정하지 않았으므로 프로젝트 공용 계정에서 `terraform apply`하셨다면 `terraform destroy` 꼭 부탁드립니다.

---

## 8. 테스트 실행
> `pytest.ini`에서 `testpaths=tests/functional` 로 설정되어 있어, **프로젝트 루트에서 실행**합니다.

### 8.1 Connectivity 테스트
```bash
pytest -m connectivity
```

검증 항목
- ALB URL 접근 가능(200 응답)
- Target Group에 Healthy 인스턴스가 최소 2대 이상 존재
- 트래픽이 단일 인스턴스에 편향되지 않고 분산되는지
- Healthy 인스턴스가 2개 이상의 AZ에 분산되는지

---

### 8.2 장애(Recovery) 테스트
```bash
pytest -m fault
```

검증 항목
- 시나리오 A: 애플리케이션 장애(`/kill`)
  - ALB가 Unhealthy 감지하는지
  - ASG가 자동 복구 수행하는지(교체 인스턴스 Healthy 도달)
  - 장애~복구 과정에서 요청 성공률(가용성) 측정
- 시나리오 B: 인프라 장애(인스턴스 강제 종료)
  - ALB Unhealthy 감지
  - ASG 자동 복구
  - 복구 과정 요청 성공률 측정

---

### 8.3 스케일링(Scaling) 테스트
```bash
pytest -m scaling
```

검증 항목
- `/work` 호출로 부하 생성 → Scale-out 발생(Desired Capacity 증가) 확인
- Healthy Target 수 증가 확인
- 부하 중단 후 Scale-in 발생(Desired Capacity 감소) 확인
- Healthy Target 수 감소 확인

> 참고
> - 스케일링 결과는 인스턴스 타입/웹서버 구현/네트워크 상태에 따라 달라질 수 있습니다.  
> - 특히 Scale-in은 시간이 오래 걸릴 수 있습니다(15분 이상).  
>   테스트를 켜두고 동작 변화를 나중에 확인하면 됩니다.

---

## 9. 테스트 후 정리 (권장)
`fixtures/` 샘플 인프라를 사용했다면 리소스 정리를 권장합니다.

```bash
cd tests/fixtures
terraform destroy
```

---

## 10. 테스트 결과 저장 (선택)
HTML 리포트로 저장하려면:

```bash
pytest -m connectivity --html=reports/connectivity.html --self-contained-html
pytest -m fault --html=reports/fault.html --self-contained-html
pytest -m scaling --html=reports/scaling.html --self-contained-html
```


---

## 11. TODO
- 스케일링 테스트 안정화: `/work` 및 `test_scaling.py` 튜닝(부하 중 인스턴스 다운 등 상황 생김)
- 메인 인프라 환경에서도 사용 가능하도록 파라미터/튜닝 정리
- 시나리오 정교화 및 미구현 케이스 추가
- 인프라의 상세한 성능 및 수치화된 metric 측정할 수 있게 할 것