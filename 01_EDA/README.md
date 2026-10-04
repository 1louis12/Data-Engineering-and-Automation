# Data Engineer Job Market Analysis (SQL + DuckDB)

Which skills should an aspiring data engineer learn first, and which ones pay the most?
This project answers those two questions by querying a real job postings dataset with SQL in DuckDB.

## 1. About the project

### Use case

Imagine you are switching into data engineering. You open a few job boards and see dozens of postings listing SQL, Python, AWS, Spark, Airflow, Terraform, Kubernetes... It is hard to know where to start.

Instead of guessing, this project looks at **real job postings** and measures:

- **Demand**: which skills appear most often in postings.
- **Salary**: which skills are linked to the highest median salary (remote data engineer roles).

The result is a data-backed learning path: start with what employers ask for most, then add the skills that raise your pay.

### Data source

The dataset is the property of **Luke Barousse** (data analyst and creator of the data job postings dataset). All credit for the data goes to him. It is shared through MotherDuck and attached directly in DuckDB:

```sql
ATTACH 'md:_share/data_jobs/87603155-cdc7-4c80-85ad-3a6b0d760d93';
```

Main tables used:

| Table | Description |
|---|---|
| `job_postings_fact` | One row per job posting (title, salary, remote flag, ...) |
| `skills_job_dim` | Link table between postings and skills |
| `skills_dim` | List of skills (SQL, Python, AWS, ...) |

### Tools

- DuckDB
- MotherDuck (shared dataset)
- SQL (joins, aggregation, `MEDIAN`, `HAVING`)

### SQL files

| # | File content | Question answered |
|---|---|---|
| 1 | Schema exploration (`information_schema`) | What does the database contain? |
| 2 | Most in-demand skills | Which skills are requested most for data engineers? |
| 3 | Highest-paying skills | Which skills have the highest median salary? |

---

## 2. Skills analysis

### 2.1 Most in-demand skills for data engineers

**Method:** join `job_postings_fact` -> `skills_job_dim` -> `skills_dim`, count postings per skill, keep the top 10. Filters for `Data Engineer` and remote jobs are available in the query and can be toggled on or off.

| Skill | Demand count |
|---|---:|
| sql | 29,221 |
| python | 28,776 |
| aws | 17,823 |
| azure | 14,143 |
| spark | 12,799 |
| airflow | 9,996 |
| snowflake | 8,639 |
| databricks | 8,183 |
| java | 7,267 |
| gcp | 6,446 |

**Key insights**

- **SQL and Python are the foundation.** They are nearly tied and each has about 60% more postings than the next skill (AWS).
- **Cloud is the second tier.** AWS (17,823) > Azure (14,143) > GCP (6,446). Three of the top 10 skills are cloud platforms.
- **Pipeline tools matter.** Spark (processing) and Airflow (orchestration) show employers want people who can build and schedule pipelines.
- **Modern data platforms are rising.** Snowflake and Databricks are within about 5% of each other.
- **Java is the only other language** in the top 10, likely tied to the JVM ecosystem (Spark, Kafka) and legacy stacks.

**Suggested learning order:** SQL -> Python -> one cloud (AWS) -> Spark -> Airflow -> Snowflake / Databricks

### 2.2 Highest-paying skills for remote data engineers

**Method:** median `salary_year_avg` per skill, remote `Data Engineer` postings only, skills with more than 100 postings (`HAVING COUNT(*) > 100`), top 25 by median salary.

| Skill | Median salary ($) | Demand count |
|---|---:|---:|
| rust | 210,000 | 232 |
| golang | 184,000 | 912 |
| terraform | 184,000 | 3,248 |
| spring | 175,500 | 364 |
| neo4j | 170,000 | 277 |
| gdpr | 169,616 | 582 |
| zoom | 168,438 | 127 |
| graphql | 167,500 | 445 |
| mongo | 162,250 | 265 |
| fastapi | 157,500 | 204 |
| django | 155,000 | 265 |
| bitbucket | 155,000 | 478 |
| crystal | 154,224 | 129 |
| atlassian | 151,500 | 249 |
| c | 151,500 | 444 |
| typescript | 151,000 | 388 |
| kubernetes | 150,500 | 4,202 |
| ruby | 150,000 | 736 |
| css | 150,000 | 262 |
| node | 150,000 | 179 |
| airflow | 150,000 | 9,996 |
| redis | 149,000 | 605 |
| vmware | 148,798 | 136 |
| ansible | 148,798 | 475 |
| jupyter | 147,500 | 400 |

**Key insights**

- **Cloud/infrastructure and data-engineering tools** such as Terraform, Kubernetes and Airflow combine substantial demand with competitive salaries.
- **Rust is the top payer ($210K)** but is niche (232 postings), so the median rests on a small sample.
- **Terraform is the strongest all-rounder:** a $184K median with 3,248 postings.
- **Software engineering skills are rewarded.** Rust, Golang, Spring, Django, FastAPI, TypeScript and Node all appear, showing a premium for data engineers who code like software engineers.
- **NoSQL, graph and API skills add value:** Neo4j, GraphQL, Mongo, Redis.
- **DevOps tooling pays well:** Terraform, Kubernetes, Ansible, VMware, Bitbucket.
- **Some entries are probably noise.** GDPR, Zoom and Crystal likely reflect the type of employer (compliance-heavy or enterprise) rather than a skill that directly raises pay.

### 2.3 Combined takeaways

| Goal | Skills |
|---|---|
| Get hired (most openings) | SQL, Python, AWS, Spark, Airflow |
| Earn more | Terraform, Kubernetes, Golang, Rust |
| Best balance of pay and demand | Terraform, Kubernetes, Airflow |

---

## Limitations

- `demand_count` counts postings that mention a skill. Skills overlap inside a posting, so counts cannot be added together.
- Median salary is computed only on postings that list a salary, so real sample sizes are smaller than `demand_count`.
- A skill's salary is not isolated from the rest of the stack it appears with.
- Results for the salary analysis cover remote roles only and may differ for on-site jobs.

## How to run

1. Install [DuckDB](https://duckdb.org/) and create a free [MotherDuck](https://motherduck.com/) account.
2. Attach the shared database:
   ```sql
   ATTACH 'md:_share/data_jobs/87603155-cdc7-4c80-85ad-3a6b0d760d93';
   ```
3. Run the SQL files in order: schema exploration, in-demand skills, highest-paying skills.
