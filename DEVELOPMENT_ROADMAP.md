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

* **Premium Web Application (Next.js):**
  * **Homepage:** Trending search terms, curated collections (e.g., "Deep Space"), and top categories.
  * **Search Results Page:** Masonry-style fluid grid, infinite scroll, and visual-first design.
  * **Product Detail Page (PDP):** Large watermarked preview, EXIF data display, license type selection (Standard vs. Enhanced), and "Similar Images" concept-matching.
* **Search & Facet Implementation:**
  * Integration with Phase 2's Vertex AI Search.
  * Dynamic facets: Orientation (Horizontal/Vertical), Color Palette (HEX-based), and Contributor.
* **Commerce Architecture (Stripe):**
  * **Stripe Checkout:** Secure session management for card payments.
  * **Subscriptions:** Implementation of monthly/yearly "Download Credit" plans.
  * **Post-Purchase Flow:** Automated licensing PDF generation and transaction emails.
* **The Secure Download Gateway:**
  * Implementation of an "Access Gateway" that verifies license ownership.
  * Triggering **GCS V4 Signed URLs** with a 15-minute expiration only for authorized high-res original files.

---

## 🎨 Phase 4: Contributor Ecosystem (Content Engine)

*Goal: Enable photographers to join the platform and submit new content.*

* **Contributor Onboarding:**
  * Registration flow with legal identity verification.
  * **Stripe Connect Integration:** Linking bank accounts for automated payouts (Express or Custom).
* **High-Volume Asset Submission:**
  * **Direct-to-GCS Uploader:** Client-side multi-file uploader using Signed URLs to bypass server bottlenecks.
  * **AI Tagging Station:** Real-time preview of Vertex AI suggested tags; contributors can add/modify/delete tags before final submission.
* **Portfolio Management Dashboard:**
  * **Asset Control:** Manage "Live" vs "Pending Review" vs "Rejected" status.
  * **Bulk Edit:** Update prices or metadata for multiple items at once.
* **Earnings & Analytics:**
  * Graphical breakdown of revenue per month/image.
  * Real-time payout balance and automated monthly withdrawal settings.

---

## 🛡️ Phase 5: Admin Panel & Governance (Operations)

*Goal: Provide the tools required to moderate content and manage the platform.*

* **Content Moderation Suite:**
  * **Smart Review Queue:** Side-by-side view showing the submitted image + AI-suggested metadata.
  * **Decision Workflow:** Approve, Reject (with reason codes: "Focus", "Noise", "Copyright"), or "Request Revision".
* **Platform Configuration:**
  * **Pricing Engine:** Global control over platform margins and subscription prices.
  * **Collection Management:** Curate homepage carousels, "Staff Picks", and Seasonal topics.
  * **System Messaging:** Global banners for site maintenance or contributor announcements.
* **Advanced User Governance:**
  * Cross-portal management: Audit logs and user status controls (Banning/Suspend/Elevate).
  * Role Management: Management of platform access levels (Moderator vs. Super Admin).
* **Business Intelligence (BI):**
  * Dashboards integrated with **BigQuery** for high-level sales data, top-performing contributors, and churn analytics.

---

## 🚀 Phase 6: Optimization & Global Scaling

*Goal: Fine-tune performance and prepare for global traffic.*

* **Global Load Balancing:** Deploy Google Cloud Load Balancer (GCLB) with multi-region support.
* **Advanced SEO:** Static Generation (SSG) for 100K+ tag pages (e.g., `/search/forest-backgrounds`).
* **A/B Testing:** Implementation of feature flags for testing search ranking changes.
* **Observability:** Fine-tuning Cloud Monitoring alerts for API latency and DB performance.
