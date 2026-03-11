# Shutterstock-like Image Marketplace — System Architecture (GCP Edition)

> **Version:** 1.2 · **Date:** 2026-02-18 · **Scale Target:** 5M+ images, 10K RPM search · **Stack:** Google Cloud Platform (GCP)

---

## 🚀 Implementation Roadmap (3 Pillars)

### [Step 1: Image Ingestion (Batch Migration)](./BATCH_INGESTION_WORKFLOW.md)

* **Goal:** Processing 5M+ local images into **Google Cloud Storage (GCS)**.
* **Key Tech:** Python, Vertex AI (Vision), Cloud SQL (pgvector).

### [Step 2: Search Engine (Vertex AI Search Integration)](./VERTEX_AI_SEARCH_INTEGRATION.md)

* **Goal:** Enabling conceptual "Semantic" search + Keyword search.
* **Key Tech:** Vertex AI Search, Vector Search (Matching Engine).

### [Step 3: Triple-Portal Website Development](./WEBSITE_DEVELOPMENT.md)

* **Goal:** Launching the **Public**, **Contributor**, and **Admin** portals on **Cloud Run**.
* **Key Tech:** Next.js, Stripe, Google Cloud Identity Platform.

### [Project Roadmap: Development Phases](./DEVELOPMENT_ROADMAP.md)

* **Phased Build:** 6 phases from Foundation/Migration to Global Scaling.
* **Priority:** Search and Data integrity before frontend expansion.

---

## 1. High-Level Integrated Architecture (GCP)

```text
                          ┌─────────────────────────────────────────────┐
                          │         Google Cloud CDN / Load Balancer    │
                          └────────────────────┬────────────────────────┘
                                               │
               ┌───────────────────────────────┼──────────────────────────────┐
               ▼                               ▼                              ▼
    ┌────────────────────┐          ┌────────────────────┐          ┌────────────────────┐
    │    Public Site     │          │ Contributor Panel  │          │    Admin Panel     │
    │  (Next.js on Run)  │          │  (Next.js on Run)  │          │  (Next.js on Run)  │
    └──────────┬─────────┘          └──────────┬─────────┘          └──────────┬─────────┘
               │                               │                               │
               └─────────────────┬─────────────┴───────────────────────────────┘
                                 │
                          ┌──────▼──────────────────────────────────────┐
                          │         Unified Backend (Cloud Run)         │
                          │   (JWT Auth, RBAC, Rate Limiting, Logic)    │
                          └──┬──────┬──────┬──────┬──────┬──────┬───────┘
                             │      │      │      │      │      │
              ┌──────────────┘      │      │      │      │      └──────────────┐
              ▼                     ▼      │      ▼      ▼                     ▼
   ┌──────────────────┐  ┌─────────────┐  │ ┌─────────────┐  ┌──────────────────┐
   │Identity Platform │  │ Cloud Pub/Sub│  │ │ Vertex AI    │  │ Payment Gateway  │
   │ (Firebase Auth)  │  │ (Messaging)  │  │ │ Search      │  │ (Stripe)         │
   └──────────────────┘  └──────┬──────┘  │ └─────────────┘  └──────────────────┘
                                │         │
                                ▼         │          ┌──────────────────────────┐
                   ┌────────────────────┐ │          │   Cloud Storage (GCS)    │
                   │  Image Processor   │ │          │                          │
                   │ (Cloud Functions)  │ │          │  /originals  (private)   │
                   └────────┬───────────┘ │          │  /thumbnails (public)    │
                            │             │          │  /watermarked (public)   │
                            ▼             │          └──────────────────────────┘
                   ┌────────────────────┐ │
                   │  Vertex AI Vision  │ │          ┌──────────────────────────┐
                   │  (Tagging/Embed)   │◄┘          │   Cloud SQL (Postgres)   │
                   └────────────────────┘            │   (Primary Metadata)     │
                                                     └──────────────────────────┘
```

---

## 2. Integrated Feature Matrix

| Pillar | Public (Buyer) | Contributor (Artist) | Admin (Staff) |
| :--- | :--- | :--- | :--- |
| **Search** | Semantic (Vertex AI) | Portfolio Management | Moderation Queue |
| **Commerce** | Stripe Checkout | Stripe Connect Payouts | Platform Revenue Ops |
| **Content** | GCS Signed URLs | Direct GCS Upload (V4) | Content Governance |
| **Access** | Identity Platform | RBAC: Contributor | RBAC: Admin |

---

## 3. Data Infrastructure (GCP)

### 3.1 Metadata Storage (Cloud SQL for PostgreSQL)

The source of truth for all relational data. Uses `pgvector` for local vector operations and Vertex AI Matching Engine for large-scale similarity.

### 3.2 Search Index (Vertex AI Search)

The high-performance discovery engine. Uses **Hybrid Search** (combining keyword and vector search) for ultra-relevant results.

### 3.3 Object Storage (Google Cloud Storage)

* **Standard Class:** Watermarked previews and thumbnails for fast delivery.
* **Coldline/Archive:** Original raw files to optimize costs.

---

## 4. Scalability & Security (GCP)

* **Cloud Run:** Serverless scaling of all three portals and the backend API.
* **Cloud IAM + RBAC:** Strict permission boundaries using Google Cloud Identity.
* **Cloud Armor:** Edge security to protect against DDoS and OWASP top 10.
* **VPC Service Controls:** Ensuring data exfiltration protection between SQL and GCS.

---

## 5. Economic Value & ROI

This custom architecture is designed to disrupt the high cost of traditional enterprise DAM platforms (Adobe AEM Assets, Bynder, Orange Logic, etc.), which typically range from **$6,000 to $50,000+/year** in licensing alone.

* **One-Time Investment:** $25,000 flat build-out.
* **Infrastructure:** Only pay-as-you-go Google Cloud costs.
* **Long-Term Scaling:** No per-user or per-asset licensing fees; costs grow strictly with business volume.
