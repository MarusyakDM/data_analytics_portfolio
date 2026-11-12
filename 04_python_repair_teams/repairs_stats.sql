SELECT 
    t.team_name AS "Бригада",
    EXTRACT(MONTH FROM r.start_date)::INTEGER AS "Месяц",
    COUNT(r.repair_id) AS "Кол-во ремонтов",
    ROUND(AVG(EXTRACT(EPOCH FROM (r.end_date - r.start_date)) / 3600), 1) AS "Среднее время (ч)",
    ROUND(AVG(r.cost), 0) AS "Средняя стоимость"
FROM teams t
JOIN repairs r ON r.team_id = t.team_id
GROUP BY 
    t.team_name, 
    EXTRACT(MONTH FROM r.start_date)
ORDER BY 
    "Бригада", 
    "Месяц";