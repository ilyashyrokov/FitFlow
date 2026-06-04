# FitFlow Training Analysis API

Python is the training-analysis core for FitFlow. It accepts only workout dates, exercise names, units and completed-set values. It does not store user workout history or process free-text notes. Its small regression model is fitted from the submitted history for each request; no shared or persistent model is trained.

## What it calculates

- Groups exercise names after trimming whitespace and ignoring letter case.
- Combines duplicate entries for the same exercise on the same date.
- Calculates set count, total repetitions, training volume, top recorded weight and an estimated one-repetition maximum.
- Classifies each exercise as new, improving, stable, declining, plateauing or returning after a long break.
- Returns a short recommendation with an explanation and confidence level.
- Fits a small per-exercise linear regression to estimated one-rep-max history and forecasts the next session after five or more sessions. The forecast is a separate experimental signal; it does not replace the rule-based recommendation.

Trend thresholds are named constants in `fitflow_api/domain/analysis.py`. The estimated one-repetition maximum uses the Epley formula and caps its repetition input at 12 to avoid overstating estimates for very high-repetition sets. The value is a rough trend metric, not a target or medical assessment.

## Structure

```text
fitflow_api/
  api/routes.py                       HTTP routes
  application/recommendation_engine.py Recommendation and analysis use cases
  domain/analysis.py                  Pure workout metrics and trend rules
  models.py                           Validated request and response models
  main.py                             FastAPI application and health check
```

The analysis module has no database or network dependencies, so the calculations can be tested directly. FastAPI routes are thin adapters around those use cases.

```sh
python -m venv .venv
source .venv/bin/activate
pip install '.[test]'
uvicorn fitflow_api.main:app --reload
pytest
ruff check .
ruff format --check .
```

Routes: `GET /health`, `POST /v1/recommendations` and `POST /v1/analysis`. Both recommendation and analysis responses include the per-exercise forecast once there are five sessions to fit the model. Requests contain only workout dates, exercise names, and completed set values. Free-text notes and unknown fields are rejected.

The forecast is recalculated from the request history for each call and is not persisted. It uses only the Python standard library; histories with fewer than five sessions return `forecast: null`. The iOS Debug build points to `http://127.0.0.1:8000/`; from this directory, run `python3 -m venv .venv`, activate it, run `pip install -e '.[test]'`, then `uvicorn fitflow_api.main:app --reload`.

The tests cover metric calculations, naming normalization, same-day set merging, all recommendation trends, API output, and invalid inputs. `pytest --cov=fitflow_api --cov-branch --cov-report=term-missing` shows branch coverage when `pytest-cov` is installed.
