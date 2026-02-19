# GCP Infrastructure Setup Guide

This guide outlines the steps to initialize your Google Cloud environment for the Shutterstock-like marketplace.

## 📋 Prerequisites

1. **Google Cloud Account:** Ensure you have an active account with billing enabled.
2. **gcloud CLI:** Install and initialize the Google Cloud SDK.

    ```bash
    gcloud auth login
    gcloud config set project [YOUR_PROJECT_ID]
    ```

---

## 🛠️ Step 1: Enable Required APIs

Run the following command to enable all necessary services for our architecture:

```bash
gcloud services enable \
    compute.googleapis.com \
    run.googleapis.com \
    sqladmin.googleapis.com \
    storage.googleapis.com \
    aiplatform.googleapis.com \
    discoveryengine.googleapis.com \
    iam.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    cloudresourcemanager.googleapis.com
```

---

## 🏗️ Step 2: Storage Setup (GCS)

Create the primary buckets for image storage and derivatives.

```bash
# Set your preferred region (e.g., us-central1)
REGION="us-central1"
PROJECT_ID=$(gcloud config get-value project)

# Create the main asset bucket
gsutil mb -l $REGION gs://$PROJECT_ID-marketplace-assets

# Create folders for structure (simulation)
gsutil cp /dev/null gs://$PROJECT_ID-marketplace-assets/originals/.
gsutil cp /dev/null gs://$PROJECT_ID-marketplace-assets/thumbnails/.
gsutil cp /dev/null gs://$PROJECT_ID-marketplace-assets/watermarked/.
```

---

## 🗄️ Step 3: Database Setup (Cloud SQL)

Initialize the PostgreSQL instance with `pgvector` support.

1. **Create Instance:**

    ```bash
    gcloud sql instances create marketplace-db \
        --database-version=POSTGRES_15 \
        --tier=db-f1-micro \
        --region=$REGION \
        --root-password=[YOUR_PASSWORD]
    ```

2. **Enable pgvector:**
    Connect to the instance and run:

    ```sql
    CREATE EXTENSION IF NOT EXISTS vector;
    ```

---

## 🔍 Step 4: Search Engine (Vertex AI)

Initialize the Vertex AI Search (formerly Discovery Engine) data store.

1. Navigate to the **Search & Conversation** console in GCP.
2. Create a new **Data Store** of type **Cloud Storage**.
3. Point it to your metadata JSONL files (once ingestion starts in Phase 1).

---

## 🔑 Step 5: Service Accounts & Permissions

Create a dedicated service account for the application to interact with GCS and Vertex AI.

```bash
# Create the service account
gcloud iam service-accounts create marketplace-sa \
    --display-name="Marketplace Application Service Account"

# Grant Storage Admin (for initial ingestion)
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:marketplace-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Grant Vertex AI User
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:marketplace-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"
```

---

## 🚀 Next Steps

Once these services are initialized, proceed to **Phase 1: Ingestion** as outlined in the [DEVELOPMENT_ROADMAP.md](./DEVELOPMENT_ROADMAP.md).
