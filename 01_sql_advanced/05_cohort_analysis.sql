/*
 * ЗАДАЧА: Когортный анализ клиентской базы (Q1 2024)
 * 
 * БИЗНЕС-СМЫСЛ: 
 * Маркетинг хочет понять, в каком месяце пришли «качественные» клиенты, 
 * и возвращаются ли они вообще. Строим когортный анализ по месяцу первого заказа:
 * паспорт клиента, матрицу удержания (retention) и выручку-рамп по когортам.
 * 
 * ЧТО ОТРАБОТАНО (Skill Matrix):
 * - Множественные CTE для пошагового расчета (first_ord -> offset_ord).
 * - DATE_TRUNC для определения месяца когорты (месяц первого заказа).
 * - DATE_PART для расчета offset в месяцах (разница между заказом и когортой).
 * - Пивот через COUNT(DISTINCT ...) FILTER (WHERE ...) и SUM(...) FILTER (WHERE ...) — 
 *   без подзапросов на каждую колонку (эффективный когортный анализ).
 * - CASE внутри SUM/COUNT (альтернатива FILTER для совместимости).
 * - COALESCE для защиты от NULL при отсутствии заказов в месяце.
 * - Приведение типов (::numeric) для корректного дробного деления при расчете retention.
 * - Агрегации: COUNT, SUM, MIN, MAX, AVG.
 * - Обработка «дырок» в lifetime (перерыв в заказах не разрывает lifetime).
 * 
 * ДАТА: 2026-11-13
 */

--=========================
-- Часть 1. Паспорт клиента
--=========================
with cust_stats as (
	select 
		c.id 																		   		as c_id,
		c.name 																		   		as cust_name,
		count(o.id) 																   		as total_orders,
		sum(o.amount) 																   		as total_revenue,
		round(avg(o.amount),2) as avg_check,
		date_trunc('month', min(o.order_date)) 										   		as cohort_month,
		(date_part('year',max(o.order_date))-date_part('year',min(o.order_date)))*12
		+(date_part('month',max(o.order_date))-date_part('month',min(o.order_date)))+1::int as lifetime_months
	from customers c
	join orders o on o.customer_id=c.id
	group by c.id, c.name		
)
select
    cust_name 		as "Клиент",
    cohort_month 	as "Когорта",
    total_orders 	as "Кол-во заказов",
    total_revenue 	as "Выручка",
    lifetime_months as "Lifetime, мес",
    avg_check 		as "Средний чек"
from cust_stats
order by cohort_month, total_revenue desc;
--=======================================
-- Часть 2. Матрица удержания (Retention)
--=======================================
with first_ord as (
    select 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) as cohort_month
    from orders
    group by customer_id      
),
offset_ord as (
    select
        o.customer_id,
        fo.cohort_month,
        o.amount,
        (DATE_PART('year', o.order_date) - DATE_PART('year', fo.cohort_month)) * 12
        + (DATE_PART('month', o.order_date) - DATE_PART('month', fo.cohort_month)) as m_offset
    from first_ord fo
    JOIN orders o on o.customer_id = fo.customer_id
)
select
    TO_CHAR(cohort_month, 'YYYY-MM') as "Когорта",
    count(distinct customer_id) 	 as "Размер когорты",
    count(distinct case when m_offset = 0 then customer_id end) as "M0",
    count(distinct case when m_offset = 1 then customer_id end) as "M1",
    count(distinct case when m_offset = 2 then customer_id end) as "M2",
    ROUND(count(distinct case when m_offset = 0 then customer_id end) * 100.0 / count(distinct customer_id), 1) as "Удержание М0, %",
    ROUND(count(distinct case when m_offset = 1 then customer_id end) * 100.0 / count(distinct customer_id), 1) as "Удержание М1, %",
    ROUND(count(distinct case when m_offset = 2 then customer_id end) * 100.0 / count(distinct customer_id), 1) as "Удержание М2, %"
from offset_ord
group by cohort_month
order by cohort_month;
--==============================
-- Часть 3. Выручка рамп когорт
--==============================
with first_ord as (
    select 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) as cohort_month
    from orders
    group by customer_id      
),
offset_ord as (
    select
        o.customer_id,
        fo.cohort_month,
        o.amount,
        (DATE_PART('year', o.order_date) - DATE_PART('year', fo.cohort_month)) * 12
        + (DATE_PART('month', o.order_date) - DATE_PART('month', fo.cohort_month)) as m_offset
    from first_ord fo
    JOIN orders o on o.customer_id = fo.customer_id
)
select
    TO_CHAR(cohort_month, 'YYYY-MM') as "Когорта",
    sum(amount) as "Общая выручка когорты",
    coalesce(sum(case when m_offset = 0 then amount end), 0) as "Выручка M0",
    coalesce(sum(case when m_offset = 1 then amount end), 0) as "Выручка M1",
    coalesce(sum(case when m_offset = 2 then amount end), 0) as "Выручка M2",
    ROUND(coalesce(sum(case when m_offset = 0 then amount end), 0) * 100.0 / sum(amount), 1) as "Удержание М0, %"
from offset_ord
group by cohort_month
order by cohort_month;