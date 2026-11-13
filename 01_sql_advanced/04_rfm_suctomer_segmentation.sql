/*
 * ЗАДАЧА: RFM-сегментация клиентской базы и сводный отчет (Q1 2024)
 * 
 * БИЗНЕС-СМЫСЛ: 
 * Маркетинговый отдел хочет понять, кто из клиентов «золотой» (Champions), 
 * кто «умирает» (Hibernating/Lost), а кого пора реактивировать (At Risk). 
 * Нужно провести RFM-анализ (Recency, Frequency, Monetary) и присвоить каждому клиенту сегмент.
 * 
 * ЧТО ОТРАБОТАНО (Skill Matrix):
 * - Множественные CTE для пошаговой агрегации и сегментации (cus_ord -> rfm_seg -> cust_cat).
 * - LEFT JOIN для сохранения в отчете клиентов без заказов (с нулевой выручкой).
 * - COALESCE для защиты от NULL в суммах и средних чеках.
 * - CASE для скоринга метрик (1-5) и присвоения сегментов (Champion, Loyal, At Risk и др.).
 * - Внимание к порядку условий в CASE: более узкие сегменты (Champion, New customer, Lost) 
 *   проверяются раньше, чем более широкие (Loyal, Potential loyalist, Hibernating), 
 *   чтобы избежать логических пересечений.
 * - TO_CHAR для форматирования дат в выводе (ДД-ММ-ГГГГ).
 * - Оконная функция SUM() OVER () для расчета доли сегмента в общей выручке (Pareto).
 * - Агрегации: COUNT, SUM, AVG, MIN, MAX.
 * 
 * ДАТА: 2026-11-13
 */

--=================================
--ЗАПРОС 1: Детализация по клиентам
--=================================

--1.1. Агрегация по клиентам
with cus_ord as (
	select 
		c.id   					  				as cust_id,
		c.name 					 				as cust_name,
		c.city 					  				as cust_city,
		count(o.id) 			  				as ord_count,
		coalesce(sum(o.amount),0) 				as total_revenue,
		coalesce(avg(o.amount),0) 				as avg_order_value,
		min(o.order_date) 						as first_date,
		max(o.order_date) 						as last_date,
		(date '2024-04-01' - max(o.order_date)) as days_since_last
	from customers c
	left join orders o on o.customer_id=c.id --клиенты без заказов попадут в итоговую таблицу
	group by c.id, c.name, c.city
),
--1.2. RFM сегментация
rfm_seg as (
	select *,
		case
			when days_since_last >=0  and days_since_last <=15 then 5
			when days_since_last >15  and days_since_last <=30 then 4
			when days_since_last >=31 and days_since_last <=60 then 3
			when days_since_last >=61 and days_since_last <=90 then 2
			when days_since_last >90 						   then 1
			else 1
		end as r_score,
		case
			when ord_count >=4 then 5
			when ord_count =3  then 4
			when ord_count =2  then 3
			when ord_count =1  then 2
			when ord_count =0  then 1
			else 1
		end as f_score,
		case
			when total_revenue >= 50000 then 5
			when total_revenue >=30000  then 4
			when total_revenue >=15000  then 3
			when total_revenue >=5000   then 2
			when total_revenue < 5000	then 1
			else 1
		end as m_score
	from cus_ord
),
--1.3. Категории клиентов
cust_cat as (
	select *,
	case 
		when r_score >= 4 and f_score >= 4 and m_score >= 4 then 'Champion'
		when r_score >= 3 and f_score >= 3 and m_score >= 3 then 'Loyal'
		when r_score >= 4 and f_score = 1 					then 'New customer'
		when r_score >= 4 and f_score <= 2 					then 'Potential loyalist'
		when r_score <= 2 and f_score >= 3 					then 'At risk'
		when r_score = 1  and f_score = 1 					then 'Lost'
		when r_score <= 2 and f_score <= 2 					then 'Hibernating'
		when r_score = 3  and f_score >= 2					then 'Need attention'
		else 'others'
	end as rfm_segment
from rfm_seg	
)
--1.4. Основной запрос 1
select
	cust_name 				  	 	  as "Клиент",
	cust_city 				 		  as "Город",
	ord_count 				 		  as "Кол-во заказов",
	total_revenue   		 		  as "Сумма заказов",
	round(avg_order_value,2) 		  as "Средний чек",
	to_char(first_date, 'DD-MM-YYYY') as "Дата первого заказа",
	to_char(last_date, 'DD-MM-YYYY')  as "Дата последнего заказа",
	days_since_last 		 		  as "Дней с момента последнего заказа",
	r_score,
	f_score,
	m_score,
	rfm_segment 					  as "Категория клиента"
from cust_cat
order by m_score desc, f_score desc, r_score desc;

--============================
--ЗАПРОС 2: Сводка по клиентам
--============================
--2.1. Агрегация по клиентам
with cus_ord as (
	select 
		c.id   					  				as cust_id,
		c.name 					 				as cust_name,
		c.city 					  				as cust_city,
		count(o.id) 			  				as ord_count,
		coalesce(sum(o.amount),0) 				as total_revenue,
		coalesce(avg(o.amount),0) 				as avg_order_value,
		min(o.order_date) 						as first_date,
		max(o.order_date) 						as last_date,
		(date '2024-04-01' - max(o.order_date)) as days_since_last
	from customers c
	left join orders o on o.customer_id=c.id --клиенты без заказов попадут в итоговую таблицу
	group by c.id, c.name, c.city
),
--2.2. RFM сегментация
rfm_seg as (
	select *,
		case
			when days_since_last >=0  and days_since_last <=15 then 5
			when days_since_last >15  and days_since_last <=30 then 4
			when days_since_last >=31 and days_since_last <=60 then 3
			when days_since_last >=61 and days_since_last <=90 then 2
			when days_since_last >90 						   then 1
			else 1
		end as r_score,
		case
			when ord_count >=4 then 5
			when ord_count =3  then 4
			when ord_count =2  then 3
			when ord_count =1  then 2
			when ord_count =0  then 1
			else 1
		end as f_score,
		case
			when total_revenue >= 50000 then 5
			when total_revenue >=30000  then 4
			when total_revenue >=15000  then 3
			when total_revenue >=5000   then 2
			when total_revenue < 5000	then 1
			else 1
		end as m_score
	from cus_ord
),
--2.3. Категории клиентов
cust_cat as (
	select *,
	case 
		when r_score >= 4 and f_score >= 4 and m_score >= 4 then 'Champion'
		when r_score >= 3 and f_score >= 3 and m_score >= 3 then 'Loyal'
		when r_score >= 4 and f_score = 1 					then 'New customer'
		when r_score >= 4 and f_score <= 2 					then 'Potential loyalist'
		when r_score <= 2 and f_score >= 3 					then 'At risk'
		when r_score = 1  and f_score = 1 					then 'Lost'
		when r_score <= 2 and f_score <= 2 					then 'Hibernating'
		when r_score = 3  and f_score >= 2					then 'Need attention'
		else 'others'
	end as rfm_segment
from rfm_seg	
)
--2.4. Основной запрос 2
select 
	rfm_segment															   as "Категория клиента",
	count(cust_id) 														   as "Кол-во клиентов",
	sum(total_revenue) 													   as "Сумма выручки",
	round(avg(total_revenue), 2)										   as "Средняя выручка на клиента",
	round(100.0 * sum(total_revenue) / sum(sum(total_revenue)) over (), 2) as "Доля в общей выручке, %"
from cust_cat
group by rfm_segment
order by sum(total_revenue) desc;