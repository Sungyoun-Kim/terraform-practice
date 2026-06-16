# Local Docker Registry

로컬 GitOps 이미지 배포 실습용 Docker Registry입니다.

```bash
make registry-up
make demo-image
make registry-tags
```

기본 endpoint:

```text
localhost:5001
```

Docker image push/pull은 MinIO가 아니라 Docker Registry API를 통해 이뤄집니다. MinIO는 registry의 storage backend로 붙일 수는 있지만, 그 경우에도 클라이언트가 바라보는 대상은 MinIO가 아니라 registry endpoint입니다.

GitHub-hosted Actions의 `localhost`는 GitHub runner 자신을 의미하므로 이 로컬 registry에 접근할 수 없습니다. 이 registry를 Actions에서 쓰려면 이 Mac에 self-hosted runner를 띄우거나, 외부에서 접근 가능한 registry를 사용해야 합니다.
