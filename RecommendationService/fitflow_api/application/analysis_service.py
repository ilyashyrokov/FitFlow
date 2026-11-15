from datetime import date
from typing import Optional

from fitflow_api.application.response_mapping import to_exercise_insight_response
from fitflow_api.domain.analysis import analyze_training
from fitflow_api.models import RecommendationRequest, TrainingAnalysisResponse


def analyze(
    request: RecommendationRequest, *, today: Optional[date] = None
) -> TrainingAnalysisResponse:
    reference_date = today or date.today()
    insights = analyze_training(request, today=reference_date)
    return TrainingAnalysisResponse(
        insights=[to_exercise_insight_response(item) for item in insights]
    )
