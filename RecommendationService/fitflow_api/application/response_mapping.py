from typing import Optional

from fitflow_api.domain.analysis import ExerciseInsight
from fitflow_api.models import ExerciseInsightResponse, ForecastResponse


def to_forecast_response(insight: ExerciseInsight) -> Optional[ForecastResponse]:
    if insight.forecast is None:
        return None
    return ForecastResponse(
        estimated_one_rep_max=round(insight.forecast.estimated_one_rep_max, 2),
        change_percent=round(insight.forecast.change_percent, 2),
        sessions_used=insight.forecast.sessions_used,
        unit=insight.unit,
    )


def to_exercise_insight_response(insight: ExerciseInsight) -> ExerciseInsightResponse:
    latest = insight.latest
    return ExerciseInsightResponse(
        exercise_name=insight.name,
        unit=insight.unit,
        sessions_analyzed=insight.sessions_analyzed,
        latest_workout_date=latest.date,
        trend=insight.trend,
        set_count=latest.set_count,
        total_reps=latest.total_reps,
        total_volume=round(latest.total_volume, 2),
        top_weight=latest.top_weight,
        estimated_one_rep_max=round(latest.estimated_one_rep_max, 2),
        forecast=to_forecast_response(insight),
    )
