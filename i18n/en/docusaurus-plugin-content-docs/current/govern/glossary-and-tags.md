---
title: Glossary, tags, and ownership
sidebar_label: Glossary, tags, and ownership
sidebar_position: 3
description: Build a glossary, manage tags, and assign owners for data assets in Hanas Catalog.
---

Glossary, tags, and ownership help everyone share one language about data and know who is responsible. This page is for data stewards and data owners.

## Concepts

| Component | Purpose |
|---|---|
| Term | A business term with a definition, for example "Individual customer". |
| Term group | A folder to organize terms in a hierarchy. |
| Related terms | Relationships between terms, helping readers move from one concept to a related one. |
| Tag | A lightweight label for classification, for example sensitivity level or data domain. Each tag has a color. |
| Owner | The person or team responsible for the asset. |

A term describes business meaning; a tag is for filtering and quick classification. If the same concept needs both a definition and filtering, use a term and keep tags for technical classification.

## Requirements

:::note Requirements

The viewer level is read-only. Applying and removing tags, terms, and owners, editing descriptions, creating and editing tag definitions, and managing the glossary require the editor level. See [Data access control](access-control.md).

:::

## Build a glossary

1. Open **Data Governance** and choose **Glossary**.
2. Create a term group for a business domain, for example "Customer" or "Account".
3. In the group, create a term and enter its name and definition.
4. Use the **Related terms** action to link related terms.
5. Add documentation or explanatory links if needed.
6. Apply the term to the relevant data assets.

You can rename terms, move them between groups, or delete them.

## Manage tags

1. Open **Data Governance** and choose **Tags**.
2. Create a new tag: enter a name and description, choose a color, and choose the tag owner.
3. Edit or delete tags when needed.

:::caution Note when deleting a tag

Deleting a tag definition removes the tag from every asset it is applied to, including assets you do not have permission to view. Check the scope before you delete.

:::

## Apply to assets

You can apply tags, terms, and owners in several places:

- The dataset details page: for the dataset and for each column.
- The search results list: quickly apply a tag or term.
- The term or tag details page: add many assets at once.

After applying them, you can filter search results by tag, term, or owner. See [Catalog](catalog.md).

## Organization example

A retail banking data team might use:

| Type | Value |
|---|---|
| Term group | Customer, Account, Transaction |
| Term | Individual customer, Available balance |
| Tag | `pii`, `gold`, `deprecated` |
| Owner | Customer data team |

## Limitations

- Custom properties added from the UI are not confirmed to be saved to the server; do not use them to store important information.
- The Domains screen is no longer a separate page and has been moved to search.

## Next steps

- [Search and discover data assets](catalog.md)
- [Lineage](lineage.md)
- [Data access control](access-control.md)
