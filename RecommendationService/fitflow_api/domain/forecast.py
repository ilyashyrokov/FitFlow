from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from fitflow_api.domain.analysis import ExerciseSession

MIN_SESSIONS_FOR_FORECAST = 5


@dataclass(frozen=True)
class LinearRegressionForecast:
    estimated_one_rep_max: float
    change_percent: float
    sessions_used: int


def predict_next_session(
    sessions: tuple[ExerciseSession, ...],
) -> Optional[LinearRegressionForecast]:  # noqa: UP045 - keep Python 3.9 support
    """Fit a per-exercise linear regression over session order and forecast one step ahead."""
    if len(sessions) < MIN_SESSIONS_FOR_FORECAST:
        return None

    # Sessions arrive newest-first; reverse them so x increases with time.
    values = [session.estimated_one_rep_max for session in reversed(sessions)]
    count = len(values)
    mean_x = (count - 1) / 2
    mean_y = sum(values) / count
    denominator = sum((index - mean_x) ** 2 for index in range(count))
    slope = (
        sum((index - mean_x) * (value - mean_y) for index, value in enumerate(values)) / denominator
    )
    prediction = mean_y + slope * (count - mean_x)
    latest = values[-1]
    change_percent = ((prediction - latest) / latest * 100) if latest > 0 else 0.0

    return LinearRegressionForecast(
        estimated_one_rep_max=max(0.0, prediction),
        change_percent=change_percent,
        sessions_used=count,
    )
