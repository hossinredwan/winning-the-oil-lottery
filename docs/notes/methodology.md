---
title: "Methodology - Econometric Model"
project: "Replication of Winning the Oil Lottery"
---

# 4. Methodology

## 4.1 Econometric Model(i)

The objective of this study is to estimate the **causal impact of oil discovery on municipal economic development in Brazil**. Simply comparing municipalities with oil production to municipalities without oil production would produce biased estimates because these municipalities may differ in many observable and unobservable characteristics.

To overcome this problem, Cavalcanti et al. (2019) employ a **quasi-experimental research design** combined with **panel data econometric techniques**. The identification strategy compares municipalities where oil was discovered (treatment group) with municipalities where drilling occurred but no oil was discovered (control group). Since both groups experienced oil exploration activities, the difference between them is assumed to arise primarily from the random success or failure of oil discovery.

The empirical analysis consists of three main econometric components:

1. Quasi-Experimental Design
2. Fixed Effects Panel Regression
3. Instrumental Variable (Two-Stage Least Squares)

---

# 4.1.1 Quasi-Experimental Design

## Why is this model used?

A randomized experiment is impossible because researchers cannot randomly assign oil deposits to municipalities.

Instead, the paper exploits a naturally occurring event.

Petrobras drilled wells in many municipalities.

Some municipalities:

- discovered oil
- did not discover oil

The authors argue that conditional on drilling, whether oil is discovered behaves like a natural lottery.

Therefore, municipalities with successful discoveries become the **treatment group**, while municipalities with unsuccessful drilling become the **control group**.

This creates a **Quasi-Experimental (Natural Experiment) Design**, allowing the estimation of causal effects.

---

Treatment Group

```
Drilling
      +
Oil Discovery
```

Control Group

```
Drilling
      +
No Discovery
```

Main assumption:

> Conditional on drilling activity, oil discovery is approximately random.

---

# 4.1.2 Fixed Effects Panel Regression

## Why is this model used?

The data contain repeated observations for municipalities over several years.

Different municipalities have different characteristics such as

- geography
- institutions
- climate
- historical development

Many of these characteristics do not change over time but may influence economic outcomes.

To eliminate these time-invariant differences, the paper employs a **Municipality Fixed Effects Model**.

In addition, national economic shocks may affect all municipalities simultaneously.

Therefore, **Year Fixed Effects** are also included.

The estimated coefficient on Oil Discovery represents the average treatment effect after controlling for municipality-specific and year-specific effects.

---

## Econometric Specification

$begin:math:display$
Y\_\{it\}\=\\alpha\+\\tau Z\_\{it\}\+\\beta X\_\{it\}\+\\gamma\_i\+\\rho\_t\+\\varepsilon\_\{it\}
$end:math:display$

where

| Symbol | Explanation |
|---------|-------------|
| $begin:math:text$Y\_\{it\}$end:math:text$ | Outcome variable for municipality *i* in year *t* (GDP per capita, sectoral GDP, urbanization, etc.) |
| $begin:math:text$\\alpha$end:math:text$ | Constant term |
| $begin:math:text$Z\_\{it\}$end:math:text$ | Oil discovery treatment indicator (1 = discovery, 0 = no discovery) |
| $begin:math:text$X\_\{it\}$end:math:text$ | Vector of control variables |
| $begin:math:text$\\tau$end:math:text$ | Average causal effect of oil discovery |
| $begin:math:text$\\gamma\_i$end:math:text$ | Municipality Fixed Effects |
| $begin:math:text$\\rho\_t$end:math:text$ | Year Fixed Effects |
| $begin:math:text$\\varepsilon\_\{it\}$end:math:text$ | Random error term |

---

## Interpretation

The coefficient

$begin:math:display$
\\tau
$end:math:display$

measures the average impact of oil discovery on municipal economic outcomes after controlling for observed characteristics and fixed effects.

---

# 4.1.3 Instrumental Variable (2SLS)

## Why is this model used?

Although oil discovery is relatively exogenous, **oil production itself is not**.

Municipalities with

- better infrastructure,
- better institutions,
- lower extraction costs,

are more likely to produce larger quantities of oil.

Consequently, estimating

```
GDP ← Oil Production
```

using Ordinary Least Squares (OLS) would produce biased estimates due to endogeneity.

To solve this problem, the paper uses **Oil Discovery as an Instrumental Variable (IV)** for Oil Production.

---

## Instrument

```
Oil Discovery
```

↓

predicts

```
Oil Production
```

↓

which affects

```
GDP
```

---

## Why is Oil Discovery a Valid Instrument?

A valid instrument must satisfy two conditions.

### (1) Relevance

Oil discovery must increase oil production.

```
Oil Discovery
        ↓
Oil Production
```

---

### (2) Exogeneity

Oil discovery should not directly affect GDP except through oil production.

```
Oil Discovery
        ↓
Oil Production
        ↓
GDP
```

There should be no alternative direct channel.

---

## Two-Stage Least Squares (2SLS)

### First Stage

Estimate predicted oil production using oil discovery.

```
Oil Production
        =
Discovery
      +
Controls
```

---

### Second Stage

Replace actual production with predicted production.

```
GDP
     =
Predicted Oil Production
      +
Controls
```

The resulting coefficient measures the causal impact of oil production on economic development.

---

# Summary of the Econometric Framework

| Model | Purpose |
|--------|---------|
| Quasi-Experimental Design | Construct comparable treatment and control groups |
| Fixed Effects Panel Regression | Estimate the causal impact of oil discovery while controlling for municipality and year effects |
| Instrumental Variable (2SLS) | Correct endogeneity when estimating the effect of oil production |

---

## Key Takeaway

The paper combines a natural experiment with panel fixed effects and instrumental variable estimation to identify the causal relationship between natural resource discoveries and long-run municipal economic development. This empirical strategy substantially reduces selection bias, omitted variable bias, and endogeneity, providing more credible estimates than conventional cross-sectional regression.