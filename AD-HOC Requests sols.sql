#1
#select * from dim_customer;
select distinct market,customer,region from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

#2
#select * from fact_sales_monthly; 
with cte(2020pc) as
  (select count(distinct product_code) as 2020pc from fact_sales_monthly where fiscal_year=2020),
cte1(2021pc) as 
  (select count(distinct product_code) as 2021pc from fact_sales_monthly where fiscal_year=2021)
 select 2020pc as unique_products_2020,
 2021pc as unique_products_2021,
 round((2021pc-2020pc)*100/2020pc) as percentage_chg 
 from cte cross join cte1;

#3.
#select * from dim_product;
select segment,count( distinct product_code) as product_count
from dim_product group by segment
 order by product_count desc;
 
#4
select p.segment, count(distinct case when fmc.cost_year=2020 then p.product_code end) as product_count_2020,
count(distinct case when fmc.cost_year=2021 then p.product_code end) as product_count_2021,  
count(distinct case when fmc.cost_year=2021 then p.product_code end) - 
count(distinct case when fmc.cost_year=2020 then p.product_code end) as difference
from dim_product p join fact_manufacturing_cost fmc on p.product_code=fmc.product_code
group by 1 order by difference desc;

#5.
#select * from dim_product;
#select * from fact_manufacturing_cost;
select dp.product_code, dp.product, fm.manufacturing_cost 
from dim_product dp inner join fact_manufacturing_cost fm 
on dp.product_code = fm.product_code
where fm.manufacturing_cost in ((select max(manufacturing_cost) from fact_manufacturing_cost),
								(select min(manufacturing_cost) from fact_manufacturing_cost)) 
order by fm.manufacturing_cost  desc;

#6.
#select *  from fact_pre_invoice_deductions;
#select * from dim_customer;
select dc.customer_code, dc.customer, round(fpi.pre_invoice_discount_pct*100,2) as average_discount_percentage
from dim_customer dc inner join fact_pre_invoice_deductions fpi on dc.customer_code = fpi.customer_code 
where fpi.pre_invoice_discount_pct >=(select avg(pre_invoice_discount_pct) as avg from fact_pre_invoice_deductions)
and fpi.fiscal_year=2021 and market="India" 
order by average_discount_percentage desc limit 5;

#7.
#select * from fact_sales_monthly;
#select * from fact_gross_price;
#select * from dim_customer;
select left({fn monthname(fsm.date)},3) as Month,fsm.fiscal_year as Year,
round(sum(fsm.sold_quantity*fgp.gross_price)) as Gross_Sales_Amount 
from fact_sales_monthly fsm inner join fact_gross_price fgp 
on fsm.product_code=fgp.product_code inner join dim_customer dc on fsm.customer_code=dc.customer_code 
where dc.customer="Atliq Exclusive" group by 1,2  order by  Year, Gross_Sales_Amount desc;

#8
#select * from fact_sales_monthly;
with cte as 
(select (case when month(date) in ( 09,10,11)  then "Q1" 
            when month(date) in ( 12,01,02)  then "Q2"
            when month(date) in ( 03,04,05) then "Q3" else "Q4" end) as Quarter,            
sum(sold_quantity) as total_sold_quantity from fact_sales_monthly
where fiscal_year=2020 group by Quarter order by sum(sold_quantity) desc)
select * from cte;
 
#9 
with cte as 
 (select dc.channel as channel,round(sum(fgp.gross_price*fsm.sold_quantity),2) as gross_sales_mln
  from fact_gross_price fgp inner join  fact_sales_monthly fsm on fgp.product_code=fsm.product_code
  inner join dim_customer dc on dc.customer_code=fsm.customer_code 
  where fsm.fiscal_year= 2021 group by dc.channel)
select channel,gross_sales_mln, round((gross_sales_mln/sum(gross_sales_mln) over())*100,2) as
percentage from cte order by percentage desc;

#10
#select * from dim_product; 
#select * from fact_sales_monthly;
with cte as 
     (select dp.division as division,dp.product_code as product_code,
     dp.product as product,dp.variant as variant,sum(fsm.sold_quantity) as total_sold_quantity,
	 rank() over(partition by division order by sum(fsm.sold_quantity) desc) as rank_order
	 from fact_sales_monthly fsm inner join dim_product dp 
     on dp.product_code=fsm.product_code where fsm.fiscal_year= 2021 
     group by product_code,division ,product,variant order by total_sold_quantity desc) 
select * from cte where cte.rank_order<4;









