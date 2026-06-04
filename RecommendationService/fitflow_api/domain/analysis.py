from collections import defaultdict
from dataclasses import dataclass
from datetime import date
from typing import Optional

from fitflow_api.domain.forecast import LinearRegressionForecast, predict_next_session
from fitflow_api.models import RecommendationRequest, SetInput, TrainingTrend, Unit

RETURN_AFTER_DAYS = 30
REP_DECLINE_THRESHOLD = 0.12
VOLUME_DECLINE_THRESHOLD = 0.15
ESTIMATED_STRENGTH_GAIN_THRESHOLD = 0.025
VOLUME_GAIN_THRESHOLD = 0.08
PLATEAU_SESSION_COUNT = 3
PLATEAU_SPREAD_THRESHOLD = 0.025
ESTIMATED_REPETITION_CAP = 12


@dataclass(frozen=True)
class ExerciseSession:
    name: str
    date: date
    set_count: int
    total_reps: int
    total_volume: float
    top_weight: float
    estimated_one_rep_max: float


@dataclass(frozen=True)
class ExerciseHistory:
    name: str
    sessions: tuple[ExerciseSession, ...]


@dataclass(frozen=True)
class ExerciseInsight:
    name: str
    unit: Unit
    sessions_analyzed: int
    latest: ExerciseSession
    previous: Optional[ExerciseSession]
    trend: TrainingTrend
    forecast: Optional[LinearRegressionForecast]


def analyze_training(request: RecommendationRequest, *, today: date) -> list[ExerciseInsight]:
    """Summarize completed sets into exercise-level trends, newest session first."""
    sets_by_exercise_and_date: dict[str, dict[date, list[SetInput]]] = defaultdict(
        lambda: defaultdict(list)
    )
    display_names: dict[str, str] = {}

    for workout in request.workouts:
        for exercise in workout.exercises:
            if not exercise.sets:
                continue
            key = " ".join(exercise.name.split()).casefold()
            display_names.setdefault(key, " ".join(exercise.name.split()))
            sets_by_exercise_and_date[key][workout.date].extend(exercise.sets)

    histories = [
        ExerciseHistory(
            name=display_names[key],
            sessions=tuple(
                _session(display_names[key], session_date, sets)
                for session_date, sets in sorted(daily_sets.items(), reverse=True)
            ),
        )
        for key, daily_sets in sets_by_exercise_and_date.items()
    ]
    insights = [
        ExerciseInsight(
            name=history.name,
            unit=request.unit,
            sessions_analyzed=len(history.sessions),
            latest=history.sessions[0],
            previous=history.sessions[1] if len(history.sessions) > 1 else None,
            trend=_trend(history.sessions, today=today),
            forecast=predict_next_session(history.sessions),
        )
        for history in histories
    ]
    return sorted(
        insights,
        key=lambda insight: (-insight.latest.date.toordinal(), insight.name.casefold()),
    )


def _session(name: str, session_date: date, sets: list[SetInput]) -> ExerciseSession:
    total_reps = sum(item.repetitions for item in sets)
    total_volume = sum(item.weight * item.repetitions for item in sets)
    top_weight = max(item.weight for item in sets)
    estimated_one_rep_max = max(
        item.weight * (1 + min(item.repetitions, ESTIMATED_REPETITION_CAP) / 30) for item in sets
    )
    return ExerciseSession(
        name=name,
        date=session_date,
        set_count=len(sets),
        total_reps=total_reps,
        total_volume=total_volume,
        top_weight=top_weight,
        estimated_one_rep_max=estimated_one_rep_max,
    )


def _trend(sessions: tuple[ExerciseSession, ...], *, today: date) -> TrainingTrend:
    latest = sessions[0]
    if len(sessions) == 1:
        return TrainingTrend.NEW
    if (today - latest.date).days >= RETURN_AFTER_DAYS:
        return TrainingTrend.RETURNING

    previous = sessions[1]
    if _fell(latest.total_reps, previous.total_reps, threshold=REP_DECLINE_THRESHOLD) or _fell(
        latest.total_volume, previous.total_volume, threshold=VOLUME_DECLINE_THRESHOLD
    ):
        return TrainingTrend.DECLINING

    estimated_gain = _relative_change(latest.estimated_one_rep_max, previous.estimated_one_rep_max)
    volume_gain = _relative_change(latest.total_volume, previous.total_volume)
    if estimated_gain >= ESTIMATED_STRENGTH_GAIN_THRESHOLD or (
        volume_gain >= VOLUME_GAIN_THRESHOLD and latest.total_reps >= previous.total_reps
    ):
        return TrainingTrend.IMPROVING

    if len(sessions) >= PLATEAU_SESSION_COUNT and _is_plateau(sessions[:PLATEAU_SESSION_COUNT]):
        return TrainingTrend.PLATEAU
    return TrainingTrend.STABLE


def _fell(current: float, previous: float, *, threshold: float) -> bool:
    return previous > 0 and (previous - current) / previous >= threshold


def _relative_change(current: float, previous: float) -> float:
    if previous <= 0:
        return 0.0
    return (current - previous) / previous


def _is_plateau(sessions: tuple[ExerciseSession, ...]) -> bool:
    best_estimates = [session.estimated_one_rep_max for session in sessions]
    if min(best_estimates) <= 0:
        return False
    spread = (max(best_estimates) - min(best_estimates)) / min(best_estimates)
    return spread <= PLATEAU_SPREAD_THRESHOLD
