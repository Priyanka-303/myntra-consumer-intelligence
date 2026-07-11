# src/sentiment_nlp.py
# Core sentiment analysis functions — used by notebook and tests

from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

analyzer = SentimentIntensityAnalyzer()


def get_vader_score(text: str) -> float:
    """Returns VADER compound score for a given text (-1 to +1)"""
    return analyzer.polarity_scores(str(text))['compound']


def analyze_polarity(text: str, rating: int = None) -> str:
    """
    Hybrid sentiment classification combining VADER score + star rating.
    
    If rating is provided — uses hybrid approach (more accurate).
    If rating is None — uses VADER score only.
    
    Returns one of: Positive, Mixed Positive, Neutral, Mixed Negative, Negative
    """
    score = get_vader_score(text)

    if rating is not None:
        # Hybrid approach: VADER + star rating
        if rating >= 4 and score >= 0.05:
            return 'Positive'
        elif rating >= 4 and score < 0.05:
            return 'Mixed Positive'
        elif rating == 3:
            return 'Neutral'
        elif rating <= 2 and score <= -0.05:
            return 'Negative'
        else:
            return 'Mixed Negative'
    else:
        # VADER only
        if score >= 0.05:
            return 'Positive'
        elif score <= -0.05:
            return 'Negative'
        else:
            return 'Neutral'


def sentiment_bucket(score: float) -> str:
    """Groups VADER score into 4 ranges for Power BI filtering"""
    if score >= 0.5:
        return '0.5 to 1.0'
    elif 0.0 <= score < 0.5:
        return '0.0 to 0.49'
    elif -0.5 <= score < 0.0:
        return '-0.49 to 0.0'
    else:
        return '-1.0 to -0.5'


def categorize_issue(text: str) -> str:
    """
    Keyword-based issue categorization for negative reviews.
    Maps complaint language to business issue categories.
    """
    text = str(text).lower()
    if any(w in text for w in ['worth', 'money', 'expensive', 'price', 'costly']):
        return 'Product Cost'
    elif any(w in text for w in ['arrived', 'late', 'delivery', 'shipping']):
        return 'Delivery'
    elif any(w in text for w in ['meet', 'expectations', 'average', 'nothing', 'special']):
        return 'Unmet Expectations'
    elif any(w in text for w in ['stopped', 'working', 'broke', 'month']):
        return 'Durability'
    elif any(w in text for w in ['performance', 'disappointed', 'bad', 'terrible']):
        return 'Product Performance'
    elif any(w in text for w in ['instructions', 'unclear', 'confusing']):
        return 'Usability'
    elif any(w in text for w in ['customer', 'service', 'support']):
        return 'Customer Service'
    else:
        return 'General Dissatisfaction'
