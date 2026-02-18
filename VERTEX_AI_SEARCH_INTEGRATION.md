# Vertex AI Search Integration — GCP

This document implementation details for **Vertex AI Search** (formerly Enterprise Search) and **Vertex AI Vector Search** (Matching Engine) as the core discovery engine on GCP.

---

## 1. Hybrid Search Architecture

GCP provides a unified way to combine large-scale vector similarity with high-quality keyword search.

| Component | Role |
| :--- | :--- |
| **Vertex AI Search** | Handles keyword retrieval, autocomplete, and facets. |
| **Vertex AI Vector Search** | Handles semantic "image-to-image" and "text-to-image" conceptual matching. |
| **Hybrid Ranking** | Merges results from both using a Weighted Scoring model. |

---

## 2. Schema Definition (GCP)

| Field | Type | Use Case |
| :--- | :--- | :--- |
| `id` | `String` | Unique Key |
| `text_features` | `String` | Title, description, and tags for BM25 search. |
| `embedding` | `Float[]` | 768 or 1024 dimension vector for visual search. |
| `category` | `String` | Filtering and faceting. |
| `price` | `Double` | Sorting and filtering. |

---

## 3. Implementation Workflow

### 3.1 Vector Indexing

1. Generate embeddings using **Vertex AI Multimodal Embeddings**.
2. Deploy to a **Vector Search Index Endpoint** for sub-10ms similarity search.

### 3.2 Data Ingestion (Cloud Storage Pipeline)

Vertex AI Search can automatically index data from **Google Cloud Storage** if provided in JSONL format.

**Command Example:**

```bash
gcloud ai-platform search indexes create ...
```

---

## 4. Why GCP for Image Search?

* **Vertex AI Matching Engine:** Offers the industry's lowest latency and highest scale for multi-million vector search (industry benchmarking shows superior performance over typical HNSW implementations).
* **Fully Managed:** Unlike OpenSearch or custom Qdrant, GCP handles scaling of the infrastructure automatically based on query volume (QPS).
