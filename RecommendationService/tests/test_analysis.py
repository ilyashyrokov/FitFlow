from datetime import date

from fitflow_api.domain.analysis import TrainingTrend, analyze_training
from fitflow_api.models import RecommendationRequest


def test_analysis_calculates_volume_estimated_strength_and_unit() -> None:
    request = RecommendationRequest.model_validate(
        {
            "unit": "lb",
            "workouts": [
                {
                    "date": "2026-11-10",
                    "exercises": [
                        {
                            "name": "Bench press",
                            "sets": [
                                {"weight": 100, "repetitions": 8},
                                {"weight": 95, "repetitions": 9},
                            ],
                        }
                    ],
                },
                {
                    "date": "2026-11-03",
                    "exercises": [
                        {
                            "name": "Bench press",
                            "sets": [{"weight": 95, "repetitions": 8}],
                        }
                    ],
                },
            ],
        }
    )

    insight = analyze_training(request, today=date(2026, 11, 13))[0]

    assert insight.unit.value == "lb"
    assert insight.latest.set_count == 2
    assert insight.latest.total_reps == 17
    assert insight.latest.total_volume == 1655
    assert round(insight.latest.estimated_one_rep_max, 2) == 126.67
    assert insight.trend == TrainingTrend.IMPROVING


def test_same_exercise_names_are_normalized_and_same_day_sets_are_merged() -> None:
    request = RecommendationRequest.model_validate(
        {
            "workouts": [
                {
                    "date": "2026-11-10",
                    "exercises": [
                        {"name": "  Жим   лёжа ", "sets": [{"weight": 40, "repetitions": 8}]},
                        {"name": "жим лёжа", "sets": [{"weight": 40, "repetitions": 9}]},
                    ],
                },
                {
                    "date": "2026-11-03",
                    "exercises": [{"name": "Жим лёжа", "sets": [{"weight": 40, "repetitions": 8}]}],
                },
            ]
        }
    )

    insight = analyze_training(request, today=date(2026, 11, 13))[0]

    assert insight.name == "Жим лёжа"
    assert insight.sessions_analyzed == 2
    assert insight.latest.set_count == 2
    assert insight.latest.total_reps == 17


def test_estimated_strength_caps_high_rep_sets() -> None:
    request = RecommendationRequest.model_validate(
        {
            "workouts": [
                {
                    "date": "2026-11-10",
                    "exercises": [
                        {"name": "Жим ногами", "sets": [{"weight": 100, "repetitions": 30}]}
                    ],
                }
            ]
        }
    )

    insight = analyze_training(request, today=date(2026, 11, 13))[0]

    assert insight.latest.estimated_one_rep_max == 140


def test_insights_sort_by_latest_workout_date() -> None:
    request = RecommendationRequest.model_validate(
        {
            "workouts": [
                {
                    "date": "2026-11-10",
                    "exercises": [{"name": "Жим лёжа", "sets": [{"weight": 40, "repetitions": 8}]}],
                },
                {
                    "date": "2026-11-12",
                    "exercises": [
                        {"name": "Приседания", "sets": [{"weight": 60, "repetitions": 8}]}
                    ],
                },
            ]
        }
    )

    insights = analyze_training(request, today=date(2026, 11, 13))

    assert [item.name for item in insights] == ["Приседания", "Жим лёжа"]


def test_ml_forecast_learns_from_five_sessions_and_predicts_next_strength_estimate() -> None:
    request = RecommendationRequest.model_validate(
        {
            "workouts": [
                {
                    "date": session_date,
                    "exercises": [
                        {"name": "Жим лёжа", "sets": [{"weight": weight, "repetitions": 5}]}
                    ],
                }
                for session_date, weight in [
                    ("2026-11-10", 48),
                    ("2026-11-07", 46),
                    ("2026-11-04", 44),
                    ("2026-11-01", 42),
                    ("2026-10-29", 40),
                ]
            ]
        }
    )

    insight = analyze_training(request, today=date(2026, 11, 13))[0]

    assert insight.forecast is not None
    assert insight.forecast.sessions_used == 5
    assert round(insight.forecast.estimated_one_rep_max, 2) == 58.33


def test_ml_forecast_waits_for_five_sessions() -> None:
    request = RecommendationRequest.model_validate(
        {
            "workouts": [
                {
                    "date": session_date,
                    "exercises": [{"name": "Жим лёжа", "sets": [{"weight": 40, "repetitions": 5}]}],
                }
                for session_date in ["2026-11-10", "2026-11-07", "2026-11-04", "2026-11-01"]
            ]
        }
    )

    insight = analyze_training(request, today=date(2026, 11, 13))[0]

    assert insight.forecast is None
