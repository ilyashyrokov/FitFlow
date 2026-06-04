from datetime import date
from enum import Enum
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator


def _to_camel(value: str) -> str:
    head, *tail = value.split("_")
    return head + "".join(part.capitalize() for part in tail)


class ApiModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=_to_camel,
        extra="forbid",
        populate_by_name=True,
    )


class Unit(str, Enum):
    KG = "kg"
    LB = "lb"


class Confidence(str, Enum):
    LOW = "low"
    MODERATE = "moderate"


class TrainingTrend(str, Enum):
    NEW = "new"
    IMPROVING = "improving"
    STABLE = "stable"
    DECLINING = "declining"
    PLATEAU = "plateau"
    RETURNING = "returning"


class SetInput(ApiModel):
    weight: float = Field(ge=0)
    repetitions: int = Field(gt=0, le=100)


class ExerciseInput(ApiModel):
    name: str = Field(min_length=1, max_length=120)
    sets: list[SetInput] = Field(max_length=30)

    @field_validator("name")
    @classmethod
    def normalize_name(cls, value: str) -> str:
        normalized = " ".join(value.split())
        if not normalized:
            raise ValueError("Exercise name must contain a visible character")
        return normalized


class WorkoutInput(ApiModel):
    date: date
    exercises: list[ExerciseInput] = Field(max_length=40)


class RecommendationRequest(ApiModel):
    unit: Unit = Unit.KG
    workouts: list[WorkoutInput] = Field(max_length=200)


class ForecastResponse(ApiModel):
    model: str = "linear_regression_v1"
    estimated_one_rep_max: float
    change_percent: float
    sessions_used: int
    unit: Unit


class RecommendationResponse(ApiModel):
    title: str
    message: str
    reason: str
    confidence: Confidence
    based_on_workout_count: int
    exercise_id: Optional[str] = None
    forecast: Optional[ForecastResponse] = None


class ExerciseInsightResponse(ApiModel):
    exercise_name: str
    unit: Unit
    sessions_analyzed: int
    latest_workout_date: date
    trend: TrainingTrend
    set_count: int
    total_reps: int
    total_volume: float
    top_weight: float
    estimated_one_rep_max: float
    forecast: Optional[ForecastResponse] = None


class TrainingAnalysisResponse(ApiModel):
    insights: list[ExerciseInsightResponse]
