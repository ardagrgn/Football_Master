
# Football Master

Target: Aim to make accurate betting on a football match about resulting over 2.5 goals.




## Used Technologies

**Languages:** Python, SQL

**Libraries:** Numpy , Pandas, Requests, Sklearn, Xgboost

  
## Project Flow

This project created on CRISP-DM methodology:

- EDA: Previously downloaded data analysed according to following criterias:
    -  Data provider's data qualty and which columns to be used.
    -  Which football leagues to be choosed.
    -  Possible features to be generated.
- Data Collection: The data downloaded and updated regularly via api calls from the data provider (Api-Football).
- Data Preperation(Python): From downloaded datas a datamart created for machine learning step:
    
    - Features created from match statistics and events for each team.
    - A teams last 5 matches  features/perfomance aggregated for current the current match.
    - Teams' standings for each league/season/played day created and binary features created from it.
    - Most recent stading features added for given team's current match.
    
- Data Preperation(SQL): Same data preperation steps followed in order to show sql skills 
    - sql files order:
        - matches_to_play.sql 
        - stats.sql
        - events.sql
        - standings.sql
        - datamart.sql

- Modelling: A python class created for running, comparing, saving selected ml algorithm and recording each algorithm performance.

    Two target distrubitions are used:
    - Binomial Distrubition: 
        - From goal outcome of match, binary outcome created according being over 2.5 goals
        - For binary outcome, sklearn's LogisticRegression, RandomForrectClassifier, DecisionTreeClassifier models used.
    - Poisson Distrubition:
        - For count outcome, XGboost's GBtree algorithm used with poisson objective.
    
    Two feature selection strategy used: 
    - Plotting distrubitions: Each feature distrubitions according to target variables examined and selected manually.
    - Automated feature selection: Each feature evaluated with statistical test (F-test or Chi-Square).

- Inference/Evaluation: 
    - Best performed models or their ensemble combinations evaluated with past data.
    - According to the evaluation, prediction made for upcoming matches with selected algorithms.
