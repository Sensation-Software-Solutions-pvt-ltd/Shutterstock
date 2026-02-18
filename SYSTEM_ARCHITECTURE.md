# Shutterstock-like Image Marketplace — System Architecture

> **Version:** 1.0 · **Date:** 2026-02-18 · **Scale Target:** 5M+ images, 10K RPM search

---

## 🚀 Implementation Roadmap (3 Pillars)

To build a production-grade marketplace, we follow a three-step implementation strategy:

### [Step 1: Image Ingestion (Batch Migration)](./BATCH_INGESTION_WORKFLOW.md)

* **Goal:** Efficiently process 5M+ local images into the cloud.
* **Key Tech:** Python, CLIP (AI Tagging), Pillow (Processing), S3/Azure.
* **Outcome:** A high-quality image library with searchable tags and vector embeddings.

### [Step 2: Search Engine (Azure AI Search Integration)](./AZURE_AI_SEARCH_INTEGRATION.md)

* **Goal:** Enable lightning-fast, "Shutterstock-style" discovery.
* **Key Tech:** Azure AI Search, Hybrid Retrieval, HNSW (Vector Search).
* **Outcome:** Semantic search capability (search by concept, not just keywords).

### [Step 3: Website Development (Premium Frontend)](./WEBSITE_DEVELOPMENT.md)

* **Goal:** Launch the user-facing marketplace.
* **Key Tech:** Next.js, Tailwind CSS, Stripe.
* **Outcome:** A premium, responsive UI for both Buyers (Search & Checkout) and Contributors (Portfolio).

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
                   │  Processing        │ │  │Azure AI   │   │ Stripe / Payment │
                   │  Pipeline          │ │  │Search     │   │ Gateway          │
                   │  (Async Workers)   │ │  │           │   └──────────────────┘
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
                   └────────────────────┘          └──────────────────────────┘

   ┌────────────────────────────────────────────────────────────────────────┐
   │                    Observability Layer                                  │
   │   Prometheus + Grafana │ ELK/Loki │ Jaeger/X-Ray │ PagerDuty           │
   └────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Microservices Breakdown

(Refer to individual Steps for deep dives into implementation)

### 2.1 Technical Specifications

| Feature | implementation |
|---|---|
| **Step 1: Ingestion** | Event-driven pipeline for live uploads; [Batch pipeline](./BATCH_INGESTION_WORKFLOW.md) for migration. |
| **Step 2: Search** | [Azure AI Search](./AZURE_AI_SEARCH_INTEGRATION.md) with Hybrid RRF and vector indexing. |
| **Step 3: App** | [Next.js Marketplace](./WEBSITE_DEVELOPMENT.md) with Stripe Connect for contributor payouts. |

---

## 3. Data Flow — Image Ingestion

### [Initial Migration: Batch Model (Phase 0)](./BATCH_INGESTION_WORKFLOW.md)

Optimized for high-throughput migration of 5M+ existing files.

### 3.1 Live Contributor Ingestion (Event-Driven)

Standard path for new uploads post-launch. Includes real-time validation, AI tagging, and instant indexing.

---

## 4. Search Request Flow (Azure AI Search)

Our search logic combines traditional text matching with modern visual concept matching. **Check [Step 2](./AZURE_AI_SEARCH_INTEGRATION.md) for the exact retrieval logic.**

---

## 5. Scaling & Infrastructure

Refer to the **Phased Infrastructure Plan** in the original documentation to see how costs scale from **$455/mo (MVP)** to **$10,500/mo (Full Scale)**.

---

*Note: This architecture is "API-First" and designed to be deployed across either AWS or Azure clouds.*
