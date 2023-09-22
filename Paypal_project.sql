--Paypal Credit Card Data Analysis Project
use namastesql;
Select * from credit_card_transcations;

Select card_type , count(transaction_id) from credit_card_transcations
group by card_type;

--1 write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with cte1 as
(
SELECT city , SUM(amount) as "spends" 
FROM credit_card_transcations
group by city
)

, cte2 as 
(
SELECT * , 
(SELECT sum(Cast(amount as BIGINT)) as "Total_spending" from credit_card_transcations) as "total_spend", 
Cast(round(100.0*spends/(Select sum(Cast(amount as BIGINT)) from credit_card_transcations),2) as float) as "percent_contribution" from cte1
)

Select city,percent_contribution from 
(
Select * ,
Row_number()Over(order by percent_contribution desc) as rnk 
from cte2
)a
where rnk <=5;



--2  write a query to print highest spend month and amount spent in that month for each card type

with cte1 as
(
Select MONTH(transaction_date) as "amt_month" , card_type ,SUM(amount) as amt from credit_card_transcations
group by MONTH(transaction_date),card_type
)
, cte2 as 
(Select card_type , max(amt) as max_amt from cte1  group by card_type)

Select cte1.* , cte2.* from 
cte1 inner join cte2 on cte1.card_type=cte2.card_type and cte1.amt=cte2.max_amt

Select * from 
(
Select * , 
RANK() Over	( partition by card_type order by amt desc) as rnk from
(
Select card_type,year(transaction_date)as amt_yr,MONTH(transaction_date) as "amt_month" ,SUM(amount) as amt from credit_card_transcations
group by MONTH(transaction_date),year(transaction_date), card_type
) a
)b where rnk = 1

--3- write a query to print the transaction details(all columns from the table) for each card type when 
--it reaches a cumulative of 1,000,000 total spends(We should have 4 rows in the o/p one for each card type)

Select * from credit_card_transcations;


with cte1 as (
Select card_type , transaction_id, amount, sum(amount) over ( Partition by card_type order by transaction_date,transaction_id) as "cumm_amt" from credit_card_transcations
)
, cte2 as (
Select card_type, min(cumm_amt) as min_amt from cte1
where cumm_amt >=1000000
group by card_type
) 
,cte3 as (
Select cte2.card_type,cte1.transaction_id,cte1.cumm_amt from cte2  inner join cte1  on cte1.card_type=cte2.card_type and cte2.min_amt=cte1.cumm_amt
)

Select cct.* , b.cumm_amt from credit_card_transcations cct inner join cte3 b on 
cct.card_type=b.card_type and cct.transaction_id=b.transaction_id
order by card_type

--easier Solution
with cte as (
select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
from credit_card_transcations
--order by card_type,total_spend desc
)
select * from (select *, rank() over(partition by card_type order by total_spend) as rn  
from cte where total_spend >= 1000000) a where rn=1


--4- write a query to find city which had lowest percentage spend for gold card type
Select * from credit_card_transcations;

Select city,t1.Total_amt from 
(
Select city , sum(amount) as "Total_amt" from 
credit_card_transcations
where card_type in ('Gold')
group by city ) t1
where Total_amt = 
(
Select min(Total_amt) as "min_amt"
from
(Select city , sum(amount) as "Total_amt" from 
credit_card_transcations
where card_type in ('Gold')
group by city) a
)

--5 write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
Select * from credit_card_transcations;

with cte as (
select city,exp_type, sum(amount) as total_amount from credit_card_transcations
group by city,exp_type)
select
city , max(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type
from
(select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city;

--6- write a query to find percentage contribution of spends by females for each expense type
Select *, round(100.0*amt/amt_exp_type , 2) as "%_spend" from
(
Select * , sum(amt) over(partition by exp_type) as "Amt_exp_type" from (
Select exp_type , gender , sum(amount) as "amt" 
from credit_card_transcations
group by exp_type , gender ) a 
) b 
where gender = 'F'
order by exp_type ;

--easier solution
select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_female_contribution
from credit_card_transcations
group by exp_type
order by percentage_female_contribution desc;

--7- which card and expense type combination saw highest month over month growth in Jan-2014
Select * from credit_card_transcations;

with cte1 as (
Select card_type, exp_type , MONTH(transaction_date) as 'mth' ,year(transaction_date) as 'yr' ,sum(amount) as amt
from credit_card_transcations
where (MONTH(transaction_date)=12 and year(transaction_date)=2013 ) or (MONTH(transaction_date)=1 and year(transaction_date)=2014)
group by card_type, exp_type , MONTH(transaction_date) ,year(transaction_date) 

)
, cte2 as
(
Select * , LEAD(amt,1) over(partition by card_type,exp_type order by exp_type) as lead_amount from cte1
)

Select * , cast(round(100.0*(amt-lead_amount)/lead_amount,2) as float) as MoM_Jan_2014
from cte2
where lead_amount is not null
order by MoM_Jan_2014 desc ;

--8 during weekends which city has highest total spend to total no of transcations ratio

Select top 1 city , cast(total_spend/tranasctions as float) as ratio from
(
Select city , sum(amount) as total_spend,count(transaction_id) as tranasctions
from credit_card_transcations
where datepart(weekday,transaction_date) in (1,7)
group by city
) a
order by ratio desc;

--9which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte1 as
(
Select * , ROW_NUMBER()over (partition by city order by transaction_date) as rn from credit_card_transcations
)

, th_trans as
(Select city, transaction_date as Lead_trasn_Date from cte1 
where rn = 500 
)
, first_trans as
(Select city, transaction_date as first_trasn_Date from cte1 
where rn = 1 
)
Select *,Datediff(Day,first_trasn_Date,Lead_trasn_Date)as Days_to_reach 
from 
th_trans inner join first_trans on 
th_trans.city=first_trans.city
order by Days_to_reach;







