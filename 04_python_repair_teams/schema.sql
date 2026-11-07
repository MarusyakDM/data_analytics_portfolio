DROP TABLE IF EXISTS repairs;
DROP TABLE IF EXISTS teams;

-- 1. Создаем таблицу бригад
CREATE TABLE teams (
    team_id INTEGER PRIMARY KEY,
    team_name VARCHAR(50),
    shift VARCHAR(20)
);

-- Заполняем бригады
INSERT INTO teams (team_id, team_name, shift) VALUES
(1, 'Бригада А', 'Дневная'),
(2, 'Бригада Б', 'Ночная'),
(3, 'Бригада В', 'Дневная');

-- 2. Создаем таблицу ремонтов
CREATE TABLE repairs (
    repair_id SERIAL PRIMARY KEY,
    team_id INTEGER,
    machine_id INTEGER,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    cost INTEGER,
    FOREIGN KEY (team_id) REFERENCES teams(team_id)
);

-- 3. Заполняем ремонты (генерируем данные за 3 месяца)
-- Бригада А (стабильно, среднее время ~4 часа)
INSERT INTO repairs (team_id, machine_id, start_date, end_date, cost) VALUES
(1, 101, '2024-01-05 08:00:00', '2024-01-05 12:00:00', 15000),
(1, 102, '2024-01-15 09:00:00', '2024-01-15 13:30:00', 18000),
(1, 103, '2024-02-10 10:00:00', '2024-02-10 14:00:00', 16000),
(1, 101, '2024-03-20 08:00:00', '2024-03-20 11:30:00', 14000);

-- Бригада Б (работает чуть медленнее, ~5 часов)
INSERT INTO repairs (team_id, machine_id, start_date, end_date, cost) VALUES
(2, 101, '2024-01-10 20:00:00', '2024-01-11 01:00:00', 20000),
(2, 104, '2024-02-15 22:00:00', '2024-02-16 03:00:00', 21000),
(2, 102, '2024-03-05 21:00:00', '2024-03-06 02:30:00', 19500);

-- Бригада В (в январе-феврале работала как все, а в марте внедрили мотивацию, и она стала быстрее!)
INSERT INTO repairs (team_id, machine_id, start_date, end_date, cost) VALUES
(3, 105, '2024-01-20 08:00:00', '2024-01-20 13:00:00', 17000),
(3, 105, '2024-02-25 09:00:00', '2024-02-25 14:00:00', 17000),
(3, 105, '2024-03-25 08:00:00', '2024-03-25 10:30:00', 12000); -- <-- ЭФФЕКТ МОТИВАЦИИ