# Local Vault

로컬 External Secrets Operator 실습용 HashiCorp Vault dev server입니다.

```bash
make vault-bootstrap
make vault-read
```

기본값:

```text
Vault URL: http://127.0.0.1:8200
Root token: root
Secret path: secret/hello-app
```

이 구성은 로컬 학습 전용입니다. Vault dev mode는 자동 초기화/자동 unseal을 사용하고, dev root token을 고정합니다. 운영 환경에서는 이 방식으로 Vault를 실행하지 않습니다.
