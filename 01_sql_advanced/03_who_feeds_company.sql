/*
 * ЗАДАЧА: Аналитический отчет «Кто кормит компанию» (Q1 2024)
 * 
 * БИЗНЕС-СМЫСЛ: 
 * Совет директоров хочет видеть, кто из сотрудников приносит деньги, 
 * кто просто сидит на окладе, и насколько отдел зависит от одного человека.
 * Нужен единый отчет по каждому сотруднику с ключевыми метриками эффективности.
 * 
 * ЧТО ОТРАБОТАНО (Skill Matrix):
 * - Множественные CTE для разбиения сложной логики (агрегаты, доли, пропуски).
 * - RANK для ранжирования сотрудников внутри отдела (при равной выручке — одинаковый ранг).
 * - SUM() OVER (ORDER BY ... ROWS BETWEEN ...) для расчета накопленной доли (Парето).
 * - LAG в LATERAL для поиска максимального перерыва между заказами.
 * - generate_series + LEFT JOIN для поиска месяцев без заказов (пропуски).
 * - STRING_AGG для сбора пропущенных месяцев в строку через запятую.
 * - COALESCE для показа сотрудников без заказов (нулевая выручка, не ломает проценты).
 * - NULLIF и CASE для защиты от деления на ноль (пустые отделы, нулевой оклад).
 * - Агрегации: SUM, COUNT, AVG, STDDEV.
 * 
 * ДАТА: 2026-11-12
 */
 
with
-- 1. Заказы за 1 квартал 2024
q1_orders as (
    select
        o.id as order_id,
        o.employee_id,
        o.customer_id,
        o.amount,
        o.order_date
    from orders o
    where o.order_date >= '2024-01-01'
      and o.order_date <  '2024-04-01'
),
-- 2. Агрегаты по сотрудникам
emp_agg as (
    select
        e.id as employee_id,
        e.name as employee_name,
        e.salary,
        d.id as department_id,
        d.name as department_name,
        coalesce(sum(q.amount), 0) as revenue,
        count(distinct q.customer_id) as uniq_customers,
        count(distinct q.order_id) as total_orders,
        -- loyal: клиенты с >= 2 заказами у этого сотрудника
        count(distinct case
            when cnt.cnt >= 2 then cnt.customer_id
        end) as loyal_customers,
        -- max_gap: максимальный перерыв между соседними заказами
        max(gap_days) as max_gap_days
    from employees e
    join departments d on d.id = e.department_id
    left join q1_orders q on q.employee_id = e.id
    -- подзапрос для loyal
    left join (
        select employee_id, customer_id, count(*) as cnt
        from q1_orders
        group by employee_id, customer_id
    ) cnt on cnt.employee_id = e.id and cnt.customer_id = q.customer_id
    -- подзапрос для gap_days
    left join lateral (
        select
            max((order_date - prev_date)) as gap_days
        from (
            select
                order_date,
                lag(order_date) over (order by order_date) as prev_date
            from q1_orders
            where employee_id = e.id
        ) g
        where prev_date is not null
    ) gaps on TRUE
    group by e.id, e.name, e.salary, d.id, d.name
),
-- 3. Выручка по отделам
dept_totals as (
    select
        department_id,
        sum(revenue) as dept_revenue
    from emp_agg
    group by department_id
),
-- 4. Доли, накопленная доля (Парето), ранг
with_shares as (
    select
        ea.*,
        dt.dept_revenue,
        -- доля в отделе, %
        case
            when dt.dept_revenue = 0 then 0
            else ROUND(ea.revenue * 100.0 / dt.dept_revenue, 1)
        end as share_dept_pct,
        -- накопленная доля (Парето), %
        case
            when dt.dept_revenue = 0 then 0
            else ROUND(
                sum(ea.revenue) over (
                    partition by ea.department_id
                    order by ea.revenue desc
                    rows between unbounded preceding and current row
                ) * 100.0 / dt.dept_revenue, 1)
        end as cum_share_dept_pct,
        -- ROI
        case
            when ea.salary = 0 then null
            else ROUND(ea.revenue::numeric / ea.salary, 2)
        end as roi,
        -- ранг внутри отдела (при равной выручке — одинаковый)
        rank() over (partition by ea.department_id order by ea.revenue desc) as rnk_in_dept
    from emp_agg ea
    join dept_totals dt on dt.department_id = ea.department_id
),
-- 5. Shared customers: клиенты, которых обслуживает >= 2 сотрудников
shared_cust as (
    select
        q.employee_id,
        count(distinct q.customer_id) as shared_customers
    from q1_orders q
    join (
        select customer_id
        from q1_orders
        group by customer_id
        having count(distinct employee_id) >= 2
    ) multi on multi.customer_id = q.customer_id
    group by q.employee_id
),
-- 6. Missing months: месяцы без заказов (через generate_series)
months as (
    select generate_series(1, 3) as month_num
),
emp_months as (
    select
        e.id as employee_id,
        m.month_num,
        count(q.order_id) as cnt
    from employees e
    cross join months m
    left join q1_orders q
        on q.employee_id = e.id
       and extract(month from q.order_date) = m.month_num
    group by e.id, m.month_num
),
missing_months as (
    select
        employee_id,
        STRING_AGG(month_num::text, ',' order by month_num) as missing_months
    from emp_months
    where cnt = 0
    group by employee_id
)
-- Финальный select
select
    ws.department_name as "Отдел",
    ws.employee_name as "Сотрудник",
    ws.revenue as "Выручка",
    ws.share_dept_pct as "Доля в отделе, %",
    ws.cum_share_dept_pct as "Накопленная доля, %",
    ws.roi as "ROI",
    ws.rnk_in_dept as "Ранг в отделе",
    ws.uniq_customers as "Уник. клиентов",
    ws.loyal_customers as "Лояльных клиентов",
    coalesce(sc.shared_customers, 0) as "Shared клиентов",
    coalesce(mm.missing_months, '') as "Месяцы без заказов",
    ws.max_gap_days as "Макс. перерыв, дней"
from with_shares ws
left join shared_cust sc on sc.employee_id = ws.employee_id
left join missing_months mm on mm.employee_id = ws.employee_id
order by ws.department_name, ws.revenue desc;