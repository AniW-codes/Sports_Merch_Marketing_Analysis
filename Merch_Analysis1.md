# Sports Merchandise Marketing Analytics Portfolio Project

## Project Overview

**Project Title**: Sports Merchandise Marketing Analytics Portfolio Project 

**Level**: Advanced

**Database**: `PortforlioProject_MarketingAnalysis`


![Sport_merch](https://github.com/AniW-codes/Sports_Merch_Marketing_Analysis/blob/main/apparel_display.jpg)

## Introduction to Business Problem

**ShopEasy**, an online retail sports merch business, is facing reduced customer engagement and conversion rates despite launching several new online marketing campaigns. They are reaching out to you to help conduct a detailed analysis and identify areas for improvement in their marketing strategies.

**Key Points**:
Reduced Customer Engagement: The number of customer interactions and engagement with the site and marketing content has declined.
Decreased Conversion Rates: Fewer site visitors are converting into paying customers.
High Marketing Expenses: Significant investments in marketing campaigns are not yielding expected returns.
Need for Customer Feedback Analysis: Understanding customer opinions about products and services is crucial for improving engagement and conversions.

## Key Performance Indicators (KPIs) to assess:
1. **Conversion Rate**: Percentage of website visitors who make a purchase.
2. **Customer Engagement Rate**: Level of interaction with marketing content (clicks, likes, comments).
3. **Average Order Value (AOV)**: Average amount spent by a customer per transaction.
4. **Customer Feedback Score**: Average rating from customer reviews.

## Goals
1. **Increase Conversion Rates**:
Goal: Identify factors impacting the conversion rate and provide recommendations to improve it.
Insight: Highlight key stages where visitors drop off and suggest improvements to optimize the conversion funnel.
2. **Enhance Customer Engagement**:
Goal: Determine which types of content drive the highest engagement. 
Insight: Analyze interaction levels with different types of marketing content to inform better content strategies.
3. **Improve Customer Feedback Scores**:
Goal: Understand common themes in customer reviews and provide actionable insights.
Insight: Identify recurring positive and negative feedback to guide product and service improvements.


- **Database Creation**: Restore a database named `PortforlioProject_MarketingAnalysis`.
- **Data refinement for Power BI and Sentimental analysis**: Setup queries and resultant tables for use to be extracted into Power BI to generate viz and extract csv for sentimental analysis using Python.

```sql

select * from customer_journey

select * from customer_reviews

select * from customers

select * from engagement_data

select * from geography

select * from products

------------
--Price Classification
------------
select ProductID,
		ProductName,
		Price,
		CASE
			When Price < 50 then 'Low'
			When Price between 50 and 200 then 'Medium'
			else 'High'
		END as Product_Price_Classification
from products

------------
--Enrich customer data with geographical data
------------

select CustomerID,
		CustomerName,
		Email,
		Gender,
		Age,
		Country,
		City
from customers
	left join geography
		on customers.GeographyID = geography.GeographyID

------------
--Cleaning column in Cust Review to make a better reading of it for sentimental analysis in python
------------

select ReviewID,
		CustomerID,
		ProductID,
		ReviewDate,
		Rating,
		REPLACE(ReviewText, '  ',' ') as ReviewText
from customer_reviews

------------
--Cleaning engagement data which would be beneficial for analysis in PowerBI later on.
------------

select EngagementID,
		ContentID,
		CampaignID,
		ProductID,
		Upper(REPLACE(ContentType, 'socialmedia', 'Social Media')) as ContentType,
		LEFT(ViewsClicksCombined,CHARINDEX('-',ViewsClicksCombined)-1) as Views,
		RIGHT(ViewsClicksCombined, len(ViewsClicksCombined) - CHARINDEX('-',ViewsClicksCombined)) as Clicks,
		Likes,
		FORMAT(CONVERT(DATE, EngagementDate), 'dd.MM.yyyy') AS EngagementDate  -- Converts and formats the date as dd.mm.yyyy
from engagement_data
where ContentType != 'newsletter'


------------
--Cleaning duplicates in engagement table and fixing NULL values in duration column
------------

--Verification of null values in the DB.

With CTE_Engagement_Duplicates as
(select 
	JourneyID,
	CustomerID,
	ProductID,
	VisitDate,
	Stage,
	Action,
	Duration,
	ROW_NUMBER() Over(Partition by CustomerID,ProductID,VisitDate,Stage,Action 
						Order by JourneyID) as row_num
from customer_journey

)

Select * 
from CTE_Engagement_Duplicates
	where row_num = 1
	order by JourneyID


--Getting rid of all the null values and duplicates in this query to upload in PowerBI.


SELECT JourneyID,
		CustomerID,
		ProductID,
		VisitDate,
		Stage,
		Action,
		COALESCE(Duration, avg_Duration) as Duration
FROM
(select JourneyID,
		CustomerID,
		ProductID,
		VisitDate,
		UPPER(Stage) as Stage,
		Action,
		Duration, 
		AVG(Duration) Over(Partition by VisitDate Order by JourneyID) as avg_Duration,
		ROW_NUMBER() Over(Partition by CustomerID,ProductID,VisitDate, UPPER(Stage), Action Order by JourneyID) as row_num
from customer_journey) as t1
			WHERE row_num = 1


```

### 2. Establishing relationships within Power BI 

![Sport_merch](https://github.com/AniW-codes/Sports_Merch_Marketing_Analysis/blob/main/Relationships.png)


- **Establish MEASURES for dashboard using DAX in Power BI**:

```DAX

1. **Avg Rating** = AVERAGE(fact_customer_reviews_with_sentiment[Rating])
   
2. **Clicks** = SUM(fact_engagement_data[Clicks])

3. **Conversion Rate** = 

VAR TotalVisitors = CALCULATE(COUNT(fact_customer_journey[JourneyID]),fact_customer_journey[Action]="View")
VAR TotalPurchases = CALCULATE(
    COUNT(fact_customer_journey[JourneyID]),
    fact_customer_journey[Action] = "Purchase"
)
RETURN
IF(
    TotalVisitors = 0,
    0,
    DIVIDE(TotalPurchases,TotalVisitors)
)

4. **Likes** = SUM(fact_engagement_data[Likes])
   
5. **No of Campaigns** = DISTINCTCOUNT(fact_engagement_data[CampaignID])

6. **No of Customer Journeys** = DISTINCTCOUNT(fact_customer_journey[JourneyID])

7. **No of Customer Reviews** = DISTINCTCOUNT(fact_customer_reviews_with_sentiment[ReviewID])
   
8. **Views** = SUM(fact_engagement_data[Views])

9. **Calendar** = 
ADDCOLUMNS (
    
    CALENDAR ( DATE ( 2023, 1, 1 ), DATE ( 2025, 12, 31 ) ),
    "DateAsInteger", FORMAT ( [Date], "YYYYMMDD" ),
    "Year", YEAR ( [Date] ),
    "Monthnumber", FORMAT ( [Date], "MM" ),
    "YearMonthnumber", FORMAT ( [Date], "YYYY/MM" ),
    "YearMonthShort", FORMAT ( [Date], "YYYY/mmm" ),
    "MonthNameShort", FORMAT ( [Date], "mmm" ),
    "MonthNameLong", FORMAT ( [Date], "mmmm" ),
    "DayOfWeekNumber", WEEKDAY ( [Date] ),
    "DayOfWeek", FORMAT ( [Date], "dddd" ),
    "DayOfWeekShort", FORMAT ( [Date], "ddd" ),
    "Quarter", "Q" & FORMAT ( [Date], "Q" ),
    "YearQuarter",
        FORMAT ( [Date], "YYYY" ) & "/Q"
            & FORMAT ( [Date], "Q" )
)

```

**Extracting Sentimental analysis as a CSV in customer reviews table**

```{python}

# pip install pandas nltk pyodbc sqlalchemy

import pandas as pd
import pyodbc
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer


# Download the VADER lexicon for sentiment analysis if not already present.
nltk.download('vader_lexicon')

# Define a function to fetch data from a SQL database using a SQL query
def fetch_data_from_sql():
    # Define the connection string with parameters for the database connection
    conn_str = (
        "Driver={SQL Server};"  # Specify the driver for SQL Server
        "Server=aniruddha-waran;"  # Specify your SQL Server instance
        "Database=PortfolioProject_MarketingAnalytics;"  # Specify the database name
        "Trusted_Connection=yes;" # Use Windows Authentication for the connection
    )
    # Establish the connection to the database
    conn = pyodbc.connect(conn_str)
    
    # Define the SQL query to fetch customer reviews data
    query = "SELECT ReviewID, CustomerID, ProductID, ReviewDate, Rating, ReviewText FROM customer_reviews"
    
    # Execute the query and fetch the data into a DataFrame
    df = pd.read_sql(query, conn)
    
    # Close the connection to free up resources
    conn.close()
    
    # Return the fetched data as a DataFrame
    return df

# Fetch the customer reviews data from the SQL database
customer_reviews_df = fetch_data_from_sql()

# Initialize the VADER sentiment intensity analyzer for analyzing the sentiment of text data
sia = SentimentIntensityAnalyzer()

# Define a function to calculate sentiment scores using VADER
def calculate_sentiment(review):
    # Get the sentiment scores for the review text
    sentiment = sia.polarity_scores(review)
    # Return the compound score, which is a normalized score between -1 (most negative) and 1 (most positive)
    return sentiment['compound']

# Define a function to categorize sentiment using both the sentiment score and the review rating
def categorize_sentiment(score, rating):
    # Use both the text sentiment score and the numerical rating to determine sentiment category
    if score > 0.05:  # Positive sentiment score
        if rating >= 4:
            return 'Positive'  # High rating and positive sentiment
        elif rating == 3:
            return 'Mixed Positive'  # Neutral rating but positive sentiment
        else:
            return 'Mixed Negative'  # Low rating but positive sentiment
    elif score < -0.05:  # Negative sentiment score
        if rating <= 2:
            return 'Negative'  # Low rating and negative sentiment
        elif rating == 3:
            return 'Mixed Negative'  # Neutral rating but negative sentiment
        else:
            return 'Mixed Positive'  # High rating but negative sentiment
    else:  # Neutral sentiment score
        if rating >= 4:
            return 'Positive'  # High rating with neutral sentiment
        elif rating <= 2:
            return 'Negative'  # Low rating with neutral sentiment
        else:
            return 'Neutral'  # Neutral rating and neutral sentiment

# Define a function to bucket sentiment scores into text ranges
def sentiment_bucket(score):
    if score >= 0.5:
        return '0.5 to 1.0'  # Strongly positive sentiment
    elif 0.0 <= score < 0.5:
        return '0.0 to 0.49'  # Mildly positive sentiment
    elif -0.5 <= score < 0.0:
        return '-0.49 to 0.0'  # Mildly negative sentiment
    else:
        return '-1.0 to -0.5'  # Strongly negative sentiment

# Apply sentiment analysis to calculate sentiment scores for each review
customer_reviews_df['SentimentScore'] = customer_reviews_df['ReviewText'].apply(calculate_sentiment)

# Apply sentiment categorization using both text and rating
customer_reviews_df['SentimentCategory'] = customer_reviews_df.apply(
    lambda row: categorize_sentiment(row['SentimentScore'], row['Rating']), axis=1)

# Apply sentiment bucketing to categorize scores into defined ranges
customer_reviews_df['SentimentBucket'] = customer_reviews_df['SentimentScore'].apply(sentiment_bucket)

# Display the first few rows of the DataFrame with sentiment scores, categories, and buckets
print(customer_reviews_df.head())

# Save the DataFrame with sentiment scores, categories, and buckets to a new CSV file
customer_reviews_df.to_csv('fact_customer_reviews_with_sentiment.csv', index=False)


```

The code above will generate a .csv file 

![Sport_merch](https://github.com/AniW-codes/Sports_Merch_Marketing_Analysis/blob/main/Sentimental.png)


The .csv file is then uploaded onto Power BI server to generate actionable insights based on reviews, ratings and sentimental category, which can be observed in the video attached on LinkedIn post.


## Summary Reports:

Based on outcomes observed from insights, certain actions are suggested to enhance Customer engagement on social media posts, improve customer ratings and increase conversion rates.

**Increase Conversion Rates**:
Target High-Performing Product Categories: Focus marketing efforts on products with demonstrated high conversion rates, such as Hockey Sticks, Ski Boots, and Baseball Gloves. Implement seasonal promotions or personalized campaigns during peak months (e.g., January and September) to capitalize on these trends.

**Enhance Customer Engagement**:
Revitalize Content Strategy: To turn around declining views and low interaction rates, experiment with more engaging content formats, such as interactive videos or user-generated content. 
Additionally, boost engagement by optimizing call-to-action placement in social media and blog content, particularly during historically lower-engagement months (September-December).

**Improve Customer Feedback Scores**:
Address Mixed and Negative Feedback: Implement a feedback loop where mixed and negative reviews are analyzed to identify common issues. Develop improvement plans to address these concerns. Consider following up with dissatisfied customers to resolve issues and encourage re-rating, aiming to move average ratings closer to the 4.0 target.


## Conclusion

This project demonstrates the application of SQL and Python skills in marketing analysis of sports merchandise throughout different times of the year. It also showcases my skills to manipulate and manage data to arrive at actionable insights for the marketing and customer experience teams. 

## Author - Aniruddha Warang

- **LinkedIn**: [Connect with me professionally](https://www.linkedin.com/in/aniruddhawarang/)

Thank you for your interest in this project!
