---
title: Upload files
sidebar_label: Upload files
sidebar_position: 2
description: Upload CSV, JSON, Parquet, or Excel files to a workspace from the DATA tree in SQL Studio and choose a format before saving as a dataset.
---

This page shows you how to upload a local file to your workspace so you can query it with SQL right away. This approach suits small reference data or one-off files; for data that updates regularly, use [data sources](./data-sources.md) or [Ingestion](./ingestion.md).

## Steps

1. Open [SQL Studio](../query/sql-studio.md) and find **DATA** in the data tree.
2. Select your personal workspace (home) or a folder inside it, then select the **Upload** action.
3. Select the file with the browse button or drag and drop it into the dialog. Set a dataset name if needed.
4. In the next step, select the appropriate **Format** and adjust the options. The preview updates as you change settings.
5. If the preview reports an error (for example, a CSV with the wrong delimiter), change the options and review again.
6. Save. The file becomes a physical dataset in the selected folder; open it in SQL Studio or create a view.

## Supported formats

| Format | Main options |
|---|---|
| Delimited text (CSV, TSV) | Column delimiter (comma, tab, pipe), quote character, escape character, line delimiter, comment character, extract the first line as header, skip the first line, trim header whitespace |
| JSON | No options |
| Parquet | Parquet-specific options in the dialog |
| Excel, XLS | Sheet name, extract the first line as header, expand merged cells |

The dialog also lists Iceberg and Delta Lake table formats. These apply to folder-based data; for a single file, choose one of the formats above.

## Limitations

:::caution Current limitations

The interface does not set an explicit size limit; the practical limit depends on the query engine configuration and the environment's gateway (request size, temporary storage area). For large files, put the file in object storage and add it as a [data source](./data-sources.md). Uploaded files reside in your workspace and follow that workspace's permissions.

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Preview shows a parse error | Check the delimiter, quote character, and header row. |
| Columns are merged into one | Select the column delimiter again. |
| Upload fails for a large file | Use object storage and add it as a source. |

## Next steps

- [SQL Studio](../query/sql-studio.md)
- [Workspaces, folders, and views](../query/spaces-and-views.md)
- [Query data sources in place](./data-sources.md)
