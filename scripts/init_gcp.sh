#!/bin/bash

# Configuration
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"

echo "🚀 Initializing GCP Infrastructure for Project: $PROJECT_ID"

# 1. Enable APIs
echo "📡 Enabling Google Cloud APIs..."
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

# 2. Storage Setup
echo "📦 Creating Cloud Storage Buckets..."
gsutil mb -l $REGION gs://$PROJECT_ID-marketplace-assets
gsutil mb -l $REGION gs://$PROJECT_ID-marketplace-metadata

# 3. Service Account Setup
echo "🔑 Configuring Service Accounts..."
gcloud iam service-accounts create marketplace-sa --display-name="Marketplace App Service Account"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:marketplace-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:marketplace-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"

echo "✅ Initialization Complete!"
echo "Next Step: Manually create your Cloud SQL instance using the GCP Console or guide."
