with played_fixtures as (

--Played fixtures selected.
select "fixture.id",cast(substring("fixture.date",0,11) as Date) fixture_date,
		substring("fixture.date",12,8) fixture_stat_time,
		"league.id","league.season","league.name","league.country",
		"league.round","teams.home.id","teams.home.name", "teams.home.winner",
		"teams.away.id","teams.away.name","teams.away.winner",
		"goals.home","goals.away", 
		case when "teams.home.winner"='True' 
			 then 3
			 when "teams.home.winner"='False'
			 then 0 
			 else 1
			 end home_point, --Point collected BY the home team
		
		case when "teams.away.winner"='True' 
			 then 3
			 when "teams.away.winner"='False'
			 then 0 
			 else 1
			 end away_point --Point collected BY the away team
	
from "Football".saved_fixtures sf 

where 
	  "fixture.status.short"='FT' -- Selecting Finished matches
	  and not ("league.country" in ('World','Europe','USA','Czech-Republic') ) -- exclude leagues with inconsistent data
	  and substring("league.round",0,15)='Regular Season' -- only regular season matches.
)

, self_stat as (

--Atack statistics of teams.
select "league.id","league.season",
		fs."fixture.id","fixture_date",
        "teams.away.id", "teams.home.id",
		"team.id" team_id,"team.name",
		case 
	         when "team.id"="teams.home.id" 
			 then 1
			 else 0
			 end Home, --The team's home status.
		case 
			 when "statistics.Fouls"=''
			 then 0 
			 else cast("statistics.Fouls" as real)
			 end Foul, 
	   "statistics.Corner Kicks" Corner_Kicks,
	   COALESCE ("statistics.Offsides",0) Offsides, 
	    coalesce ("statistics.Yellow Cards",0) Yellow_Cards,
	    coalesce("statistics.Red Cards",0) Red_Cards, "statistics.Total passes" Total_Passes,
	   case 
	   		when left("statistics.Ball Possession",-1)=''
	   		then 0
	   		else cast(left("statistics.Ball Possession",-1)as integer)
	   end ball_possession_rate, --Changes the format from string to integer. ex: '40%' to 40
	   case 
		   when "statistics.Total passes"= 0 or "statistics.Total passes" is null
		   then 0
		   else coalesce("statistics.Passes accurate",0)/"statistics.Total passes"
	   end accurate_pass_rate,
	   "statistics.Total Shots" Total_Shot, 
	    case when (coalesce("statistics.Total Shots",0)- coalesce("statistics.Blocked Shots",0))=0
	    	 then   0
	    	 else coalesce("statistics.Shots on Goal",0)/(coalesce("statistics.Total Shots",0)- coalesce("statistics.Blocked Shots",0))
	    end Shot_On_Goal_Rate,
	    case 
	    	when "statistics.Total Shots"=0  or  "statistics.Total Shots" is null
	    	then 0
	    	else  "statistics.Shots insidebox"/"statistics.Total Shots" 
	    end Inside_Box_Shot_Rate,
	   case when "statistics.Blocked Shots" is null 
	    	 then   "statistics.Total Shots"
	    	 else "statistics.Total Shots"- "statistics.Blocked Shots"
	    	 end Total_Free_Shot,
	    "statistics.Goalkeeper Saves"
from "Football".fixture_stat fs
join  played_fixtures pf  
on pf."fixture.id"= fs."fixture.id")

, oppose_stat as (

--Defending statistics of teams.
select fs."fixture.id", 
	   case when "team.id"="teams.home.id"
	   		then "teams.away.id"
	   		else "teams.home.id"
	   		end team_id,
	   coalesce ("statistics.Offsides",0) trapped_offside,
	   
	   case when "statistics.Total passes" is null or "statistics.Total passes"=0
	   		then 0
	   		else ("statistics.Total passes"-"statistics.Passes accurate")/"statistics.Total passes" 
	   		end Pass_Forced_To_Fail,
	   
	   case when "statistics.Total Shots" is null or  "statistics.Total Shots"=0
	   		then 0 
	   		else coalesce("statistics.Blocked Shots",0)/"statistics.Total Shots"
	   		end Blocked_Shot_Rate,
	   "statistics.Total Shots" Total_Shot_Opp_Given,
	   case when "statistics.Total Shots" is null or "statistics.Total Shots"=0
	   		then 0
			else "statistics.Shots insidebox"/"statistics.Total Shots" 
	        end Inside_Box_Shot_Opp_Given,
	   "statistics.Shots on Goal"
	   
	   
from "Football".fixture_stat fs
join  played_fixtures pf  
on pf."fixture.id"= fs."fixture.id"
)


,merged as (

--Merging teams' atack and defend statistics.
select cast("league.id" as integer),cast ("league.season"as integer),
		cast(s."fixture.id" as integer), 
		fixture_date, "teams.away.id", "teams.home.id",
	   cast(s.team_id as integer), "team.name", home, 
	   foul, corner_kicks,offsides,
	   yellow_cards,red_cards, total_passes, ball_possession_rate,
	   accurate_pass_rate, total_shot, shot_on_goal_rate,
	   inside_box_shot_rate, total_free_shot, 
	   case when cast("statistics.Shots on Goal" as integer) =0 or "statistics.Shots on Goal" is null
	   		then 0
	   		else	coalesce("statistics.Goalkeeper Saves",0)/cast("statistics.Shots on Goal" as integer) 
	   		end goal_saved_rate ,
	   trapped_offside, pass_forced_to_fail, blocked_shot_rate,
	   total_shot_opp_given , inside_box_shot_opp_given,
	   row_number() over (partition by s.team_id,
							  "league.id","league.season" 
							  order by fixture_date) sıra --Match order of each team AT given season.
		

from self_stat  s
join oppose_stat o 
on o."fixture.id"=s."fixture.id" and 
   o.team_id=s.team_id
)


--The teams last 4 match average of fixture statistics.
select o."league.id", o."league.season", 
	   o.team_id, o.fixture_date, o."fixture.id",
	   AVG(s.foul) fouls, AVG(s.corner_kicks) corner_kicks,
	   AVG(s.offsides) offsides, AVG(s.yellow_cards) yellow_cards,
	   AVG(s.red_cards) red_cards, avg(s.total_passes) total_passes,
	   avg(s.baLL_possession_rate)  baLL_possession_rate,
	   avg(s.accurate_pass_rate) accurate_pass_rate,
	   avg(s.total_shot) total_shot, avg(s.shot_on_goal_rate) shot_on_goal_rate,
	   avg(s.inside_box_shot_rate) inside_box_shot_rate,
	   avg(s.total_free_shot) total_free_shot, 
	   avg(s.goal_saved_rate) goal_saved_rate,
	   avg(s.trapped_offside) trapped_offside,
	   avg(s.pass_forced_to_fail) pass_forced_to_fail,
	   avg(s.blocked_shot_rate) blocked_shot_rate,
	   avg(s.total_shot_opp_given) total_shot_opp_given,
	   avg(s.inside_box_shot_opp_given) inside_box_shot_opp_given
into "Football".Lagged_Fixture_Stats
from  merged s
join merged o 
on o."league.id"= s."league.id" and 
   o."league.season"= s."league.season" and 
   o.team_id= s.team_id and 
   o.sıra> s.sıra and 
   o.sıra-5<s.sıra
group by o."league.id", o."league.season", o.team_id, o.fixture_Date,o."fixture.id";





