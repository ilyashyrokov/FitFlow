from datetime import date

from fastapi.testclient import TestClient

from fitflow_api.application.recommendation_engine import recommend
from fitflow_api.main import app
from fitflow_api.models import RecommendationRequest

client = TestClient(app)


def payload(current_reps: list[int], current_weight: float = 40) -> RecommendationRequest:
    return RecommendationRequest.model_validate(
        {
            "unit": "kg",
            "workouts": [
                {
                    "date": "2026-11-10",
                    "exercises": [
                        {
                            "name": "Жим штанги лёжа",
                            "sets": [
                                {"weight": current_weight, "repetitions": reps}
                                for reps in current_reps
                            ],
                        }
                    ],
                },
                {
                    "date": "2026-11-03",
                    "exercises": [
                        {
                            "name": "Жим штанги лёжа",
                            "sets": [{"weight": 40, "repetitions": reps} for reps in [8, 8]],
                        }
                    ],
                },
            ],
        }
    )


def test_health_endpoint() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_recommendation_endpoint_keeps_the_swift_response_contract() -> None:
    response = client.post(
        "/v1/recommendations",
        json=payload([8, 8]).model_dump(mode="json", by_alias=True),
    )

    assert response.status_code == 200
    assert response.json()["title"] == "Сохрани текущий вес"
    assert response.json()["basedOnWorkoutCount"] == 2
    assert response.json()["exerciseId"] is None
    assert response.json()["forecast"] is None


def test_recommendation_endpoint_includes_ml_forecast_after_five_sessions() -> None:
    response = client.post(
        "/v1/recommendations",
        json={
            "unit": "kg",
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
            ],
        },
    )

    assert response.status_code == 200
    forecast = response.json()["forecast"]
    assert forecast["model"] == "linear_regression_v1"
    assert forecast["sessionsUsed"] == 5
    assert forecast["estimatedOneRepMax"] == 58.33
    assert forecast["unit"] == "kg"


def test_stable_history_is_explained() -> None:
    result = recommend(payload([8, 8]), today=date(2026, 11, 13))
    assert result.title == "Сохрани текущий вес"
    assert result.based_on_workout_count == 2
    assert "Жим штанги лёжа" in result.reason


def test_reduced_repetitions_recommends_holding_load() -> None:
    result = recommend(payload([6, 7]), today=date(2026, 11, 13))
    assert result.title == "Оставь вес прежним"
    assert result.confidence == "low"


def test_progression_requires_more_weight_without_fewer_reps() -> None:
    result = recommend(payload([8, 8], current_weight=42.5), today=date(2026, 11, 13))
    assert result.title == "Нагрузка постепенно растёт"
    assert result.confidence == "moderate"


def test_insufficient_history_has_a_neutral_message() -> None:
    request = RecommendationRequest.model_validate(
        {"workouts": [{"date": "2026-11-10", "exercises": []}]}
    )
    result = recommend(request, today=date(2026, 11, 13))
    assert result.based_on_workout_count == 0
    assert result.title == "Продолжай записывать"


def test_one_exercise_record_asks_for_a_comparison() -> None:
    request = RecommendationRequest.model_validate(
        {
            "workouts": [
                {
                    "date": "2026-11-10",
                    "exercises": [{"name": "Жим лёжа", "sets": [{"weight": 40, "repetitions": 8}]}],
                }
            ]
        }
    )

    result = recommend(request, today=date(2026, 11, 13))

    assert result.title == "Запиши ещё одну тренировку"
    assert result.based_on_workout_count == 1


def test_three_flat_sessions_identify_a_plateau() -> None:
    request = RecommendationRequest.model_validate(
        {
            "workouts": [
                {
                    "date": session_date,
                    "exercises": [
                        {
                            "name": "Приседания",
                            "sets": [
                                {"weight": 60, "repetitions": 8},
                                {"weight": 60, "repetitions": 8},
                            ],
                        }
                    ],
                }
                for session_date in ["2026-11-10", "2026-11-06", "2026-11-02"]
            ]
        }
    )

    result = recommend(request, today=date(2026, 11, 13))

    assert result.title == "Попробуй небольшой шаг вперёд"
    assert result.based_on_workout_count == 3


def test_long_break_recommends_returning_with_comfortable_load() -> None:
    request = RecommendationRequest.model_validate(
        {
            "workouts": [
                {
                    "date": "2026-10-01",
                    "exercises": [
                        {"name": "Тяга блока", "sets": [{"weight": 30, "repetitions": 10}]}
                    ],
                },
                {
                    "date": "2026-08-28",
                    "exercises": [
                        {"name": "Тяга блока", "sets": [{"weight": 30, "repetitions": 10}]}
                    ],
                },
            ]
        }
    )

    result = recommend(request, today=date(2026, 11, 13))

    assert result.title == "Вернись к комфортной нагрузке"
    assert result.confidence == "low"


def test_request_rejects_negative_weight_and_zero_repetitions() -> None:
    body = {
        "unit": "kg",
        "workouts": [
            {
                "date": "2026-11-10",
                "exercises": [{"name": "Приседания", "sets": [{"weight": -1, "repetitions": 0}]}],
            }
        ],
    }
    response = client.post("/v1/recommendations", json=body)
    assert response.status_code == 422


def test_unknown_personal_fields_are_rejected() -> None:
    response = client.post(
        "/v1/recommendations",
        json={"unit": "kg", "notes": "private note", "workouts": []},
    )
    assert response.status_code == 422


def test_whitespace_only_exercise_name_is_rejected() -> None:
    response = client.post(
        "/v1/recommendations",
        json={
            "workouts": [
                {
                    "date": "2026-11-10",
                    "exercises": [{"name": "   ", "sets": [{"weight": 10, "repetitions": 8}]}],
                }
            ]
        },
    )

    assert response.status_code == 422


def test_unrealistic_repetition_count_is_rejected() -> None:
    response = client.post(
        "/v1/recommendations",
        json={
            "workouts": [
                {
                    "date": "2026-11-10",
                    "exercises": [
                        {"name": "Жим лёжа", "sets": [{"weight": 10, "repetitions": 101}]}
                    ],
                }
            ]
        },
    )

    assert response.status_code == 422


def test_analysis_endpoint_returns_metrics_for_each_exercise() -> None:
    response = client.post(
        "/v1/analysis",
        json={
            "unit": "kg",
            "workouts": [
                {
                    "date": "2026-11-10",
                    "exercises": [
                        {
                            "name": "Жим лёжа",
                            "sets": [
                                {"weight": 40, "repetitions": 8},
                                {"weight": 40, "repetitions": 8},
                            ],
                        },
                        {
                            "name": "Тяга блока",
                            "sets": [{"weight": 30, "repetitions": 10}],
                        },
                    ],
                },
                {
                    "date": "2026-11-03",
                    "exercises": [
                        {
                            "name": "Жим лёжа",
                            "sets": [
                                {"weight": 37.5, "repetitions": 8},
                                {"weight": 37.5, "repetitions": 8},
                            ],
                        }
                    ],
                },
            ],
        },
    )

    assert response.status_code == 200
    result = response.json()["insights"]
    assert result[0]["exerciseName"] == "Жим лёжа"
    assert result[0]["trend"] == "improving"
    assert result[0]["setCount"] == 2
    assert result[0]["totalReps"] == 16
    assert result[0]["totalVolume"] == 640
    assert result[0]["estimatedOneRepMax"] == 50.67
    assert result[1]["exerciseName"] == "Тяга блока"
    assert result[1]["trend"] == "new"
    assert result[0]["forecast"] is None


def test_analysis_endpoint_returns_ml_forecast_after_five_sessions() -> None:
    response = client.post(
        "/v1/analysis",
        json={
            "unit": "kg",
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
            ],
        },
    )

    assert response.status_code == 200
    forecast = response.json()["insights"][0]["forecast"]
    assert forecast["model"] == "linear_regression_v1"
    assert forecast["sessionsUsed"] == 5
    assert forecast["estimatedOneRepMax"] == 58.33
