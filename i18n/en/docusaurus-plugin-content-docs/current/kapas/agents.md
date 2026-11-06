---
title: Agents, skills, and tools
sidebar_label: Agents, skills, and tools
sidebar_position: 2
description: The Kapas system agents in Hanas, the tools each agent can use, and how skills support agents.
---

Kapas organizes work around **agents**. Each agent has its own instructions, a set of enabled tools and, where needed, attached skills. This page lists the system agents that serve the data platform and their main tool groups.

## Concepts

| Concept | Meaning |
|---|---|
| Agent | An assistant specialized in one task, created from a template. |
| Tool | An action an agent can call, such as reading a schema, running a query, or creating a chart. |
| Skill | A package of domain guidance that an agent loads when needed (for example, how to choose a chart). |
| System agent | An agent provided by Hanas out of the box and visible to all users. |

You can see and use only the tools enabled in an agent's template. One agent does not automatically have all the permissions of another.

## Nine system agents

| Agent | Used for | Channel |
|---|---|---|
| Hanas Analyst | Data Q&A, running metrics, read-only queries, citing figures | Console |
| Analytics Studio Copilot | Create datasets, charts, and dashboards on Superset | Console, embedded |
| Dashboard Copilot | Edit dashboards through a YAML spec, validate, then create a draft dashboard | Console, embedded |
| SQL Copilot | Write, fix, explain, and check SQL in SQL Studio | Console, embedded |
| Catalog Steward | Find assets, lineage, and freshness; check and update metadata in Hanas Catalog | Console, embedded |
| Ontology Assistant | Browse Ontology objects, relationships, and metrics | Console, embedded |
| Project Copilot | Support dbt projects: models, lineage, dbt commands, board-style reports | Console, embedded |
| Concept Copilot | Propose concepts and relationships in an Ontology draft | Console, embedded |
| Mapping Copilot | Propose and check mappings, and handle server-managed blockers | Console, embedded |

:::note Requirements

An agent works only when its target service is enabled: Superset for the two dashboard agents, Hanas Catalog for Catalog Steward, dbt Studio for Project Copilot, and Ontology for the three Ontology agents.

:::

Points to know:

- Hanas Analyst does not create dashboards. Requests to build a dashboard are handed to Analytics Studio Copilot.
- Dashboard Copilot creates only **unpublished** (draft) dashboards. When you import an existing dashboard, Kapas works on a copy and does not modify the original.
- Concept Copilot and Mapping Copilot write proposals into an Ontology draft. These two agents have no tool to publish an Ontology; publishing is still done by an administrator, see [Ontology governance](../ontology/governance.md).
- Project Copilot is embedded per dbt project.

## Main tool groups

### Query engine

| Tool | Function |
|---|---|
| Browse catalog, find table paths | Lists sources, spaces, and folders; finds the full path instead of guessing names. |
| Read schema | Gets column names and types. |
| Check SQL | Uses `EXPLAIN` to validate without returning data. |
| Safe query (single or batch) | Runs read-only `SELECT`/`WITH`. See [Safety](safety.md). |
| Read Reflection, user, and role information | Reads metadata only; still follows your permissions. |
| Save accepted queries | Hanas Analyst saves the question and SQL pair you confirm for later reference. |

### Ontology and metrics

| Tool | Function |
|---|---|
| Object type catalog | View the list, then property, link, and metric details. |
| Query, search, aggregate | Filter, sort, search by substring, group, and compute count/sum/avg/min/max. |
| Get object, follow link | Read one object by primary key and follow declared relationships. |
| Find and run metrics | Build SQL from a metric definition (simple, ratio, derived), then run a read-only query. |
| Concept and Mapping tools | Read run context, write proposals, check, and handle blockers. |

### BI, catalog, and dbt

| Group | Function |
|---|---|
| Superset | Find existing objects, read dataset context, create or edit datasets, charts, dashboards, and layouts; use dashboard templates. |
| Dashboard spec | Open, read, edit, write, and undo the spec; validate and apply it as a draft dashboard, with a screenshot for the agent to self-review when available. |
| Hanas Catalog | Find assets, view lineage, check metadata completeness and freshness; edit descriptions, tags, and owners; create glossary terms. |
| dbt | Read and write project files, view models and lineage, run dbt commands, run read-only warehouse queries, and build and render boards. |

Write tools (creating charts, editing metadata, writing dbt files) change real systems. Review the agent's proposal before you confirm; see [Safety](safety.md) for the limits of the approval mechanism.

## Skills

Skills attached to an agent provide domain guidance, such as how to choose a chart type by purpose and data shape, the 12-column layout, and how to answer questions about project data. Administrators view and enable skills for each agent in Kapas Console. A skill existing in the system does not mean every agent is using it.

## Optional agents

In addition to the nine system agents, Kapas can be configured with a documentation Q&A agent (using Knowledge Platform, limited to the knowledge bases you are allowed to access, and selectable with `@`). This agent works only when Knowledge Platform is connected.

## Limitations

:::caution Current limitations

- Embedded agents (Catalog Steward, Project Copilot, and others) are useful only when the host application attaches them to its UI. In Kapas Console, you can still chat directly with each agent.
- No Hanas MCP server is enabled out of the box. Integration with data services uses built-in tools.

:::

## Next

- [Data Q&A](chat-with-data.md)
- [Reports, citations, and schedules](reports-and-schedules.md)
- [Embed Kapas in an application](../develop/kapas-embed.md)
