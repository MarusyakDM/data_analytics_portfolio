with 
--Находим дату первой покупки для каждого пользователя
start_date as (
	select user_id as uid, min(purchase_date) as first_date
	from user_purchases
	group by user_id
	order by user_id
),
--Находим разницу между покупкой и первой покупкой
m_diff as (
	select sd.uid as uid, sd.first_date as fdate,
			(extract(year from up.purchase_date)*12+extract(month from up.purchase_date))-
			(extract(year from sd.first_date)*12+extract(month from sd.first_date)) as month_diff --Расчет разницы в месяцах
	from start_date as sd
	join user_purchases as up on up.user_id=sd.uid
)
--Основной запрос: 
select 
	count(distinct uid) as "Кол-во уникальных пользователей",
	date_trunc('month', fdate) as "Месяц когорты", --Обрезаем дату до начала месяца
	month_diff as "Разница между покупками"
from m_diff
group by date_trunc('month', fdate), month_diff
order by "Месяц когорты", month_diff;
	