# Databricks Data Engineering

A data engineering project developed during a Databricks immersion, following the **Medallion Architecture** to process and transform data through Bronze, Silver, and Gold layers.

<details>
<summary>🇧🇷 Português</summary>

## Sobre o projeto

Este é um projeto de engenharia de dados desenvolvido durante uma imersão em **Databricks**, utilizando a **Arquitetura Medalhão (Medallion Architecture)** para organizar o processamento e a transformação dos dados em diferentes camadas.

## Arquitetura

O projeto segue as seguintes camadas:

* **Bronze** — dados brutos, carregados a partir dos arquivos de origem.
* **Silver** — dados tratados, limpos e transformados.
* **Gold** — dados agregados e preparados para análise e consumo.

## Tecnologias

* Databricks
* Apache Spark
* Python
* SQL
* Unity Catalog
* Git & GitHub

## Estrutura

```text
├── notebooks/
│   ├── bronze/
│   ├── silver/
│   └── gold/
├── pipelines/silver-qualidade
│   ├── transformations/
└── README.md
```

## Objetivo

Praticar conceitos de engenharia de dados utilizando o ecossistema Databricks, incluindo ingestão, transformação, organização e análise de dados.

</details>

<details>
<summary>🇺🇸 English</summary>

## About the Project

This is a data engineering project developed during a **Databricks immersion**, using the **Medallion Architecture** to organize data processing and transformation across different layers.

## Architecture

The project follows these layers:

* **Bronze** — raw data loaded from source files.
* **Silver** — cleaned, processed, and transformed data.
* **Gold** — aggregated data prepared for analysis and consumption.

## Technologies

* Databricks
* Apache Spark
* Python
* SQL
* Unity Catalog
* Git & GitHub

## Structure

```text
├── notebooks/
│   ├── bronze/
│   ├── silver/
│   └── gold/
├── pipelines/silver-qualidade
│   ├── transformations/
└── README.md
```

## Purpose

To practice data engineering concepts using the Databricks ecosystem, including data ingestion, transformation, organization, and analysis.

</details>
