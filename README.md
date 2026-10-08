# From Data Analysis to DevOps / DataOps: My Learning Roadmap

I'm a student building a hands-on portfolio to become a **DevOps / DataOps engineer**.
This repository documents the journey level by level. Each level is a folder with its own code, README and a concrete deliverable.

The roadmap is not random: **it is driven by data.** In Level 1, I analyzed real job postings to find which skills employers ask for and which ones pay the most. The next levels follow those results.

## Why this path? (evidence from Level 1)

Data source: Luke Barousse's data job postings dataset, queried with SQL in DuckDB.

| Skill | Signal from my analysis |
|---|---|
| SQL, Python | Most requested skills overall (about 29K postings each) |
| AWS | Most requested cloud platform (17,823 postings) |
| Airflow | Standard orchestration tool (9,996 postings) |
| Terraform | $184,000 median salary (remote data engineers) with 3,248 postings |
| Kubernetes | $150,500 median salary with 4,202 postings |

Takeaway: **Terraform, Kubernetes and Airflow** combine high demand and competitive pay. They are the core of the DevOps/DataOps direction, so they are the main milestones below.

## Roadmap

| Level | Folder | Milestone | Status |
|:---:|---|---|:---:|
| 1 | [`01_EDA`](./01_EDA) | Exploratory data analysis with SQL and DuckDB | Done |
| 2 | [`02_BUILD_DW`](./02_BUILD_DW) | Build a Data Warehouse (Star Schema) and Data Marts with DuckDB | Done |
| 3 | `03_Docker` | Containerize the pipeline for reproducible runs | Planned |
| 4 | `04_CI_CD` | Automate tests and checks with GitHub Actions or Gitlab-ci | Planned |
| 5 | `05_Terraform` | Provision cloud infrastructure as code (AWS or local) | Planned |
| 6 | `06_Airflow` | Orchestrate and schedule the pipeline | Planned |
| 7 | `07_Data_Quality` | Add data tests and validation (dbt / Great Expectations) | Planned |
| 8 | `08_Kubernetes` | Deploy containers on a Kubernetes cluster | Planned |
| 9 | `09_Monitoring` | Logging, alerts and observability | Planned |
| 10 | `10_Capstone` | End-to-end project combining all levels | Planned |

## Level details

### Level 1: EDA (completed)

**Folder:** [`01_EDA`](./01_EDA)

Use case: a student wants to know which skills to learn for data engineering jobs.

- Explored the database schema with `information_schema`
- Ranked the most in-demand skills for data engineers
- Ranked the highest-paying skills (median salary, remote roles, demand > 100)

**Skills practiced:** SQL, joins, aggregation, `MEDIAN`, `HAVING`, DuckDB, MotherDuck, interpreting results.

### Level 2: Build Data Warehouse (completed)

**Folder:** [`02_BUILD_DW`](./02_BUILD_DW)

Use case: transition from raw data to a structured Data Warehouse to power reporting and analytics efficiently.

- Created a core Data Warehouse using a Star Schema (fact and dimension tables).
- Loaded data from CSVs and enforced referential integrity checks.
- Built specific business-focused Data Marts: a denormalized flat mart, a skills demand mart, an incrementally updated priority jobs mart, and a complex company prospecting mart.
- Orchestrated the entire build process into a single pipeline.

**Skills practiced:** Data Modeling (Star Schema), Dimensional Data Marts, Incremental updates (`MERGE`), Data Types (STRUCT, ARRAY), Idempotency, Pipeline orchestration via SQL.

### Level 3: Docker (planned)

Package the pipeline in a container so it runs the same on any machine. Goal: `docker run` reproduces the full pipeline.

### Level 4: CI/CD (planned)

Add GitHub Actions to run linting and tests on every push. Goal: no broken code reaches `main`.

### Level 5: Terraform (planned)

Describe cloud resources (storage, compute, permissions) as code on AWS. Goal: create and destroy the infrastructure with `terraform apply` and `terraform destroy`.

### Level 6: Airflow (planned)

Schedule and monitor the pipeline as a DAG with retries and dependencies. Goal: a daily automated run.

### Level 7: Data quality (planned)

Add tests on the data itself (nulls, duplicates, ranges) so bad data is caught early. Goal: pipeline fails loudly when data is wrong.

### Level 8: Kubernetes (planned)

Deploy the containerized pipeline on a cluster. Goal: run jobs on Kubernetes with a basic configuration.

### Level 9: Monitoring (planned)

Track pipeline health with logs, metrics and alerts. Goal: know when something breaks before users do.

### Level 10: Capstone (planned)

Combine everything into one project: infrastructure with Terraform, pipeline in Docker, orchestrated by Airflow, tested in CI/CD, monitored. Goal: a complete, documented DataOps project to showcase.

## Repository structure

```text
.
├── README.md              <- this roadmap
├── 01_EDA/                <- Level 1 (done)
│   ├── README.md
│   └── *.sql
├── 02_BUILD_DW/           <- Level 2 (done)
│   ├── README.md
│   └── *.sql
├── 03_Docker/             <- next
├── 04_CI_CD/
├── 05_Terraform/
├── 06_Airflow/
├── 07_Data_Quality/
├── 08_Kubernetes/
├── 09_Monitoring/
└── 10_Capstone/