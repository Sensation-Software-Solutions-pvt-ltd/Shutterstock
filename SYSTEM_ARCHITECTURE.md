# Shutterstock-like Image Marketplace — System Architecture

> **Version:** 1.1 · **Date:** 2026-02-18 · **Scale Target:** 5M+ images, 10K RPM search

---

## 🚀 Implementation Roadmap (3 Pillars)

### [Step 1: Image Ingestion (Batch Migration)](./BATCH_INGESTION_WORKFLOW.md)

* **Goal:** Processing 5M+ local images into Azure Blob Storage.
* **Key Tech:** Python, CLIP (AI Tagging), pgvector.

### [Step 2: Search Engine (Azure AI Search Integration)](./AZURE_AI_SEARCH_INTEGRATION.md)

* **Goal:** Enabling conceptual "Semantic" search + Keyword search.
* **Key Tech:** Azure AI Search, Hybrid RRF.

### [Step 3: Triple-Portal Website Development](./WEBSITE_DEVELOPMENT.md)

* **Goal:** Launching the **Public**, **Contributor**, and **Admin** portals.
* **Key Tech:** Next.js, Stripe, Role-Based Access Control (RBAC).

---

## 1. High-Level Integrated Architecture

```
                          ┌─────────────────────────────────────────────┐
                          │         CDN (Azure Front Door / Akamai)     │
                          └────────────────────┬────────────────────────┘
                                               │
               ┌───────────────────────────────┼──────────────────────────────┐
               ▼                               ▼                              ▼
    ┌────────────────────┐          ┌────────────────────┐          ┌────────────────────┐
    │    Public Site     │          │ Contributor Panel  │          │    Admin Panel     │
    │  (Search/Purchase) │          │  (Upload/Earnings) │          │ (Moderate/Payouts) │
    └──────────┬─────────┘          └──────────┬─────────┘          └──────────┬─────────┘
               │                               │                               │
               └─────────────────┬─────────────┴───────────────────────────────┘
                                 │
                          ┌──────▼──────────────────────────────────────┐
                          │           Unified Backend API Layer         │
                          │   (JWT Auth, RBAC, Rate Limiting, Logic)    │
                          └──┬──────┬──────┬──────┬──────┬──────┬───────┘
                             │      │      │      │      │      │
              ┌──────────────┘      │      │      │      │      └──────────────┐
              ▼                     ▼      │      ▼      ▼                     ▼
   ┌──────────────────┐  ┌─────────────┐  │ ┌─────────────┐  ┌──────────────────┐
   │  Auth Service    │  │ Background  │  │ │ Azure AI    │  │ Payment Gateway  │
   │  (Azure AD/Auth0)│  │ Processing  │  │ │ Search      │  │ (Stripe)         │
   └──────────────────┘  └──────┬──────┘  │ └─────────────┘  └──────────────────┘
                                │         │
                                ▼         │          ┌──────────────────────────┐
                   ┌────────────────────┐ │          │   Azure Blob Storage     │
                   │  Image Processor   │ │          │                          │
                   │  (AI, Thumb, WM)   │ │          │  /originals  (private)   │
                   └────────┬───────────┘ │          │  /thumbnails (public)    │
                            │             │          │  /watermarked (public)   │
                            ▼             │          └──────────────────────────┘
                   ┌────────────────────┐ │
                   │  Service Bus       │ │          ┌──────────────────────────┐
                   │  (Queue / Topics)  │◄┘          │  Primary Metadata DB     │
                   └────────────────────┘            │  (PostgreSQL)            │
                                                     └──────────────────────────┘
```

---

## 2. Integrated Feature Matrix

| Pillar | Public (Buyer) | Contributor (Artist) | Admin (Staff) |
| :--- | :--- | :--- | :--- |
| **Search** | Semantic & Faceted | Personal Portfolio Search | Flagged Content Search |
| **Commerce** | Cart & Subscriptions | Earnings & Tax Info | Payout Batches & Pricing |
| **Content** | High-res Downloads | AI-Assisted Uploads | Moderation & Categorization |
| **Access** | Guest / Account | RBAC: Contributor Role | RBAC: Admin Role |

---

## 3. Data Infrastructure (Unified)

### 3.1 Metadata Storage (PostgreSQL)

The source of truth for all relational data: users, licenses, image metadata, and audit logs.

### 3.2 Search Index (Azure AI Search)

The high-performance read-model for discovery. Synchronized from PostgreSQL and Blob metadata.

### 3.3 Object Storage (Azure Blob)

Stores millions of files across tiers:

* **Hot Tier:** Watermarked previews and thumbnails.
* **Cool/Archive Tier:** Original high-res RAW/TIFF files.

---

## 4. Scalability & Security

* **RBAC:** Strict separation of duties. Admin APIs are inaccessible to Contributor/Public tokens.
* **Queueing:** Azure Service Bus handles all long-running tasks (e.g., massive 5M image migrations).
* **Elasticity:** Frontend portals are statically generated at the edge (SSG) for instant global load times.
