# Expected manuscript results

`code/05_validate_outputs.do` compares regenerated estimates with the values below. These values are audit targets only; no estimation script reads them as data.

## Main Table 1

| Model | Post-Craigslist coefficient | Standard error | Observations |
|---|---:|---:|---:|
| OLS | 51.879 | 1.004 | 824,710 |
| ZIP fixed effects | 43.942 | 0.682 | 824,710 |
| ZIP and year fixed effects | 20.845 | 0.668 | 824,710 |
| ZIP-specific trends | 2.954 | 0.296 | 824,033 |
| CSDID | 5.781 | 0.298 | 518,433 |

## Main Table 2

| Model | Post effect | Linear density interaction | Quadratic density interaction | Observations |
|---|---:|---:|---:|---:|
| Common-sample base | 4.216 | | | 707,161 |
| Linear density | 4.078 | 0.062 | | 707,161 |
| Quadratic density | 3.640 | 0.379 | -0.005 | 707,161 |
| CSDID with density controls | 10.734 | | | 454,497 |

## Kernel checkpoints

| Density percentile | Local effect |
|---|---:|
| 5th | 0.506 |
| 50th | 1.107 |
| 75th | 4.669 |
| 80th | 5.517 |
| 95th | 2.603 |

## Analysis panel

- 824,710 ZIP-year observations
- 38,264 ZIP codes
- 22,601 treated ZIP codes
- 15,663 never-treated ZIP codes
- 223,011 post-Craigslist ZIP-year observations
- 31,264 ZIP codes with Census 2000 population and density
