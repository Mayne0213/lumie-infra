# PostgreSQL 16 → 18 메이저 업그레이드 계획

## 개요

| 항목 | 내용 |
|------|------|
| 현재 버전 | PostgreSQL 16.6 |
| 목표 버전 | PostgreSQL 18.1 |
| 대상 클러스터 | 6개 |
| 예상 다운타임 | 클러스터당 5-15분 |

## 대상 클러스터

| 클러스터 | 네임스페이스 | Instances | Storage | 우선순위 |
|----------|-------------|-----------|---------|----------|
| lumie-dev-db | lumie-dev | 1 | 5Gi | 1 (테스트용) |
| grafana-db | grafana | 2 | 1Gi | 2 |
| umami-db | umami | 2 | 1Gi | 3 |
| mas-db | mas | 2 | 1Gi | 4 |
| authelia-db | authelia | 2 | 1Gi | 5 |
| lumie-db | lumie-db | 2 | 20Gi | 6 (프로덕션) |

---

## Phase 1: 사전 준비

### 1.1 이미지 준비

```bash
# upstream-versions.json 업데이트
"ghcr:cloudnative-pg/postgresql": "18.1"

# Zot이 이미지를 미리 pull하도록 트리거
curl -u admin:PASSWORD https://zot.mayne.kro.kr/v2/storage/postgresql/manifests/18.1
```

### 1.2 전체 백업 (필수)

각 클러스터에서 pg_dump 실행:

```bash
# 각 클러스터에 대해 실행
for ns in lumie-dev grafana umami mas authelia lumie-db; do
  kubectl exec -n $ns ${ns}-db-1 -- pg_dumpall -U postgres > backup-${ns}-$(date +%Y%m%d).sql
done
```

### 1.3 호환성 확인

```bash
# PostgreSQL 18 릴리즈 노트 확인
# - 제거된 기능
# - 변경된 기본값
# - 마이그레이션 필요 항목
```

**주요 확인 사항:**
- [ ] 앱에서 사용하는 PostgreSQL extension 호환성
- [ ] 연결 문자열/드라이버 호환성
- [ ] SQL 문법 변경 사항

---

## Phase 2: 마이그레이션 방법 선택

### Option A: CNPG Import (권장)

CNPG의 `importDatabases` 기능 사용 - 새 클러스터 생성 후 기존 데이터 import

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: lumie-dev-db-v18
  namespace: lumie-dev
spec:
  instances: 1
  imageName: zot.mayne.kro.kr/storage/postgresql:18.1

  bootstrap:
    initdb:
      import:
        type: monolith
        databases:
          - "*"
        source:
          externalCluster: lumie-dev-db-v16

  externalClusters:
    - name: lumie-dev-db-v16
      connectionParameters:
        host: lumie-dev-db-rw.lumie-dev.svc
        user: postgres
      password:
        name: lumie-dev-db-superuser
        key: password
```

**장점:** CNPG 네이티브, 자동화, 검증됨
**단점:** 새 클러스터 이름 또는 전환 작업 필요

### Option B: Dump & Restore (가장 안전)

1. pg_dumpall로 전체 백업
2. 기존 클러스터 삭제
3. 새 버전으로 클러스터 생성
4. pg_restore로 복원

**장점:** 가장 안전, 같은 이름 유지
**단점:** 다운타임 김 (데이터 크기에 비례)

### Option C: Logical Replication (무중단)

1. 18.1 클러스터 생성
2. Logical replication 설정
3. 동기화 완료 후 앱 전환
4. 기존 클러스터 삭제

**장점:** 무중단
**단점:** 설정 복잡, extension 제한

---

## Phase 3: 마이그레이션 실행 (Option A 기준)

### Step 1: lumie-dev-db (테스트)

```yaml
# lumie-dev/manifests/cluster-v18.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: lumie-dev-db
  namespace: lumie-dev
spec:
  instances: 1
  imageName: zot.mayne.kro.kr/storage/postgresql:18.1
  storage:
    size: 5Gi

  bootstrap:
    initdb:
      import:
        type: monolith
        databases: ["*"]
        roles: ["*"]
        source:
          externalCluster: old-cluster

  externalClusters:
    - name: old-cluster
      connectionParameters:
        host: lumie-dev-db-rw.lumie-dev.svc
        user: postgres
      password:
        name: lumie-dev-db-superuser
        key: password
```

**실행 순서:**

```bash
# 1. 기존 클러스터 이름 변경 (또는 백업 후 삭제)
kubectl patch cluster lumie-dev-db -n lumie-dev \
  --type='json' -p='[{"op": "replace", "path": "/metadata/name", "value": "lumie-dev-db-old"}]'

# 2. 새 클러스터 배포
kubectl apply -f lumie-dev/manifests/cluster-v18.yaml

# 3. 마이그레이션 완료 대기
kubectl wait --for=condition=Ready cluster/lumie-dev-db -n lumie-dev --timeout=600s

# 4. 앱 테스트
kubectl logs -n lumie-dev -l app=lumie-dev --tail=50

# 5. 이상 없으면 기존 클러스터 삭제
kubectl delete cluster lumie-dev-db-old -n lumie-dev
```

### Step 2-6: 나머지 클러스터

lumie-dev-db 성공 확인 후 순차 진행:
1. grafana-db
2. umami-db
3. mas-db
4. authelia-db
5. lumie-db (마지막, 가장 중요)

---

## Phase 4: GitOps 적용

### 4.1 파일 변경 목록

```bash
# 1. upstream-versions.json
"ghcr:cloudnative-pg/postgresql": "18.1"

# 2. charts/common/values.yaml
database:
  version: "18.1"

# 3. charts/common/templates/cnpg-dump-backup.yaml
image: zot.mayne.kro.kr/storage/postgresql:18.1

# 4. 각 앱의 common-values.yaml (필요시)
# - applications/lumie-dev/common-values.yaml
# - observability/grafana/common-values.yaml
# - security/authelia/common-values.yaml
# 등
```

### 4.2 커밋 전략

```bash
# 각 클러스터별로 별도 커밋 & 배포
git commit -m "CHORE(cnpg): upgrade lumie-dev-db to PostgreSQL 18.1"
git push
# ArgoCD sync & 검증
# 다음 클러스터 진행
```

---

## Phase 5: 롤백 계획

### 즉시 롤백 (마이그레이션 중 실패)

```bash
# 새 클러스터 삭제
kubectl delete cluster lumie-dev-db -n lumie-dev

# 기존 클러스터 복원 (이름 변경한 경우)
kubectl patch cluster lumie-dev-db-old -n lumie-dev \
  --type='json' -p='[{"op": "replace", "path": "/metadata/name", "value": "lumie-dev-db"}]'
```

### 백업에서 복원 (마이그레이션 후 문제 발견)

```bash
# 1. 앱 중지
kubectl scale deployment -n lumie-dev --all --replicas=0

# 2. 클러스터 삭제 후 16.6으로 재생성
kubectl delete cluster lumie-dev-db -n lumie-dev
# helm-values를 16.6으로 되돌리고 ArgoCD sync

# 3. 백업 복원
cat backup-lumie-dev-20260203.sql | kubectl exec -i -n lumie-dev lumie-dev-db-1 -- psql -U postgres

# 4. 앱 재시작
kubectl scale deployment -n lumie-dev --all --replicas=1
```

---

## 체크리스트

### 마이그레이션 전
- [ ] 모든 클러스터 pg_dumpall 백업 완료
- [ ] PostgreSQL 18 릴리즈 노트 검토
- [ ] 앱 호환성 확인
- [ ] 다운타임 공지 (필요시)

### 마이그레이션 중
- [ ] lumie-dev-db 마이그레이션 & 테스트
- [ ] grafana-db 마이그레이션 & 테스트
- [ ] umami-db 마이그레이션 & 테스트
- [ ] mas-db 마이그레이션 & 테스트
- [ ] authelia-db 마이그레이션 & 테스트
- [ ] lumie-db 마이그레이션 & 테스트

### 마이그레이션 후
- [ ] 모든 앱 정상 동작 확인
- [ ] 성능 모니터링 (1주일)
- [ ] 기존 클러스터 백업 파일 보관 (30일)
- [ ] 문서 업데이트

---

## 예상 일정

| 단계 | 소요 시간 |
|------|----------|
| Phase 1: 사전 준비 | 1시간 |
| Phase 3: lumie-dev-db | 30분 |
| Phase 3: 나머지 5개 | 각 15분 (총 1시간 15분) |
| Phase 5: 검증 | 1시간 |
| **총 소요 시간** | **약 4시간** |

---

## 참고 자료

- [CNPG Database Import](https://cloudnative-pg.io/documentation/current/database_import/)
- [PostgreSQL 18 Release Notes](https://www.postgresql.org/docs/18/release-18.html)
- [CNPG Major Version Upgrades](https://cloudnative-pg.io/documentation/current/rolling_update/)
