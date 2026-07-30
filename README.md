# Winning the Oil Lottery
### Replication Project for *Applied Econometrics Using GIS Techniques* (Summer Semester 2026)

## Overview

This repository contains the materials for my replication project completed as part of the course **Applied Econometrics Using GIS Techniques** (Summer Semester 2026).

The objective is to replicate the empirical analysis presented in:

> Cavalcanti, T., Da Mata, D., & Toscani, F. (2019). *Winning the Oil Lottery: The Impact of Natural Resource Extraction on Growth*. Journal of Economic Growth, 24(1), 79–115.

The paper investigates the causal effect of oil discoveries on long-run municipal economic growth in Brazil using a quasi-experimental research design.

---

## Project Objectives

- Replicate the main empirical results of the paper
- Reconstruct the data processing pipeline in R
- Reproduce the econometric analysis
- Perform GIS-based spatial analysis and visualization
- Produce a reproducible research workflow

---

## Repository Structure

```
winning-the-oil-lottery/
│
├── code/              # Analysis scripts
├── src/               # Project configuration and reusable functions
├── data/
│   ├── raw/
│   ├── external/
│   ├── processed/
│   └── gis/
│
├── output/
│   ├── figures/
│   ├── maps/
│   ├── tables/
│   └── models/
│
├── docs/              # Paper, slides, and project notes
├── resources/         # Papers, documentation, and references
│
├── README.md
└── .gitignore
```

---

## Software

The project is developed using:

- R
- Quarto

Main R packages include:

- tidyverse
- sf
- terra
- fixest
- data.table
- here
- modelsummary

---

## Reproducibility

The project follows a reproducible workflow.

- Original datasets are stored in `data/raw/`
- Cleaned datasets are stored in `data/processed/`
- All tables, figures, and maps are generated from the analysis scripts in `code/`

---

## Author

**MD Redwan Hossin**

M.Sc. Applied Economics and Data Science

Carl von Ossietzky University of Oldenburg

Summer Semester 2026