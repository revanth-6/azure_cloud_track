# Azure Database & Data Processing Notes

## 1. What is OLTP? How does it maintain/process business flows?

### OLTP (Online Transaction Processing)

OLTP is a type of data processing that focuses on **executing real-time transactional operations** — such as inserts, updates, and deletes — that occur in day-to-day business operations.

### Key Characteristics:
- **High volume of short, atomic transactions** (e.g., placing an order, processing a payment)
- **ACID compliance** (Atomicity, Consistency, Isolation, Durability)
- **Low latency** — responses in milliseconds
- **Normalized data** to minimize redundancy
- **Concurrent access** by many users simultaneously

### How OLTP Maintains/Processes Business Flows:

```text
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ Customer     │────▶│ OLTP System   │────▶│ Database     │
│ (Request)    │      │ (App Logic)  │      │ (ACID Txns)  │
└──────────────┘      └──────────────┘      └──────────────┘
                            │
                ┌─────────────┼─────────────┐
                ▼             ▼             ▼
           ┌──────────┐  ┌──────────┐  ┌──────────┐
           │ Order    │  │ Payment  │  │ Inventory│
           │ Created  │  │ Processed│  │ Updated  │
           └──────────┘  └──────────┘  └──────────┘
```

text

### Business Flow Processing:

| Step | Action | OLTP Role |
|------|--------|-----------|
| 1 | Customer places an order | **INSERT** order record |
| 2 | Payment is processed | **UPDATE** payment status |
| 3 | Inventory is decremented | **UPDATE** stock count |
| 4 | Shipping is triggered | **INSERT** shipment record |
| 5 | If any step fails | **ROLLBACK** entire transaction |

### Azure Services for OLTP:
- **Azure SQL Database** — Fully managed relational database
- **Azure Database for PostgreSQL** — Managed PostgreSQL
- **Azure Database for MySQL** — Managed MySQL
- **Azure Cosmos DB** (for NoSQL OLTP workloads)

### Example — Bank Transfer Transaction:

```sql
BEGIN TRANSACTION;
    UPDATE accounts SET balance = balance - 500 WHERE account_id = 'A123';
    UPDATE accounts SET balance = balance + 500 WHERE account_id = 'B456';
    INSERT INTO transactions (from_acc, to_acc, amount, timestamp)
        VALUES ('A123', 'B456', 500, GETDATE());
COMMIT TRANSACTION;
-- If ANY step fails, the entire transaction is ROLLED BACK
```

2. How to Design a Database for Low Latency?

Design Principles for Low Latency

text

```text
┌─────────────────────────────────────────────────────┐
│              LOW LATENCY DATABASE DESIGN             │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────┐  ┌──────────┐  ┌────────────────────┐ │
│  │Indexing  │  │Partitioning│ │Connection Pooling │ │
│  └─────────┘  └──────────┘  └────────────────────┘ │
│  ┌─────────┐  ┌──────────┐  ┌────────────────────┐ │
│  │Caching  │  │Read       │  │Data Locality      │ │
│  │Layer    │  │Replicas   │  │(Geo-distribution) │ │
│  └─────────┘  └──────────┘  └────────────────────┘ │
│  ┌─────────┐  ┌──────────┐  ┌────────────────────┐ │
│  │Query    │  │Schema    │  │Right DB Engine     │ │
│  │Optimize │  │Design    │  │Selection           │ │
│  └─────────┘  └──────────┘  └────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

Strategy Breakdown:

### A. Proper Indexing

SQL

```sql
-- Create indexes on frequently queried columns
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);

-- Composite index for multi-column queries
CREATE INDEX idx_orders_composite ON orders(customer_id, order_date DESC);

-- Covering index to avoid table lookups entirely
CREATE INDEX idx_covering ON orders(customer_id) INCLUDE (order_total, status);
```

### B. Caching Layer

text

```text
┌────────┐     ┌───────────────┐     ┌──────────┐
│ Client │────▶│ Azure Cache   │────▶│ Database │
│        │     │ for Redis     │     │          │
│        │◀────│ (< 1ms reads) │◀────│          │
└────────┘     └───────────────┘     └──────────┘
                Cache Hit: ~0.5ms
                Cache Miss: ~5-20ms (then cache it)
```

### C. Read Replicas

text

```text
                    ┌──────────────┐
         Writes ───▶│   Primary    │
                    │   Database   │
                    └──────┬───────┘
                           │ Replication
                ┌──────────┼──────────┐
                ▼          ▼          ▼
          ┌──────────┐ ┌──────────┐ ┌──────────┐
 Reads───▶│ Replica 1│ │ Replica 2│ │ Replica 3│
          └──────────┘ └──────────┘ └──────────┘
```

### D. Partitioning / Sharding

SQL

```sql
-- Horizontal partitioning by date range
CREATE PARTITION FUNCTION pf_order_date (DATE)
AS RANGE RIGHT FOR VALUES ('2023-01-01', '2024-01-01', '2025-01-01');

-- Queries on recent data only scan the relevant partition
SELECT * FROM orders WHERE order_date >= '2025-01-01';
-- Scans only the 2025 partition instead of the full table
```

### E. Connection Pooling

text

```text
┌──────────────┐     ┌─────────────────┐     ┌──────────┐
│ App Instance │────▶│ Connection Pool  │────▶│ Database │
│ (100 users)  │     │ (20 connections) │     │          │
└──────────────┘     └─────────────────┘     └──────────┘

Without pooling: 100 connections (expensive)
With pooling:     20 connections (reused efficiently)
```

### F. Data Locality (Geo-Distribution)

text

```text
    US Users ──▶ Azure SQL (East US)    ~5ms
    EU Users ──▶ Azure SQL (West EU)    ~5ms
    Asia Users──▶ Azure SQL (SE Asia)   ~5ms
    
    vs. Single Region:
    Asia Users──▶ Azure SQL (East US)   ~200ms ❌
```

### Azure Services & Configuration Tips:

| Strategy | Azure Service | Impact |
|-----------|--------------|---------|
| Caching | Azure Cache for Redis | Sub-millisecond reads |
| Read Replicas | Azure SQL Read Scale-Out | Offload read traffic |
| Geo-distribution | Cosmos DB Multi-Region | Local latency globally |
| Connection Pooling | PgBouncer / Built-in pooling | Reduce connection overhead |
| In-Memory Tables | Azure SQL In-Memory OLTP | 10-30x faster transactions |
| Tier Selection | Business Critical / Premium Tier | Local SSD, higher IOPS |

---

## 3. How to Create a Normalized Database?

### What is Normalization?

Normalization is the process of organizing a relational database to reduce data redundancy
and improve data integrity by dividing large tables into smaller, related tables.

### The Normal Forms:

text

```text
┌─────────────────────────────────────────────────────────┐
│                  NORMALIZATION LEVELS                   │
├──────────┬──────────────────────────────────────────────┤
│   UNF    │ Unnormalized — raw data, repeating groups    │
│   1NF    │ Atomic values, no repeating groups           │
│   2NF    │ 1NF + No partial dependencies                │
│   3NF    │ 2NF + No transitive dependencies             │
│   BCNF   │ Stricter 3NF (every determinant is a key)    │
└──────────┴──────────────────────────────────────────────┘
```

### Step-by-Step Example:

❌ Unnormalized Table (UNF):

text

```text
┌──────────┬──────────┬───────────┬──────────────────────────────────┐
│ OrderID  │ Customer │ Phone     │ Items                            │
├──────────┼──────────┼───────────┼──────────────────────────────────┤
│ 1001     │ Alice    │ 555-0101  │ Laptop:$999, Mouse:$25           │
│ 1002     │ Bob      │ 555-0202  │ Keyboard:$75                     │
│ 1003     │ Alice    │ 555-0101  │ Monitor:$300, Cable:$10          │
└──────────┴──────────┴───────────┴──────────────────────────────────┘
```

Problems: Repeating groups, redundant customer data

### ✅ First Normal Form (1NF) — Atomic Values, No Repeating Groups:

SQL

```sql
-- Each cell contains a single value; each row is unique
CREATE TABLE orders_1nf (
    order_id      INT,
    customer_name VARCHAR(100),
    phone         VARCHAR(20),
    item_name     VARCHAR(100),
    item_price    DECIMAL(10,2),
    PRIMARY KEY (order_id, item_name)
);
```

text

```text
┌──────────┬──────────┬───────────┬───────────┬────────────┐
│ OrderID  │ Customer │ Phone     │ Item      │ Price      │
├──────────┼──────────┼───────────┼───────────┼────────────┤
│ 1001     │ Alice    │ 555-0101  │ Laptop    │ 999.00     │
│ 1001     │ Alice    │ 555-0101  │ Mouse     │  25.00     │
│ 1002     │ Bob      │ 555-0202  │ Keyboard  │  75.00     │
│ 1003     │ Alice    │ 555-0101  │ Monitor   │ 300.00     │
│ 1003     │ Alice    │ 555-0101  │ Cable     │  10.00     │
└──────────┴──────────┴───────────┴───────────┴────────────┘
```

Problem: Customer name & phone repeated (partial dependency)

### ✅ Second Normal Form (2NF) — Remove Partial Dependencies:

SQL

```sql
-- Separate customer info (depends only on customer, not on full composite key)
CREATE TABLE customers (
    customer_id   INT PRIMARY KEY IDENTITY,
    customer_name VARCHAR(100),
    phone         VARCHAR(20)
);

CREATE TABLE orders (
    order_id    INT PRIMARY KEY,
    customer_id INT FOREIGN KEY REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id   INT FOREIGN KEY REFERENCES orders(order_id),
    item_name  VARCHAR(100),
    item_price DECIMAL(10,2),
    PRIMARY KEY (order_id, item_name)
);
```

### ✅ Third Normal Form (3NF) — Remove Transitive Dependencies:

SQL

```sql
-- If item_price depends on item_name (not on order), extract it
CREATE TABLE products (
    product_id   INT PRIMARY KEY IDENTITY,
    product_name VARCHAR(100),
    price        DECIMAL(10,2)
);

CREATE TABLE customers (
    customer_id   INT PRIMARY KEY IDENTITY,
    customer_name VARCHAR(100),
    phone         VARCHAR(20)
);

CREATE TABLE orders (
    order_id    INT PRIMARY KEY,
    customer_id INT FOREIGN KEY REFERENCES customers(customer_id),
    order_date  DATE
);

CREATE TABLE order_items (
    order_id   INT FOREIGN KEY REFERENCES orders(order_id),
    product_id INT FOREIGN KEY REFERENCES products(product_id),
    quantity   INT,
    PRIMARY KEY (order_id, product_id)
);
```

### Final Normalized Schema:

text

```text
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  customers   │     │   orders     │     │  order_items │
├──────────────┤     ├──────────────┤     ├──────────────┤
│ customer_id  │◀───▶│ order_id     │◀───▶│ order_id     │
│ name         │  FK │ customer_id  │  FK │ product_id   │
│ phone        │     │ order_date   │     │ quantity     │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │ FK
                                           ┌──────▼───────┐
                                           │  products    │
                                           ├──────────────┤
                                           │ product_id   │
                                           │ product_name │
                                           │ price        │
                                           └──────────────┘
```

### Benefits of Normalization:

| Benefit | Description |
|----------|-------------|
| No redundancy | Customer data stored once, not repeated per order |
| Data integrity | Update a phone number in one place only |
| Storage efficiency | Less duplicate data = smaller database |
| Easier maintenance | Schema changes are localized |

## 4. What is OLAP?

### OLAP (Online Analytical Processing)

OLAP is a category of data processing optimized for complex analytical queries,
aggregations, and reporting on large volumes of historical data.

It is the counterpart to OLTP.

text

```text
┌─────────────────────────────────────────────────────────────┐
│                    OLTP  vs  OLAP                           │
├────────────────────┬────────────────────────────────────────┤
│       OLTP         │              OLAP                      │
├────────────────────┼────────────────────────────────────────┤
│ INSERT/UPDATE/     │ SELECT with complex                    │
│ DELETE (write-     │ aggregations (read-heavy)              │
│ heavy)             │                                        │
│                    │                                        │
│ Current data       │ Historical data                        │
│ (today's orders)   │ (years of orders)                      │
│                    │                                        │
│ Millisecond        │ Seconds to minutes                     │
│ response           │ response (acceptable)                  │
│                    │                                        │
│ Normalized schema  │ Denormalized / Star schema             │
│                    │                                        │
│ Thousands of       │ Few analysts / BI tools                │
│ concurrent users   │                                        │
│                    │                                        │
│ Individual records │ Millions/billions of rows              │
│                    │ scanned per query                      │
│                    │                                        │
│ Azure SQL DB       │ Azure Synapse Analytics                │
│ Cosmos DB          │ Azure Data Explorer                    │
└────────────────────┴────────────────────────────────────────┘
```

### OLAP Architecture:

text

```text
┌──────────┐  ┌──────────┐  ┌──────────┐
│  OLTP    │  │  CRM     │  │  Logs    │
│  System  │  │  System  │  │  (Files) │
└────┬─────┘  └────┬─────┘  └────┬─────┘
     │             │              │
     └─────────────┼──────────────┘
                   ▼
          ┌────────────────┐
          │  ETL / ELT     │    (Extract, Transform, Load)
          │  Azure Data    │
          │  Factory       │
          └───────┬────────┘
                  ▼
          ┌────────────────┐
          │  Data Warehouse│    (OLAP - Denormalized)
          │  Azure Synapse │
          │  Analytics     │
          └───────┬────────┘
                  ▼
          ┌────────────────┐
          │  BI / Reports  │    (Power BI, Dashboards)
          │  "Total sales  │
          │   by region    │
          │   last 3 years"│
          └────────────────┘
```

### OLAP Query Examples:

SQL

```sql
-- Total revenue by product category per quarter (last 3 years)
SELECT 
    p.category,
    DATEPART(YEAR, o.order_date) AS year,
    DATEPART(QUARTER, o.order_date) AS quarter,
    SUM(oi.quantity * p.price) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM fact_orders o
JOIN fact_order_items oi ON o.order_id = oi.order_id
JOIN dim_products p ON oi.product_id = p.product_id
WHERE o.order_date >= DATEADD(YEAR, -3, GETDATE())
GROUP BY p.category, DATEPART(YEAR, o.order_date), DATEPART(QUARTER, o.order_date)
ORDER BY year, quarter;
```

### Azure Services for OLAP:

| Service | Use Case |
|----------|----------|
| Azure Synapse Analytics | Enterprise data warehouse + big data analytics |
| Azure Data Explorer | Real-time analytics on streaming/log data |
| Azure Analysis Services | OLAP cubes for BI models |
| Power BI | Visualization layer on top of OLAP systems |

---

## 5. How to Analyze Historical Data and Handle Complex Databases?

### Strategy Overview:

text

```text
┌─────────────────────────────────────────────────────────────┐
│         ANALYZING HISTORICAL DATA - FULL PIPELINE           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. COLLECT ──▶ 2. STORE ──▶ 3. MODEL ──▶ 4. ANALYZE      │
│                                                             │
│  Data Sources   Data Lake /   Star/Snow-   SQL Queries /   │
│  (OLTP, Logs,   Warehouse     flake        BI Dashboards   │
│   APIs, Files)                Schema                        │
└─────────────────────────────────────────────────────────────┘
```

### Step 1: Collect — Ingestion with Azure Data Factory

text

```text
┌──────────────────────────────────────────────────┐
│              DATA SOURCES                         │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐ │
│  │SQL DB  │  │ APIs   │  │CSV/JSON│  │IoT/Logs│ │
│  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘ │
│      └───────────┼───────────┼───────────┘       │
│                  ▼                                │
│       ┌──────────────────────┐                   │
│       │ Azure Data Factory   │ (ETL/ELT)         │
│       │ - Scheduled Pipelines│                   │
│       │ - Data Flows         │                   │
│       └──────────┬───────────┘                   │
│                  ▼                                │
│       ┌──────────────────────┐                   │
│       │ Azure Data Lake      │ (Raw Storage)     │
│       │ Gen2 (Bronze Layer)  │                   │
│       └──────────────────────┘                   │
└──────────────────────────────────────────────────┘
```

### Step 2: Store — Medallion Architecture (Bronze → Silver → Gold)

text

```text
┌────────────────┐    ┌────────────────┐    ┌────────────────┐
│   BRONZE       │    │   SILVER       │    │   GOLD         │
│   (Raw Data)   │───▶│  (Cleaned &    │───▶│  (Aggregated & │
│                │    │   Validated)   │    │   Business-    │
│ - As-is from   │    │ - Deduplication│    │   Ready)       │
│   source       │    │ - Type casting │    │ - Star schema  │
│ - JSON, CSV,   │    │ - Null handling│    │ - KPIs, metrics│
│   Parquet      │    │ - Joined data  │    │ - Dashboard-   │
│                │    │                │    │   ready tables │
└────────────────┘    └────────────────┘    └────────────────┘
```

### Step 3: Model — Star Schema for OLAP

text

```text
                    ┌──────────────────┐
                    │   dim_date       │
                    ├──────────────────┤
                    │ date_key (PK)    │
                    │ full_date        │
                    │ year             │
                    │ quarter          │
                    │ month            │
                    │ day_of_week      │
                    └────────┬─────────┘
                             │
┌──────────────┐    ┌────────▼─────────┐    ┌──────────────┐
│ dim_customer │    │  fact_sales      │    │ dim_product  │
├──────────────┤    ├──────────────────┤    ├──────────────┤
│ customer_key │◀──▶│ sale_id (PK)     │◀──▶│ product_key  │
│ name         │ FK │ date_key (FK)    │ FK │ product_name │
│ segment      │    │ customer_key(FK) │    │ category     │
│ region       │    │ product_key (FK) │    │ brand        │
│ city         │    │ store_key (FK)   │    │ unit_price   │
└──────────────┘    │ quantity         │    └──────────────┘
                    │ total_amount     │
                    │ discount         │    ┌──────────────┐
                    └────────┬─────────┘    │ dim_store    │
                             │              ├──────────────┤
                             └─────────────▶│ store_key    │
                                         FK │ store_name   │
                                            │ city         │
                                            │ country      │
                                            └──────────────┘
```

### Step 4: Analyze — Querying & Visualization

SQL

```sql
-- Year-over-year sales growth by region
WITH yearly_sales AS (
    SELECT 
        dc.region,
        dd.year,
        SUM(fs.total_amount) AS revenue
    FROM fact_sales fs
    JOIN dim_customer dc ON fs.customer_key = dc.customer_key
    JOIN dim_date dd ON fs.date_key = dd.date_key
    GROUP BY dc.region, dd.year
)
SELECT 
    region,
    year,
    revenue,
    LAG(revenue) OVER (PARTITION BY region ORDER BY year) AS prev_year_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (PARTITION BY region ORDER BY year)) 
        / LAG(revenue) OVER (PARTITION BY region ORDER BY year) * 100, 2
    ) AS yoy_growth_pct
FROM yearly_sales
ORDER BY region, year;
```

### Handling Complex Databases:

| Challenge | Solution | Azure Tool |
|------------|-----------|------------|
| Massive data volume (TBs/PBs) | Distributed query engine | Azure Synapse Serverless SQL |
| Slow complex joins | Pre-aggregated materialized views | Synapse Materialized Views |
| Multiple data formats | Schema-on-read (Data Lake) | Azure Data Lake Gen2 |
| Real-time + historical | Lambda architecture (batch + stream) | Synapse + Event Hubs |
| Complex transformations | Spark-based processing | Azure Databricks / Synapse Spark |
| Data versioning / time travel | Delta Lake format | Delta Lake on Azure |

### Azure End-to-End Architecture:

text

```text
Sources ──▶ Data Factory ──▶ Data Lake Gen2 ──▶ Databricks/Synapse Spark
                              (Bronze/Silver)     (Transform)
                                                      │
                                                      ▼
                                              Synapse Analytics ──▶ Power BI
                                              (Gold - Star Schema)  (Dashboards)
```

## 6. What is PG-Vector?

### PGVector (pgvector)

pgvector is an open-source PostgreSQL extension that adds support for
vector data types and vector similarity search directly inside PostgreSQL.

It enables storing, indexing, and querying high-dimensional vectors (embeddings)
making PostgreSQL suitable for AI/ML and semantic search workloads.

### Why Vectors?

text

```text
Traditional Search:
  Query: "comfortable running shoes"
  SQL:   WHERE description LIKE '%comfortable%' AND description LIKE '%running%'
  Result: Only exact keyword matches ❌

Vector/Semantic Search:
  Query: "comfortable running shoes" → Embedding: [0.12, -0.85, 0.33, ..., 0.67]
  SQL:   ORDER BY embedding <=> query_embedding LIMIT 5
  Result: Finds "lightweight jogging sneakers with cushioned soles" ✅
         (semantically similar, even without matching keywords)
```

### How It Works:

text

```text
┌────────────────┐     ┌────────────────────┐     ┌────────────────┐
│   Text/Image   │────▶│  Embedding Model   │────▶│   Vector       │
│   Data         │     │  (OpenAI, Azure    │     │  [0.1, -0.3,   │
│                │     │   OpenAI, etc.)    │     │   0.7, ...,    │
│ "The cat sat   │     │                    │     │   0.2]         │
│  on the mat"   │     │  text-embedding-   │     │  (1536 dims)   │
└────────────────┘     │  ada-002           │     └───────┬────────┘
                       └────────────────────┘             │
                                                          ▼
                                                 ┌────────────────┐
                                                 │  PostgreSQL    │
                                                 │  + pgvector    │
                                                 │                │
                                                 │  Store, Index  │
                                                 │  & Search      │
                                                 └────────────────┘
```

### Setup in Azure Database for PostgreSQL:

SQL

```sql
-- Enable the extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create a table with a vector column
CREATE TABLE documents (
    id         SERIAL PRIMARY KEY,
    title      TEXT,
    content    TEXT,
    embedding  vector(1536)   -- 1536 dimensions (OpenAI ada-002)
);

-- Insert a document with its embedding
INSERT INTO documents (title, content, embedding)
VALUES (
    'Azure Overview',
    'Azure is a cloud computing platform by Microsoft...',
    '[0.012, -0.034, 0.056, ..., 0.078]'  -- 1536-dim vector
);
```

### Vector Similarity Search:

SQL

```sql
-- Find the 5 most similar documents to a query embedding
-- Using cosine distance (<=>)
SELECT 
    id,
    title,
    content,
    embedding <=> '[0.011, -0.032, 0.054, ..., 0.076]' AS distance
FROM documents
ORDER BY embedding <=> '[0.011, -0.032, 0.054, ..., 0.076]'
LIMIT 5;
```

### Distance Operators:

| Operator | Distance Type | Use Case |
|-----------|--------------|----------|
| `<->` | L2 (Euclidean) distance | General-purpose similarity |
| `<=>` | Cosine distance | Text embeddings (most common) |
| `<#>` | Inner Product (negative) | When vectors are normalized |

### Indexing for Performance:

SQL

```sql
-- IVFFlat index (faster search, approximate)
CREATE INDEX idx_docs_embedding ON documents
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- HNSW index (better recall, higher memory)
CREATE INDEX idx_docs_embedding_hnsw ON documents
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
```

### Index Comparison:

text

```text
┌──────────────┬────────────────────┬────────────────────┐
│              │     IVFFlat        │       HNSW         │
├──────────────┼────────────────────┼────────────────────┤
│ Build Speed  │ Faster             │ Slower             │
│ Query Speed  │ Fast               │ Faster             │
│ Recall       │ Good               │ Better             │
│ Memory       │ Lower              │ Higher             │
│ Best For     │ Large datasets     │ High-accuracy      │
│              │ with moderate      │ requirements       │
│              │ accuracy needs     │                    │
└──────────────┴────────────────────┴────────────────────┘
```

### Real-World Use Case — RAG (Retrieval-Augmented Generation):

text

```text
┌──────────┐    ┌───────────────┐    ┌──────────────────┐
│  User    │    │ Azure OpenAI  │    │ PostgreSQL +     │
│  Query   │───▶│ Embedding API │───▶│ pgvector         │
│          │    │ (vectorize    │    │ (similarity      │
│"How do I │    │  the query)   │    │  search)         │
│ deploy   │    └───────────────┘    └────────┬─────────┘
│ to AKS?" │                                  │
└──────────┘                           Top 5 relevant
                                       documents
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │ Azure OpenAI     │
                                    │ GPT-4            │
                                    │ (Generate answer │
                                    │  using retrieved │
                                    │  context)        │
                                    └──────────────────┘
                                              │
                                              ▼
                                    "To deploy to AKS,
                                     first create a
                                     cluster using..."
```

### Azure Service:

- Azure Database for PostgreSQL — Flexible Server supports pgvector natively
- Combined with Azure OpenAI for generating embeddings
- Ideal for RAG applications, semantic search, and recommendation engines

### Complete RAG Example:

Python

```python
import openai
import psycopg2

# 1. Generate embedding for user query
response = openai.Embedding.create(
    input="How to deploy containers on Azure?",
    model="text-embedding-ada-002"
)
query_embedding = response['data'][0]['embedding']

# 2. Search similar documents in PostgreSQL + pgvector
conn = psycopg2.connect("host=myserver.postgres.database.azure.com ...")
cur = conn.cursor()
cur.execute("""
    SELECT title, content, embedding <=> %s::vector AS distance
    FROM documents
    ORDER BY embedding <=> %s::vector
    LIMIT 5
""", (str(query_embedding), str(query_embedding)))

results = cur.fetchall()

# 3. Use retrieved context to generate answer with GPT-4
context = "\n".join([row[1] for row in results])
answer = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": f"Answer based on this context:\n{context}"},
        {"role": "user", "content": "How to deploy containers on Azure?"}
    ]
)
print(answer.choices[0].message.content)
```

### Quick Reference Summary

| # | Topic | Key Takeaway | Azure Service |
|---|--------|-------------|---------------|
| 1 | OLTP | Real-time transactions, ACID, normalized | Azure SQL DB, Cosmos DB |
| 2 | Low Latency DB | Indexing, caching, replicas, geo-distribution | Redis, SQL Read Replicas |
| 3 | Normalization | 1NF → 2NF → 3NF to eliminate redundancy | Azure SQL DB, PostgreSQL |
| 4 | OLAP | Complex analytics on historical data | Azure Synapse Analytics |
| 5 | Historical Data | ETL pipelines, star schema, medallion architecture | Data Factory + Synapse + Power BI |
| 6 | PGVector | Vector similarity search in PostgreSQL for AI/ML | Azure PostgreSQL Flexible Server |
