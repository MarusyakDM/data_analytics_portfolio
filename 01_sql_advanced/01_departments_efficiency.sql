/*
 * ЗАДАЧА: Итоговый отчет по эффективности отделов (Advanced)
 * 
 * БИЗНЕС-СМЫСЛ: 
 * Сформировать сводную таблицу по отделам (выручка, зарплаты, окупаемость, 
 * лучший менеджер, ранги и разницы с конкурентами).
 * 
 * ЧТО ОТРАБОТАНО (Skill Matrix):
 * - CTE (WITH ...) для разбиения сложной логики на шаги.
 * - LEFT JOIN + COALESCE для сохранения отделов без сотрудников/заказов.
 * - NULLIF(..., 0) для защиты от деления на ноль (Деление на ноль в SQL).
 * - Оконные функции: ROW_NUMBER (поиск лучшего), RANK (ранжирование), LAG (разница с вышестоящим).
 * - CASE WHEN для категоризации (High / Medium / Low).
 * - Агрегации: COUNT, SUM, AVG.
 * 
 * ДАТА: 2026-11-02
 */

 with
--Кол-во сотрудников в отделе и суммарная зарплата по отделу
dep_emp as (
	select d.id as did, d.name, coalesce(sum(e.salary),0) as salary, count(e.id) as kol
	from departments d
	left join employees e on e.department_id=d.id
	group by d.id, d.name),
--Общая выручка по отделам
emp_ord as (
	select e.department_id as did, sum(o.amount) as total
	from employees e
	join orders o on o.employee_id=e.id
	group by e.department_id),
--Выручка по каждому менеджеру
emp_rev as (
	SELECT e.id as eid, e.name as emp_name, e.department_id as did, sum(o.amount) as total_rev
	from employees e
	join orders o on o.employee_id=e.id
	GROUP by e.id, e.name, e.department_id),
--Поиск лучшего менеджера
best_emp as (
	SELECT did, emp_name, row_number() over (PARTITION by did order by total_rev desc) as rn
	from emp_rev),
--Соединяем все
dep_stats as (
	select de.name as depart, de.kol as kol, de.salary as sal, coalesce(eo.total,0) as total_rev, be.emp_name as best_manager, round(coalesce(eo.total,0)*1.0/nullif(de.salary,0),2) as roi
	from dep_emp de
	left join emp_ord eo on eo.did=de.did
	left join best_emp be on be.did=de.did and be.rn=1)
--Основной запрос
SELECT
	depart as "отдел",
	kol as "кол-во сотрудников",
	sal as "сумма зарплат сотрудников",
	total_rev as "суммарная выручка",
	round(total_rev*1.0/nullif(kol,0),2) as "средняя выручка",
	roi as "коэффициент окупаемости",
	case 
		when roi> 1.5 then 'высокая'
		when roi> 1.0 then 'средняя'
		else 'низкая'
		end as "категория по окупаемости",
	best_manager as "лучший менеджер",
	coalesce(total_rev-lag(total_rev) over (order by total_rev desc),0) as "разница в выручке с предыдущим отделом",
	rank() over (order by total_rev desc) as "ранг по выручке"
from dep_stats
order by "ранг по выручке";
	
	
	
	



	
	
	
	
	
	
	
	
	
	