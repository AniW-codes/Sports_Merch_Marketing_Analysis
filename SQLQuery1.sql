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

