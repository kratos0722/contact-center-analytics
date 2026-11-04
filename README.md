# Contact Center Analytics — shared metric definitions on dbt + DuckDB

A dbt + DuckDB analytics-engineering project that models **contact-center / BPO
metrics on shared definitions**. It solves the problem every multi-client BPO
analytics team eventually hits:

> *"AHT", "FCR", "service level" and "CSAT" must mean exactly the same thing for
> every client account — even though each client sends us different raw labels,
> different queues, and different dispositions.*

Each client's raw feed is conformed onto one **canonical metric dictionary** and
every KPI is computed **once, centrally**, so no account can quietly invent its
own version of a number. The whole thing is self-contained: `dbt build` seeds
synthetic data into a local DuckDB file, builds the warehouse, and runs the full
test suite — locally and in CI.

> **Data note:** 100% synthetic, deterministic sample data invented for this
> repo (two fictional clients, *Acme Corp* and *Globex LLC*). No real, client,
> or proprietary data is used anywhere.

---

## The problem, concretely

The two demo clients report the *same* outcomes using *different* raw labels.
The mapping layer is what makes them comparable:

| Client | Raw disposition | Raw channel | → Canonical disposition | → Canonical channel |
| ------ | --------------- | ----------- | ----------------------- | ------------------- |
| Acme   | `RESOLVED`      | `PHONE`     | `RESOLVED`              | `VOICE`             |
| Acme   | `CALLBACK`      | `CHAT`      | `FOLLOW_UP`             | `CHAT`              |
| Acme   | `ESCALATED`     | `EMAIL`     | `ESCALATED`             | `EMAIL`             |
| Globex | `Solved`        | `Voice`     | `RESOLVED`              | `VOICE`             |
| Globex | `Follow-up`     | `WebChat`   | `FOLLOW_UP`             | `CHAT`              |
| Globex | `Transferred`   | `E-Mail`    | `ESCALATED`             | `EMAIL`             |

`RESOLVED` / `Solved`, `CALLBACK` / `Follow-up` — same meaning, different strings.
After the staging + conform layers, a single `canonical_disposition` drives every
downstream metric, so Acme and Globex can be compared apples-to-apples.

---

## Architecture (medallion / layered)

```
  seeds (raw CSV)            staging (views)         intermediate (ephemeral)        marts (tables)                 metrics (views)
  ─────────────────         ──────────────────      ───────────────────────────     ──────────────────────────     ────────────────────
  raw_contacts        ┐
  raw_agents          │     stg_contacts            int_contacts_enriched           dim_agent  (SCD type-2)         metric_aht
  raw_queues          │     stg_agents          ┌──►(conform labels + derive        dim_queue                      metric_csat
  raw_surveys         ├───► stg_queues  ────────┤   handle/wait/SLA/FCR flags)      dim_date                       metric_fcr
  raw_agent_shifts    │     stg_surveys          │                             ┌──► dim_disposition           ┌──► metric_sla
  map_channel         │     stg_agent_shifts     └──►int_agent_scd  ───────────┘    fct_contacts  (grain)      │    metric_occupancy
  map_disposition     │     stg_channel_map          (build valid_from/to,          fct_csat      (grain) ─────┤
  ref_canonical_...   │     stg_disposition_map      is_current)                    fct_agent_day (grain)      │
  ref_clients         ┘     stg_canonical_dispo                                     rpt_client_scorecard  ─────┘
                            stg_clients                                               v1 / v2  (versioned + contract)

        raw            →        clean/type      →        conform + derive        →        dimensional model      →   shared KPIs
   (sources + seeds)        (+ source tests)            (business logic)             (contracts + SCD-2 + grains)   (one definition each)
```

**Why these layers**

- **staging** — one model per source, pure cleaning: cast types, rename, trim,
  `nullif` blanks. No business logic. Declared against dbt `sources` (see
  `models/staging/_sources.yml`) with column tests.
- **intermediate** — the *conform* step (ephemeral, so it is inlined and leaves
  no clutter in the warehouse). Here the per-client crosswalks are applied and
  all row-level business logic is derived exactly once: handle time, wait time,
  resolution / escalation / SLA / FCR flags.
- **marts** — the star schema: conformed dimensions + facts at explicit grains,
  all under enforced **model contracts**.
- **metrics** — the shared KPI definitions, each computed in a single model on
  top of the facts.

---

## Grains (documented in every fact's schema YAML)

| Model                  | Grain — one row per …                              |
| ---------------------- | -------------------------------------------------- |
| `fct_contacts`         | customer interaction (contact)                     |
| `fct_csat`             | CSAT survey response                               |
| `fct_agent_day`        | agent per staffed day                              |
| `dim_agent`            | agent **version** (SCD type-2)                     |
| `dim_queue`            | client queue                                       |
| `dim_disposition`      | canonical disposition                              |
| `dim_date`             | calendar day                                       |
| `rpt_client_scorecard` | client (versioned v1 / v2)                         |

---

## Shared metric dictionary

Each metric is defined in exactly one model so every account is forced to agree.

| Metric | Model | Definition |
| ------ | ----- | ---------- |
| **AHT** (Average Handle Time) | `metric_aht` | `sum(talk + hold + wrap) / count(handled contacts)` |
| **CSAT** | `metric_csat` | mean score (1–5) + top-box rate (share scoring 4–5) |
| **FCR** (First Contact Resolution) | `metric_fcr` | `fcr_contacts / resolved_contacts`, where a contact is FCR if it was resolved **and** the same customer did not contact the same client again within 7 days |
| **Service Level / SLA** | `metric_sla` | `answered_within_sla / offered` (offered includes abandoned; SLA threshold is per-queue) |
| **Occupancy** (WFM) | `metric_occupancy` | `handle_seconds / available_seconds` (productive time ÷ logged-in time) |

---

## SCD type-2 — `dim_agent`

Agents change teams and sites over time. `dim_agent` keeps full history: one row
per agent *version* with `valid_from` / `valid_to` / `is_current`, built from the
`raw_agents` version feed in `int_agent_scd`. Facts attribute each event to the
attributes that were true **at the time** via:

```sql
left join dim_agent a
  on  f.agent_id   = a.agent_id
  and f.client_id  = a.client_id
  and f.contact_date between a.valid_from and a.valid_to
```

Example (from the seeds): agent `A1001` moved `Billing → Retention` on
2024-04-01, so there are two rows — `valid_to = 2024-03-31` (historical) and
`valid_to = 9999-12-31, is_current = true`.

---

## Contracts & versioning — breaking changes fail CI, not the client report

Every mart enforces a **model contract** (`contract: {enforced: true}` with a
typed column list). If a model's output drifts from its declared shape — a
renamed column, a changed type, a dropped field — `dbt build` fails **in CI**,
before the bad shape ever reaches a client's dashboard.

`rpt_client_scorecard` is a **versioned model** demonstrating how a breaking
change is managed instead of forced:

- **v1** — the stable contract existing dashboards are pinned to
  (`resolution_rate`, `csat_avg`).
- **v2** — the breaking change: drops `resolution_rate`, renames
  `csat_avg → csat_mean`, adds `fcr_contacts` / `fcr_rate` / `occupancy_pct`.

Both versions are built and tested. Downstream consumers keep calling
`ref('rpt_client_scorecard', v=1)` until they migrate, then move to the default
(latest) version — a safe, auditable deprecation path.

---

## Tests

- **Generic tests** (in the schema YAMLs): `unique`, `not_null`,
  `relationships` (every fact FK resolves to its dimension), and
  `accepted_values` (canonical channels/dispositions, CSAT 1–5).
- **Singular tests** (in `tests/`):
  - `assert_handle_seconds_non_negative` — handle time is never negative.
  - `assert_sla_implies_answered` — nothing can be "within SLA" unless answered.
  - `assert_occupancy_within_bounds` — occupancy stays within `(0, 1]`.

A full run is **141 nodes green** (9 seeds, 9 table models, 14 view models,
109 data tests) — see below.

---

## Run it

Windows is the reference environment; Python 3.12 available as `python`.

**Git Bash**

```bash
python -m venv .venv
source .venv/Scripts/activate
pip install dbt-duckdb==1.9.4

# make the project self-contained: dbt reads profiles.yml from the repo root
export DBT_PROFILES_DIR="$(pwd)"

dbt build          # = seed + run + test (the whole thing, green)
```

**PowerShell**

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install dbt-duckdb==1.9.4

$env:DBT_PROFILES_DIR = (Get-Location).Path

dbt build
```

Handy follow-ups:

```bash
dbt docs generate && dbt docs serve   # browse the DAG, grains, contracts
dbt build --select rpt_client_scorecard.v1   # build just the pinned version
dbt compile --select cross_client_metric_comparison   # the cross-client analysis
```

Expected final line:

```
Done. PASS=141 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=141
```

---

## How it stays reproducible

- **Pinned** `dbt-duckdb==1.9.4` (dbt-core 1.12.x) in both the README and CI.
- **Project-local `profiles.yml`** at the repo root (`DBT_PROFILES_DIR`), pointing
  at a single DuckDB file `warehouse.duckdb` via a relative path — no global dbt
  config, no external warehouse.
- **No dbt packages** — the date spine, surrogate keys and compound-key tests are
  written with plain DuckDB SQL to keep CI a single `pip install`.
- **Deterministic seeds** — no randomness; the same numbers every run.
- **CI** (`.github/workflows/ci.yml`) runs `dbt build` on Ubuntu with
  `DBT_PROFILES_DIR` set to the workspace, so the green build is enforced on
  every push and PR.

## Project layout

```
contact-center-analytics/
├── dbt_project.yml            # project config + per-layer materializations
├── profiles.yml               # DuckDB, relative path (resolved via DBT_PROFILES_DIR)
├── macros/
│   └── generate_schema_name.sql   # seeds land in a stable `raw` schema
├── seeds/                     # synthetic raw data for 2 clients + the mapping dictionary
│   ├── raw_contacts.csv  raw_agents.csv  raw_queues.csv  raw_surveys.csv  raw_agent_shifts.csv
│   ├── map_channel.csv   map_disposition.csv          # per-client → canonical crosswalks
│   └── ref_canonical_disposition.csv  ref_clients.csv # conformed master dimensions
├── models/
│   ├── staging/      # stg_* (one per source) + _sources.yml + column tests
│   ├── intermediate/ # int_contacts_enriched, int_agent_scd (ephemeral)
│   ├── marts/        # dim_* / fct_* (contracts + grains) + rpt_client_scorecard v1/v2
│   └── metrics/      # metric_aht / csat / fcr / sla / occupancy
├── tests/            # 3 singular tests
├── analyses/         # cross-client comparison (compiled, not materialised)
└── .github/workflows/ci.yml
```

---

*Built by Clarence Averion as an analytics-engineering reference project.*
