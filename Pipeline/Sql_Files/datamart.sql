

with table1 as (
		-- Events and statistics features merged for each home and away team.
		select  sf."fixture.id", cast(substring("fixture.date",0,11) as Date) fixture_date,
		sf."league.id", sf."league.name",sf."league.country", sf."league.season",
		"teams.home.name", "teams.home.id",
		"teams.away.id", "teams.away.name", "goals.home", "goals.away",
		
		hfs.fouls home_fouls, hfs.corner_kicks home_corner,
		hfs.offsides home_offsides, hfs.yellow_cards home_yellow_cards,
		hfs.red_cards home_red_cards, hfs.total_passes home_total_passes,
		hfs.ball_possession_rate home_ball_possession_rate,
		hfs.accurate_pass_rate home_accurate_pass_rate,
		hfs.total_shot home_total_shot, hfs.shot_on_goal_rate home_shot_on_goal_rate,
		hfs.inside_box_shot_rate home_inside_box_shot_rate,
		hfs.total_free_shot home_total_free_shot, hfs.goal_saved_rate home_goal_saved_rate,
		hfs.trapped_offside home_trapped_offside, hfs.pass_forced_to_fail home_pass_forced_to_fail,
		hfs.blocked_shot_rate home_blocked_shot_rate, 
		hfs.total_shot_opp_given home_total_shot_opp_given,
		hfs.inside_box_shot_opp_given home_inside_box_shot_opp_given,
		
		afs.fouls away_fouls, afs.corner_kicks away_corner,
		afs.offsides away_offsides, afs.yellow_cards away_yellow_cards,
		afs.red_cards away_red_cards, afs.total_passes away_total_passes,
		afs.ball_possession_rate away_ball_possession_rate,
		afs.accurate_pass_rate away_accurate_pass_rate,
		afs.total_shot away_total_shot, afs.shot_on_goal_rate away_shot_on_goal_rate,
		afs.inside_box_shot_rate away_inside_box_shot_rate,
		afs.total_free_shot away_total_free_shot, afs.goal_saved_rate away_goal_saved_rate,
		afs.trapped_offside away_trapped_offside, afs.pass_forced_to_fail away_pass_forced_to_fail,
		afs.blocked_shot_rate away_blocked_shot_rate, 
		afs.total_shot_opp_given away_total_shot_opp_given,
		afs.inside_box_shot_opp_given away_inside_box_shot_opp_given,
		
		hel."1st_Quarter_Normal Goal" "1st_Quarter_Normal Goal_Home",
		hel."1st_Quarter_Normal Goal Concieved" "1st_Quarter_Normal Goal Concieved_Home",
		hel."2nd_Quarter_Normal Goal" "2nd_Quarter_Normal Goal_Home",
		hel."2nd_Quarter_Normal Goal Concieved" "2nd_Quarter_Normal Goal Concieved_Home",
		hel."3rd_Quarter_Normal Goal" "3rd_Quarter_Normal Goal_Home",
		hel."3rd_Quarter_Normal Goal Concieved" "3rd_Quarter_Normal Goal Concieved_Home",
		hel."4th_Quarter_Normal Goal" "4th_Quarter_Normal Goal_Home",
		hel."4th_Quarter_Normal Goal Concieved" "4th_Quarter_Normal Goal Concieved_Home",
		hel."5th_Quarter_Normal Goal" "5th_Quarter_Normal Goal_Home",
		hel."5th_Quarter_Normal Goal Concieved" "5th_Quarter_Normal Goal Concieved_Home",
		hel."6th_Quarter_Normal Goal" "6th_Quarter_Normal Goal_Home",
		hel."6th_Quarter_Normal Goal Concieved" "6th_Quarter_Normal Goal Concieved_Home",
		
		ael."1st_Quarter_Normal Goal" "1st_Quarter_Normal Goal_Away",
		ael."1st_Quarter_Normal Goal Concieved" "1st_Quarter_Normal Goal Concieved_Away",
		ael."2nd_Quarter_Normal Goal" "2nd_Quarter_Normal Goal_Away",
		ael."2nd_Quarter_Normal Goal Concieved" "2nd_Quarter_Normal Goal Concieved_Away",
		ael."3rd_Quarter_Normal Goal" "3rd_Quarter_Normal Goal_Away",
		ael."3rd_Quarter_Normal Goal Concieved" "3rd_Quarter_Normal Goal Concieved_Away",
		ael."4th_Quarter_Normal Goal" "4th_Quarter_Normal Goal_Away",
		ael."4th_Quarter_Normal Goal Concieved" "4th_Quarter_Normal Goal Concieved_Away",
		ael."5th_Quarter_Normal Goal" "5th_Quarter_Normal Goal_Away",
		ael."5th_Quarter_Normal Goal Concieved" "5th_Quarter_Normal Goal Concieved_Away",
		ael."6th_Quarter_Normal Goal" "6th_Quarter_Normal Goal_Away",
		ael."6th_Quarter_Normal Goal Concieved" "6th_Quarter_Normal Goal Concieved_Away"
		
		
 from  "Football".saved_fixtures sf


join "Football".lagged_fixture_stats  hfs --Fixture stats for home teams
on hfs."fixture.id"=  sf."fixture.id" and 
   cast(hfs.team_id as integer)= sf."teams.home.id"


join "Football".lagged_fixture_stats  afs --Fixture stats for away teams
on afs."fixture.id"=  sf."fixture.id" and 
   cast(afs.team_id as integer)= sf."teams.away.id"

join "Football".event_lagged   hel      -- Fixture events for home teams
on hel."fixture.id"=  sf."fixture.id" and 
   cast(hel."team.id" as integer)= sf."teams.home.id"

join "Football".event_lagged   ael     --  Fixture events for away teams
on ael."fixture.id"=  sf."fixture.id" and 
   cast(ael."team.id" as integer)= sf."teams.away.id"
   )
   

 
, per_rank as (
			   --Rank date of given team at most recent to fixture to be predict.
			   select tr."league.season", tr."league.id",
	   				  tr.team_id,tr."fixture_date", max(pr.fixture_date) rank_date
			   from "Football".teams_rank tr 

				join "Football".teams_rank pr
				
				on  tr."league.season"= pr."league.season" and
					tr."league.id"= pr."league.id" and 
					tr.team_id= pr.team_id and 
					tr.fixture_date> pr.fixture_date
				
				group by tr."league.season", tr."league.id",
					   tr.team_id,tr."fixture_date"
				   )

--Rank features of each home and away teams merged to main data.
select t1.*,tr.rank_name home_rank_name,
	   tr.rise_need home_rise_need,
	   tr.fall_prevent home_fall_prevent,
	   tr1.rank_name away_rank_name,
	   tr1.rise_need away_rise_need,
	   tr1.fall_prevent away_fall_prevent
into "Football".Datamart
from table1 t1

join per_rank hpr -- Home rank date
on hpr."league.season"= t1."league.season" and 
   hpr."league.id"= t1."league.id" and 
   hpr.team_id= t1."teams.home.id" and 
   hpr.fixture_date=t1.fixture_date

join "Football".teams_rank tr -- Home rank features
on  hpr."league.season"= tr."league.season" and 
	hpr."league.id"= tr."league.id" and 
	hpr.team_id= tr.team_id and 
	hpr.rank_date=tr.fixture_date

join per_rank apr --Away rank date
on apr."league.season"= t1."league.season" and 
   apr."league.id"= t1."league.id" and 
   apr.team_id= t1."teams.away.id" and 
   apr.fixture_date=t1.fixture_date

join "Football".teams_rank tr1 --Away rank features.
on  apr."league.season"= tr1."league.season" and 
	apr."league.id"= tr1."league.id" and 
	apr.team_id= tr1.team_id and 
	apr.rank_date=tr1.fixture_date


	
	
