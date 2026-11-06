---
title: Search and discover data assets
sidebar_label: Catalog
sidebar_position: 1
description: Search and filter data assets and read the dataset details page in Hanas Catalog.
---

This page shows you how to find a dataset in Hanas Catalog and read the information that comes with it: schema, description, owner, tags, terms, lineage, and quality check results. What is displayed depends on the metadata that has been [collected](metadata-ingestion.md) or declared.

## Requirements

:::note Requirements

Every signed-in user can view Hanas Catalog (viewer level). You only see the assets that the query engine, dbt, or Superset allow you to see. Permission to edit metadata requires the editor level. See [Data access control](access-control.md).

:::

## Search and filter

1. Open **Data Governance** in Hanas Console. The landing page is the metadata search.
2. Enter a keyword in the search box. Results include the names, descriptions, and metadata of assets.
3. Use the **Type**, **Platform**, **Environment**, **Owner**, **Tag**, and **Platform Instance** filters to narrow the results. Use **Sort by** to change the ordering.
4. Use the browse panel on the side to follow the platform and container structure.
5. Select a result to open the details page. If you are an editor, you can add tags or terms directly in the results table.

If you need to update descriptions for many assets, editors can import descriptions in bulk from a CSV file.

:::caution Current limitations

Search only returns assets that are already in Hanas Catalog. A table newly created in the query engine does not appear until a metadata ingestion run collects it.

:::

## Dataset details page

The details page groups a dataset's information into tabs. The tabs shown can differ depending on the asset type and the type of metadata the source brings in.

| Area | Content |
|---|---|
| Schema (Columns) | The list of columns, data types, descriptions, tags, and terms of each column. |
| Documentation | A text description and related documentation links. |
| Ownership, Tags, Terms | Owners, tags, and glossary terms attached at the dataset level. |
| Lineage | The upstream and downstream graph. See [Lineage](lineage.md). |
| Quality | Assertion results and run history, when the source brings in this metadata. |
| Properties | Dataset properties provided by the source. |

For a view, the page also has a view definition section. A dataset produced by a pipeline or job can have additional run history.

### Edit metadata

If you have editor permission, you can:

- Edit the description of the dataset and of each column.
- Apply or remove tags, terms, and owners. See [Glossary, tags, and ownership](glossary-and-tags.md).
- Add or remove documentation links.

Admins also have the action to delete an entity from the catalog. The system shows a preview of the deletion scope before you confirm.

### Assertions

Hanas Catalog shows assertions and run history when the metadata source brings them in, for example dbt test results. Catalog does not run quality checks itself. If the Quality tab is empty, the dataset's source has not provided this type of metadata.

## Troubleshooting

| Symptom | Common cause | Resolution |
|---|---|---|
| You do not see a dataset | You lack view permission on the query engine, or it has not been collected | Check permissions; ask an admin to run metadata ingestion |
| The edit button is hidden | You are at the viewer level | Ask an administrator to grant the editor role |
| Lineage or assertions are empty | The source does not bring in that metadata | See [Lineage](lineage.md) |

## Next steps

- [Metadata ingestion](metadata-ingestion.md)
- [Glossary, tags, and ownership](glossary-and-tags.md)
- [Lineage](lineage.md)
