from datetime import date

from fastapi import APIRouter

from fitflow_api.application.recommendation_engine import analyze, recommend
from fitflow_api.models import (
    RecommendationRequest,
    RecommendationResponse,
    TrainingAnalysisResponse,
)

router = APIRouter(prefix="/v1")


@router.post("/recommendations", response_model=RecommendationResponse)
def create_recommendation(request: RecommendationRequest) -> RecommendationResponse:
    return recommend(request)


@router.post("/analysis", response_model=TrainingAnalysisResponse)
def create_analysis(request: RecommendationRequest) -> TrainingAnalysisResponse:
    return analyze(request, today=date.today())
