import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

random.seed(42)
np.random.seed(42)

OUTPUT_DIR = "/home/claude/myntra_dataset"
MYNTRA_RAW = "/mnt/user-data/uploads/myntra_dataset_ByScraping.csv"

INDIAN_CITIES = [
    ("Mumbai", "Maharashtra"), ("Delhi", "Delhi"), ("Bengaluru", "Karnataka"),
    ("Hyderabad", "Telangana"), ("Chennai", "Tamil Nadu"), ("Kolkata", "West Bengal"),
    ("Pune", "Maharashtra"), ("Ahmedabad", "Gujarat"), ("Jaipur", "Rajasthan"),
    ("Lucknow", "Uttar Pradesh"), ("Surat", "Gujarat"), ("Kanpur", "Uttar Pradesh"),
    ("Nagpur", "Maharashtra"), ("Indore", "Madhya Pradesh"), ("Bhopal", "Madhya Pradesh"),
    ("Patna", "Bihar"), ("Vadodara", "Gujarat"), ("Coimbatore", "Tamil Nadu"),
    ("Kochi", "Kerala"), ("Bhubaneswar", "Odisha")
]

CAMPAIGN_IDS = [f"CAMP_{i:03d}" for i in range(1, 11)]
CONTENT_TYPES_CLEAN = ["Blog", "SocialMedia", "Video", "Newsletter"]
STAGES_CLEAN = ["Homepage", "ProductPage", "Checkout", "Purchase"]

REVIEW_TEMPLATES_POS = [
    "Amazing quality! Totally worth the price.",
    "Fast delivery and great packaging.",
    "Loved the fabric and the fit. Will buy again.",
    "Fits perfectly. Very happy with the purchase.",
    "Excellent product. Myntra never disappoints.",
    "Great value for money. Highly recommend.",
    "Beautiful design. Exactly as shown in the photo.",
    "Super comfortable jeans. Bought in two colours.",
    "Perfect fit. The material feels premium.",
    "Delivery was quick and product is exactly as described.",
]
REVIEW_TEMPLATES_NEG = [
    "Quality is below average. Not what I expected.",
    "Delivery was very late. Poor experience.",
    "Size runs small. Return process is very difficult.",
    "The color faded after first wash. Very disappointing.",
    "Product looks different from the photo online.",
    "Customer support was unhelpful when I raised an issue.",
    "Stitching came off within a week. Terrible quality.",
    "The jeans are too tight at the waist. Sizing is off.",
    "Material feels cheap. Not worth the price at all.",
    "Received a damaged product. Very unhappy.",
]
REVIEW_TEMPLATES_MID = [
    "Decent product but could be better for the price.",
    "Average quality. Nothing special about it.",
    "Okay product. Expected more based on the description.",
    "Not bad but not great either. Fits okay.",
    "Material is fine but the colour is slightly different.",
]

def generate_products():
    df = pd.read_csv(MYNTRA_RAW)
    df = df.dropna()

    def get_category(desc):
        d = desc.lower()
        if 'jogger' in d or 'cargo' in d: return 'Joggers & Cargo'
        elif 'bootcut' in d or 'wide leg' in d or 'flare' in d: return 'Wide Leg & Bootcut'
        elif 'slim' in d or 'skinny' in d: return 'Slim Fit Jeans'
        elif 'relaxed' in d or 'loose' in d or 'anti fit' in d: return 'Relaxed Fit Jeans'
        elif 'regular' in d or 'straight' in d: return 'Regular Fit Jeans'
        elif 'stretchable' in d or 'stretch' in d: return 'Stretchable Jeans'
        else: return 'Denim & Jeans'

    df['Category'] = df['pants_description'].apply(get_category)
    sampled = df.drop_duplicates(subset=['brand_name', 'Category']).head(50).reset_index(drop=True)

    products = pd.DataFrame({
        "ProductID": range(1, len(sampled) + 1),
        "ProductName": sampled["pants_description"].values,
        "Brand": sampled["brand_name"].values,
        "Category": sampled["Category"].values,
        "Price": sampled["price"].round(2).values,
        "MRP": sampled["MRP"].round(2).values,
        "DiscountPercent": sampled["discount_percent"].round(1).values,
        "AvgRating": sampled["ratings"].values,
        "NumberOfRatings": sampled["number_of_ratings"].astype(int).values
    })
    return products

def generate_customers(n=500):
    names_male = ["Aarav","Rohan","Vikram","Arjun","Karan","Rahul","Aditya","Siddharth","Nikhil","Pranav","Akash","Vishal","Raj","Dev","Amit"]
    names_female = ["Priya","Sneha","Ananya","Kavya","Divya","Riya","Pooja","Isha","Nisha","Simran","Aditi","Meera","Sakshi","Tanya","Anjali"]
    surnames = ["Sharma","Verma","Patel","Gupta","Singh","Kumar","Joshi","Mehta","Shah","Rao","Nair","Reddy","Iyer","Das","Mishra"]
    rows = []
    for i in range(1, n+1):
        gender = random.choice(["Male","Female"])
        first = random.choice(names_male if gender=="Male" else names_female)
        last = random.choice(surnames)
        city, state = random.choice(INDIAN_CITIES)
        signup_date = datetime(2021,1,1) + timedelta(days=random.randint(0,730))
        rows.append({
            "CustomerID": i,
            "CustomerName": f"{first} {last}",
            "Age": random.randint(18,55),
            "Gender": gender,
            "City": city,
            "State": state,
            "Email": f"{first.lower()}.{last.lower()}{i}@email.com",
            "MembershipType": random.choice(["Bronze","Silver","Gold","Platinum"]),
            "SignupDate": signup_date.date()
        })
    return pd.DataFrame(rows)

def generate_geography():
    rows = []
    for i,(city,state) in enumerate(INDIAN_CITIES,1):
        rows.append({
            "GeographyID": i, "City": city, "State": state,
            "Region": ("North" if state in ["Delhi","Uttar Pradesh","Rajasthan","Punjab","Bihar"]
                       else "South" if state in ["Karnataka","Tamil Nadu","Kerala","Telangana","Andhra Pradesh"]
                       else "West" if state in ["Maharashtra","Gujarat"]
                       else "East")
        })
    return pd.DataFrame(rows)

def generate_customer_journey(customers_df, products_df, n=4000):
    stage_variants = {
        "Homepage":    ["Homepage","homepage","HOMEPAGE"],
        "ProductPage": ["ProductPage","productpage","PRODUCTPAGE"],
        "Checkout":    ["Checkout","checkout","CHECKOUT"],
        "Purchase":    ["Purchase","purchase","PURCHASE"]
    }
    action_variants = {
        "View":      ["View","view","VIEW"],
        "Click":     ["Click","click","CLICK"],
        "AddToCart": ["AddToCart","addtocart","ADDTOCART"],
        "Purchase":  ["Purchase","purchase","PURCHASE"],
        "Drop-off":  ["Drop-off","drop-off","DROP-OFF"]
    }
    customer_ids = customers_df["CustomerID"].tolist()
    product_ids = products_df["ProductID"].tolist()
    start_date = datetime(2023,1,1)
    end_date = datetime(2024,12,31)
    rows = []
    journey_id = 1
    for _ in range(n-80):
        customer_id = random.choice(customer_ids)
        product_id = random.choice(product_ids)
        visit_date = start_date + timedelta(days=random.randint(0,(end_date-start_date).days))
        stage_clean = random.choice(STAGES_CLEAN)
        if stage_clean=="Homepage":
            action_clean = random.choices(["View","Click","Drop-off"],weights=[0.4,0.4,0.2])[0]
        elif stage_clean=="ProductPage":
            action_clean = random.choices(["View","Click","AddToCart","Drop-off"],weights=[0.3,0.3,0.2,0.2])[0]
        elif stage_clean=="Checkout":
            action_clean = random.choices(["AddToCart","Purchase","Drop-off"],weights=[0.2,0.3,0.5])[0]
        else:
            action_clean = "Purchase"
        stage = random.choices(stage_variants[stage_clean],weights=[0.7,0.15,0.15])[0]
        action = random.choices(action_variants[action_clean],weights=[0.7,0.15,0.15])[0]
        duration = None if action_clean=="Drop-off" else round(random.uniform(10,600),1)
        rows.append({"JourneyID":journey_id,"CustomerID":customer_id,"ProductID":product_id,
                     "VisitDate":visit_date.date(),"Stage":stage,"Action":action,"Duration":duration})
        journey_id += 1
    dupe_sources = random.sample(rows[:500],80)
    for dupe in dupe_sources:
        new_row = dupe.copy()
        new_row["JourneyID"] = journey_id
        rows.append(new_row)
        journey_id += 1
    random.shuffle(rows)
    for idx,row in enumerate(rows,1):
        row["JourneyID"] = idx
    return pd.DataFrame(rows)

def generate_customer_reviews(customers_df, products_df, n=1400):
    customer_ids = customers_df["CustomerID"].tolist()
    product_ids = products_df["ProductID"].tolist()
    start_date = datetime(2023,1,1)
    end_date = datetime(2024,12,31)
    rows = []
    for i in range(1,n+1):
        rating = random.choices([1,2,3,4,5],weights=[0.08,0.07,0.10,0.25,0.50])[0]
        if rating>=4: base_text = random.choice(REVIEW_TEMPLATES_POS)
        elif rating==3: base_text = random.choice(REVIEW_TEMPLATES_MID)
        else: base_text = random.choice(REVIEW_TEMPLATES_NEG)
        if random.random()<0.4: base_text = f"  {base_text}  "
        if random.random()<0.3: base_text = base_text.replace(". ",".  ").replace(", ",",  ")
        review_date = start_date + timedelta(days=random.randint(0,(end_date-start_date).days))
        rows.append({"ReviewID":i,"CustomerID":random.choice(customer_ids),
                     "ProductID":random.choice(product_ids),"ReviewDate":review_date.date(),
                     "Rating":rating,"ReviewText":base_text})
    return pd.DataFrame(rows)

def generate_engagement_data(products_df, n=4500):
    content_variants = {
        "Blog":        ["Blog","blog","BLOG"],
        "SocialMedia": ["SocialMedia","socialmedia","SOCIALMEDIA"],
        "Video":       ["Video","video","VIDEO"],
        "Newsletter":  ["Newsletter","newsletter","NEWSLETTER"]
    }
    product_ids = products_df["ProductID"].tolist()
    start_date = datetime(2023,1,1)
    end_date = datetime(2024,12,31)
    rows = []
    for i in range(1,n+1):
        content_clean = random.choice(CONTENT_TYPES_CLEAN)
        content = random.choices(content_variants[content_clean],weights=[0.65,0.2,0.15])[0]
        views = random.randint(500,50000)
        clicks = random.randint(50,int(views*0.3))
        likes = random.randint(10,int(clicks*0.5))
        eng_date = start_date + timedelta(days=random.randint(0,(end_date-start_date).days))
        rows.append({"EngagementID":i,"ContentID":f"CONT_{i:05d}","ContentType":content,
                     "Likes":likes,"EngagementDate":eng_date.date(),"CampaignID":random.choice(CAMPAIGN_IDS),
                     "ProductID":random.choice(product_ids),"ViewsClicksCombined":f"{views}-{clicks}"})
    return pd.DataFrame(rows)

if __name__ == "__main__":
    print("Generating Myntra Consumer Intelligence Dataset")
    print("(Products grounded in real Myntra scraping data)")
    print("="*55)

    products  = generate_products()
    customers = generate_customers(500)
    geography = generate_geography()
    journey   = generate_customer_journey(customers, products, n=4000)
    reviews   = generate_customer_reviews(customers, products, n=1400)
    engagement= generate_engagement_data(products, n=4500)

    products.to_csv(f"{OUTPUT_DIR}/products.csv",   index=False)
    customers.to_csv(f"{OUTPUT_DIR}/customers.csv", index=False)
    geography.to_csv(f"{OUTPUT_DIR}/geography.csv", index=False)
    journey.to_csv(f"{OUTPUT_DIR}/customer_journey.csv",   index=False)
    reviews.to_csv(f"{OUTPUT_DIR}/customer_reviews.csv",   index=False)
    engagement.to_csv(f"{OUTPUT_DIR}/engagement_data.csv", index=False)

    print(f"✓ products           → {len(products)} rows | {products['Brand'].nunique()} brands | {products['Category'].nunique()} categories")
    print(f"✓ customers          → {len(customers):,} rows | SignupDate: {customers['SignupDate'].min()} → {customers['SignupDate'].max()}")
    print(f"✓ geography          → {len(geography)} rows")
    print(f"✓ customer_journey   → {len(journey):,} rows | NULLs: {journey['Duration'].isna().sum()} | Stage variants: {journey['Stage'].nunique()}")
    print(f"✓ customer_reviews   → {len(reviews):,} rows | Whitespace issues: {reviews['ReviewText'].str.startswith('  ').sum()} rows")
    print(f"✓ engagement_data    → {len(engagement):,} rows | ContentType variants: {engagement['ContentType'].nunique()}")
    print("\nAll 6 CSVs saved!")
    print("\nSample Real Myntra Products:")
    print(products[["ProductName","Brand","Category","Price","AvgRating"]].head(10).to_string(index=False))
