"""
Lightweight wrapper around nfl_data_py to provide JSON-serializable
responses that are easy to consume from MATLAB or other clients.

Each public function validates inputs, fetches data via nfl_data_py,
applies optional filters, and returns a JSON string with orient='records'.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, asdict
from datetime import datetime
from typing import Iterable, List, Optional, Sequence

import pandas as pd

try:
    import nfl_data_py as nfl
except ModuleNotFoundError as exc:  # pragma: no cover - handled at runtime
    raise ImportError(
        "nfl_data_py is not installed. "
        "Install it with `pip install nfl_data_py` in the active Python environment."
    ) from exc


@dataclass
class QueryMetadata:
    source: str
    seasons: Sequence[int]
    filters: dict


_POSITION_GROUP_FILTERS = {
    "offense": {"QB", "RB", "WR", "TE", "OL"},
    "defense": {"DL", "LB", "DB"},
    "kicking": {"SPEC"},
    "special": {"SPEC"},
    "special_teams": {"SPEC"},
    "specialteams": {"SPEC"},
    "team": set(),
    "all": set(),
}

_POSITION_GROUP_ALIASES = {
    "offence": "offense",
    "defence": "defense",
    "specialteams": "special_teams",
    "specialteam": "special_teams",
    "special-teams": "special_teams",
    "special teams": "special_teams",
    "kicker": "kicking",
    "kick": "kicking",
}

_SEASON_TYPE_ALIASES = {
    "reg": "REG",
    "regular": "REG",
    "regular_season": "REG",
    "regular-season": "REG",
    "offense": "REG",
    "offence": "REG",
    "defense": "REG",
    "defence": "REG",
    "team": "REG",
    "kicking": "REG",
    "all": "ALL",
    "full": "ALL",
    "post": "POST",
    "postseason": "POST",
    "playoffs": "POST",
}


def _normalize_years(season: Optional[int] = None, years: Optional[Iterable[int]] = None) -> List[int]:
    if years is not None:
        normalized = sorted({int(year) for year in years})
    elif season is not None:
        normalized = [int(season)]
    else:
        normalized = [datetime.utcnow().year]
    if not normalized:
        raise ValueError("At least one season/year must be provided.")
    return normalized


def _validate_week(week: Optional[int]) -> Optional[int]:
    if week is None or week == "":
        return None
    week_int = int(week)
    if week_int < 1 or week_int > 23:
        raise ValueError("Week must be between 1 and 23 (including playoffs).")
    return week_int


def _filter_frame(
    frame: pd.DataFrame,
    *,
    week: Optional[int] = None,
    team: Optional[str] = None,
    stat_type: Optional[str] = None,
) -> pd.DataFrame:
    filtered = frame.copy()
    if week is not None and "week" in filtered.columns:
        filtered = filtered[filtered["week"] == week]
    if team is not None:
        team = str(team).upper()
        team_cols = [col for col in filtered.columns if col.endswith("_team") or col == "team" or col == "recent_team"]
        if not team_cols:
            team_cols = ["team"]
        mask = pd.Series(False, index=filtered.index)
        for col in team_cols:
            if col in filtered.columns:
                mask = mask | (filtered[col].astype(str).str.upper() == team)
        filtered = filtered[mask]
    filtered = _apply_stat_type_filter(filtered, stat_type)
    return filtered


def _apply_stat_type_filter(frame: pd.DataFrame, stat_type: Optional[str]) -> pd.DataFrame:
    if stat_type is None or str(stat_type).strip() == "":
        return frame

    normalized = str(stat_type).strip().lower().replace("-", "_")
    normalized = _POSITION_GROUP_ALIASES.get(normalized, normalized)

    if "stat_type" in frame.columns:
        return frame[frame["stat_type"].astype(str).str.lower() == normalized]

    if "position_group" not in frame.columns:
        return frame

    groups = _POSITION_GROUP_FILTERS.get(normalized)
    if groups is None:
        raise ValueError(f"Unsupported stat_type '{stat_type}'. Available options: {sorted(_POSITION_GROUP_FILTERS)}")
    if not groups:
        return frame

    mask = frame["position_group"].astype(str).str.upper().isin({group.upper() for group in groups})
    return frame[mask]


def _normalize_season_type(stat_type: Optional[str], season_type: Optional[str]) -> str:
    candidate: Optional[str]
    if season_type is not None and str(season_type).strip() != "":
        candidate = season_type
    else:
        candidate = stat_type

    if candidate is None or str(candidate).strip() == "":
        return "REG"

    normalized = str(candidate).strip().lower().replace(" ", "_").replace("-", "_")
    normalized = _POSITION_GROUP_ALIASES.get(normalized, normalized)
    normalized = _SEASON_TYPE_ALIASES.get(normalized, normalized.upper())

    if normalized not in {"REG", "ALL", "POST"}:
        raise ValueError(
            "season_type must be one of {'REG', 'ALL', 'POST'} "
            "or a recognised alias such as 'regular', 'all', 'post'."
        )
    return normalized


def _frame_to_json(frame: pd.DataFrame, metadata: QueryMetadata) -> str:
    if frame.empty:
        payload = {"data": [], "meta": asdict(metadata)}
        return json.dumps(payload)
    cleaned = frame.where(pd.notnull(frame), None)
    payload = {
        "data": cleaned.to_dict(orient="records"),
        "meta": asdict(metadata),
    }
    return json.dumps(payload, default=str)


def get_weekly_data(
    season: Optional[int] = None,
    *,
    week: Optional[int] = None,
    years: Optional[Iterable[int]] = None,
    stat_type: str = "offense",
) -> str:
    normalized_years = _normalize_years(season=season, years=years)
    week_int = _validate_week(week)
    frame = nfl.import_weekly_data(years=normalized_years)
    filtered = _filter_frame(frame, week=week_int, stat_type=stat_type)
    stat_filter = str(stat_type).lower() if stat_type else None
    metadata = QueryMetadata(
        source="import_weekly_data",
        seasons=normalized_years,
        filters={
            "week": week_int,
            "stat_type": stat_filter,
        },
    )
    return _frame_to_json(filtered, metadata)


def get_play_by_play(
    season: Optional[int] = None,
    *,
    week: Optional[int] = None,
    years: Optional[Iterable[int]] = None,
    team: Optional[str] = None,
) -> str:
    normalized_years = _normalize_years(season=season, years=years)
    week_int = _validate_week(week)
    frame = nfl.import_pbp_data(years=normalized_years)
    filtered = _filter_frame(frame, week=week_int, team=team)
    metadata = QueryMetadata(
        source="import_pbp_data",
        seasons=normalized_years,
        filters={"week": week_int, "team": team},
    )
    return _frame_to_json(filtered, metadata)


def get_seasonal_data(
    season: Optional[int] = None,
    *,
    years: Optional[Iterable[int]] = None,
    stat_type: Optional[str] = None,
    season_type: Optional[str] = None,
) -> str:
    normalized_years = _normalize_years(season=season, years=years)
    scope = _normalize_season_type(stat_type, season_type)
    frame = nfl.import_seasonal_data(normalized_years, s_type=scope)
    metadata = QueryMetadata(
        source="import_seasonal_data",
        seasons=normalized_years,
        filters={
            "stat_type": str(stat_type) if stat_type else None,
            "season_type": scope,
        },
    )
    return _frame_to_json(frame, metadata)


def get_win_totals(
    season: Optional[int] = None,
    *,
    years: Optional[Iterable[int]] = None,
) -> str:
    normalized_years = _normalize_years(season=season, years=years)
    frame = nfl.import_win_totals(years=normalized_years)
    metadata = QueryMetadata(
        source="import_win_totals",
        seasons=normalized_years,
        filters={},
    )
    return _frame_to_json(frame, metadata)


def get_rosters(
    season: Optional[int] = None,
    *,
    years: Optional[Iterable[int]] = None,
) -> str:
    normalized_years = _normalize_years(season=season, years=years)
    frame = nfl.import_seasonal_rosters(years=normalized_years)
    metadata = QueryMetadata(
        source="import_seasonal_rosters",
        seasons=normalized_years,
        filters={},
    )
    return _frame_to_json(frame, metadata)


def check_module() -> str:
    """
    Lightweight health check for clients.
    Returns JSON containing the nfl_data_py version and available helpers.
    """
    metadata = {
        "module": "nfl_data_py",
        "version": getattr(nfl, "__version__", "unknown"),
        "datetime_utc": datetime.utcnow().isoformat(),
        "functions": [
            "get_weekly_data",
            "get_play_by_play",
            "get_seasonal_data",
            "get_win_totals",
            "get_rosters",
        ],
    }
    return json.dumps(metadata)


__all__ = [
    "get_weekly_data",
    "get_play_by_play",
    "get_seasonal_data",
    "get_win_totals",
    "get_rosters",
    "check_module",
]


def _cli():
    """Simple command-line interface for system-call integrations."""
    import argparse

    parser = argparse.ArgumentParser(description="nfl_data_py MATLAB bridge")
    parser.add_argument(
        "function",
        choices=[
            "get_weekly_data",
            "get_play_by_play",
            "get_seasonal_data",
            "get_win_totals",
            "get_rosters",
            "check_module",
        ],
        help="Wrapper function to execute",
    )
    parser.add_argument(
        "--params",
        type=str,
        default="{}",
        help="JSON-encoded string with keyword arguments",
    )
    parsed = parser.parse_args()

    params = json.loads(parsed.params)
    func = globals()[parsed.function]
    result = func(**params)
    print(result)


if __name__ == "__main__":  # pragma: no cover
    _cli()
