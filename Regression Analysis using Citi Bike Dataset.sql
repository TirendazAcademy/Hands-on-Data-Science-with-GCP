-- Linear Regression Analysis with Google BigQuery 

-- Linear regression is used to predict a continuous numerical value. 

-- You can find the relationship between the dependent and one or more explanatory variables wiht it.

/* 1. Creat a dataset */

-- Go to creat dataset

-- Enter a name let's say nyc_bike

-- Let's take a look at the citibike_trips dataset in bigquery-public-dataset.

-- The tripduration column is our target variable, which displays trip durations in seconds.

-- All the other columns are potential features.

-- Let's take a look at the other details.

-- Click on the Details tab.

-- You can see the rows and columns of the dataset in preview. 

/* 2. Exploring the dataset */

-- Let's focus on the Tripduration column and see how many values are empty or less than zero.

SELECT COUNT(*)
FROM
  `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE
  tripduration is NULL
  OR tripduration<=0;
  
-- As you can see, there are more than five million records where the tripduration field not properly valued.

/* 3. Creating the Datasets */

-- Let's create train, evaluation and test sets.

-- Let's create the train set first. 

CREATE OR REPLACE TABLE `nyc_bike.training_table` AS
-- Let's select the columns that will be used to train the model
SELECT 
	tripduration/60 tripduration,
	starttime,
	stoptime,
	start_station_id,
	start_station_name,
	start_station_latitude,
	start_station_longitude,
	end_station_id,
	end_station_name,
	end_station_latitude,
	end_station_longitude,
	bikeid,
	usertype,
	birth_year,
	gender,
	customer_plan
-- Let's get the dataset.
FROM
	`bigquery-public-data.new_york_citibike.citibike_trips`
WHERE 
	(
-- The extract method returns the value corresponding to the specified date part. 
-- Let's extract year and month and deal with 2018 years.
	(EXTRACT (YEAR FROM starttime)=2017 AND
-- Let's take the months from 1 to 10.
	(EXTRACT (MONTH FROM starttime)>=01 OR EXTRACT (MONTH FROM starttime)<=10))
	)
-- Let's specify rental time.
	AND (tripduration>=3*60 AND tripduration<=3*60*60)
--Finally let's deal with the birth_year column.
	AND  birth_year is not NULL
	AND birth_year < 2007;
	
-- Let's create the evaluation set and copy these codes and then modify these codes for evaluation set.


CREATE OR REPLACE TABLE `nyc_bike.evaluation_table` AS

SELECT 
	tripduration/60 tripduration,
	starttime,
	stoptime,
	start_station_id,
	start_station_name,
	start_station_latitude,
	start_station_longitude,
	end_station_id,
	end_station_name,
	end_station_latitude,
	end_station_longitude,
	bikeid,
	usertype,
	birth_year,
	gender,
	customer_plan

FROM
	`bigquery-public-data.new_york_citibike.citibike_trips`
WHERE 
	(
	-- Let's select only eleventh month.
	(EXTRACT (YEAR FROM starttime)=2017 AND
	(EXTRACT (MONTH FROM starttime)=11))
	)
	AND (tripduration>=3*60 AND tripduration<=3*60*60)
	AND  birth_year is not NULL
	AND birth_year < 2007;

-- Let's create prediction set using these codes


CREATE OR REPLACE TABLE `nyc_bike.prediction_table` AS

SELECT 
	tripduration/60 tripduration,
	starttime,
	stoptime,
	start_station_id,
	start_station_name,
	start_station_latitude,
	start_station_longitude,
	end_station_id,
	end_station_name,
	end_station_latitude,
	end_station_longitude,
	bikeid,
	usertype,
	birth_year,
	gender,
	customer_plan

FROM
	`bigquery-public-data.new_york_citibike.citibike_trips`
WHERE 
	(
	-- Let's select only twelfth month.
	(EXTRACT (YEAR FROM starttime)=2017 AND
	(EXTRACT (MONTH FROM starttime)=12))
	)
	AND (tripduration>=3*60 AND tripduration<=3*60*60)
	AND  birth_year is not NULL
	AND birth_year < 2007;
	
-- Nice! we created the datasets. Let's build a regression model using the training set.

/* 4. Building the Model */

-- First, let's give a model name

CREATE OR REPLACE MODEL `nyc_bike.reg_model`
-- Let's set the type of the model.
OPTIONS
  (model_type='linear_reg') AS
-- Let's select the columns
SELECT
  start_station_name,
  end_station_name,
-- Let's set the day of week. 
   IF (EXTRACT(DAYOFWEEK FROM starttime)=1 
		OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
-- Let's specify the target variable.
  tripduration as label
FROM
  `nyc_bike.training_table`;
  
-- Let's click RUN 

-- You can see your model in the navigation panel.

-- To look at the metric of the model click the model.

-- Go to training tab.

-- Click table 

-- You can see the mean square error metric by default.

/* 5. Evaluating the model */

-- You can use the ML.EVALUATE function to evaluate the model.

SELECT
  *
FROM
-- Let's set the name of our model.
   ML.EVALUATE(MODEL `nyc_bike.reg_model`,
    (
-- Let's selecet the variables.
SELECT
  start_station_name,
  end_station_name,
  IF (EXTRACT(DAYOFWEEK FROM starttime)=1 
    OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
  tripduration as label
-- Let's get the dataset.
FROM
  `nyc_bike.evaluation_table`));
  
-- Let's click RUN

-- After completing the query, you can see the metrics in the results.

/* 6. Predicting the values */

SELECT
  *
FROM
  ML.PREDICT(MODEL `nyc_bike.reg_model`,
    (
	SELECT
	  start_station_name,
	  end_station_name,
	  IF (EXTRACT(DAYOFWEEK FROM starttime)=1 
		OR EXTRACT(DAYOFWEEK FROM starttime)=7, true, false) is_weekend,
	  tripduration as label
    FROM
      `nyc_bike.prediction_table`))
	  
-- Let's click run 

-- You can see the predicts in the results tab.

