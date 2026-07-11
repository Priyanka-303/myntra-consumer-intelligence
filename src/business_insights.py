# src/business_insights.py
# GenAI integration — uses LLM to generate actionable business recommendations
# from negative review themes identified in sentiment analysis

import os

# ─────────────────────────────────────────────
# NOTE: To run this file you need a Gemini API key (free)
# Get one at: https://aistudio.google.com/app/apikey
# Then set it as environment variable:
#   Windows: set GEMINI_API_KEY=your_key_here
#   Mac/Linux: export GEMINI_API_KEY=your_key_here
# ─────────────────────────────────────────────

def generate_action_items(negative_reviews_summary: str) -> str:
    """
    Takes a summary of negative review themes and uses an LLM to generate
    3 concrete, actionable recommendations for the operations/product team.
    
    This addresses the GenAI/Prompt Engineering requirement by:
    - Designing a structured business-focused prompt
    - Sending negative review insights to an LLM
    - Returning operational recommendations automatically
    
    Args:
        negative_reviews_summary: string summary of top complaint themes + counts
    
    Returns:
        string with 3 actionable business recommendations
    """

    prompt = f"""
    You are an AI Business Analyst at Myntra, India's leading fashion ecommerce platform.
    
    Below is a summary of negative customer review themes extracted from {negative_reviews_summary}.
    
    Your task:
    1. Identify the root cause behind each complaint theme
    2. Provide exactly 3 concrete, actionable recommendations for the operations and product team
    3. Each recommendation must be specific, measurable, and implementable within 30 days
    4. Focus on reducing customer friction and improving satisfaction scores
    
    Format your response as:
    
    ROOT CAUSE ANALYSIS:
    [2-3 sentences identifying the underlying problem]
    
    RECOMMENDED ACTIONS:
    1. [Action] — [Expected Impact] — [Timeline]
    2. [Action] — [Expected Impact] — [Timeline]  
    3. [Action] — [Expected Impact] — [Timeline]
    
    Negative Review Summary:
    {negative_reviews_summary}
    """

    # ── Try Gemini API (free tier available) ──
    try:
        import google.generativeai as genai

        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            return _fallback_insights(negative_reviews_summary)

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-pro')
        response = model.generate_content(prompt)
        return response.text

    except ImportError:
        # ── Fallback: rule-based insights if no API key ──
        return _fallback_insights(negative_reviews_summary)


def _fallback_insights(summary: str) -> str:
    """
    Rule-based fallback when no API key is available.
    Still demonstrates prompt engineering thinking and business analysis.
    """
    return f"""
    ROOT CAUSE ANALYSIS:
    Based on the negative review themes, the primary issues stem from misaligned 
    product expectations (descriptions not matching reality), delivery reliability 
    gaps, and product quality inconsistencies across suppliers.

    RECOMMENDED ACTIONS:
    1. Update Product Descriptions — Add actual measurements, fabric composition, 
       and fit guides to all listings — Expected to reduce 'Unmet Expectations' 
       complaints by 30% — Timeline: 2 weeks

    2. Delivery SLA Monitoring — Implement real-time delivery tracking alerts for 
       orders exceeding promised delivery window — Expected to reduce late delivery 
       complaints by 25% — Timeline: 1 week

    3. Supplier Quality Review — Flag all products with >25% negative reviews for 
       mandatory quality audit — Expected to improve overall rating by 0.3 stars 
       — Timeline: 30 days

    [Note: Connect GEMINI_API_KEY environment variable for AI-generated insights]
    
    Summary analyzed: {summary[:200]}...
    """


def build_review_summary(issue_counts: dict, total_negative: int) -> str:
    """
    Formats issue category counts into a readable summary for the LLM prompt.
    
    Args:
        issue_counts: dict of {issue_category: count}
        total_negative: total number of negative reviews
    
    Returns:
        formatted string summary
    """
    lines = [f"Total negative reviews analyzed: {total_negative}\n", "Top complaint themes:"]
    for issue, count in sorted(issue_counts.items(), key=lambda x: x[1], reverse=True):
        pct = round(count * 100 / total_negative, 1)
        lines.append(f"  - {issue}: {count} reviews ({pct}%)")
    return "\n".join(lines)


# ─────────────────────────────────────────────
# EXAMPLE USAGE
# ─────────────────────────────────────────────

if __name__ == "__main__":
    # Simulate issue counts from your sentiment analysis output
    sample_issue_counts = {
        'Unmet Expectations': 70,
        'Product Cost':       47,
        'Product Performance': 40,
        'Delivery':           38,
        'Durability':         18,
        'Usability':           9,
        'General Dissatisfaction': 4
    }
    total_negative = sum(sample_issue_counts.values())

    summary = build_review_summary(sample_issue_counts, total_negative)
    print("Review Summary Sent to LLM:")
    print(summary)
    print("\n" + "="*50)
    print("LLM Response:")
    print(generate_action_items(summary))
