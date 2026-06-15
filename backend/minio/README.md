# MinIO Terraform Backend

This directory runs a local MinIO server for Terraform S3 backend practice.

MinIO stores the state object and Terraform's S3 lockfile:

```text
terraform-state/
└── terraform-practice/prometheus-stack/
    ├── terraform.tfstate
    └── terraform.tfstate.tflock
```

Run MinIO:

```bash
make backend-up
```

Migrate local state to MinIO:

```bash
make backend-migrate
```

Open the MinIO console:

```text
http://localhost:9001
```

Default local credentials:

```text
minioadmin / minioadmin
```

Keep the Docker volume. Removing it deletes the remote state for this local lab.
