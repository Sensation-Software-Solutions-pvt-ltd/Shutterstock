# Estimated Operational Costs (GCP)

This document provides a breakdown of the ongoing "pay-as-you-go" costs for the Google Cloud Platform infrastructure. Unlike enterprise licensing, these costs scale directly with your traffic and storage usage.

---

## 📊 Summary of Costs (Optimized)

| Phase | Volume | Estimated Monthly Cost | Savings vs. Enterprise SaaS |
| :--- | :--- | :--- | :--- |
| **Start-up** | < 1M images | **$120 – $250** | ~90% Lower |
| **Growth Phase** | ~5M images | **$450 – $800** | ~85% Lower |
| **Enterprise Archive** | **~150TB / 10M+ images** | **$850 – $1,400** | **~$50k+/year Saved** |

---

## 🛠️ Itemized Monthly Breakdown (Enterprise Archive Scale)

Based on a baseline of **150 Terabytes** of archival assets.

### 1. Storage (Google Cloud Storage) — **The Major Saver**

* **Strategy:** 95% of data (Originals) in **Archive Class** ($0.0012/GB); 5% (Thumbnails/Watermarked) in **Standard**.
* **Estimated Cost:** **$180 – $350/mo** (Reduced from ~$2,000/mo)

### 2. Database (Cloud SQL for PostgreSQL)

* **Specs:** 2 vCPU, 8GB RAM with `pgvector` for semantic search.
* **Estimated Cost:** **$120 – $200/mo**

### 3. Search Intelligence (Hybrid Approach)

* **Optimization:** Instead of a persistent Vertex AI Search endpoint ($$$), we use **Vertex AI Embeddings** (pay-per-use) + **pgvector** for the actual search.
* **Estimated Cost:** **$80 – $150/mo**

### 4. Compute (Cloud Run)

* **Optimization:** Hosting the Next.js frontend and Backend API with aggressive scale-to-zero during idle hours.
* **Estimated Cost:** **$60 – $120/mo**

### 5. Networking & CDN

* **Usage:** Global CDN delivery. Costs are purely traffic-driven.
* **Estimated Cost:** **$50 – $150/mo**

---

## 💡 Key Optimization Strategies

* **Archive Storage Tiering:** By setting a GCS Lifecycle Policy to move files to "Archive" after 7 days, storage costs drop by **90%**.
* **Hybrid Vector Search:** Using `pgvector` inside our existing database eliminates the need for expensive dedicated vector search clusters in the early years.
* **Batch Vision Processing:** During ingestion, we use "Batch" mode for Vertex AI Vision, which is significantly cheaper than real-time API calls.

---

## 📉 Comparison: The "Invisible" Savings

When comparing these costs to a "Server" (old-school VPS), remember that GCP includes:

1. **Zero Maintenance:** No OS patching, security updates, or hardware failure management.
2. **High Availability:** Your site is distributed across multiple data centers automatically.
3. **Security:** Enterprise-grade DDoS protection (Cloud Armor) included at the edge.
