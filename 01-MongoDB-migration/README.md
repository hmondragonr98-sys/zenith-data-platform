# Project: MongoDB to Azure Data Pipeline Modernization

## 1. The Challenge (Pain Points)
*   **Operational Bottlenecks:** The analytics team was heavily dependent on manual JSON exports from MongoDB, causing significant delays in data availability.
*   **Data Integrity Issues:** A high rate of corrupted or incomplete files during the export process led to constant, inefficient cycles of re-requesting information.
*   **Business Latency:** The update time for executive dashboards exceeded 24 hours, hindering agile decision-making and negatively impacting the end-user experience.

## 2. The Solution
Migration of the database to an **Azure Cloud-Native** ecosystem, transforming a manual, error-prone workflow into an automated and secure Data Pipeline.

*   **Orchestrated Ingestion:** Leveraged **Azure Data Factory** to automate data extraction, eliminating manual intervention from the database team.
*   **Medallion Architecture:** Raw JSON data is landed in **Azure Data Lake Storage (ADLS) Gen2** and processed through **Azure Databricks**, transitioning data through Bronze, Silver, and Gold quality tiers.
*   **Enterprise Security:** Implemented **VNETs, Private Endpoints, and RBAC via Microsoft Entra ID**, ensuring sensitive data remains protected within a secure, private network perimeter.
*   **Business Intelligence:** Established native connectivity between **Power BI** and the Gold layer in ADLS, reducing dashboard update times from **+24 hours to under 2 hours**.

## 3. Business Impact (Key Metrics)
*   **Reduced Time-to-Insight (TTI):** Achieved a **90% improvement** in the speed of executive report updates.
*   **Reliability:** Eliminated human errors in file transfers through full automation of the loading process.
*   **Increased Productivity:** The analytics team shifted focus from manual data preparation and validation to high-value data analysis and insights generation.