# tests/test_integration.py
# Integration tests — run the sentiment pipeline against the REAL dataset,
# not hand-written example strings. Validates the pipeline behaves correctly
# end-to-end on actual customer_reviews_cleaned.csv data.
#
# Run with: pytest tests/test_integration.py -v

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import csv
import pytest
from src.sentiment_nlp import analyze_polarity, get_vader_score, categorize_issue

DATA_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "data",
    "processed",
    "customer_reviews_cleaned.csv",
)

VALID_SENTIMENT_LABELS = {
    "Positive", "Negative", "Neutral", "Mixed Positive", "Mixed Negative"
}


def load_reviews():
    """Load the real cleaned reviews dataset used in the actual analysis."""
    if not os.path.exists(DATA_PATH):
        pytest.skip(f"Dataset not found at {DATA_PATH} — place customer_reviews_cleaned.csv in data/")
    with open(DATA_PATH, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return list(reader)


# ─────────────────────────────────────────────
# INTEGRATION TESTS — full pipeline on real data
# ─────────────────────────────────────────────

def test_dataset_loads_and_has_expected_columns():
    rows = load_reviews()
    assert len(rows) > 0, "Dataset is empty"
    expected_columns = {"reviewid", "customerid", "productid", "reviewdate", "rating", "reviewtext"}
    assert expected_columns.issubset(rows[0].keys())


def test_pipeline_runs_on_full_dataset_without_crashing():
    """
    The core integration check: run analyze_polarity across every real
    review in the dataset and confirm it completes without exceptions
    and returns a valid label for every row.
    """
    rows = load_reviews()
    results = []
    for row in rows:
        label = analyze_polarity(row["reviewtext"], rating=int(row["rating"]))
        results.append(label)

    assert len(results) == len(rows)
    assert all(r in VALID_SENTIMENT_LABELS for r in results), (
        f"Found labels outside expected set: {set(results) - VALID_SENTIMENT_LABELS}"
    )


def test_sentiment_distribution_is_reasonable():
    """
    Sanity check against the real distribution reported in the analysis
    (Positive ~68.7%, combined negative ~14%). Uses a wide tolerance band
    since this is a regression guard, not an exact reproduction check —
    the goal is catching a broken pipeline (e.g. everything returning
    'Neutral'), not asserting the published percentages to the decimal.
    """
    rows = load_reviews()
    labels = [analyze_polarity(r["reviewtext"], rating=int(r["rating"])) for r in rows]

    positive_pct = labels.count("Positive") / len(labels)
    negative_pct = (labels.count("Negative") + labels.count("Mixed Negative")) / len(labels)

    assert positive_pct > 0.5, f"Expected majority positive sentiment, got {positive_pct:.1%}"
    assert 0.05 < negative_pct < 0.30, f"Negative signal out of expected range: {negative_pct:.1%}"


def test_five_star_reviews_are_rarely_negative():
    """
    A 5-star rating paired with negative-classified sentiment should be
    rare. This catches a broken hybrid scoring function — if ratings
    stop influencing the label at all, this would fail loudly.
    """
    rows = load_reviews()
    five_star = [r for r in rows if r["rating"] == "5"]
    assert len(five_star) > 0, "No 5-star reviews found in dataset"

    labels = [analyze_polarity(r["reviewtext"], rating=5) for r in five_star]
    negative_count = labels.count("Negative")
    negative_rate = negative_count / len(five_star)

    assert negative_rate < 0.05, (
        f"{negative_rate:.1%} of 5-star reviews classified Negative — "
        "hybrid rating logic may not be applying correctly"
    )


def test_one_star_reviews_are_rarely_positive():
    """Mirror check for the low end of the rating scale."""
    rows = load_reviews()
    one_star = [r for r in rows if r["rating"] == "1"]
    if not one_star:
        pytest.skip("No 1-star reviews in dataset to test against")

    labels = [analyze_polarity(r["reviewtext"], rating=1) for r in one_star]
    positive_rate = labels.count("Positive") / len(one_star)

    assert positive_rate < 0.05, (
        f"{positive_rate:.1%} of 1-star reviews classified Positive — "
        "hybrid rating logic may not be applying correctly"
    )


def test_issue_categorization_runs_on_negative_reviews_without_crashing():
    """
    Runs categorize_issue across every review classified as negative-leaning
    in the real dataset, confirming the theme-extraction step used to
    produce the 'Unmet Expectations = 31%' finding doesn't crash or
    silently return None on real text.
    """
    rows = load_reviews()
    negative_rows = [
        r for r in rows
        if analyze_polarity(r["reviewtext"], rating=int(r["rating"])) in ("Negative", "Mixed Negative")
    ]
    assert len(negative_rows) > 0, "No negative reviews found to test issue categorization against"

    categories = [categorize_issue(r["reviewtext"]) for r in negative_rows]
    assert all(c is not None and c != "" for c in categories)


def test_vader_score_never_crashes_on_real_review_text():
    """
    Runs get_vader_score across all 1,400 real reviews to confirm no
    real-world text (punctuation, emojis, mixed case, etc.) breaks the
    scorer — something hand-written example strings in unit tests
    wouldn't necessarily catch.
    """
    rows = load_reviews()
    for row in rows:
        score = get_vader_score(row["reviewtext"])
        assert isinstance(score, float)
        assert -1.0 <= score <= 1.0
