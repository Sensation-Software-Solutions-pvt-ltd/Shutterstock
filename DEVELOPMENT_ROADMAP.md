# Development Roadmap — Shutterstock-like Marketplace

This roadmap breaks down the build into six logical phases, prioritizing core infrastructure and search logic before expanding into user-facing portals.

---

## 🏗️ Phase 1: Foundation & Bulk Ingestion (Initial Migration)

*Goal: Ingest the initial 5M+ images into Google Cloud and build the metadata foundation.*

* **Setup Infrastructure:**
  * Initialize GCP Project, Cloud SQL (PostgreSQL), and Google Cloud Storage (GCS).
  * Configure VPC and IAM Service Accounts.
* **Batch Pipeline development:**
  * Develop the [Batch Processing Script](./BATCH_INGESTION_WORKFLOW.md).
  * Implement AI Tagging (Vertex AI Vision) and custom CLIP embeddings.
* **Execution:**
  * Run the migration.
  * Output: 5M originals, 5M thumbnails, 5M watermarked previews, and a populated Metadata DB.

---

## 🔍 Phase 2: Search Infrastructure (The Brain)

*Goal: Enable sub-second discovery using hybrid keyword and conceptual search.*

* **Vector Search Deployment:** Deploy Vertex AI Tracking Engine index endpoints.
* **Vertex AI Search Setup:** Configure data stores and indexing policies for metadata.
* **Search Service API:**
  * Develop the Search API (Cloud Run).
  * Implement Hybrid RRF (Reciprocal Rank Fusion) logic.
* **Outcome:** A functional Search API that can retrieve images via Concept (Vectors) or Keyword (BM25).

---

## 🌐 Phase 3: Public Portal & Commerce (The Shop)

*Goal: Launch the primary buyer-facing website and start generating revenue.*

* **Website Core:** Next.js application on Cloud Run + Cloud CDN.
* **Search & Discovery:**
  * Infinite scroll search results grid.
  * Faceted filtering (Orientation, Color, Category).
  * Image Detail Page (PDP) with watermarked previews.
* **Payments Integration:**
  * Stripe Checkout for single-image licenses.
  * Subscription plan implementation.
* **Secure Downloads:** JWT-protected signed URL generation for purchasing high-res originals.

---

## 🎨 Phase 4: Contributor Ecosystem (Content Engine)

*Goal: Enable photographers to join the platform and submit new content.*

* **Contributor Portal:** Dedicated protected area for artists.
* **Secure Uploads:** Implementation of GCS V4 Signed URLs for direct binary uploads.
* **Submission Workflow:**
  * Auto-tagging preview UI.
  * Metadata editing station.
* **Earnings Dashboard:** Stripe Connect integration for payout onboarding and balance tracking.

---

## 🛡️ Phase 5: Admin Panel & Governance (Operations)

*Goal: Provide the tools required to moderate content and manage the platform.*

* **Moderation Queue:** UI for Admins to Approve/Reject submissions.
* **User Management:** Audit logs, banning, and role escalation.
* **Global Metadata:** Direct control over categories, trending tags, and homepage collections.
* **Revenue Dashboard:** Platform-wide sales analytics and payout batch processing.

---

## 🚀 Phase 6: Optimization & Global Scaling

*Goal: Fine-tune performance and prepare for global traffic.*

* **Global Load Balancing:** Deploy Google Cloud Load Balancer (GCLB) with multi-region support.
* **Advanced SEO:** Static Generation (SSG) for 100K+ tag pages (e.g., `/search/forest-backgrounds`).
* **A/B Testing:** Implementation of feature flags for testing search ranking changes.
* **Observability:** Fine-tuning Cloud Monitoring alerts for API latency and DB performance.
