from datetime import date
from typing import Optional

from fitflow_api.domain.analysis import ExerciseInsight, TrainingTrend, analyze_training
from fitflow_api.models import (
    ExerciseInsightResponse,
    ForecastResponse,
    RecommendationRequest,
    RecommendationResponse,
    TrainingAnalysisResponse,
)


def analyze(
    request: RecommendationRequest, *, today: Optional[date] = None
) -> TrainingAnalysisResponse:
    reference_date = today or date.today()
    insights = analyze_training(request, today=reference_date)
    return TrainingAnalysisResponse(insights=[_response_item(item) for item in insights])


def recommend(
    request: RecommendationRequest,
    *,
    today: Optional[date] = None,
) -> RecommendationResponse:
    reference_date = today or date.today()
    insights = analyze_training(request, today=reference_date)
    if not insights:
        return RecommendationResponse(
            title="Продолжай записывать",
            message="Добавь ещё пару тренировок — тогда появится первая подсказка по твоим данным.",
            reason="Пока нет завершённых подходов для сравнения.",
            confidence="low",
            based_on_workout_count=0,
        )

    insight = insights[0]
    records_count = insight.sessions_analyzed
    if insight.trend == TrainingTrend.NEW:
        return RecommendationResponse(
            title="Запиши ещё одну тренировку",
            message=(
                f"Для упражнения «{insight.name}» пока есть одна запись. "
                "Повтори его, чтобы сравнить нагрузку."
            ),
            reason="Рекомендации по прогрессу появляются после сравнения нескольких занятий.",
            confidence="low",
            based_on_workout_count=records_count,
            forecast=_forecast_response(insight),
        )

    previous = insight.previous.date if insight.previous is not None else None
    comparison = (
        f"Последняя запись упражнения «{insight.name}» — {insight.latest.date.isoformat()}; "
        f"учтено занятий: {records_count}."
    )
    if previous is not None:
        comparison += f" Предыдущая запись: {previous.isoformat()}."

    if insight.trend == TrainingTrend.RETURNING:
        return RecommendationResponse(
            title="Вернись к комфортной нагрузке",
            message=(
                "После перерыва начни с привычного веса, который ощущается уверенно, "
                "и оцени самочувствие."
            ),
            reason=f"С последней записи прошло не меньше 30 дней. {comparison}",
            confidence="low",
            based_on_workout_count=records_count,
            forecast=_forecast_response(insight),
        )
    if insight.trend == TrainingTrend.DECLINING:
        return RecommendationResponse(
            title="Оставь вес прежним",
            message=(
                "В последней записи стало меньше повторов или общего объёма. "
                "Повтори нагрузку, если она ощущается комфортно."
            ),
            reason=f"Сравнены повторы, объём и оценка силы за последние занятия. {comparison}",
            confidence="low",
            based_on_workout_count=records_count,
            forecast=_forecast_response(insight),
        )
    if insight.trend == TrainingTrend.IMPROVING:
        return RecommendationResponse(
            title="Нагрузка постепенно растёт",
            message=(
                "В последних записях есть рост расчётной силы или объёма. "
                "Продолжай небольшими шагами и ориентируйся на ощущения."
            ),
            reason=(
                "Расчётная оценка силы или объём выросли по сравнению с прошлой записью. "
                f"{comparison}"
            ),
            confidence="moderate",
            based_on_workout_count=records_count,
            forecast=_forecast_response(insight),
        )
    if insight.trend == TrainingTrend.PLATEAU:
        return RecommendationResponse(
            title="Попробуй небольшой шаг вперёд",
            message=(
                "Несколько записей подряд выглядят похоже. Если самочувствие хорошее, "
                "добавь один повтор или немного веса."
            ),
            reason=f"Показатели трёх последних записей изменились незначительно. {comparison}",
            confidence="low",
            based_on_workout_count=records_count,
            forecast=_forecast_response(insight),
        )
    return RecommendationResponse(
        title="Сохрани текущий вес",
        message="Последние занятия выглядят стабильными. Повтори нагрузку, если она комфортна.",
        reason=f"Сравнены повторы, объём и оценка силы за последние занятия. {comparison}",
        confidence="moderate",
        based_on_workout_count=records_count,
        forecast=_forecast_response(insight),
    )


def _forecast_response(insight: ExerciseInsight) -> Optional[ForecastResponse]:
    if insight.forecast is None:
        return None
    return ForecastResponse(
        estimated_one_rep_max=round(insight.forecast.estimated_one_rep_max, 2),
        change_percent=round(insight.forecast.change_percent, 2),
        sessions_used=insight.forecast.sessions_used,
        unit=insight.unit,
    )


def _response_item(insight: ExerciseInsight) -> ExerciseInsightResponse:
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
        forecast=_forecast_response(insight),
    )
