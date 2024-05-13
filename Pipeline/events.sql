with main as  (

--Interested events of given fixture selected.
select  
case 
	when detail in ('Own Goal', 'Penalty')
	then 'Normal Goal'
	else detail 
end detail , -- Own goal and penalties are rare in normal season game. So they will be treated as normal goal.

case
	when 0<="time.elapsed" and "time.elapsed" <=15
	then '1st_Quarter'
	when 16<="time.elapsed" and "time.elapsed"<=30
	then '2nd_Quarter'
	when 31<="time.elapsed" and "time.elapsed"<=45
	then '3rd_Quarter'
	when 46<="time.elapsed" and "time.elapsed"<=60
	then '4th_Quarter'
	when 61<="time.elapsed" and "time.elapsed"<=75
	then '5th_Quarter'
	else '6th_Quarter' 
	
end time_intervals, -- Total played time divided into 6 equal time intervals 
  "team.id",
 "team.name","fixture.id",
 1 occurance -- Created for counting given event
from "Football".fixture_event_df
where detail in ('Yellow Card', 'Red Card','Normal Goal', 'Own Goal', 'Penalty') -- Events of interest
)
,

normal_event as (
		--Normal events for recording selected teams own events.
		select m."fixture.id", "team.id",
		
		--Each event records become event columns.
		sum(case when '1st_Quarter_Normal Goal' = time_intervals || '_' || detail then occurance
			 else 0 end)"1st_Quarter_Normal Goal",
		sum(case when '1st_Quarter_Red Card' = time_intervals || '_' || detail then occurance
			 else 0 end )  "1st_Quarter_Red Card",
		sum(case when '1st_Quarter_Yellow Card' = time_intervals || '_' || detail then occurance
			 else 0 end ) "1st_Quarter_Yellow Card",
		sum(case when '2nd_Quarter_Normal Goal' = time_intervals || '_' || detail then occurance
			 else 0 end )  "2nd_Quarter_Normal Goal",
		sum(case when '2nd_Quarter_Red Card' = time_intervals || '_' || detail then occurance
			 else 0 end )  "2nd_Quarter_Red Card" ,
		sum(case when '2nd_Quarter_Yellow Card' = time_intervals || '_' || detail then occurance
			 else 0 end ) "2nd_Quarter_Yellow Card" ,
		sum(case when '3rd_Quarter_Normal Goal' = time_intervals || '_' || detail then occurance
			 else 0 end )  "3rd_Quarter_Normal Goal" ,
		sum(case when '3rd_Quarter_Red Card' = time_intervals || '_' || detail then occurance
			 else 0  end )  	"3rd_Quarter_Red Card" ,
		sum(case when '3rd_Quarter_Yellow Card' = time_intervals || '_' || detail then occurance
			 else 0 end )  	"3rd_Quarter_Yellow Card" ,
		sum(case when '4th_Quarter_Normal Goal'  = time_intervals || '_' || detail then occurance
			 else 0 end )   "4th_Quarter_Normal Goal" ,
		sum(case when '4th_Quarter_Red Card' = time_intervals || '_' || detail then occurance
			 else 0 end )	"4th_Quarter_Red Card" ,
		sum(case when '4th_Quarter_Yellow Card' = time_intervals || '_' || detail then occurance
			 else 0 end )	"4th_Quarter_Yellow Card" ,
		sum(case when '5th_Quarter_Normal Goal' = time_intervals || '_' || detail then occurance
			 else 0 end )  	"5th_Quarter_Normal Goal" ,
		sum(case when '5th_Quarter_Red Card' = time_intervals || '_' || detail then occurance
			 else 0 end )	"5th_Quarter_Red Card" ,
		sum(case when '5th_Quarter_Yellow Card' = time_intervals || '_' || detail then occurance
			 else 0 end )	"5th_Quarter_Yellow Card" ,
		sum(case when '6th_Quarter_Normal Goal' = time_intervals || '_' || detail then occurance
			 else 0 end )	"6th_Quarter_Normal Goal" ,
		sum(case when '6th_Quarter_Red Card' = time_intervals || '_' || detail then occurance
			 else 0  end)	"6th_Quarter_Red Card"  ,
		sum(case when '6th_Quarter_Yellow Card'  = time_intervals || '_' || detail then occurance
			 else 0 end )  "6th_Quarter_Yellow Card" 
		

from main m
group by m."fixture.id","team.id")



,concieved as (
		--Concieved events for recording events performed by oppose team againts the selected team 
		
		select     m."fixture.id",       
				  case 
					when "team.id"= "teams.home.id"
					then "teams.away.id"
					else "teams.home.id"
				  end con_team,
	 	  "1st_Quarter_Normal Goal" "1st_Quarter_Normal Goal Concieved" ,
	 	  "2nd_Quarter_Normal Goal" "2nd_Quarter_Normal Goal Concieved",
	 	  "3rd_Quarter_Normal Goal"  "3rd_Quarter_Normal Goal Concieved",
	 	  "4th_Quarter_Normal Goal"  "4th_Quarter_Normal Goal Concieved",
	 	  "5th_Quarter_Normal Goal"  "5th_Quarter_Normal Goal Concieved",
	 	  "6th_Quarter_Normal Goal"  "6th_Quarter_Normal Goal Concieved",
	 	  
	 	   "1st_Quarter_Red Card" "1st_Quarter_Red Card Concieved",
	 	   "2nd_Quarter_Red Card"  "2nd_Quarter_Red Card Concieved" ,
	 	   "3rd_Quarter_Red Card" "3rd_Quarter_Red Card Concieved",
	 	   "4th_Quarter_Red Card" "4th_Quarter_Red Card Concieved" ,
	 	   "5th_Quarter_Red Card"  "5th_Quarter_Red Card Concieved" ,
	 	   "6th_Quarter_Red Card" "6th_Quarter_Red Card Concieved" ,
	 	   
		    "1st_Quarter_Yellow Card" "1st_Quarter_Yellow Card Concieved",
		    "2nd_Quarter_Yellow Card" "2nd_Quarter_Yellow Card Concieved" ,
		    "3rd_Quarter_Yellow Card" "3rd_Quarter_Yellow Card Concieved" ,
		    "4th_Quarter_Yellow Card" "4th_Quarter_Yellow Card Concieved" ,
		    "5th_Quarter_Yellow Card" "5th_Quarter_Yellow Card Concieved" ,
		    "6th_Quarter_Yellow Card" "6th_Quarter_Yellow Card Concieved" 
		    

from normal_event m

join "Football".saved_fixtures sf 
on sf."fixture.id"=m."fixture.id")

, merged_final as (
				 --Merging team's own and concieved events at given fixture.
				  select row_number() over (partition by  
				  							sf."league.id",sf."league.season",
										    fix."team.id" order by "fixture.date") Sıra , -- Match order of  the team in given season.
				   sf."league.id",sf."league.season", 
					cast(substring("fixture.date",0,11) as Date) fixture_date,
					fix."fixture.id", fix."team.id",
					
					-- Empty event columns filled with 0
					coalesce("1st_Quarter_Normal Goal",0) "1st_Quarter_Normal Goal",
					coalesce("1st_Quarter_Normal Goal Concieved",0) "1st_Quarter_Normal Goal Concieved" ,
				 	  coalesce("2nd_Quarter_Normal Goal",0) "2nd_Quarter_Normal Goal",
				 	  coalesce("2nd_Quarter_Normal Goal Concieved",0) "2nd_Quarter_Normal Goal Concieved",
				 	  coalesce("3rd_Quarter_Normal Goal",0) "3rd_Quarter_Normal Goal", 
				 	  coalesce("3rd_Quarter_Normal Goal Concieved",0) "3rd_Quarter_Normal Goal Concieved",
				 	  coalesce("4th_Quarter_Normal Goal",0) "4th_Quarter_Normal Goal",
				 	  coalesce("4th_Quarter_Normal Goal Concieved",0) "4th_Quarter_Normal Goal Concieved",
				 	  coalesce("5th_Quarter_Normal Goal",0) "5th_Quarter_Normal Goal", 
				 	  coalesce("5th_Quarter_Normal Goal Concieved",0) "5th_Quarter_Normal Goal Concieved",
				 	  coalesce ("6th_Quarter_Normal Goal",0) "6th_Quarter_Normal Goal",
				 	  coalesce("6th_Quarter_Normal Goal Concieved",0) "6th_Quarter_Normal Goal Concieved",
				 	  
				 	   coalesce("1st_Quarter_Red Card",0) "1st_Quarter_Red Card", 
				 	   coalesce("1st_Quarter_Red Card Concieved",0) "1st_Quarter_Red Card Concieved" ,
				 	   coalesce("2nd_Quarter_Red Card",0) "2nd_Quarter_Red Card",
				 	   coalesce("2nd_Quarter_Red Card Concieved",0) "2nd_Quarter_Red Card Concieved" ,
				 	   coalesce("3rd_Quarter_Red Card",0) "3rd_Quarter_Red Card",
				 	   coalesce("3rd_Quarter_Red Card Concieved",0) "3rd_Quarter_Red Card Concieved",
				 	   coalesce("4th_Quarter_Red Card",0) "4th_Quarter_Red Card",
				 	   coalesce("4th_Quarter_Red Card Concieved",0) "4th_Quarter_Red Card Concieved",
				 	   coalesce("5th_Quarter_Red Card",0) "5th_Quarter_Red Card",
				 	   coalesce("5th_Quarter_Red Card Concieved",0) "5th_Quarter_Red Card Concieved"  ,
				 	   coalesce("6th_Quarter_Red Card",0) "6th_Quarter_Red Card",
				 	   coalesce("6th_Quarter_Red Card Concieved",0) "6th_Quarter_Red Card Concieved" ,
				 	   
					    coalesce("1st_Quarter_Yellow Card",0) "1st_Quarter_Yellow Card",
					    coalesce("1st_Quarter_Yellow Card Concieved",0) "1st_Quarter_Yellow Card Concieved" ,
					    coalesce("2nd_Quarter_Yellow Card",0) "2nd_Quarter_Yellow Card",
					    coalesce("2nd_Quarter_Yellow Card Concieved",0) "2nd_Quarter_Yellow Card Concieved" ,
					    coalesce("3rd_Quarter_Yellow Card",0) "3rd_Quarter_Yellow Card",
					    coalesce("3rd_Quarter_Yellow Card Concieved",0) "3rd_Quarter_Yellow Card Concieved" ,
					    coalesce("4th_Quarter_Yellow Card",0) "4th_Quarter_Yellow Card",
					    coalesce("4th_Quarter_Yellow Card Concieved") "4th_Quarter_Yellow Card Concieved",
					    
					    coalesce("5th_Quarter_Yellow Card",0) "5th_Quarter_Yellow Card",
					    coalesce("5th_Quarter_Yellow Card Concieved",0) "5th_Quarter_Yellow Card Concieved",
					    coalesce("6th_Quarter_Yellow Card",0) "6th_Quarter_Yellow Card",
					    coalesce("6th_Quarter_Yellow Card Concieved",0) "6th_Quarter_Yellow Card Concieved" 

from (select distinct "fixture.id","team.id"
	  from "Football".fixture_stat) fix
join "Football".saved_fixtures sf -- Fixture infos from main fixture table.
on sf."fixture.id" = fix."fixture.id"
left join normal_event ne         -- Normal events
on fix."fixture.id"= ne."fixture.id" and 
   fix."team.id"= ne."team.id"
left join concieved con           -- Concieved events
on fix."fixture.id"= con."fixture.id" and 
   fix."team.id"=con.con_team
   )

 select
 		-- Given team's mean of  last 5 match events' count.
 		a."league.id",a."league.season",a."fixture_date",
 		a."fixture.id",a."team.id",
 		AVG(m."1st_Quarter_Normal Goal") "1st_Quarter_Normal Goal", 
 		AVG(m."1st_Quarter_Normal Goal Concieved") "1st_Quarter_Normal Goal Concieved",
	 	  AVG(m."2nd_Quarter_Normal Goal") "2nd_Quarter_Normal Goal", 
	 	  AVG (m."2nd_Quarter_Normal Goal Concieved") "2nd_Quarter_Normal Goal Concieved",
	 	  AVG(m."3rd_Quarter_Normal Goal") "3rd_Quarter_Normal Goal",
	 	  AVG(m."3rd_Quarter_Normal Goal Concieved") "3rd_Quarter_Normal Goal Concieved",
	 	  AVG(m."4th_Quarter_Normal Goal") "4th_Quarter_Normal Goal",  
	 	  AVG(m."4th_Quarter_Normal Goal Concieved") "4th_Quarter_Normal Goal Concieved",
	 	  AVG(m."5th_Quarter_Normal Goal") "5th_Quarter_Normal Goal",  
	 	  AVG(m."5th_Quarter_Normal Goal Concieved") "5th_Quarter_Normal Goal Concieved",
	 	  AVG(m."6th_Quarter_Normal Goal") "6th_Quarter_Normal Goal" ,
	 	  AVG(m."6th_Quarter_Normal Goal Concieved") "6th_Quarter_Normal Goal Concieved",
	 	   AVG(m."1st_Quarter_Red Card") "1st_Quarter_Red Card",
	 	   AVG(m."1st_Quarter_Red Card Concieved") "1st_Quarter_Red Card Concieved",
	 	   AVG(m."2nd_Quarter_Red Card") "2nd_Quarter_Red Card",  
	 	   AVG(m."2nd_Quarter_Red Card Concieved") "2nd_Quarter_Red Card Concieved",
	 	   AVG(m."3rd_Quarter_Red Card") "3rd_Quarter_Red Card", 
	 	   AVG(m."3rd_Quarter_Red Card Concieved") "3rd_Quarter_Red Card Concieved",
	 	   AVG(m."4th_Quarter_Red Card") "4th_Quarter_Red Card" ,
	 	   AVG(m."4th_Quarter_Red Card Concieved") "4th_Quarter_Red Card Concieved",
	 	   AVG(m."5th_Quarter_Red Card") "5th_Quarter_Red Card",
	 	   AVG(m."5th_Quarter_Red Card Concieved") "5th_Quarter_Red Card Concieved",
	 	   AVG(m."6th_Quarter_Red Card") "6th_Quarter_Red Card",
	 	   AVG(m."6th_Quarter_Red Card Concieved") "6th_Quarter_Red Card Concieved",
	 	   
		    AVG(m."1st_Quarter_Yellow Card")  "1st_Quarter_Yellow Card",
		    AVG(m."1st_Quarter_Yellow Card Concieved") "1st_Quarter_Yellow Card Concieved",
		    AVG(m."2nd_Quarter_Yellow Card") "2nd_Quarter_Yellow Card", 
		    AVG(m."2nd_Quarter_Yellow Card Concieved") "2nd_Quarter_Yellow Card Concieved",
		    AVG(m."3rd_Quarter_Yellow Card") "3rd_Quarter_Yellow Card",
		    AVG(m."3rd_Quarter_Yellow Card Concieved") "3rd_Quarter_Yellow Card Concieved",
		    AVG(m."4th_Quarter_Yellow Card") "4th_Quarter_Yellow Card Concieved" ,
		    AVG(m."5th_Quarter_Yellow Card") "5th_Quarter_Yellow Card",
		    AVG(m."5th_Quarter_Yellow Card Concieved") "5th_Quarter_Yellow Card Concieved",
		    AVG(m."6th_Quarter_Yellow Card") "6th_Quarter_Yellow Card", 
		    AVG(m."6th_Quarter_Yellow Card Concieved") "6th_Quarter_Yellow Card Concieved"
 into "Football".event_lagged	
 from merged_final a
 join merged_final m
 on a."league.id"= m."league.id" and 
 	a."league.season"= m."league.season" and
 	a."team.id" = m."team.id" and
 	cast(a.sıra as integer)> cast (m.sıra as integer) and
 	cast(a.sıra-5 as integer)<=cast(m.sıra as integer)
 group by a."league.id",a."league.season",a."fixture_date",
 		a."fixture.id",a."team.id"
 
   