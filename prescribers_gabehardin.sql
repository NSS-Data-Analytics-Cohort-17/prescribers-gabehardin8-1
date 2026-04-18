-- 1. ANSWER COMMENTS --, THINKING COMMENTS --*,--**

--** fips counties can identify unique counties and remove country-wide duplicates

SELECT cbsa,cbsaname
FROM cbsa
GROUP BY cbsa,cbsaname

--** so are there 409 unique cbsa names with a one-to-many relationship to fipscounties?

SELECT * FROM cbsa;

SELECT * FROM drug;

SELECT * FROM fips_county;

SELECT * FROM overdose_deaths;

SELECT * FROM population;

SELECT * FROM prescriber;

SELECT * FROM prescription;

SELECT * FROM zip_fips;



--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi,total_claim_count
FROM prescription
ORDER BY total_claim_count DESC; -- claims: 4538, npi:1912011792 
  

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT nppes_provider_first_name,nppes_provider_last_org_name,specialty_description,total_claim_count
FROM prescription INNER JOIN prescriber 
	ON prescriber.npi=prescription.npi
ORDER BY total_claim_count DESC NULLS LAST

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description,SUM(total_claim_count)AS total_claims
FROM prescriber INNER JOIN prescription 
	ON prescription.npi=prescriber.npi
GROUP BY specialty_description
ORDER BY total_claims DESC;  -- Family Practice: 9752347

--     b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, opioid_drug_flag, SUM(total_claim_count)AS total_claims
FROM prescriber 
	INNER JOIN prescription ON prescription.npi=prescriber.npi
	INNER JOIN drug USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY total_claims DESC
LIMIT 1;                                                                -- Nurse Practitioner: 900845

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description
FROM prescriber LEFT JOIN prescription ON prescriber.npi = prescription.npi
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL; -- yes, 15

-- SELECT specialty_description, drug_name
-- FROM prescriber
-- 	LEFT JOIN prescription USING(npi)
-- -- WHERE is counteracting the LEFT JOIN
-- WHERE drug_name IS NULL 
-- GROUP BY specialty_description,prescription.drug_name;



--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. 
--Which specialties have a high percentage of opioids?

SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
	INNER JOIN prescription USING (npi)
GROUP BY specialty_description;

SELECT SUM(total_claim_count)
FROM drug
	INNER JOIN prescription USING(drug_name)


SELECT specialty_description, SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count ELSE 0)
FROM prescriber INNER JOIN prescription USING(npi)
				INNER JOIN drug USING(drug_name)

SELECT specialty_description, SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count ELSE 0 END) * 100.0 / SUM(total_claim_count)  > 0.5 AS opioid_percentage
FROM prescriber JOIN prescription ON prescriber.npi = prescription.npi
				JOIN drug ON prescription.drug_name = drug.drug_name
GROUP BY specialty_description
ORDER BY opioid_percentage DESC;

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost? --* is this asking for the highest sum of the column total drug cost? or the highest individual prescribed total drug cost?
SELECT generic_name, SUM(total_drug_cost) AS true_total_cost
FROM prescription
	INNER JOIN drug ON drug.drug_name=prescription.drug_name
GROUP BY generic_name
ORDER BY true_total_cost DESC;                   -- INSULIN GLARGINE,HUM.REC.ANLOG


--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**


SELECT generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2)::MONEY AS cost_per_day --* this doesn't make sense to me. Is the total day supply what they buy every day? oh, total_day_supply means the aggregate number of a days worth of that particular drug
FROM drug
	INNER JOIN prescription USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC
LIMIT 1;

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT drug_name,
    CASE 
        WHEN opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type
FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT SUM(total_drug_cost)::MONEY AS total_cost,drug_type
From(
	SELECT drug_name,
	    CASE 
	        WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	        ELSE 'neither'
	    END AS drug_type
	FROM drug)AS drug_type_table
INNER JOIN prescription ON drug_type_table.drug_name=prescription.drug_name
GROUP BY drug_type
	HAVING drug_type <> 'neither'
ORDER BY total_cost DESC;

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
--*cbsa: core based statistical areas: https://data.cms.gov/search?keywords=cbsa&sort=Relevancy
--*fips: federal information processing standards: https://legalclarity.org/what-is-a-fips-code-and-how-are-they-used/

SELECT cbsaname
FROM cbsa
	INNER JOIN fips_county USING (fipscounty)
WHERE state = 'TN'
GROUP BY cbsaname; -- 10 total CBSA's in TN

-- *there are multiple counties per cbsaname, so i think i need to group by cbsaname.

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname,SUM(population)AS combined_population
FROM cbsa 
	INNER JOIN population USING (fipscounty)
GROUP BY cbsaname
--*ORDER BY ensures sql is pulling more than just the top row
ORDER BY combined_population DESC; -- Largest is Nashville-Davidson--Murfreesboro--Franklin, TN: 1830410   , smallest is Morristown, TN: 116352

--* i think this is showing the min and max population of a given cbsa name. so the min and max for two different instances of Chatt TN-GA. but why are there multiple instances?
	--* do i somehow need to find the sum of population for these instances and then find the highest one?
SELECT *
FROM cbsa
	INNER JOIN population USING (fipscounty)
	INNER JOIN fips_county USING (fipscounty)
	--* seems like a cbsa can span multiple couties
	

--*trying to check my answers with this query
SELECT cbsaname,population
FROM cbsa 
	INNER JOIN population USING (fipscounty)
	INNER JOIN fips_county USING (fipscounty)
WHERE state = 'TN'
GROUP BY cbsaname,population
--* got confused when i had multiple cbsa names with different populations

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
--*first, what counties aren't in a CBSA?
SELECT county,population AS total_county_population
FROM fips_county 
	LEFT JOIN cbsa USING(fipscounty)
-- 2nd, add population
	LEFT JOIN population USING(fipscounty)
WHERE cbsa IS NULL
GROUP BY county, total_county_population
ORDER BY total_county_population DESC NULLS LAST
LIMIT 1; -- Sevier county has a population of 95,523
--*If a region has to be 10k to be considered a cbsa, then why am I getting SEVIER county with a population of 95523? Census Bureau supports the population being around 100,000 in 2025


-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name,total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
--* what is an instance? 

SELECT drug_name,
CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN opioid_drug_flag = 'N' THEN 'not opioid'
END AS drug_type,total_claim_count
FROM prescription 
	INNER JOIN drug USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;


--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
--* am I trying to join on columns instead of tables?
SELECT nppes_provider_first_name,nppes_provider_last_org_name,drug_name,
CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN opioid_drug_flag = 'N' THEN 'not opioid'
END AS drug_type,total_claim_count
FROM prescription 
	INNER JOIN drug USING(drug_name)
--* makes sense to start off by joining the prescriber table
	INNER JOIN prescriber USING(npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

SELECT 
CONCAT(nppes_provider_first_name,' ',nppes_provider_last_org_name)
drug_name,
CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN opioid_drug_flag = 'N' THEN 'not opioid'
END AS drug_type,total_claim_count
FROM prescription 
	INNER JOIN drug USING(drug_name)
--* makes sense to start off by joining the prescriber table
	INNER JOIN prescriber USING(npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

	
-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi,drug_name
FROM prescriber
CROSS JOIN drug
WHERE nppes_provider_city= 'NASHVILLE' 
	AND specialty_description = 'Pain Management'
	AND opioid_drug_flag= 'Y'

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi,drug_name,COUNT(total_claim_count)AS claims_per_drug_per_prescriber
FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription USING(drug_name)
WHERE nppes_provider_city= 'NASHVILLE' 
	AND specialty_description = 'Pain Management'
	AND opioid_drug_flag= 'Y'
GROUP BY prescriber.npi, drug_name
ORDER BY claims_per_drug_per_prescriber DESC; --* looks like i did it a different way, probably need to check before submitting ASK CHRIS!
	
--     c. fFinally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.