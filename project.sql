select * from dim_customer;
select * from dim_product;
select * from fact_gross_price;
select * from fact_pre_invoice_deductions;
select * from fact_sales_monthly;

/*
1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region
*/
select customer_code,market from dim_customer where region='APAC' and customer like'%Atliq Exclusive%';

/*
2.What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
*/

/*
3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
The final output contains 2 fields, segment product_count

*/

select segment,count(product_code) as Total_unique_products from dim_product
group by segment
order by Total_unique_products desc;

/*
4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
The final output contains these fields, segment product_count_2020 product_count_2021 difference
*/

/*
5.Get the products that have the highest and lowest manufacturing costs.
 The final output should contain these fields, product_code product manufacturing_cost
*/

/*6.
Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
for the fiscal year 2021 and in the Indian market.
The final output contains these fields, customer_code customer average_discount_percentage
*/
with high_avg as (
select c.customer_code,customer,avg(pre_invoice_discount_pct) as avg_pre_invoice_discount_pct 
from fact_pre_invoice_deductions invd join dim_customer c on invd.customer_code=c.customer_code
 where fiscal_year=2021 and market like '%India%'
group by c.customer_code,customer
),
ranks_high_avg as(
SELECT *,
    DENSE_RANK() OVER (ORDER BY avg_pre_invoice_discount_pct DESC) AS ranks
FROM 
    high_avg)
    
select * from ranks_high_avg where ranks<=5;

/*
7.
Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
The final report contains these columns: Month Year Gross sales Amount
*/

select concat(monthname(date),'-',year(date)) as month_name,fsm.fiscal_year,sum(sold_quantity*gross_price) from fact_sales_monthly fsm 
join fact_gross_price fgp on fsm.product_code=fgp.product_code and fsm.fiscal_year=fgp.fiscal_year
join dim_customer c on fsm.customer_code=c.customer_code
where customer like '%Atliq Exclusive%'
group by month_name,fsm.fiscal_year
order by fsm.fiscal_year


/*
8.In which quarter of 2020, got the maximum total_sold_quantity? 
The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity
*/
SELECT get_quarter(date),sum(sold_quantity) as total_sold_quantity FROM fact_sales_monthly
where fiscal_year=2020
group by get_quarter(date)
order by total_sold_quantity desc;

/*
9. Which channel helped to bring more gross sales in the fiscal year 2021 and 
the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage
*/
with more_gross_sales_2021 as (
select channel,round(sum(sold_quantity*gross_price)/100000,2) as total_gross_sales_mln from fact_sales_monthly fsm
join  fact_gross_price fgp on fsm.product_code=fgp.product_code and fsm.fiscal_year=fgp.fiscal_year
join dim_customer c on c.customer_code=fsm.customer_code
where fsm.fiscal_year=2021
group by channel
)
select *,round((total_gross_sales_mln*100)/sum(total_gross_sales_mln) over(),2) as gross_sales_pct
from more_gross_sales_2021;



/*
10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields, division product_code
*/
with total_sold_quantity as(
SELECT division,dp.product_code,sum(sold_quantity) as total_sold_quantity
 from fact_sales_monthly fsm join  dim_product dp on fsm.product_code=dp.product_code
 group by division,dp.product_code
),
 division_rank as (
select *,dense_rank () over(partition by division order by total_sold_quantity desc) as ranks
from total_sold_quantity
)

select * from division_rank where ranks<=3;
