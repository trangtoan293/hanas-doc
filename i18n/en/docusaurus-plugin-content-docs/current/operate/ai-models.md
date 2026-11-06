---
title: Configure AI models for Kapas
sidebar_label: AI models
sidebar_position: 8
description: Declare providers and models for Kapas, use OpenAI-compatible endpoints or on-prem models, the main environment variables, and recommendations.
---

This page shows administrators how to configure language models (LLMs) for Kapas, including cloud services and models that run in the internal network.

## Concepts

- **Provider**: where a model is served from (endpoint, API key).
- **Model**: a specific model of a provider.
- **Active model**: the model Kapas currently uses to answer.

Kapas supports several built-in providers (OpenAI and compatible APIs, Azure OpenAI, Anthropic, Gemini, DeepSeek, OpenRouter...) and a **custom OpenAI-compatible endpoint**. For a self-operated model, use vLLM, Ollama, LM Studio, or any server that speaks the OpenAI-compatible protocol.

When answering, Kapas chooses the model in this order: the model specified in the request, the agent's model, then the global default model.

## Requirements

- Kapas administrator permission to change the global default model.
- An LLM endpoint reachable from the Kapas Pod. The address `127.0.0.1` inside a Pod is the Pod itself, not your model server.
- An API key (if the provider requires one) stored in a Secret, not in values.

## Configure through the interface

1. Sign in to Kapas Console with an administrator account.
2. Open **Models**.
3. Choose a provider or add a custom **OpenAI-compatible** provider. Enter the base URL and the API key if any.
4. Use the discovery and test functions to get the model list and try the connection.
5. Set a model as the global **active model**, or choose a separate model for each agent.

Regular users can choose the model for their own agents; changing the global default requires admin permission.

## Initial configuration with environment variables

When there is no active model yet, Kapas initializes the default provider and model from environment variables. Values already saved in the interface are not overwritten on later starts.

```yaml
# example: an OpenAI-compatible endpoint in the internal network
env:
  QWENPAW_DEFAULT_PROVIDER: "<provider-id>"
  QWENPAW_DEFAULT_MODEL: "<model-name>"
  QWENPAW_DEFAULT_BASE_URL: "http://llm.internal.example:8000/v1"
  # put the API key in a Secret, do not write it into values
  QWENPAW_DEFAULT_API_KEY: "<from Secret>"
```

| Variable | Meaning |
|---|---|
| `QWENPAW_DEFAULT_PROVIDER` | Default provider. |
| `QWENPAW_DEFAULT_MODEL` | Default model name. |
| `QWENPAW_DEFAULT_BASE_URL` | Base URL of the endpoint (for OpenAI-compatible, usually ending in `/v1`). |
| `QWENPAW_DEFAULT_API_KEY` | API key, if the provider requires one. |
| `QWENPAW_DEFAULT_PROVIDER_NAME` | Display name of the custom provider. |
| `EMBEDDING_MODEL_NAME`, `EMBEDDING_BASE_URL`, `EMBEDDING_API_KEY` | Embedding endpoint for the memory and search features. |

This configuration lives in the Kapas Helm release; pass additional variables through the `extraEnv` Secret. See [Configuration reference](configuration.md).

## Related integration environment variables

| Group | Variables |
|---|---|
| Query engine | `DREMIO_URL`, `DREMIO_KEYCLOAK_AUDIENCE` |
| Ontology, dbt | `ONTOLOGY_API_URL`, `DBT_RUNNER_URL` |
| Superset | `SUPERSET_URL`, `SUPERSET_KEYCLOAK_AUDIENCE`, `SUPERSET_DATABASE_NAME` |
| Limits | `QWENPAW_USER_REQUESTS_PER_MINUTE`, `QWENPAW_GLOBAL_REQUESTS_PER_MINUTE`, `QWENPAW_DAILY_TOKEN_BUDGET`, `QWENPAW_TENANT_DAILY_TOKEN_BUDGET` |
| Tracing | `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_BASE_URL` (enabled when all three are set) |

Variable names are kept as is so you can look them up exactly. The default token budget in Helm is currently 5,000,000 per day; this is a configuration value, and you should adjust it to your needs.

## On-prem models

1. Run the model server in the internal network (for example vLLM, Ollama).
2. Make sure the Kapas Pod can resolve and connect to that server.
3. Add an OpenAI-compatible provider with the internal base URL.
4. Verify with the connection test function, then set it as the active model.

:::caution Current limitations

- Using a local model does not by itself guarantee there is no outbound traffic. To run entirely in the internal network, you must also configure embedding, tracing, and all integration URLs internally.
- Kapas has a configuration for routing between local and cloud models, but this feature is not officially supported in the main chat flow. Do not rely on automatic routing by data sensitivity.
- Hanas does not include a model server in the deployment package; you provide your own.

:::

## Recommendations

- Choose a model with reliable tool calling; data agents call many tools in sequence.
- For sensitive data, prefer an on-prem model or a provider approved by your legal team.
- Set the token budget and request limits to suit the number of users; these limits are soft, per-process limits.
- Record the model in use when you report figures, because the same question can produce different results across models.
- Test important business questions after every model change.

## Troubleshooting

| Symptom | Common cause | Fix |
|---|---|---|
| Connection test fails | The Pod cannot reach the base URL | Use an address the Pod can resolve, and check NetworkPolicy. |
| Model list is empty | The endpoint does not support listing models | Enter the model name manually. |
| Agent does not call tools | The model does not support tool calling | Switch to a model that does. |
| Changing an environment variable has no effect | An active model is already saved | Change it in **Models**; the variables are used only when there is no active model. |

## Next

- [Configuration reference](configuration.md)
- [Authentication and SSO with Keycloak](identity.md)
- [Safety in Kapas](../kapas/safety.md)
