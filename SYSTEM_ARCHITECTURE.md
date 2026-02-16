# Shutterstock-like Image Marketplace — System Architecture

> **Version:** 1.0 · **Date:** 2026-02-16 · **Scale Target:** 5M+ images, 10K RPM search

---

## Table of Contents

1. [High-Level System Architecture](#1-high-level-system-architecture)
2. [Microservices Breakdown](#2-microservices-breakdown)
3. [Data Flow — Image Ingestion](#3-data-flow--image-ingestion)
4. [Data Flow — Search Request](#4-data-flow--search-request)
5. [Recommended Tech Stack](#5-recommended-tech-stack)
6. [Scaling Strategy](#6-scaling-strategy)
7. [Estimated Infrastructure (5M Images)](#7-estimated-infrastructure-5m-images)
8. [Failure Handling Strategy](#8-failure-handling-strategy)
9. [Cost Optimization Strategy](#9-cost-optimization-strategy)

---

## 1. High-Level System Architecture

```
                          ┌─────────────────────────────────────────────┐
                          │              CDN (CloudFront/Akamai)        │
                          │   Static assets, watermarked previews,      │
                          │   thumbnail delivery                        │
                          └────────────────────┬────────────────────────┘
                                               │
                          ┌────────────────────▼────────────────────────┐
                          │           API Gateway / Load Balancer        │
                          │   (Kong / AWS API Gateway + ALB)             │
                          │   Rate limiting, JWT validation, routing     │
                          └──┬──────┬──────┬──────┬──────┬──────┬──────┘
                             │      │      │      │      │      │
              ┌──────────────┘      │      │      │      │      └──────────────┐
              ▼                     ▼      │      ▼      ▼                     ▼
   ┌──────────────────┐  ┌─────────────┐  │ ┌─────────────┐  ┌──────────────────┐
   │  Auth Service    │  │ Upload Svc  │  │ │ Search Svc  │  │ Commerce Svc     │
   │  (IAM/Roles)     │  │ (Ingest)    │  │ │ (Query)     │  │ (License/Pay)    │
   └──────────────────┘  └──────┬──────┘  │ └──────┬──────┘  └────────┬─────────┘
                                │         │        │                   │
                                ▼         │        ▼                   ▼
                   ┌────────────────────┐ │  ┌───────────┐   ┌──────────────────┐
                   │  Processing        │ │  │Elastic /  │   │ Stripe / Payment │
                   │  Pipeline          │ │  │OpenSearch  │   │ Gateway          │
                   │  (Async Workers)   │ │  │+ Qdrant   │   └──────────────────┘
                   │                    │ │  └───────────┘
                   │ ┌────────────────┐ │ │
                   │ │ AI Tagger      │ │ │        ┌──────────────────────────┐
                   │ │ Thumbnail Gen  │ │ │        │   Object Storage (S3)    │
                   │ │ Watermarker    │ │ │        │                          │
                   │ │ Embedding Gen  │ │ │        │  /originals  (private)   │
                   │ └────────────────┘ │ │        │  /thumbnails (public)    │
                   └────────┬───────────┘ │        │  /watermarked (public)   │
                            │             │        │  /downloads  (signed)    │
                            ▼             │        └──────────────────────────┘
                   ┌────────────────────┐ │
                   │  Message Queue     │ │        ┌──────────────────────────┐
                   │  (SQS / RabbitMQ   │ │        │  Metadata DB             │
                   │   / Kafka)         │◄┘        │  (PostgreSQL + pgvector) │
                   └────────────────────┘          │  or separate Qdrant      │
                                                   └──────────────────────────┘

   ┌────────────────────────────────────────────────────────────────────────┐
   │                    Observability Layer                                  │
   │   Prometheus + Grafana │ ELK/Loki │ Jaeger/X-Ray │ PagerDuty           │
   └────────────────────────────────────────────────────────────────────────┘
```

### Architectural Principles

| Principle | Implementation |
|---|---|
| **API-First** | OpenAPI 3.1 specs, versioned endpoints (`/v1/`), SDK generation |
| **Event-Driven** | Async processing via message queues for all heavy work |
| **Zero-Trust** | JWT + mTLS between services, signed URLs for downloads |
| **Cloud-Native** | Containerized (K8s), IaC (Terraform), multi-AZ |
| **CQRS** | Separate read (search) and write (upload) paths |

---

## 2. Microservices Breakdown

### 2.1 Auth Service
| Aspect | Detail |
|---|---|
| **Responsibility** | User registration, login, OAuth2/OIDC, role management (Contributor/Buyer/Admin) |
| **Tech** | Node.js or Go + PostgreSQL |
| **Key APIs** | `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me` |
| **Auth Model** | JWT access tokens (15min TTL) + refresh tokens (30d), RBAC with roles: `contributor`, `buyer`, `admin` |
| **Storage** | PostgreSQL `users` table with bcrypt-hashed passwords, `roles` table |

### 2.2 Upload / Ingestion Service
| Aspect | Detail |
|---|---|
| **Responsibility** | Accepts image uploads from contributors, validates format/size, stores original, triggers processing pipeline |
| **Tech** | Go or Node.js |
| **Key APIs** | `POST /v1/images/upload` (multipart), `GET /v1/images/{id}/status` |
| **Upload Flow** | Presigned S3 URL → direct client upload → webhook confirmation → enqueue processing |
| **Validation** | Max 200MB, formats: JPEG, PNG, TIFF, RAW. EXIF stripping for PII. Perceptual hash for duplicate detection |
| **Storage** | S3 `/originals/{contributor_id}/{uuid}.{ext}` |

### 2.3 Image Processing Pipeline (Async Workers)
| Aspect | Detail |
|---|---|
| **Responsibility** | Thumbnail generation, watermarking, AI tagging, embedding generation, metadata extraction |
| **Tech** | Python (Celery workers or AWS Lambda) |
| **Components** | 4 independent worker types consuming from queue |

**Worker Types:**

| Worker | Input | Output | Tech |
|---|---|---|---|
| **Thumbnail Generator** | Original image | 150px, 450px, 1000px thumbnails | Pillow/libvips |
| **Watermark Generator** | 1000px thumbnail | Watermarked preview (visible + invisible watermark) | Pillow + custom overlay |
| **AI Tagger** | Original image | Tags, categories, description, NSFW score | CLIP / BLIP-2 / cloud Vision API |
| **Embedding Generator** | Original image | 768-dim vector embedding | CLIP ViT-L/14 |

### 2.4 Search Service
| Aspect | Detail |
|---|---|
| **Responsibility** | Keyword search, semantic search, faceted filtering, auto-complete |
| **Tech** | Go or Python + OpenSearch + Qdrant |
| **Key APIs** | `GET /v1/search?q=...&category=...&orientation=...&color=...&page=...` |
| **Search Modes** | `keyword` (OpenSearch BM25), `semantic` (Qdrant ANN), `hybrid` (RRF fusion) |
| **Facets** | category, orientation, color palette, contributor, license type, date range, image type |
| **Latency Target** | p99 < 200ms |

### 2.5 Image Delivery Service
| Aspect | Detail |
|---|---|
| **Responsibility** | Serve thumbnails/previews via CDN, generate time-limited signed URLs for paid downloads |
| **Tech** | Go (lightweight) |
| **Key APIs** | `GET /v1/images/{id}/preview`, `GET /v1/images/{id}/download?license=...` |
| **Download Flow** | Verify license → generate signed S3 URL (5min TTL) → log download event → return URL |

### 2.6 Commerce / Licensing Service
| Aspect | Detail |
|---|---|
| **Responsibility** | Cart, checkout, payment processing, license generation, subscription management |
| **Tech** | Node.js or Go + PostgreSQL |
| **Key APIs** | `POST /v1/cart/add`, `POST /v1/checkout`, `GET /v1/licenses`, `POST /v1/subscriptions` |
| **Payment** | Stripe integration (cards, subscriptions), webhook-driven status updates |
| **License Types** | Standard (web/social), Enhanced (print/merch), Editorial |
| **Revenue Split** | Configurable contributor payout (e.g., 25-40%), automated monthly payouts via Stripe Connect |

### 2.7 Contributor Portal Service
| Aspect | Detail |
|---|---|
| **Responsibility** | Portfolio management, earnings dashboard, upload history, payout settings |
| **Key APIs** | `GET /v1/contributor/portfolio`, `GET /v1/contributor/earnings`, `PUT /v1/contributor/payout-settings` |

### 2.8 Moderation Service
| Aspect | Detail |
|---|---|
| **Responsibility** | Content review queue, NSFW filtering, copyright checks, manual review UI |
| **Tech** | Python + ML models + admin dashboard |
| **Flow** | Auto-approve if NSFW < 0.1 & no duplicate hash → else queue for human review |

### 2.9 Analytics / Recommendation Service
| Aspect | Detail |
|---|---|
| **Responsibility** | Track views, downloads, search patterns; generate recommendations |
| **Tech** | ClickHouse for event storage, Python for recommendations |

---

## 3. Data Flow — Image Ingestion

```
Contributor                   System
    │
    ├──1─► POST /v1/images/upload (metadata + auth)
    │       │
    │       ├──2─► Validate auth (contributor role)
    │       ├──3─► Validate metadata (title, description, categories)
    │       ├──4─► Generate presigned S3 upload URL
    │       └──5─► Return { uploadUrl, imageId, expiresIn: 3600 }
    │
    ├──6─► PUT {uploadUrl} (binary upload direct to S3)
    │       │
    │       └──7─► S3 triggers event notification ──►  Message Queue
    │                                                       │
    │              ┌────────────────────────────────────────┘
    │              ▼
    │         8. Orchestrator consumes event, dispatches parallel jobs:
    │
    │         ┌──────────────────────────────────────────────────────┐
    │         │  8a. Duplicate Detection                             │
    │         │      • Compute pHash → check against DB              │
    │         │      • If duplicate: mark REJECTED, notify, STOP     │
    │         │                                                      │
    │         │  8b. Thumbnail Generation (parallel)                 │
    │         │      • Generate 150px, 450px, 1000px variants        │
    │         │      • Store in S3 /thumbnails/{id}/                 │
    │         │                                                      │
    │         │  8c. Watermark Generation                            │
    │         │      • Apply semi-transparent tiled watermark         │
    │         │      • Apply steganographic invisible watermark       │
    │         │      • Store in S3 /watermarked/{id}/                │
    │         │                                                      │
    │         │  8d. AI Tagging                                      │
    │         │      • CLIP/BLIP-2: generate tags (top 30)           │
    │         │      • Categorize: Nature, People, Business, etc.    │
    │         │      • NSFW detection score                          │
    │         │      • Color palette extraction (dominant 5 colors)  │
    │         │      • Store tags in PostgreSQL                      │
    │         │                                                      │
    │         │  8e. Embedding Generation                            │
    │         │      • CLIP ViT-L/14: generate 768-dim vector        │
    │         │      • Upsert into Qdrant vector DB                  │
    │         │                                                      │
    │         │  8f. Metadata Extraction                             │
    │         │      • EXIF: dimensions, camera, lens, ISO, GPS      │
    │         │      • Strip PII, store technical metadata            │
    │         └──────────────────────────────────────────────────────┘
    │              │
    │              ▼
    │         9. All jobs complete → Orchestrator:
    │            • If NSFW score > threshold → status = PENDING_REVIEW
    │            • Else → status = APPROVED
    │            • Index metadata + tags in OpenSearch
    │            • Update PostgreSQL image record
    │            • Invalidate CDN cache for contributor portfolio
    │
    ◄──10── Webhook/SSE notification: "Image processed successfully"
```

### PostgreSQL Schema (Core Tables)

```sql
-- Users
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    role            VARCHAR(20) NOT NULL CHECK (role IN ('contributor','buyer','admin')),
    display_name    VARCHAR(100),
    stripe_account  VARCHAR(255),  -- Stripe Connect account for contributors
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Images
CREATE TABLE images (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contributor_id  UUID REFERENCES users(id),
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    status          VARCHAR(20) DEFAULT 'processing'
                    CHECK (status IN ('processing','approved','rejected','pending_review')),
    phash           BIGINT,                    -- perceptual hash for dedup
    width           INT,
    height          INT,
    file_size_bytes BIGINT,
    format          VARCHAR(10),
    s3_original_key VARCHAR(500),
    s3_thumb_prefix VARCHAR(500),
    s3_watermark_key VARCHAR(500),
    nsfw_score      REAL DEFAULT 0,
    orientation     VARCHAR(15) GENERATED ALWAYS AS (
                        CASE WHEN width > height THEN 'landscape'
                             WHEN height > width THEN 'portrait'
                             ELSE 'square' END
                    ) STORED,
    embedding       vector(768),               -- pgvector
    color_palette   JSONB,                     -- [{hex, percentage}]
    technical_meta  JSONB,                     -- camera, lens, ISO etc.
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Tags
CREATE TABLE image_tags (
    image_id    UUID REFERENCES images(id) ON DELETE CASCADE,
    tag         VARCHAR(100),
    confidence  REAL,
    source      VARCHAR(20) CHECK (source IN ('ai','contributor','moderator')),
    PRIMARY KEY (image_id, tag)
);

-- Categories
CREATE TABLE image_categories (
    image_id    UUID REFERENCES images(id) ON DELETE CASCADE,
    category    VARCHAR(100),
    PRIMARY KEY (image_id, category)
);

-- Licenses / Purchases
CREATE TABLE licenses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id        UUID REFERENCES users(id),
    image_id        UUID REFERENCES images(id),
    license_type    VARCHAR(20) CHECK (license_type IN ('standard','enhanced','editorial')),
    price_cents     INT NOT NULL,
    currency        VARCHAR(3) DEFAULT 'USD',
    stripe_payment  VARCHAR(255),
    downloaded_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_images_contributor ON images(contributor_id);
CREATE INDEX idx_images_status ON images(status);
CREATE INDEX idx_images_phash ON images(phash);
CREATE INDEX idx_tags_tag ON image_tags(tag);
```

---

## 4. Data Flow — Search Request

```
Buyer / Client                          System
    │
    ├──1─► GET /v1/search?q=sunset+over+ocean&category=nature
    │      &orientation=landscape&color=orange&page=1&mode=hybrid
    │       │
    │       ├──2─► API Gateway: rate-limit check, JWT validation
    │       │
    │       ├──3─► Search Service receives parsed query
    │       │       │
    │       │       ├──3a─► Text Processing:
    │       │       │       • Tokenize, stem, spell-correct
    │       │       │       • Expand synonyms (ocean → sea, waves)
    │       │       │
    │       │       ├──3b─► Parallel Execution:
    │       │       │       │
    │       │       │       ├── Keyword Path (OpenSearch):
    │       │       │       │   BM25 query on title + description + tags
    │       │       │       │   + filters: category=nature,
    │       │       │       │     orientation=landscape,
    │       │       │       │     color_palette contains #FFA500
    │       │       │       │   → Returns top 100 with scores
    │       │       │       │
    │       │       │       └── Semantic Path (Qdrant):
    │       │       │           Encode query via CLIP text encoder
    │       │       │           → 768-dim vector
    │       │       │           ANN search (HNSW) top 100
    │       │       │           + metadata filters
    │       │       │           → Returns top 100 with distances
    │       │       │
    │       │       ├──3c─► Reciprocal Rank Fusion (RRF):
    │       │       │       • Merge keyword + semantic results
    │       │       │       • RRF_score = Σ 1/(k + rank_i)  [k=60]
    │       │       │       • Re-rank by fused score
    │       │       │       • Apply business boost (premium, trending)
    │       │       │
    │       │       └──3d─► Build response:
    │       │               • Paginate (20/page)
    │       │               • Attach CDN thumbnail URLs
    │       │               • Compute facet counts
    │       │               • Cache in Redis (TTL: 60s, key: query hash)
    │       │
    │       └──4─► Return JSON:
    │              {
    │                "total": 14832,
    │                "page": 1,
    │                "results": [
    │                  {
    │                    "id": "uuid",
    │                    "title": "Golden sunset over Pacific Ocean",
    │                    "thumbnail_url": "https://cdn.example.com/thumb/450/...",
    │                    "preview_url": "https://cdn.example.com/watermark/...",
    │                    "contributor": "Jane Doe",
    │                    "tags": ["sunset","ocean","golden hour"],
    │                    "dimensions": "6000x4000",
    │                    "price": { "standard": 299, "enhanced": 1499 }
    │                  }
    │                ],
    │                "facets": {
    │                  "categories": [{"name":"nature","count":8231},...],
    │                  "orientations": [{"name":"landscape","count":9821},...],
    │                  "colors": [{"hex":"#FFA500","count":2104},...]
    │                }
    │              }
    │
    ◄──5─── Render results in UI
```

---

## 5. Recommended Tech Stack

| Layer | Technology | Rationale |
|---|---|---|
| **API Gateway** | Kong / AWS API Gateway | Rate limiting, auth, versioning, analytics |
| **Backend Services** | Go (perf-critical), Node.js (CRUD) | Go for search/delivery (low latency), Node for auth/commerce (ecosystem) |
| **Processing Workers** | Python (Celery) or AWS Lambda | ML model compatibility, auto-scaling |
| **Metadata DB** | PostgreSQL 16 + pgvector | ACID, JSONB, vector search, mature ecosystem |
| **Search Engine** | OpenSearch 2.x | BM25 full-text, aggregations, facets |
| **Vector DB** | Qdrant (dedicated) | Purpose-built ANN with filtering, superior to pgvector at scale |
| **Message Queue** | Amazon SQS + SNS (or Kafka) | SQS: simple, serverless; Kafka: if event streaming needed |
| **Object Storage** | Amazon S3 (or GCS/Azure Blob) | Virtually unlimited, 11 nines durability |
| **CDN** | CloudFront / Cloudflare | Global edge caching, signed URLs |
| **Cache** | Redis Cluster (ElastiCache) | Search result caching, session store, rate limiting |
| **Payments** | Stripe + Stripe Connect | PCI compliant, marketplace payouts built-in |
| **AI/ML Models** | CLIP ViT-L/14, BLIP-2 | State-of-art for tagging + embeddings |
| **Container Orchestration** | Kubernetes (EKS) | Auto-scaling, service mesh, rolling deploys |
| **IaC** | Terraform + Helm | Reproducible infra, multi-env |
| **CI/CD** | GitHub Actions → ArgoCD | GitOps deployment model |
| **Observability** | Prometheus + Grafana + Loki + Jaeger | Full-stack monitoring, tracing, logging |
| **Frontend** | Next.js (React) | SSR for SEO, image optimization built-in |

---

## 6. Scaling Strategy

### 6.1 Horizontal Scaling

| Component | Strategy |
|---|---|
| **API Services** | HPA in K8s: scale on CPU (70%) and request rate |
| **Processing Workers** | KEDA: scale to zero, burst to 100+ pods on queue depth |
| **PostgreSQL** | Read replicas (up to 15), connection pooling (PgBouncer) |
| **OpenSearch** | 3-node cluster → scale data nodes horizontally, dedicated master nodes |
| **Qdrant** | Sharded collection across nodes, replication factor 2 |
| **Redis** | Cluster mode with 6+ shards |
| **S3** | Auto-scales (no action needed) |

### 6.2 Read Path Optimization

```
Client → CDN (cache hit: 85%+) → API Gateway → Redis (cache hit: 60%) → Search Service → DB
```

- **CDN caching**: Thumbnails/watermarks cached at edge (TTL: 24h)
- **Redis caching**: Search results cached by query hash (TTL: 60s)
- **OpenSearch replicas**: 1 primary + 2 replicas per shard for read throughput
- **Connection pooling**: PgBouncer (1000 connections → 50 DB connections)

### 6.3 Write Path Optimization

- **Presigned uploads**: Bypass API servers, upload direct to S3
- **Async processing**: All heavy work in background workers
- **Batch indexing**: Bulk OpenSearch/Qdrant updates every 5s

### 6.4 Data Partitioning

| Data | Partition Strategy |
|---|---|
| **S3 objects** | Prefix by contributor_id (even distribution) |
| **PostgreSQL** | Table partitioning by `created_at` (monthly) for images |
| **OpenSearch** | Index-per-month with aliases, ILM rollover |
| **Qdrant** | Shard by image_id hash across 4+ nodes |

---

## 7. Estimated Infrastructure (5M Images)

### 7.1 Storage Estimates

| Asset Type | Per Image | 5M Images | Storage Class |
|---|---|---|---|
| Original (avg 15MB) | 15 MB | **75 TB** | S3 Standard-IA |
| Thumbnails (3 sizes) | 200 KB | **1 TB** | S3 Standard |
| Watermarked preview | 300 KB | **1.5 TB** | S3 Standard |
| **Total S3** | | **~78 TB** | |

| Database | Size Estimate | Instance |
|---|---|---|
| PostgreSQL (metadata) | ~50 GB (rows) + 30 GB (pgvector) | r6g.2xlarge (64GB RAM) + 2 read replicas |
| OpenSearch (index) | ~100 GB | 3x r6g.xlarge.search (data) + 3x master |
| Qdrant (vectors) | ~25 GB (5M × 768 × 4B + overhead) | 3x 16GB RAM nodes |
| Redis (cache) | ~10 GB | r6g.large cluster (3 shards) |

### 7.2 Compute Estimates

| Service | Instance / Config | Count | Purpose |
|---|---|---|---|
| API Services (K8s) | c6g.xlarge (4c/8GB) | 6-12 pods | Request handling |
| Processing Workers | g4dn.xlarge (GPU) | 2-8 (auto-scale) | AI tagging, embeddings |
| Processing Workers (CPU) | c6g.2xlarge | 4-10 (auto-scale) | Thumbnails, watermarks |
| Kubernetes Control | m6g.large | 3 nodes | EKS management |
| Load Balancer | ALB | 1 | Ingress |

### 7.3 Monthly Cost Estimate (AWS, us-east-1)

| Component | Monthly Cost |
|---|---|
| S3 Storage (78TB mixed) | ~$1,600 |
| S3 Requests + Transfer | ~$800 |
| CloudFront (10TB egress) | ~$850 |
| EKS + EC2 (API + Workers) | ~$3,500 |
| GPU Instances (on-demand avg) | ~$1,200 |
| RDS PostgreSQL (primary + 2 replicas) | ~$1,800 |
| OpenSearch (6 nodes) | ~$2,400 |
| Qdrant (3 nodes on EC2) | ~$600 |
| ElastiCache Redis | ~$500 |
| SQS / SNS | ~$100 |
| Miscellaneous (NAT, DNS, secrets) | ~$400 |
| **Total Estimated** | **~$13,750/mo** |

---

## 8. Failure Handling Strategy

### 8.1 Service-Level Resilience

| Pattern | Implementation |
|---|---|
| **Circuit Breaker** | Resilience4j / Istio circuit breaking: open after 5 consecutive 5xx in 30s, half-open after 60s |
| **Retry with Backoff** | Exponential backoff (1s, 2s, 4s) with jitter, max 3 retries for idempotent operations |
| **Timeout Budgets** | API Gateway: 10s global; inter-service: 3s; DB queries: 2s |
| **Bulkhead Isolation** | Separate thread pools per downstream dependency |
| **Graceful Degradation** | If Qdrant down → fall back to keyword-only search; if OpenSearch down → serve from Redis cache |

### 8.2 Data Durability

| Component | Protection |
|---|---|
| **S3** | 99.999999999% durability, cross-region replication for originals |
| **PostgreSQL** | Multi-AZ standby, automated daily snapshots (30-day retention), WAL archiving to S3 |
| **OpenSearch** | Snapshot to S3 every 6h, can rebuild from PostgreSQL |
| **Qdrant** | Replication factor 2, snapshot to S3 daily, can rebuild from images |
| **Redis** | Non-critical (cache), AOF persistence for session data |

### 8.3 Processing Pipeline Resilience

```
Upload Event
    │
    ├── SQS Dead Letter Queue (DLQ)
    │   • Max 3 retries per message
    │   • Failed messages → DLQ after 3 attempts
    │   • CloudWatch alarm on DLQ depth > 0
    │   • Manual re-drive or auto-remediation Lambda
    │
    ├── Idempotent Workers
    │   • Each job keyed by (image_id, job_type)
    │   • Check completion status before processing
    │   • Safe to replay
    │
    └── Saga / Orchestrator Pattern
        • Track pipeline state in PostgreSQL
        • If any step fails after retries → mark image as "processing_failed"
        • Contributor notified, can retry upload
        • Admin dashboard shows failed processing queue
```

### 8.4 Disaster Recovery

| Metric | Target |
|---|---|
| **RTO** (Recovery Time Objective) | < 1 hour |
| **RPO** (Recovery Point Objective) | < 5 minutes |
| **Strategy** | Warm standby in secondary region, DNS failover via Route 53 health checks |

---

## 9. Cost Optimization Strategy

### 9.1 Storage Optimization

| Strategy | Savings |
|---|---|
| **S3 Intelligent-Tiering** for originals | Auto-moves cold images to IA/Glacier: **~40% on storage** |
| **Lifecycle policies** | Move images not downloaded in 90d to S3-IA, 365d to Glacier | 
| **WebP/AVIF thumbnails** | 30-50% smaller than JPEG: saves CDN egress + storage |
| **Deduplication** | pHash-based dedup prevents storing duplicate content |

### 9.2 Compute Optimization

| Strategy | Savings |
|---|---|
| **Spot Instances for workers** | Processing workers on Spot (70% cheaper), with fallback to on-demand |
| **ARM instances (Graviton)** | 20% cheaper than x86 for API services |
| **KEDA auto-scaling** | Scale processing workers to zero when idle |
| **Reserved Instances** | 1-year RI for baseline API/DB instances: **~35% savings** |
| **Model optimization** | Quantized CLIP (INT8): 3x throughput on same GPU |
| **Batch GPU inference** | Batch AI tagging requests (32 images/batch) to maximize GPU utilization |

### 9.3 Network Optimization

| Strategy | Savings |
|---|---|
| **CDN cache hit ratio > 85%** | Reduces origin fetches and S3 egress |
| **S3 Transfer Acceleration** | Only for contributor uploads (configurable) |
| **VPC Endpoints** | S3/SQS via VPC endpoint: no NAT gateway charges |
| **Regional edge caches** | CloudFront regional caching reduces origin requests |

### 9.4 Database Optimization

| Strategy | Savings |
|---|---|
| **Read replicas for search** | Offload reads from primary, use smaller primary |
| **OpenSearch UltraWarm** | Move old indices to warm storage: **~70% cheaper** |
| **Connection pooling** | PgBouncer reduces need for oversized RDS instances |
| **Materialized views** | Pre-compute popular facet counts, refresh every 5min |

### 9.5 Cost Monitoring

- **AWS Cost Explorer** + custom dashboards per service
- **Budget alerts** at 80%, 90%, 100% of monthly target
- **Per-image cost tracking**: total processing cost per image upload (~$0.003-0.005/image)
- **Monthly FinOps review**: identify underutilized resources

---

## Appendix: API Summary

| Endpoint | Method | Service | Auth |
|---|---|---|---|
| `/v1/auth/register` | POST | Auth | Public |
| `/v1/auth/login` | POST | Auth | Public |
| `/v1/images/upload` | POST | Upload | Contributor |
| `/v1/images/{id}/status` | GET | Upload | Contributor |
| `/v1/search` | GET | Search | Public (rate-limited) |
| `/v1/images/{id}` | GET | Search | Public |
| `/v1/images/{id}/similar` | GET | Search | Public |
| `/v1/images/{id}/preview` | GET | Delivery | Public |
| `/v1/images/{id}/download` | GET | Delivery | Buyer (licensed) |
| `/v1/cart` | GET/POST/DELETE | Commerce | Buyer |
| `/v1/checkout` | POST | Commerce | Buyer |
| `/v1/licenses` | GET | Commerce | Buyer |
| `/v1/contributor/portfolio` | GET | Contributor | Contributor |
| `/v1/contributor/earnings` | GET | Contributor | Contributor |
| `/v1/admin/moderation/queue` | GET | Moderation | Admin |
| `/v1/admin/moderation/{id}/approve` | POST | Moderation | Admin |

---

*End of Architecture Document*
