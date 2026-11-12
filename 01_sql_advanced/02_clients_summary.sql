/*
 * ЗАДАЧА: Сводный отчет по клиентам и их менеджерам (Advanced)
 * 
 * БИЗНЕС-СМЫСЛ: 
 * Руководство хочет видеть одну таблицу, где по каждому клиенту собрана вся информация: 
 * насколько он важен, как давно покупал, какой у него тренд, и кто из менеджеров его ведет.
 * 
 * ЧТО ОТРАБОТАНО (Skill Matrix):
 * - Множественные CTE для разбиения сложной логики (суммы, даты, менеджеры).
 * - ROW_NUMBER для поиска лучшего менеджера по выручке.
 * - COALESCE и NULLIF для защиты от деления на ноль и показа клиентов без заказов.
 * - Оконные функции RANK и LAG для ранжирования клиентов и разницы с вышестоящим.
 * - Агрегации: SUM, COUNT, MIN, MAX.
 * 
 * ДАТА: 2026-11-03
 */

with 
-- Находим суммы и заказы по клиентам
cus_ord as (
	select c.id as cid, c.name, c.city, coalesce(sum(o.amount),0) as total, count(DISTINCT(o.id)) as kol
	from customers c
	left join orders o on o.customer_id=c.id
	group by c.id, c.name, c.city),
-- Находим даты первого и последнего заказов и их разность
ord_date as (
	select c.id as cid, c.name, min(o.order_date) as first_date, max(o.order_date) as last_date, CAST(MAX(o.order_date) - MIN(o.order_date) AS INTEGER) AS diff_date
	from customers c
	left join orders o on o.customer_id=c.id
	group by c.id, c.name),
-- Считаем выручку по парам клиент-менеджер
cus_emp as (	
	select o.customer_id as cid, e.id as eid, e.name as man_name, sum(o.amount) as man_total
	from orders o
	join employees e on e.id=o.employee_id
	group by o.customer_id, e.id, e.name),
-- Находим лучшего менеджера
best_man as (
	SELECT cid, man_name, row_number() over (PARTITION by cid order by man_total desc) as rn
	from cus_emp)
-- Основной запрос
SELECT
	co.name as "Клиент",
	co.city as "Город",
	co.total as "Сумма заказов клиента",
	co.kol as "Кол-во заказов клиента",
	round(co.total*1.0/(nullif(co.kol,0)),2) as "средний чек клиента", -- Защита от деления на 0, округление до 2-х знаков
	case 
		when co.total > 80000 then 'VIP'
		when co.total > 40000 then 'крупный'
		else 'Обычный'
		end as "Категория по сумме заказов",
	coalesce(od.first_date::text,'нет заказов') as "Дата первого заказа", --добавил "нет заказов" для клиентов без заказов
	coalesce(od.last_date::text,'нет заказов') as "Дата последнего заказа", --добавил "нет заказов" для клиентов без заказов
	coalesce(diff_date,0) as "Разница между последним и первым заказом, дней", --добавил "0" для клиентов без заказов
	COALESCE(CAST('2026-11-03'::date - od.last_date AS INTEGER), 0) AS "Дней с последнего заказа", -- Добавил важную для бизнесса метрику, 0 для клиентов без заказов
	rank() over (order by co.total desc) as "Ранг по сумме заказов",
	coalesce(co.total-lag(co.total) over (order by co.total desc),0) as "Разница в сумме заказов с клиентом выше", --Первое значение 0
	bm.man_name as "Лучший менеджер"
from cus_ord co
left join ord_date od on od.cid=co.cid
left join best_man bm on bm.cid=co.cid and bm.rn=1 -- Если у клиента нет заказов, он попадет в отчет
order by "Ранг по сумме заказов";