# BreweryProject
## **Business Understanding**

**Context:** A national brewery group requires to visualize last year’s performance regarding financial and operational overview in order to make decisions based on data. 

**Assess situation:** At the moment, there are just 2 Excel files with the breweries' information. These files have general information about the facilities, therefore, it could be difficult to break down the information thoroughly.  

**Stakeholders:** C-Executives, Directors and Regional Managers.

**Tools:** 
- Data wrangling: PostgreSQL
- Data visualization: Tableau

## **Data Understanding**

<details>
<Summary> Datasets description </Summary>
	
**- Breweries - Original dataset**
<br>  
| Column       | Data type | Description                            | Comments |
| :---         | :---      | :---                                   | :---     |
| Brewery_key  | Integer   | Brewery id                             | PK       |
| Brewery_name | String    | Location name                          | - Create condensed list |
| Type         | String    | Business_type                          |          |
| Website      | String    | Location website                       |          |
| Address      | String    | Location address                       | - Create zip code and city column |
| State        | String    | State in which the location is located | - Remove unwanted strings |

<br>

**- Brewery_data - Original dataset**

| Column       | Data type  | Description                 | Comments |
| :---         | :---       | :---                        | :---     |
| Brewery_key  | Integer    | Brewery id                  | PK       |
| Costs        | Float      | COGS (Cost of goods sold)   | 	     |
| Sales        | Float      | Income                      |          |
| Employees    | Integer    | Headcount                   |          |
| Barrels      | Integer    | Number of sold barrels      |          |

<br>

**- Regional list - _This dataset was retrieved from a website in order to complement the information and moving forward can display better views of the data._**

| Column       | Data type | Description        | Comments |
| :---         | :---      | :---               | :---     |
| Abbreviation | String    | State abbreviation | PK       |
| State_name   | String    | State name   	| 	   |
| Region       | String    | Region name        |          |

</details>

<br>

<details>

<Summary> Metrics table </Summary>
<br>	
After have gone over the Excel files, below you will find the KPIs that can be put into the dashboard to show insightful operational and financial metrics.

| Metric      		        | Logic 				  |
| :---           	        | :---     	   			  |
| Revenue        		| SUM(sales)    			  |
| Sold barrels 			| SUM(barrels)           		  |
| Costs      		   	| SUM(costs)       			  |
| Breweries count      	   	| COUNT(brewery_id)       		  |
| Gross profit      	   	| Revenue - Costs      			  |
| Gross profit ratio  	   	| Gross profit / Revenue      		  |
| Gross profit per barrel   	| Gross profit / Barrels      		  |
| Breweries in Negative GP      | COUNT(brewery_id) WHERE gross_profit < 0 |
| Expenses per employee      	| Costs / employees         		  |
| Employees      		| SUM(employees)         		  |

</details>
	
<br>

## Data Preparation

This section is the most important in the process. It is very probable that if you don't clean your data correctly, you will have garbage in your model so there will be garbage out. 

### **Transform**

The transformation and cleaning process was developed in PostgreSQL. Below, you will find the script used to transform the data from the Breweries data file. This transformation was carried out to obtain support columns such as Business Type, Zip Code, State, and City in a usable format.

**Business_type mapping**

| Type      		   | Business_type |
| :---           	   | :---     	   |
| BOP-BrewOnPremise        | BOP      	   |
| BOP-BrewOnPremise-Closed | BOP           |
| Brewpub      		   | Brewpub       |
| Brewpub-Closed      	   | Brewpub       |
| ContractBrewery      	   | Contract      |
| Contract      	   | Contract      |
| ContractBrewery-Closed   | Contract      |
| Microbrewery      	   | Micro         |
| Mircobrewery      	   | Micro         |
| Microbrewery-Closed      | Micro         |
| MultitapBar      	   | Multitap      |
| RegionalBrewery      	   | Regional      |


</br>

**PostgreSQL code**


```
--Transform state column to match it with Region list later on
UPDATE brewery
SET state = INITCAP(REPLACE(state, '-', ' '));

SELECT 
	b.brewery_key, 
	brewery_name, 
	type,
	--Business_type categorization
	CASE
		WHEN type IN ('BOP-BrewOnPremise', 'BOP-BrewOnPremise-Closed') THEN 'BOP'
		WHEN type IN ('Brewpub', 'Brewpub-Closed') THEN 'Brewpub'
		WHEN type IN ('ContractBrewery', 'Contract', 'ContractBrewery-Closed') THEN 'Contract'
		WHEN type IN ('Microbrewery', 'Mircobrewery', 'Microbrewery-Closed') THEN 'Micro'
		WHEN type IN ('RegionalBrewery') THEN 'Regional'
		WHEN type IN ('MultitapBar') THEN 'Multitap'
		ELSE 'Other'
	END business_type,
	website,
	address, 
	--Zipcode extraction
	CASE
		WHEN (TRIM(REVERSE(split_part(REVERSE(address), ',', 1))) ~* '[^0-9]') IS TRUE THEN NULL
		ELSE TRIM(REVERSE(split_part(REVERSE(address), ',', 1)))
	END AS zipcode,
	b.state,
	region,
	--City extraction
	CASE 
		WHEN array_length(string_to_array(address, ','), 1) = 1 THEN NULL
		WHEN array_length(string_to_array(address, ','), 1) = 2 THEN (string_to_array(address, ','))[1]
		WHEN (array_length(string_to_array(address, ','), 1) = 3) AND ((TRIM(REVERSE(split_part(REVERSE(address), ',', 1))) ~* '[0-9]') IS TRUE) 
			THEN INITCAP(TRIM((string_to_array(address, ','))[1]))
		WHEN (array_length(string_to_array(address, ','), 1) = 3) AND ((TRIM(REVERSE(split_part(REVERSE(address), ',', 1))) ~* '[a-z]') IS TRUE) 
			AND ((TRIM(REVERSE(split_part(REVERSE(address), ',', 2))) ~* '[0-9]') IS TRUE) 
			THEN INITCAP(TRIM((string_to_array(address, ','))[3]))
		WHEN (array_length(string_to_array(address, ','), 1) = 3) AND ((TRIM(REVERSE(split_part(REVERSE(address), ',', 1))) ~* '[a-z]') IS TRUE) 
			THEN INITCAP(TRIM((string_to_array(address, ','))[2]))
		WHEN (array_length(string_to_array(address, ','), 1) = 4) AND ((TRIM(REVERSE(split_part(REVERSE(address), ',', 1))) ~* '[0-9]') IS TRUE) 
			THEN INITCAP(TRIM((string_to_array(address, ','))[2]))
		WHEN (array_length(string_to_array(address, ','), 1) = 5) AND ((TRIM(REVERSE(split_part(REVERSE(address), ',', 1))) ~* '[0-9]') IS TRUE) 
			THEN INITCAP(TRIM((string_to_array(address, ','))[3]))
		WHEN (array_length(string_to_array(address, ','), 1) = 6) AND ((TRIM(REVERSE(split_part(REVERSE(address), ',', 1))) ~* '[0-9]') IS TRUE) 
			THEN INITCAP(TRIM((string_to_array(address, ','))[4]))
	END city,
	costs,
	sales,
	employees,
	barrels
FROM brewery b
LEFT JOIN brewery_data bdata ON b.brewery_key = bdata.brewery_key
LEFT JOIN regions r ON b.state = r.state_name

```

Once the data was prepared for the presentation, it was uploaded to Tableau to create the dashboard. There are 2 views, the Executive dashboard and the Regional dashboard. Each view has a different level of detail in order to show relevant metrics measuring financial and operational performance across the multiple breweries.

</br></br>

## Data Visualization
**Comments**

The following dashboard shows the company’s performance on a national level, showcasing various KPIs presented in different breakdowns. It’s evident that the company didn’t generate gross profit last year due to high costs. Despite the West region showing a high sales volume with a third part of total revenue and a positive gross margin ratio, greater profits couldn’t be attained due to underperforming regions, namely Southwest and Southeast. In despite of strong performance in Microbreweries with a gross profit of 8.3 million dollars, brewpub breweries incurred a total loss of 6.8 million dollars, resulting in an almost negligible profit margin. Unfortunately, the collected information didn’t provide a breakdown of costs to pinpoint the reason for this behavior. Nevertheless, I recommend implementing a strategy to thoroughly analyze the states generating 80% of sales with the aim of optimizing profits.

**Executive dashboard**


![Dashboard - General overview](https://github.com/ServandoBa/BreweryProject/assets/131488634/748a750d-94be-4bbc-949d-6afc5be9d4e8)

**Regional dashboard**


![Dashboard - Regional Overview](https://github.com/ServandoBa/BreweryProject/assets/131488634/0ff5d9ec-2265-458d-8624-5962ebf1bb1f)


## **References**

**Region list**

_Mappr. (n.d.). 5 US Regions Map and Facts. https://www.mappr.co/political-maps/us-regions-map/_

**Breweries information research**

_Brewers Association. (n.d.). Craft Beer Industry Market Segments - Brewers Association. https://www.brewersassociation.org/statistics-and-data/craft-beer-industry-market-segments/_





