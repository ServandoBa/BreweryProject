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
	--Is_active categorization
	CASE
		WHEN type ILIKE '%Closed%' THEN 'No'
		ELSE 'Yes'
	END is_active,
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


