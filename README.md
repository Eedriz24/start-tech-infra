# StartTech Infrastructure

Production-grade, fully automated infrastructure for StartTech's full-stack web app
(React frontend, Golang REST API on EKS, Redis via ElastiCache, MongoDB Atlas),
provisioned with Terraform and deployed via GitHub Actions.

## Architecture

```
                         ┌─────────────────────────────┐
                         │   CloudFront Distribution    │
  User (HTTPS)  ───────► │  (single unified domain)     │
                         │                              │
                         │  default (*)  → S3-Frontend  │
                         │  /api/*       → ALB-Backend  │
                         └───────┬──────────────┬───────┘
                                 │              │
                         OAC     │              │  HTTP (origin only)
                                 ▼              ▼
                       ┌─────────────┐   ┌───────────────┐
                       │  S3 Bucket  │   │  ALB (public   │
                       │  (private,  │   │  subnets) →    │
                       │  React app) │   │  EKS Pods:8080 │
                       └─────────────┘   └───────┬────────┘
                                                  │
                                        ┌─────────┴─────────┐
                                        │   EKS Cluster      │
                                        │  starttech-cluster │
                                        │  (private subnets) │
                                        └────┬───────────┬───┘
                                             │           │
                                   ┌─────────▼───┐ ┌─────▼─────────┐
                                   │ ElastiCache │ │ MongoDB Atlas  │
                                   │starttech-redis│ (external)    │
                                   └─────────────┘ └────────────────┘
```

This solves the two classic SPA deployment problems:

1. **Client-side routing (403/404 on refresh):** CloudFront's `custom_error_response`
   blocks rewrite 403/404 responses from S3 to `/index.html` with a `200`, letting
   React Router take over.
2. **Mixed content (HTTPS → HTTP API calls):** A single CloudFront distribution
   fronts both the S3 frontend (`S3-Frontend` origin) and the HTTP-only ALB
   (`ALB-Backend` origin). The frontend calls `/api/v1/...` as a relative path, so
   everything is served over one HTTPS domain — no custom DNS/cert needed.

## Repository Layout

```
starttech-infra/
├── .github/workflows/infrastructure-deploy.yml   # CI/CD pipeline
├── terraform/
│   ├── main.tf, variables.tf, outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── networking/   # VPC, public/private/database subnets, NAT, IGW
│       ├── eks/          # EKS cluster, managed node group, IAM roles, OIDC
│       ├── storage/      # S3 static frontend bucket, ECR repo
│       ├── cdn/          # Unified CloudFront (S3 + ALB origins)
│       └── database/     # ElastiCache Redis
├── k8s/                  # Deployment / Service / Ingress for the backend
├── scripts/deploy-infrastructure.sh
└── README.md
```

## Why a Two-Phase Apply

The ALB that becomes CloudFront's `ALB-Backend` origin is created by the **AWS
Load Balancer Controller** in response to the backend `Ingress` resource — it does
not exist until the app is deployed to EKS. Terraform therefore looks it up via a
tag-based `data "aws_lb"` lookup, which requires two applies:

1. `terraform apply -target=module.networking -target=module.eks -target=module.storage -target=module.database`
2. Deploy the backend to EKS (`kubectl apply -f k8s/`), which creates the ALB.
3. `terraform apply` (no targets) — now the CDN module and S3 bucket policy can be
   created, since the ALB exists.

`scripts/deploy-infrastructure.sh` and the GitHub Actions workflow both implement
this sequence automatically.

## Naming Conventions (for automated grading)

| Resource | Identifier |
|---|---|
| VPC | `starttech-vpc` |
| EKS Cluster | `starttech-cluster` |
| EKS Node Group | `starttech-node-group` |
| S3 Frontend Bucket | `starttech-frontend-bucket-*` |
| ElastiCache Redis | `starttech-redis` |
| ECR Repository | `starttech-backend-api` |
| Container Port | `8080` |
| CloudFront S3 Origin ID | `S3-Frontend` |
| CloudFront ALB Origin ID | `ALB-Backend` |

## Getting Started

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # fill in real values
terraform init
../scripts/deploy-infrastructure.sh
```

## Secrets Required (GitHub Actions)

- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `MONGODB_ATLAS_URI`
