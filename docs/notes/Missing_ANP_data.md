## Difference in the Number of Oil Wells

Cavalcanti, Da Mata, and Toscani (2019) report **20,052 oil wells** for their historical ANP dataset:

| Location | Paper | Current ANP data | Difference |
|---|---:|---:|---:|
| Onshore | 16,021 | 15,760 | -261 |
| Offshore | 4,031 | 3,847 | -184 |
| **Total** | **20,052** | **19,607** | **-445** |

The current analysis therefore contains **445 fewer wells (2.2%)** than the original paper.

### What we can establish

The difference is **not caused by missing drilling dates or an incorrect 1940 cutoff**:

- All 30,535 wells in the current ANP shapefile have a usable drilling-start year (`INICIO`).
- The available drilling years range from **1922 to 2023**.
- Applying the same study-period rule, **1940–2000 inclusive**, produces 19,607 wells.
- Extending the lower boundary to 1938–1939 would add only **5 wells**, so it cannot explain the 445-well difference.
- The discrepancy occurs in both onshore (**261 fewer**) and offshore (**184 fewer**) observations.

### Most plausible explanation

The exact reason for the 445-well difference **cannot be established from the available files alone**. The most plausible explanation is a **difference in ANP data vintages and historical database construction**.

Cavalcanti et al. constructed their dataset using the ANP records available when the original study was conducted, whereas this replication uses the publicly available **2023 ANP well shapefile**. Historical administrative databases can be revised over time through corrections, removal or consolidation of records, reclassification of wells, and changes in database coverage.

Therefore, the 19,607 observations should be treated as the **reconstructed 1940–2000 sample from the current ANP database**, rather than artificially modified to reproduce the paper's 20,052 observations.

### Implication for the replication

This discrepancy is small:

**445 / 20,052 ≈ 2.2%**

Thus, the reconstructed dataset retains approximately **97.8% of the number of wells reported in the original study**. However, because the exact historical ANP extract used by the authors is unavailable, the analysis should be described as a **replication/adaptation using current publicly available ANP data**, rather than an exact data replication.

> **Presentation version:**  
> The original paper reports 20,052 wells for 1940–2000, while the current 2023 ANP database yields 19,607 wells using drilling-start dates, a difference of 445 wells (2.2%). The discrepancy is not explained by missing dates or the 1940 cutoff and most likely reflects revisions between historical and current versions of the ANP database. Therefore, I retain the reproducible 19,607-well sample rather than altering the filtering rule to match the original count.