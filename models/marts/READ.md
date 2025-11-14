# Marketing Campaign Performance Data Transformation

This dbt (data build tool) project is the core transformation layer for unifying and modeling cross-platform digital advertising data. It runs on Snowflake and transforms raw data ingested from various marketing APIs (via tools like Fivetran/Stitch) into clean, business-ready fact and dimension tables.

## Goal

The primary objective is to create a **single source of truth** for analyzing the performance of all marketing campaigns across platforms (TikTok, Meta, Google, etc.) and linking it to web activity (GA4).

The output **`CORE_MART`** schema is designed for consumption by BI tools (Tableau, Looker, Power BI) and Machine Learning models.

## Project Structure and Layers

This project adheres to the recommended dbt layering convention:

| Folder | Schema Output | Description |
| :--- | :--- | :--- |
| `staging/` | `STAGING` | **Standardize.** Simple views/tables that clean, cast, rename, and filter raw source data (e.g., `stg_tiktok_ad_report_daily`). |
| `intermediate/`| `INTERMEDIATE` | **Transform & Link.** Complex logic for deriving shared business concepts, such as campaign name parsing, campaign keys, and base unioned fact models (e.g., `int_meta_campaigns`). |
| `marts/` | `CORE_MART` | **Final Consumption.** Business-ready fact and dimension tables, aggregated and joined for analytical queries. |

## Key Output Models (`CORE_MART` Schema)

These are the primary tables analysts and BI tools should query.

| Model Name | Type | Key Columns | Purpose |
| :--- | :--- | :--- | :--- |
| **`fact_campaign_performance_daily`** | Fact | `date_campaign_key`, `campaign_key` | The primary daily grain fact table. Unifies **Spend, Impressions, Clicks, Conversions** from all ad platforms, and joins **GA4 Pageviews/Leads** via the `camp_ref`. |
| **`dim_campaign`** | Dimension | `campaign_key` | Contains stable campaign metadata extracted from names: **Brand, Product, Business Unit, Phase**, and the **`camp_ref`** for linking to GA4. |
| **`dim_account`** | Dimension | `account_key` | A dimension for unique Advertiser Accounts across all platforms. |
| **`agg_campaign_monthly_ml`** | Mart | `year_month`, `campaign_key` | A monthly aggregate of the fact table, including pre-calculated **CTR, CPA**, and time-based features like **lagged spend** for ML modeling. |

## How to Run the Project

### Prerequisites

1.  **Snowflake Access:** You must have a user and role with access to the `DBT_TRANSFORM_WH` warehouse and the `MARKETING_ANALYTICS_DB` database.
2.  **dbt Installed:** Ensure dbt Core is installed (`pip install dbt-snowflake`).
3.  **Raw Data:** All source schemas (`RAW_TIKTOK_ADS`, `RAW_META_ADS`, etc.) must be populated with data.

### Configuration

Update your dbt connection details in the **`~/.dbt/profiles.yml`** file:

```yaml
marketing_analytics_profile:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: ZTDPLXB-NL18620
      role: ACCOUNTADMIN
      warehouse: DBT_TRANSFORM_WH
      database: MARKETING_ANALYTICS_DB
      schema: CORE_MART
      username: kennedymbono
      authenticator: https://<your_idp_url>.com

