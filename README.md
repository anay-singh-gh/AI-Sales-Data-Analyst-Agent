# AI Sales Data Analyst Agent

A basic text-to-SQL agent: ask questions about sales data in plain English and get the answer back as a table, or as a chart if you ask for one.

> **Note:** This is a **beginner-level project built for learning purposes**. It shows how a basic SQL agent can be built: an LLM turns a plain-English question into SQL, and the result comes back as a table. It handles straightforward, single-question queries and is not a production analytics tool. See [Limitations](#limitations).

## Overview

The agent connects an LLM (Groq, `openai/gpt-oss-120b`) to a Postgres (Supabase) sales database covering vendors, employees, products, inventory, customers, orders, payments and returns. You type a question such as *"Who are the top 5 customers by total revenue?"*. The agent writes a PostgreSQL query, runs it safely, and returns a pandas DataFrame. If you ask for a chart ("plot", "bar chart of..."), it also draws one with matplotlib/seaborn. Follow-up questions work because the conversation history is kept.

## Problem statement

Sales data lives in relational databases, and getting answers out of it needs SQL. Business users such as managers and sales reps usually don't know SQL. Their questions end up queued behind an analyst or a developer, even when the question is simple ("which products sold the most units?").

## How we solve it

1. **Question to SQL.** The LLM receives the question, the conversation so far, and a hand-written description of the database schema (tables, columns, views, business notes). It returns a single PostgreSQL `SELECT` query.
2. **Validation.** The query is checked before it touches the database. It must be one `SELECT`/`WITH` statement with no write or DDL keywords.
3. **Safe execution.** The query runs in a read-only transaction with a 15-second timeout.
4. **Self-correction.** If Postgres returns an error, the error is sent back to the LLM, which gets up to two chances to fix the query.
5. **Result.** The rows come back as a DataFrame. A second small LLM call decides whether the question asked for a chart, and if so which type (bar, line, pie, scatter) and which columns to use.
6. **Guardrails.** Questions unrelated to the sales data are refused instead of answered.

## Why this project

- **Self-serve data access:** non-technical users can query data without writing SQL or waiting for an analyst.
- **Learning:** it is a compact example of the core pieces of an LLM-powered data agent: prompt design with schema context, SQL validation, error-feedback retries, conversation memory and LLM-driven visualization, all in one readable file.
- **Safety by design:** it shows why generated SQL must never be trusted blindly, with layered protections (validation, read-only transaction, timeout).

## Tech stack

| Area | Technology |
|------|------------|
| Language | Python 3 |
| LLM | [Groq](https://groq.com) API, model `openai/gpt-oss-120b` (via the `groq` SDK) |
| Database | PostgreSQL, hosted on [Supabase](https://supabase.com) |
| DB access | SQLAlchemy + psycopg2 |
| Data handling | pandas |
| Visualization | matplotlib, seaborn |
| Config | python-dotenv (`.env` file) |
| Interface | Jupyter Notebook (`ipykernel`) |
| Testing | `unittest` with mocks |

## Project structure

```
pipeline.py             # everything: config, DB connection, schema, ask()/reset()
playground.ipynb        # notebook front end where users call the agent
sales_database.sql      # DDL + seed data + views for the sales database
tests/                  # unit tests (no DB or API key needed)
requirements.txt        # pinned versions
.env.example            # copy to .env and fill in your own credentials
```

## Setup

Prerequisites: Python 3, Git, a free [Groq API key](https://console.groq.com/keys), and a Postgres database (a free [Supabase](https://supabase.com) project works).

1. Clone the repository and move into the project folder:

   ```bash
   git clone https://github.com/anay-singh-gh/AI-Sales-Data-Analyst-Agent.git
   cd AI-Sales-Data-Analyst-Agent
   ```

2. Create and activate a virtual environment:

   ```bash
   python -m venv venv
   venv\Scripts\activate      # Windows
   source venv/bin/activate   # macOS/Linux
   ```

3. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

4. Copy `.env.example` to `.env` and fill in your own `GROQ_API_KEY` and `SUPABASE_DB_URL`.

5. Load `sales_database.sql` into your Postgres/Supabase database. It creates the tables and views and seeds the vendors, employees and categories. Products, customers, orders and the other tables must be populated separately.

## Usage

**Notebook playground:** open `playground.ipynb` (select the `venv` kernel) and call `ask("your question")`. This is the intended way to use the agent.

**As a library:**

```python
from pipeline import ask, reset

ask("Who are the top 5 customers by total revenue?")
ask("Which of those has the highest revenue?")      # follow-up uses prior context
ask("Show me a bar chart of revenue by month")      # asking for a chart draws one
ask("Who are the top 5 customers?", show_sql=True)  # print the generated SQL
reset()                                             # clear conversation history
```

## Safety

- Generated SQL must be a single `SELECT`/`WITH` statement with no write/DDL keywords (`validate_sql`).
- Queries run inside a read-only transaction with a 15s statement timeout.
- Only successful turns are kept in conversation history, capped at 20 messages.
- For anything beyond learning, also connect with a read-only database role.

## Tests

```bash
python -m unittest discover -s tests -t .
```

## Limitations

- **Basic and simple queries only.** It is built for simple questions: rankings, totals, filters and monthly trends. Complex multi-step analysis, deep nested logic or ambiguous questions may produce wrong or failing SQL.
- **Answers can be wrong.** The LLM may misread the question or the schema and still return a plausible-looking table. There is no check that the result matches your intent, so verify important numbers (use `show_sql=True`).
- **Hand-written schema.** The schema description in `pipeline.py` is maintained by hand and goes stale if the database changes.
- **Keyword-based SQL validation.** `validate_sql` is a simple filter. It can reject a legitimate query that uses a blocked word as an alias, and it is not a substitute for a read-only database role.
- **Single database, single user.** State (conversation history, clients) is held in module-level globals, so it is not suited to concurrent users.
- **Row limit by prompt only.** The 50-row limit is a request to the LLM, not enforced in code.
- **Basic charts.** Charts are limited to bar, line, pie and scatter, and the LLM can pick unsuitable columns.
- **Depends on external services.** It needs the Groq API and a reachable Postgres database, and quality depends on the model.
- **Limited testing.** Unit tests cover the validation and control flow with mocks. They have not been run against the live LLM or database.

## Future scope

- **REST API:** wrap `ask()`/`reset()` in FastAPI so a web frontend or other apps can use the agent, with per-session history instead of globals.
- **Live schema introspection:** build the schema prompt from the database so it never drifts, with hand-written business notes layered on top.
- **Stronger SQL safety:** parse queries with a SQL parser (e.g. `sqlglot`), enforce `LIMIT` in code, and use a dedicated read-only DB role.
- **Natural-language answers:** summarize the result in a sentence alongside the table.
- **Better visualization:** more chart types, smarter column selection, and a single combined LLM call for the SQL and chart decision.
- **Evaluation:** a set of benchmark questions with expected results to measure accuracy across models and prompts.
- **Caching and observability:** cache repeated questions and log queries, latency and cost.
- **Richer interface:** a Streamlit or Gradio chat UI and CSV export.
