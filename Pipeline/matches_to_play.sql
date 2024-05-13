
--This script aims to select soonest unplayed fixture
WITH home AS (

--Home teams' incoming fixtures.
SELECT SUBSTR("fixture.date",0,10) fixture_date, 
		"fixture.id","league.season",
		"league.id","teams.home.id",
		"teams.away.id","teams.home.id" team_id,
		1 Home 
FROM "Football".saved_fixtures sf
WHERE "fixture.status.long"= 'Not Started'
)

,away AS (

--Away teams' incoming fixtures.
SELECT SUBSTR("fixture.date",0,10) fixture_date, 
		"fixture.id","league.season",
		"league.id","teams.home.id",
		"teams.away.id", "teams.away.id" team_id,
		0 Home 
FROM "Football".saved_fixtures sf 
WHERE "fixture.status.long"= 'Not Started'
)

,table1 AS (

--Home teams and away teams joined vertically
SELECT *FROM home 
UNION 
SELECT *FROM away 
)

,table2 AS (
SELECT u.*, 
	 ROW_NUMBER() OVER( PARTITION BY TEAM_ID ORDER BY FIXTURE_DATE) AS RN 
FROM table1 u )

,table3 AS (

-- Selecting each team's first incoming match
SELECT * 
FROM table2
WHERE RN=1)


SELECT  

-- Fixture with 2 records means that
	--both teams in the fixture had played their matches.
 FIXTURE_DATE,t."fixture.id",
	 "league.season", "league.id",
	 "teams.home.id","teams.away.id",
	 TEAM_ID,HOME
into "Football".Matches_to_play
FROM table3 t
JOIN (SELECT "fixture.id" 
      FROM table3
	  GROUP BY "fixture.id"
	  HAVING count(*)==2) f 
ON f."fixture.id"= t."fixture.id" 

select * from "Football".matches_to_play mtp 


