# Azure → Snowflake → dbt: Incremental Medallion Data Pipeline

An end-to-end data engineering project that incrementally extracts data from Azure SQL Database, lands it in Azure Data Lake Storage (ADLS), loads it into Snowflake, and transforms it with dbt through **Bronze → Silver → Gold** layers.

---

## Architecture

```
Azure SQL DB ──► Azure Data Factory ──► ADLS (dated folders) ──► Snowflake External Stage
 (SalesLT +        (incremental copy,      landings/yyyyMMdd/        │
  METADATA)         metadata-driven)                                 ▼
                                                           BRONZE (raw, COPY INTO)
                                                                     │  dbt silver job
                                                                     ▼
                                                           SILVER (typed, cleansed, merged)
                                                                     │  dbt gold job
                                                                     ▼
                                                           GOLD (business aggregates)
```

## Tech Stack

| Layer | Technology |
|---|---|
| Source | Azure SQL Database (AdventureWorksLT, `SalesLT` schema) |
| Ingestion | Azure Data Factory |
| Landing zone | Azure Data Lake Storage (`landings` container) |
| Warehouse | Snowflake |
| Transformation | dbt (with `dbt_utils`) |
| Orchestration | dbt jobs (silver job → gold job) |

---

## 1. Source: Azure SQL Database

Database `dbt-source` contains:

- **`SalesLT`**: Address, Customer, CustomerAddress, Product, ProductCategory, ProductDescription, ProductModel, ProductModelProductDescription, SalesOrderDetail, SalesOrderHeader
- **`METADATA.DBT_LOAD_PARAMETERS`**: control table with `PARAMETER_NAME` and `PARAMETER_VALUE`, used to store the last successful load date. It is populated and updated by the pipeline.

## 2. Ingestion: Azure Data Factory

The pipeline is metadata-driven and incremental:

1. **Lookup (`GETLATESTDATE`)**: reads the last-run date from the metadata table.
2. **Set variable**: stores that date.
3. **Lookup (`fetch list of tables`)**: returns the list of tables to extract.
4. **ForEach → Copy data**: for each table, copies rows changed since the last date and writes a CSV into a folder named after the load date.
5. **Script (`update meta table`)**: updates the metadata table with the new date so the next run continues from there.

## 3. Landing Zone: ADLS

- Storage account: `sadbtlanding`, container: `landings`
- One folder per run, named `yyyyMMdd` (e.g. `20261014`)
- Each folder contains one CSV per source table (10 files)

## 4. Snowflake Setup

| Object | Name | Purpose |
|---|---|---|
| Database | `DBT_PROJECT_DEV` | Holds all layers |
| Schemas | `BRONZE`, `SILVER`, `GOLD` | Medallion layers |
| Storage integration | `SF_INT_ADLS_dbt` | Secure connection from Snowflake to ADLS |
| File format | `dbt_csv_format_1` | CSV, comma delimited, skip header, optional `"` enclosure |
| External stage | `STG_dbt_ADLS` | Points at `azure://sadbtlanding.blob.core.windows.net/landings/` |

### Bronze

Transient tables that mirror the source structure. Loaded by the stored procedure:

```sql
CALL DBT_PROJECT_DEV.BRONZE.LOAD_CSV_ADLS_BRONZE('<SourceFile>', '<TARGET_TABLE>', '<yyyyMMdd>');
```

The procedure truncates the target bronze table and runs `COPY INTO` from `@STG_DBT_ADLS/<load_date>/<SourceFile>.csv` with `ON_ERROR = ABORT_STATEMENT`.

### Silver

Typed tables (`SILVERADDRESS`, `SILVERCUSTOMER`, `SILVERCUSTOMERADDRESS`, `SILVERPRODUCT`, `SILVERPRODUCTCATEGORY`, `SILVERPRODUCTDESCRIPTION`, `SILVERPRODUCTMODEL`, `SILVERPRODUCTMODELPRODUCTDESCRIPTION`, `SILVERSALESORDERDETAIL`, `SILVERSALESORDERHEADER`), each with an `ETL_MODIFIEDDATE` audit column.

---

## 5. dbt Project

Project name: `my_new_project`

```
├── macros/
│   ├── generate_schema_name.sql   # uses the custom schema name exactly (SILVER / GOLD)
│   ├── get_cleanse_fields.sql     # builds a cleansed column list from information_schema
│   └── refresh_bronze_data.sql    # calls the Snowflake procedure to load bronze
├── models/
│   ├── silvertables/              # 10 incremental merge models, one per source table
│   └── capstonegold/              # gold tables (materialized as table, schema GOLD)
├── dbt_project.yml
└── packages.yml
```

### Macros

- **`generate_schema_name`**: overrides dbt's default so models build in exactly the schema configured (`SILVER`, `GOLD`) instead of `<target>_<schema>`.
- **`get_cleanse_fields(schema_name, table_name)`**: reads the table's columns from `information_schema.columns` and generates the select list: numbers cast to int with default `-1`, timestamps cast with a default of the current timestamp, text defaulted to `'NA'`.
- **`refresh_bronze_data(srctbl, tgttbl)`**: computes today's date (IST, `yyyyMMdd`) and calls `LOAD_CSV_ADLS_BRONZE` to load that day's file into bronze.

### Silver models

All 10 models share one structure and differ only in table names:

```sql
{{
    config(materialized = 'incremental',
           incremental_strategy = 'merge',
           pre_hook = " {{refresh_bronze_data('Address','ADDRESS')}} "
    )
}}

select {{ get_cleanse_fields('BRONZE','ADDRESS') }},
       current_timestamp() as ETL_MODIFIEDDATE
from {{ source('bronze','ADDRESS') }}
```

Flow per model: the **pre-hook loads fresh data into bronze** → the model **cleanses and retypes** it → the result is **merged into silver**.

### Gold models

Business-level tables that read from silver using `ref()`, materialized as tables in the `GOLD` schema. Example: total sales amount by country.

```sql
{{ config(materialized='table') }}

select b.countryregion, sum(a.totaldue) totalamt
from {{ ref("SILVERSALESORDERHEADER") }} as a
join {{ ref("silveraddress") }} as b
  on b.addressid = case when a.shiptoaddressid = 1092 then 9 else b.addressid end
group by b.countryregion
```

---

## 6. Orchestration

Two dbt jobs run in sequence:

1. **Silver job**: runs all models in `models/silvertables` (each pre-hook loads its bronze table first).
2. **Gold job**: triggered when the silver job completes; builds all gold tables from silver.

---

## 7. End-to-End Run Order

1. ADF pipeline runs → new dated folder with CSVs lands in ADLS → metadata table date is updated.
2. dbt silver job runs → bronze is refreshed from the matching dated folder → silver tables are merged.
3. dbt gold job runs → gold aggregates are rebuilt from silver.

---

## Setup Notes

1. Create the Snowflake database, schemas, storage integration, file format and stage (see the Snowflake setup scripts).
2. Run `DESC STORAGE INTEGRATION SF_INT_ADLS_dbt;` and grant the Snowflake service principal access (e.g. *Storage Blob Data Reader*) on the ADLS storage account.
3. Create the bronze and silver tables and the `LOAD_CSV_ADLS_BRONZE` procedure.
4. Install dbt packages: `dbt deps`
5. Run the silver models, then gold:

```bash
dbt run --select silvertables
dbt run --select capstonegold
```

## Things to Keep in Mind

- `refresh_bronze_data` derives the folder name from today's date, so the ADF run and the dbt run must fall on the same day for the dated folder to exist.
- Bronze is truncated on each load, so it only holds the latest incremental batch; history is kept in silver.
- Blob paths are case-sensitive: pass file names exactly as they appear in ADLS (e.g. `SalesOrderHeader`).
- For the silver `merge` strategy, set a `unique_key` on each model to avoid duplicate rows on reruns.
