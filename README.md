# Customer Segmentation Analysis — Retail / E-commerce

> An RFM-based customer segmentation project analysing 3 years of retail transaction data to identify distinct customer groups and develop targeted retention strategies that reduce churn and grow revenue.

---

## Project Overview

Not all customers are equal. Some buy frequently and spend big; others made one purchase years ago and never returned. This project uses **RFM analysis** (Recency, Frequency, Monetary) to segment 200 customers across 500 transactions into four actionable groups — enabling the business to focus retention spend where it matters most.

**Key questions answered:**
- Which customers are most valuable and likely to stay?
- Who is at risk of churning and needs immediate attention?
- Which customers have already been lost — and is it worth trying to win them back?
- What retention strategy should be applied to each segment?

---

## Tools Used

| Tool | Purpose |
|------|---------|
| **Excel** | Data storage, RFM scoring, segment tagging, summary tables |
| **SQL (MySQL)** | Data cleaning, RFM calculations, segmentation logic, retention analysis |

---

## Dataset Description

**File:** `Customer_Segmentation_Dataset.xlsx`

| Sheet | Description |
|-------|-------------|
| `Customer_Transactions` | 500 transactions across 200 customers (Jan 2022 – Dec 2024) |
| `Customer_Segments` | RFM-scored customer list with segment labels colour-coded |
| `Segment_Summary` | Aggregated performance and recommended action per segment |

**Key columns:**

- `Customer_ID` — unique customer identifier
- `Transaction_Date` — date of purchase
- `Product_Category` — Electronics, Clothing, Beauty, Home & Kitchen, Sports
- `Total_Amount_USD` — transaction value
- `Return_Flag` — whether the item was returned
- `Segment` — Champions / Loyal Customers / At Risk / Lost Customers

---

## RFM Methodology

RFM scoring ranks each customer on three dimensions:

| Dimension | Definition | Scoring |
|-----------|-----------|---------|
| **Recency** | Days since last purchase | Lower = better |
| **Frequency** | Total number of orders | Higher = better |
| **Monetary** | Total lifetime spend | Higher = better |

Each customer receives a score of 1–4 per dimension using quartile ranking (NTILE). Combined scores determine their segment.

---

## The Four Segments

| Segment | Description | % of Base | Strategy |
|---------|-------------|-----------|---------|
| **Champions** | High frequency, high spend, recent buyers | ~20% | VIP loyalty programme, early access |
| **Loyal Customers** | Regular buyers with solid spend | ~28% | Upsell, cross-sell, referral bonuses |
| **At Risk** | Previously active but going quiet | ~30% | Win-back emails, personalised discounts |
| **Lost Customers** | No purchase in 365+ days | ~22% | Strong comeback offer or sunset |

---

## SQL Analysis Structure

**File:** `customer_segmentation_analysis.sql`

```
Section 0 — Database & table setup
Section 1 — Data exploration & quality checks
Section 2 — Revenue & purchase behaviour
Section 3 — RFM scoring (Recency, Frequency, Monetary)
Section 4 — Customer segmentation logic & overview
Section 5 — Churn & retention analysis
Section 6 — Product & category insights by segment
Section 7 — Retention strategy recommendations
```

---

## Key Findings

- **Champions (≈20% of customers) generated over 45% of total revenue** — protecting this group is the top priority.
- The **At Risk segment** contains customers with high historical spend who have gone quiet in the last 6–12 months — a targeted 15% discount campaign is recommended.
- **Electronics and Clothing** were the top revenue categories among Champions, suggesting premium product bundles as an upsell opportunity.
- **Repeat purchase rate** was highest in Nairobi (62%) and lowest in Eldoret (41%), indicating geographic differences in customer loyalty.
- Over **30% of lost customers** had made 3+ purchases before dropping off — worth targeting with a reactivation campaign.

---

## Project Structure

```
customer-segmentation-analysis/
│
├── Customer_Segmentation_Dataset.xlsx   # Dataset with 3 analysis sheets
├── customer_segmentation_analysis.sql   # Full SQL analysis (7 sections)
└── README.md                            # This file
```

---

## How to Reproduce

1. Clone this repository
2. Open `Customer_Segmentation_Dataset.xlsx` to explore the raw data
3. Import the `Customer_Transactions` sheet into a MySQL database
4. Run `customer_segmentation_analysis.sql` section by section
5. Use `vw_customer_segments` view to connect to a reporting tool

---

## Author

**Ruth Kasina**
Data Analyst | ALX Africa Programme
[LinkedIn](https://linkedin.com/in/ruthkasina) | [GitHub](https://github.com/Ruth-Kasina)

---

*This project was completed as part of the ALX Data Analytics programme.*
