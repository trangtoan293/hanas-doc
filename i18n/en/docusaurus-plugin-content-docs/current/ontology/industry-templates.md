---
title: Banking industry ontology templates
sidebar_label: Banking templates
sidebar_position: 8
description: Use the banking ontology templates and the template library to initialize a business model, then add mappings for your data.
---

Industry ontology templates let you start from a ready-made business model instead of creating each concept from scratch. This page introduces the banking templates and how to use the template library in Hanas Data Platform.

## Available templates

| Template | Scope | Data mapping |
|---|---|---|
| `BankingVN` | Retail and operations banking model, 99 entity types and 165 value types. | Includes reference mappings for 11 datamart datasets. |
| `BankingT24` | Models the parameters and objects of a core banking system, 73 entity types and 87 value types. | No mappings; you must map them yourself. |

The counts above come from the current template files and may change with the template version.

:::note Requirements

A template provides only the canonical model. Records appear only when you map concepts to your own datasets, validate, and release. Having a concept in a template does not mean the corresponding data or KPI is available.

:::

## Main object groups

The `BankingVN` template organizes objects by business domain.

| Group | Example objects |
|---|---|
| Customers and counterparties | `Customer`, `IndividualCustomer`, `CorporateCustomer`, `CustomerGroup`, `PartyRelationship` |
| Organization | `Branch`, `Employee`, `Company`, `BusinessDate` |
| Deposits and lending | `DepositAccount`, `DepositProduct`, `LoanAccount`, `LoanProduct`, `RepaymentSchedule` |
| Credit and collateral | `CreditFacility`, `CollateralAsset`, `Guarantee`, `NonPerformingLoan` |
| Payments and cards | `Transaction`, `Payment`, `Card`, `CardTransaction`, `StandingOrder` |
| Foreign exchange and money market | `FxDeal`, `MoneyMarketDeal`, `FxPosition`, `RepoTransaction` |
| Accounting and reporting | `GlAccount`, `GlBalance`, `ProfitAndLoss`, `FinancialSummary` |
| Risk and compliance | `AssetClassification`, `LoanLossProvision`, `RiskWeightedAsset`, `RegulatoryRatio` |
| Daily aggregates | `CustomerDailySummary`, `BranchDailySummary`, `LoanDailySummary` |

Subtypes such as individual customers or non-performing loans have meaning in the model; compile and validate the mapping to confirm the specific runtime.

The `BankingT24` template focuses on customers, product architecture (product line, group, property, condition), accounts, lending, overdrafts, trade finance, collateral, limits, and accounting.

:::caution Current limitations

Banking regulation content in the templates is a reference model. Hanas does not confirm that it is current or legally compliant; check it against your organization's requirements.

:::

## Use the template library

The template library stores templates and versions for multiple workspaces to share. Admins manage the library.

1. Import a seed template that ships with your deployment into the library, or upload your own template.
2. Check the content with **validate preview**, then save it as a version.
3. Mark the version as verified before letting teams use it. A version can be marked as not recommended (deprecate) or restored.
4. In a workspace, create a draft from the selected template and version.
5. Complete the [mapping](mapping.md), validate, then release following the [governance process](governance.md).

The library records which workspace is using which version, helping you assess impact before changing or deleting a version. A template version is a different resource from the serving deployment.

## Adoption tips

- Select only the concepts that need a runtime; keep the rest as vocabulary.
- Start with customers, accounts, and products, then expand gradually.
- Use automap to create the first mapping, then check keys and joins manually.
- Keep the concepts' API names unchanged so that later template updates are easier to reconcile.

## Next steps

- [Data mapping](mapping.md) for your datasets.
- [Ontology Workspace](workspace.md) for the authoring process.
- [Ontology governance](governance.md) for import, export, and release.
