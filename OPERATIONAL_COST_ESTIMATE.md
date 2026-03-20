# Stock Catalog Infrastructure Proposal & Estimated Costs (GCP)

This document outlines the revised cost structure for the Shutterstock-like platform, optimizing for high-performance delivery while minimizing unnecessary cloud spend through intelligent storage tiering and edge caching.

---

## 8. Estimated GCP Infrastructure Costs (Full Scale)

Google Cloud infrastructure costs are paid directly to Google. Below is a monthly estimate based on the **~150TB archive volume** at full enterprise scale:

| GCP Service | Monthly Estimate | Notes |
| :--- | :--- | :--- |
| **Cloud Storage (~150TB)** | ~$1,800 – 3,500 | Varies with Cold/Archive lifecycle tiers |
| **Cloud SQL (PostgreSQL)** | ~$200 – 400 | db-standard-4 instance for metadata |
| **Cloud Run (API + Pipeline)**| ~$150 – 300 | Serverless, auto-scaling compute |
| **Vertex AI (Search + Vision)**| ~$300 – 600 | Logic for semantic search and tagging |
| **Pub/Sub + Networking** | ~$50 – 100 | Event-driven messaging & internal traffic |
| **BigQuery (Analytics)** | ~$50 – 100 | Data warehouse for business intelligence |
| **ESTIMATED MONTHLY TOTAL** | **~$2,550 – 5,000** | **Usage-dependent** |

> **Note:** These are indicative estimates. Actual costs depend on usage patterns, query volume, and lifecycle policies applied to storage. Using Coldline/Archive classes for less-accessed files can significantly reduce storage costs.

---

## 💡 Key Architectural Optimizations

### 1. Unified Hot & Cold Storage Strategy

To manage 150TB cost-effectively, we implement a **Dual-Tier Storage** model:

* **Hot Storage (Standard Class):** High-speed access for thumbnails, watermarked previews, and the "Top 100k" trending assets.
* **Cold/Archive Storage:** Original high-resolution RAW files and historical archives (90% of the volume).
* **Saving:** Moving a file from Standard to Archive reduces its cost by over **90%**.

### 2. ImgIX-Style "Dynamic Imaging" Edge Cache

Instead of storing thousands of fixed-size thumbnails, we use an **ImgIX-like architecture** via **Google Cloud CDN + Cloud Run**:

* **Just-in-Time Processing:** Images are resized, watermarked, and converted to WebP/AVIF on-the-fly when first requested.
* **Aggressive Caching:** The result is stored at Google's edge locations (Points of Presence).
* **Value:**
  * **Reduced Storage:** Eliminate the need to pre-generate and store millions of preview variants.
  * **Performance:** Instant delivery from the edge, reducing latency for global users.
  * **Cost:** Significant savings on egress/bandwidth by serving optimized, modern formats (WebP).

---

## 🚀 Minimum Viable Infrastructure (Internal Pilot Phase)

If the application is initially restricted to internal users for testing and a smaller initial asset library (e.g., 2TB), the starting costs are significantly lower:

| Component | Minimum Monthly Cost | Setup |
| :--- | :--- | :--- |
| **Compute** | ~$20 – 50 | 1x Shared CPU Cloud Run instance |
| **Database** | ~$15 – 30 | Small db-f1-micro or Cloud SQL instance |
| **Storage (2TB)** | ~$10 – 40 | Standard storage with Wasabi or B2 (via GCS Interop) |
| **AI (Embeddings)** | ~$10 – 20 | Pay-per-use Vertex AI API calls |
| **TOTAL PILOT COST** | **~$55 – 140 / mo** | **$0 Upfront Investment** |

---

## 💎 The "Hybrid" Advantage (Maximum Savings)

If you choose to host the 150TB image library on a separate storage server while keeping the application in GCP:

* **Eliminate Egress Fees:** You bypass the high cost of cloud data transfer.
* **Monthly Savings:** Reduces the "ESTIMATED MONTHLY TOTAL" by an additional **$500 – $1,500** depending on traffic.
* **Total Monthly OpEx:** Could drop to as low as **~$1,500 – 2,500** for a full 150TB enterprise catalog.

---

## 📉 Long-Term Economic Moat

By building this on custom GCP infrastructure rather than subscribing to a SaaS Digital Asset Management (DAM) tool (e.g., Bynder or Adobe AEM), you transition from an **ongoing subscription tax** to a **linear utility cost**.

* **Custom Build:** Costs scale with your revenue/assets.
* **SaaS License:** Costs scale with user seats and arbitrary "platform tiers" (typically $10k–$50k/year).
