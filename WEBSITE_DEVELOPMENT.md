# Step 3: Website Development — GCP Implementation

Architecture for developing the three user portals (Public, Contributor, Admin) natively on **Google Cloud Platform**.

---

## 1. Frontend Hosting (Cloud Run)

We use **Cloud Run** for the Next.js frontend to achieve serverless scale, low latency, and easy rollbacks.

* **Public Site:** Deployed to Cloud Run with **Global Load Balancing** and **Cloud CDN**.
* **Contributor/Admin Panels:** Authenticated via **Google Identity Platform**.

---

## 2. Infrastructure Layer (GCP Unified)

### 2.1 Backend API (Cloud Run)

A containerized Python or Go API that serves all three portals.

* **Authentication:** Firebase Auth / Identity Platform for seamless user login.
* **Security:** Cloud Armor policies to block malicious traffic at the edge.

### 2.2 Storage: GCS V4 Signed URLs

To handle direct uploads from contributors securely:

1. Frontend requests a **V4 Signed URL** from the Backend API.
2. Client uploads the image directly to **Google Cloud Storage**.
3. **Cloud Pub/Sub** notifies the processing pipeline.

### 2.3 Payments: Stripe on GCP

Stripe webhooks are handled by a dedicated **Cloud Function**, ensuring they are processed asynchronously and reliably without blocking the main API thread.

---

## 3. Deployment Pipeline

* **CI/CD:** Google Cloud Build automates the "Git Push to Deploy" workflow.
* **Container Registry:** Artifact Registry for storing built images.
* **Monitoring:** Cloud Logging and Cloud Monitoring (Stackdriver) for real-time alerting on API errors or slow search queries.
