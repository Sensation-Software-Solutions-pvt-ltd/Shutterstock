# Self-Hosted / On-Premise Architecture (Bare Metal)

If you prefer to avoid ongoing cloud subscriptions (GCP/AWS) and instead invest in your own hardware, this Shutterstock-like platform can absolutely be built on an **On-Premise (Self-Hosted)** architecture.

This approach swaps proprietary cloud services for open-source equivalents running on hardware you own.

---

## 🏗️ Technology Stack Shift (Cloud vs. Self-Hosted)

| Component | GCP Cloud Version | Self-Hosted Open-Source Equivalent |
| :--- | :--- | :--- |
| **Object Storage (Files)** | Google Cloud Storage | **MinIO** or **TrueNAS** (S3-compatible) |
| **Database** | Cloud SQL for PostgreSQL | **PostgreSQL** + `pgvector` (Running locally in Docker) |
| **Compute / Hosting** | Cloud Run (Serverless) | **Docker Compose** or **Kubernetes** (k3s) on Linux |
| **AI Tagging & Embeddings** | Vertex AI Vision API | **OpenAI CLIP** or **Transformers.js** (Running locally on a GPU) |
| **Messaging / Queues** | Google Pub/Sub | **RabbitMQ** or **Redis queues** |
| **CDN / Shield** | Cloud CDN + Cloud Armor | **Cloudflare** (Sitting in front of your server) |

---

## 💻 Hardware Requirements (The "Server Build")

To handle **150TB of storage** and **AI vector search** on your own hardware, you will need a substantial server setup. 

### 1. The Storage Array (NAS / SAN)
*   **Usable Capacity needed:** 150TB. 
*   **Raw Capacity needed:** ~200TB+ (You must use RAID 6 or RAID-Z2 to protect against hard drive failures).
*   **Drives:** Approx. 12x 20TB Enterprise HDDs (e.g., Seagate Exos or WD Gold).
*   **Estimated Hardware Cost:** ~$6,000 – $8,000

### 2. The Compute Server
*   **CPU:** 16-Core to 32-Core Server CPU (AMD EPYC or Intel Xeon).
*   **RAM:** 128GB to 256GB ECC RAM (Database and Vector Search in-memory operations require high RAM).
*   **GPU:** At least one **NVIDIA RTX 4090** or **A6000** (Required for generating AI image tags and vector embeddings locally without paying Google).
*   **Boot/Cache Drives:** 2x 2TB NVMe SSDs (For O.S., database, and caching hot images).
*   **Estimated Hardware Cost:** ~$5,000 – $8,000

### 3. The Network Setup
*   **Static IP:** You need a static IP from your ISP.
*   **Bandwidth:** A dedicated symmetric fiber connection (e.g., 1 Gbps Up / 1 Gbps Down) is highly recommended. 
*   **Power:** Uninterruptible Power Supply (UPS) battery backups are critical.

---

## ⚖️ Pricing Comparison Strategy

### The Cloud Way (GCP)
*   **Upfront Cost:** $0 (Just development time).
*   **Monthly Ongoing:** ~$1,000 / month.
*   **After 3 Years:** **~$36,000** completely sunk.

### The Self-Hosted Way (Bare Metal)
*   **Upfront Cost:** ~$12,000 – $15,000 for the Server + Storage.
*   **Monthly Ongoing:** ~$100 / month (Electricity + Internet + Cloudflare Pro).
*   **After 3 Years:** **~$18,600** (And you still own the hardware).

### 💡 Alternative: Using a Hosted Server for Images (The Middle Ground)
*   If you prefer not to buy or maintain hard drives locally, you can rent a dedicated "Hosted Server" (e.g., a high-capacity Hetzner or OVH storage server, or cheap S3-compatible cloud storage like Wasabi/Backblaze B2) to host the actual image files.
*   **How it works:** You run the web app and database on a smaller local server (or a standard VPS), but the massive 150TB image repository is stored on the rented hosted server.
*   **Upfront Cost:** $0 (No massive hardware investment).
*   **Monthly Ongoing:** ~$200 - $300 / month (For a 150TB dedicated storage server).
*   **After 3 Years:** **~$9,000 – $10,800** (You eliminate hardware maintenance, drive replacement, and upfront capital expenses).

---

## 🚀 Phase 1: Internal Users & Pilot Phase

If the application is initially going to be used exclusively by internal users to test the waters, you do **not** need to provision for 150TB of storage or handle massive web traffic on Day 1.

For an internal pilot (assuming ~1TB to 5TB of initial content):

### The "Start Small" Cloud Approach (Recommended for Pilot)
*   **Compute:** A small Google Cloud Run instance or a basic VPS ($20–$50/mo).
*   **Database:** A small managed PostgreSQL database or a Docker container ($20–$50/mo).
*   **Storage:** 2TB of standard cloud object storage (e.g., Wasabi, B2, or GCP Storage) (~$10–$40/mo).
*   **AI generation:** Paid via API (OpenAI/Google) until volume justifies a GPU (~$10–$20/mo).
*   **Starting Cost:** **~$60 to $150 / month** with $0 upfront investment.

### The "Start Small" Rented Server Approach
*   **Infrastructure:** A single, standard Dedicated Server (e.g., Hetzner or DigitalOcean) with a 2TB to 4TB NVMe drive and a basic CPU.
*   **Starting Cost:** **~$40 to $70 / month** with $0 upfront investment.

*Once internal testing is complete and the library needs to scale toward 150TB, you can seamlessly migrate the data to either the Enterprise Cloud or a massive Self-Hosted bare metal array.*

---

## 🚦 Pros and Cons of Going Self-Hosted

### ✅ The Advantages
1.  **Massive Cost Savings over time:** After the system pays for itself (usually around month 12-15), your operating costs drop to almost zero compared to the cloud.
2.  **Complete Data Sovereignty:** You own the drives. No tech giant can scan, throttle, or lock you out of your data.
3.  **Flat Fee AI:** You can generate millions of image tags and vectors using your local GPU without paying a per-request AI API fee.

### ❌ The Disadvantages (The "Hidden" Catch)
1.  **You are the IT Department:** If a hard drive fails at 3 AM, you have to physically swap it. If your power goes out, your website goes down. 
2.  **Global Latency:** A server sitting in one office/datacenter will be slow for users on the other side of the world. (We mitigate this by putting **Cloudflare CDN** in front of your server to cache thumbnails globally).
3.  **Disaster Recovery:** If the building burns down, your 150TB is gone. You still need an off-site backup strategy (e.g., paying for AWS Glacier drop or buying a second smaller server for another location).
