with table1 as (
		-- Dividing home and away records, joining them vertically for creating a unified team record.
		
		--Away fixtures
		select  cast(substring("fixture.date",0,11) as Date) fixture_date,
		"league.country","league.id","league.name", 
		"league.season","teams.away.id" team_id,
		
		case 
			when "goals.away">"goals.home"
			then 3
			when "goals.away"="goals.home"
			then 1
			when "goals.away" is null 
			then null
			else 0
		end point,
		"goals.away"-"goals.home" average, -- (goals -  concieved goals) of away team
		1 match_played-- played match count
		
		from "Football".saved_fixtures sf 
		union
		
		--Home fixtures		
		select  cast(substring("fixture.date",0,11) as Date) fixture_date,
				"league.country","league.id","league.name", 
				"league.season","teams.home.id" team_id,
				
				case 
					when "goals.home">"goals.away"
					then 3
					when "goals.away"="goals.home"
					then 1
					when "goals.home" is null 
					then null
					else 0
				end point,
				"goals.home"-"goals.away" average, -- (goals -  concieved goals) of home team
				1 match_played -- played match count
				
		from "Football".saved_fixtures sf )


, table2 as (select  
					  -- For each played fixture date in given season and leagues. There will be standing table.
					  t."league.season", t."league.id",
			 		  t.team_id,d.fixture_date,
			 		  sum(coalesce(t1.average,0)) over 
			 		  (partition by t."league.season",t."league.id", t.team_id 
			 		   order by d.fixture_date)
			 		  average, -- cumsum of averages of given team within each season.
			 		  sum(coalesce(t1.match_played,0)) over 
			 		  (partition by t."league.season",t."league.id", t.team_id 
			 		   order by d.fixture_date) match_played, --  played match count of given team within each season.
			 		  sum(coalesce(t1.point,0)) over 
			 		  (partition by t."league.season",t."league.id", t.team_id 
			 		   order by d.fixture_date) point -- cumsum of points of given team within each season.
 			from (select distinct "league.season","league.id",
 						team_id
	   			  from table1) t --each team in given season and league
			join (select distinct "league.season", "league.id",
								  fixture_date
				  from table1) d -- each played fixture date in given season and league.
			on t."league.season"=d."league.season" and
			   t."league.id"= d."league.id"
			
			left join  table1 t1 -- main table added for corresponding team's info of given date.
			on t."league.season"= t1."league.season" and
			   t."league.id"= t1."league.id" and 
			   t.team_id= t1.team_id and 
			   d.fixture_date= t1.fixture_date
			   
			order by "league.season", "league.id", "fixture_date", "team_id"
			)
			
,rank_table as ( --Teams ordered and ranked according to cumulatif points acquired at given date.

					 select * , 
					 row_number() over
					 (partition by "league.season","league.id",
					 			   fixture_date 
					  order by point desc ,average desc) rank -- rank of team at given date.
				from table2
				order by "league.season","league.id",fixture_date  ,point DESC, average  desc
				)
,rank_diff as (
				-- Point diff of selected team according one above and one bellow.
				-- Played match count difference is  taked into account, in order to express actual point need.
				select r.*, r_p.point- r.point + (r.match_played-r_p.match_played)*3 up_point_diff,
							d_p.point- r.point + (r.match_played-d_p.match_played)*3 down_point_diff,
							min_rank
				from rank_table r --main teams rank info 
				left join rank_table r_p --above teams rank info 
				on r."league.season"=r_p."league.season" and 
				   r."league.id"= r_p."league.id" and 
				   r.fixture_date= r_p.fixture_date and 
				   r."rank"= r_p."rank"+1
				
				left join rank_table d_p  --below teams rank info 
				on r."league.season"=d_p."league.season" and 
				   r."league.id"= d_p."league.id" and 
				   r.fixture_date= d_p.fixture_date and 
				   r."rank"= d_p."rank"-1
				left join ( select "league.season", "league.id", max(rank) min_rank 
							from rank_table
							group by  "league.season", "league.id" ) m -- minimum rank of given season stated in order to create point need and possition columns
				on r."league.season"= m."league.season" and
				   r."league.id"=m."league.id" 
				   )

   
select *,  
	  case
	  	when "rank"=1 
	  	then 'title'
	  	when 1<"rank" and "rank"<=3
	  	then 'first_2_3'
	  	when 4<="rank" and "rank"<=6
	  	then 'first_4_6'
	  	when 7<="rank" and "rank"<= min_rank-3
	  	then 'middle'
	  	when min_rank-2<="rank" and "rank" <= min_rank-1
	  	then 'last_2_3'
	  	else 'last'
	  end  Rank_Name, --Rank possition
	  
	  case 
	  	when up_point_diff is null 
	  	then 'top'
	  	when up_point_diff<=0
	  	then '1_point_needed'
	  	when 0<up_point_diff and up_point_diff<=3
	  	then '3_point_for_catch'
	  	else '3_point_for_chase'
	  	 
	  end Rise_need, -- Point info for catching/passing above
	  
	  case
	  	when down_point_diff is null 
	  	then 'bottom'
	  	when down_point_diff>-3
	  	then '3_point_for_run'
	  	when down_point_diff=-3
	  	then '1_point_for_run'
	  	else 'comfort'
	  end Fall_Prevent --  Point info for running/not catch bellow
	  
into "Football".teams_rank	  
	  
from rank_diff


