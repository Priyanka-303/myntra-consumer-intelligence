# tests/test_sentiment.py
# Unit tests for sentiment_nlp.py
# Run with: pytest tests/

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.sentiment_nlp import analyze_polarity, get_vader_score, sentiment_bucket, categorize_issue


# ─────────────────────────────────────────────
# UNIT TESTS  analyze_polarity (VADER only)
# ─────────────────────────────────────────────

def test_positive_sentiment():
    """Clearly positive review text should return Positive"""
    result = analyze_polarity("I love this Myntra dress, the fit is perfect!")
    assert result == "Positive", f"Expected Positive, got {result}"


def test_negative_sentiment():
    result = analyze_polarity("Terrible quality, broke after one use. Very disappointed.")
    assert result == "Negative"

def test_neutral_sentiment():
    result = analyze_polarity("It is what it is. Average experience.")
    assert result == "Neutral"


# ─────────────────────────────────────────────
# UNIT TESTS  analyze_polarity (hybrid: VADER + rating
# ─────────────────────────────────────────────

def test_hybrid_positive_high_rating():
    """High rating + positive text = Positive"""
    result = analyze_polarity("Great product!", rating=5)
    assert result == "Positive"


def test_hybrid_mixed_positive_vader_gap():
    """
    VADER limitation test:
    'Top-notch' scores 0.0 on VADER but rating=5 → should be Mixed Positive
    This validates our hybrid approach handles lexicon gaps correctly
    """
    result = analyze_polarity("The quality is top-notch.", rating=5)
    assert result == "Mixed Positive", f"Expected Mixed Positive (VADER gap), got {result}"


def test_hybrid_negative_low_rating():
    """Low rating + negative text = Negative"""
    result = analyze_polarity("Terrible quality, broke after one use.", rating=1)
    assert result == "Negative"


def test_hybrid_neutral_3_star():
    """3 star rating should always return Neutral regardless of text"""
    result = analyze_polarity("It was okay I guess.", rating=3)
    assert result == "Neutral"


# ─────────────────────────────────────────────
# UNIT TESTS — get_vader_score
# ─────────────────────────────────────────────

def test_vader_score_range():
    """VADER compound score must always be between -1 and +1"""
    score = get_vader_score("This is an amazing product!")
    assert -1.0 <= score <= 1.0, f"Score out of range: {score}"


def test_vader_positive_score():
    """Clearly positive text should return positive compound score"""
    score = get_vader_score("Excellent! Loved it. Highly recommend.")
    assert score > 0.05, f"Expected positive score, got {score}"


def test_vader_negative_score():
    """Clearly negative text should return negative compound score"""
    score = get_vader_score("Terrible product. Very disappointed. Waste of money.")
    assert score < -0.05, f"Expected negative score, got {score}"


def test_vader_handles_empty_string():
    """Empty string should not crash — should return 0.0"""
    score = get_vader_score("")
    assert score == 0.0


def test_vader_handles_none():
    """None value should be handled gracefully"""
    score = get_vader_score(None)
    assert isinstance(score, float)


# ─────────────────────────────────────────────
# UNIT TESTS — sentiment_bucket
# ─────────────────────────────────────────────

def test_bucket_high_positive():
    assert sentiment_bucket(0.8) == '0.5 to 1.0'


def test_bucket_low_positive():
    assert sentiment_bucket(0.3) == '0.0 to 0.49'


def test_bucket_low_negative():
    assert sentiment_bucket(-0.3) == '-0.49 to 0.0'


def test_bucket_high_negative():
    assert sentiment_bucket(-0.8) == '-1.0 to -0.5'


def test_bucket_zero():
    assert sentiment_bucket(0.0) == '0.0 to 0.49'


# ─────────────────────────────────────────────
# UNIT TESTS — categorize_issue
# ─────────────────────────────────────────────

def test_issue_delivery():
    result = categorize_issue("The product arrived very late.")
    assert result == "Delivery"


def test_issue_product_cost():
    result = categorize_issue("Not worth the money at all.")
    assert result == "Product Cost"


def test_issue_unmet_expectations():
    result = categorize_issue("Did not meet my expectations at all.")
    assert result == "Unmet Expectations"


def test_issue_durability():
    result = categorize_issue("It stopped working after one month.")
    assert result == "Durability"


def test_issue_customer_service():
    result = categorize_issue("Customer service was completely unhelpful.")
    assert result == "Customer Service"


def test_issue_general():
    result = categorize_issue("Just okay I guess.")
    assert result == "General Dissatisfaction"


def test_issue_case_insensitive():
    """Issue categorization should work regardless of text casing"""
    result1 = categorize_issue("ARRIVED LATE")
    result2 = categorize_issue("arrived late")
    assert result1 == result2 == "Delivery"
