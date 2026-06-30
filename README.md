# Olist E-Commerce Analytics Project

End-to-end analytics project using the Olist Brazilian e-commerce marketplace dataset.

This project covers data cleaning, SQL Server modelling, analytical view creation, and Power BI dashboarding for marketplace sales, delivery reliability, customer experience, product performance, seller performance, and payment reconciliation.

---

## Dashboard Preview

### Executive Overview

![Executive Overview](screenshots/01_executive_overview.png)

[View full Power BI PDF report](powerbi/Olist_Analytics_Dashboard.pdf)

---

## Project Objective

The objective of this project is to analyze marketplace performance across four major business areas:

- Executive sales and order performance
- Delivery reliability and customer satisfaction
- Product, category, freight, and payment reconciliation performance
- Seller performance, seller concentration, and freight burden

The project is designed as a portfolio-grade analytics case study showing how raw e-commerce data can be converted into business-ready reporting using Python, SQL Server, and Power BI.

---

## Business Questions Answered

- What are the overall GMV, order volume, customer count, and average order value?
- Which product categories generate the most marketplace value?
- How does late delivery affect review scores and low-review rates?
- Which customer states have the highest delivery risk?
- Which categories have high freight burden relative to GMV?
- Are payment records reconciled correctly with order item values?
- Which seller states and sellers contribute the most sales?
- Is marketplace sales concentrated among a small group of top sellers?

---

## Tools Used

- **Python** - data cleaning and preprocessing
- **pandas** - CSV transformation and validation
- **SQL Server** - staging layer, analytics layer, validation queries
- **T-SQL** - analytical views and grain-safe modelling
- **Power BI** - dashboard design, DAX measures, slicers, KPI cards, and visuals

---

## Data Pipeline

```text
Raw Olist CSV files
        |
        v
Python cleaning script
        |
        v
Cleaned CSV files
        |
        v
SQL Server staging tables
        |
        v
SQL Server analytics views
        |
        v
Power BI semantic model
        |
        v
Interactive dashboard pages
```

---

## Data Modelling Approach

A key modelling decision in this project was to keep different analytical grains separate.

| Area | Grain Used | Reason |
|---|---:|---|
| Order performance | One row per order | Prevents duplication of order-level KPIs |
| Delivery analysis | One row per order | Delivery metrics belong at order grain |
| Review analysis | One review per reviewed order | Avoids duplicated review scores |
| Product/category analysis | One row per order item | Correct grain for item sales and freight |
| Seller analysis | Order-item/seller grain | Correct grain for seller and category contribution |
| Payment reconciliation | One row per order | Prevents payment values from being duplicated through item joins |

This prevents common BI modelling errors such as inflating payment, delivery, or review metrics when joining order-level data to item-level tables.

---

## Dashboard Pages

## 1. Executive Overview

The executive page summarizes total marketplace performance using GMV, orders, customers, average order value, review score, and late delivery rate.

Key visuals include:

- Monthly GMV and order volume
- Monthly late delivery rate
- Monthly customer review score
- Top 10 categories by GMV
- Orders by customer state
- Order status breakdown
- Payment reconciliation status

Key headline metrics:

| Metric | Value |
|---|---:|
| GMV | $15.8M |
| Total Orders | 99K |
| Total Customers | 96K |
| Average Order Value | $159.3 |
| Average Review Score | 4.09 |
| Late Delivery Rate | 8.11% |

---

## 2. Delivery & Customer Experience

![Delivery & Customer Experience](screenshots/02_delivery_customer_experience.png)

This page analyzes logistics performance and its impact on customer satisfaction.

Key visuals include:

- Monthly late delivery rate
- Late delivered orders vs review score over time
- States with highest late delivery rate
- Orders by delivery delay bucket
- Review score by delivery delay bucket
- Low review rate by delivery delay bucket
- State-level delivery and review risk matrix

Key metrics:

| Metric | Value |
|---|---:|
| Total Orders | 99K |
| Delivered Orders | 96K |
| On-Time Delivery Rate | 91.89% |
| Late Delivery Rate | 8.11% |
| Average Late Delay | 10.62 days |
| Average Review Score | 4.09 |

Main insight: late deliveries are associated with weaker customer review outcomes, especially for longer delay buckets.

---

## 3. Product & Payment Performance

![Product & Payment Performance](screenshots/03_product_payment_performance.png)

This page separates item-level product/category performance from order-level payment reconciliation.

Key visuals include:

- Category sales and freight
- Category freight percentage of GMV
- Category scatter plot by item price and sales
- Category performance table
- Payment variance by reconciliation status
- Reconciliation status distribution

Key metrics:

| Metric | Value |
|---|---:|
| Total Item Sales | $13.6M |
| Total Item GMV | $15.8M |
| Order Items | 113K |
| Active Sellers | 3K |
| Payment Mismatch Rate | 0.26% |
| Payment Variance | $165.32K |

Main insight: most payment records reconcile correctly, but a small number of mismatches and missing records create measurable payment variance.

---

## 4. Seller Performance & Risk

![Seller Performance & Risk](screenshots/04_seller_performance_risk.png)

This page analyzes seller contribution, seller state performance, freight burden, and sales concentration.

Key visuals include:

- Top sellers by item sales
- Seller state performance
- Seller sales vs freight burden scatter
- Seller state performance table
- Seller sales Pareto chart

Key metrics:

| Metric | Value |
|---|---:|
| Total Item Sales | $13.6M |
| Seller Orders | 98.7K |
| Active Sellers | 3.1K |
| Average Seller Order Value | $137.8 |
| Freight % of GMV | 14.21% |
| Top 10 Seller Sales Share | 13.15% |

Main insight: seller performance is concentrated by geography and seller group, while freight burden varies materially across seller states.

---

## Key Findings

- The marketplace generated approximately **$15.8M GMV** across **99K orders**.
- Delivered orders represent the overwhelming majority of order status volume.
- The overall late delivery rate is **8.11%**, with some states showing meaningfully higher delivery risk.
- Longer delivery delays are associated with lower review scores and higher low-review rates.
- Category performance varies not only by sales volume but also by freight burden.
- Payment reconciliation is mostly clean, but mismatches and missing records still create measurable variance.
- Seller performance is uneven across seller states, with some sellers contributing disproportionately to total item sales.

---

## Repository Structure

```text
Olist-Analytics-Project/
|
├── data/
│   ├── raw/
│   └── cleaned/
|
├── scripts/
│   └── clean_olist.py
|
├── sql/
│   └── SQL scripts for staging, analytics views, and validation
|
├── powerbi/
│   └── Olist_Analytics_Dashboard.pdf
|
├── screenshots/
│   ├── 01_executive_overview.png
│   ├── 02_delivery_customer_experience.png
│   ├── 03_product_payment_performance.png
│   └── 04_seller_performance_risk.png
|
└── README.md
```

---

## Skills Demonstrated

- Data cleaning with Python and pandas
- SQL Server staging and analytics layer design
- Fact/dimension modelling
- Grain-aware BI modelling
- Power BI dashboard design
- DAX measure creation
- KPI reporting
- Payment reconciliation analysis
- Delivery and customer experience analysis
- Seller and category performance analysis
- Executive dashboard storytelling

---

## Business Value

This project demonstrates how an e-commerce marketplace can use analytics to monitor revenue, logistics performance, customer satisfaction, seller concentration, freight burden, and payment reconciliation quality.

The dashboard is designed for business stakeholders who need a high-level executive summary while still being able to drill into delivery, product, payment, and seller-level performance issues.

---

## Dataset

Dataset used: **Olist Brazilian E-Commerce Public Dataset**

The dataset contains marketplace orders, order items, customers, sellers, products, payments, and customer reviews.
