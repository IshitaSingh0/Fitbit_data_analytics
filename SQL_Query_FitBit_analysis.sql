--1]checking datatype and creating hourly_data_cleaned
SELECT
  	COLUMN_NAME, DATA_TYPE
FROM
  	INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='hourly_data'




IF EXISTS (SELECT * FROM Fitbit.dbo.hourly_data_cleaned)
DROP TABLE Fitbit.dbo.hourly_data_cleaned

CREATE TABLE Fitbit.dbo.hourly_data_cleaned
(Id float, ActivityHour nvarchar(25), Calories int, StepTotal float, TotalIntensity float, AverageIntensity float)


INSERT INTO Fitbit.dbo.hourly_data_cleaned
(Id, ActivityHour, Calories, StepTotal, TotalIntensity, AverageIntensity)
SELECT Id, ActivityHour, Calories, cast([StepTotal] as float) as StepTotal, cast(TotalIntensity as float) as TotalIntensity, cast(AverageIntensity as float) as AverageIntensity
FROM Fitbit.dbo.hourly_data

--2]checking datatype and creating heartrate_minutes

 select column_name, data_type
 from INFORMATION_SCHEMA.columns
 where table_name='heartrate_seconds'

 --select distinct(len(Time)) from heartrate_seconds (to check String length)

 Create table heartrate_minutes
 (Id float, Time nvarchar(25), Value int)

 Insert into heartrate_minutes
 (Id, Time, Value)
 Select b.Id,b.Time,b.heartrate
 from (select Id, Time, avg(Value) as heartrate
  from (select Id ,DATEADD(MINUTE, DATEDIFF(MINUTE, 0, Time), 0) as Time, Value from heartrate_seconds) as a
  group by Id,Time) as b

--3]Number of users tracking different activities

SELECT count(distinct(id)) as people_recording_activity
From dbo.dailyActivity

SELECT count(distinct(id)) as people_recording_heartrate
From dbo.heartrate_seconds

SELECT count(distinct(id)) as people_recording_MET
From dbo.minuteMETsNarrow

select count(distinct(id)) as people_recording_sleep
from dbo.minuteSleep

select count(distinct(id)) as people_recording_weight
from dbo.weightLogInfo




--4]Sleep analysis


/*select Id,value,avg(minutes) as avg_min
from(select distinct(value), Id, date, count(hour) over(partition by value,Id,date) as minutes
from (select value,Id,cast(date as date) as date, datepart(hour,date) as hour
from minuteSleep) as a
) as b
group by Id,value
order by Id*/  --Average minutes for each sleep value for each Id.

select distinct(datepart(hour,date)) as hour,count(datepart(hour,date)) over(partition by datepart(hour,date)) as number_of_sleep_records
from minuteSleep
order by number_of_sleep_records desc  --Total sleep records for each hour 

--Top 8 hours with highest number of sleep records: 11PM to 7AM

select value as sleep_value,cast(avg(minutes)/60.0 as decimal(5,3)) as avg_hours
from(select distinct(value), Id, date, count(hour) over(partition by value,Id,date) as minutes
from (select value,Id,cast(date as date) as date, datepart(hour,date) as hour
from minuteSleep) as a
) as b
group by value  --Average hours for each sleep value

select cast(avg(TotalMinutesAsleep)/60.0 as decimal(4,2)) as total_hours_asleep,cast(avg(TotalTimeInBed)/60.0 as decimal(4,2)) as total_hours_in_bed
from sleepDay  --Average total minutes asleep and average total time in bed.




--5]Weight analysis

Select distinct(Id), count(cast(Date as date)) over(partition by Id) as no_of_days_weight_recorded, max(WeightKg) over(partition by Id) as max_weightKg, min(WeightKg) over(partition by Id) as min_weightKg
from weightLogInfo




--6]calculating hourly average intensity and calories

SELECT distinct(datepart(hour,ActivityHour)) as hour, (avg(AverageIntensity) over(partition by datepart(hour,ActivityHour))) as avg_intensity,
(avg(Calories) over(partition by datepart(hour,ActivityHour))) as Calories
from hourly_data_cleaned
order by avg_intensity desc  --Average intensity and average calories by hour

/*SELECT TOP 5 a.hour, a.avg_intensity 
FROM (SELECT distinct(datepart(hour,ActivityHour)) as hour, (avg(AverageIntensity) over(partition by datepart(hour,ActivityHour))) as avg_intensity
from hourly_data_cleaned) as a
order by  a.avg_intensity desc*/  --Top 5 hours with highest average intensity(Most active hours)




--7]daily activity analysis

select avg(TotalSteps) as avg_total_steps, avg(TotalDistance) as avg_daily_distance, avg(TrackerDistance) as avg_tracked_distance, cast(avg(VeryActiveMinutes)/60.0 as decimal(4,2))  as very_active_hours,
cast(avg(FairlyActiveMinutes)/60.0 as decimal(4,2)) as fairly_active_hours, cast(avg(LightlyActiveMinutes)/60.0 as decimal(4,2)) as lightly_active_hours,
cast(avg(SedentaryMinutes)/60.0 as decimal(4,2)) as sedentary_hours, cast((avg(VeryActiveMinutes)+avg(FairlyActiveMinutes)+avg(LightlyActiveMinutes)+avg(SedentaryMinutes))/60.0 as decimal(4,2)) as total_hours_recorded
from dailyActivity  --daily average data(Steps, distance, sedentary hours etc)




--8]heartrate_analysis
select distinct(datepart(hour,Time)) as hour,avg(Value) over(partition by datepart(hour,Time) ) as avg_heartrate_per_hour
from heartrate_seconds
order by avg_heartrate_per_hour desc  --Average heart rate by hour

select distinct(Id), min(Value) over(partition by Id) as min_heart_rate, max(Value) over(partition by Id) as max_heart_rate, avg(Value) over(partition by Id) as avg_heart_rate
from heartrate_seconds  --Average, minimum and maximum heart rate for an Id.