-- Удаляем старые таблицы (если есть)
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- Отделы
CREATE TABLE departments (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50)
);

INSERT INTO departments (id, name) VALUES
(1, 'Аналитика'),
(2, 'Разработка'),
(3, 'Дизайн'),
(4, 'Маркетинг');

-- Сотрудники
CREATE TABLE employees (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50),
    position VARCHAR(50),
    salary INTEGER,
    department_id INTEGER
);

INSERT INTO employees (id, name, position, salary, department_id) VALUES
(1, 'Аня', 'аналитик', 80000, 1),
(2, 'Борис', 'разработчик', 120000, 2),
(3, 'Вика', 'дизайнер', 90000, 3),
(4, 'Гриша', 'разработчик', 130000, 2),
(5, 'Даша', 'аналитик', 85000, 1);

-- Клиенты
CREATE TABLE customers (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50),
    city VARCHAR(50)
);

INSERT INTO customers (id, name, city) VALUES
(1, 'ООО Ромашка', 'Москва'),
(2, 'ИП Иванов', 'Санкт-Петербург'),
(3, 'ООО ТехноСофт', 'Москва'),
(4, 'ЗАО Прогресс', 'Казань'),
(5, 'ООО Старт', 'Новосибирск'),
(6, 'ИП Петрова', 'Москва'),
(7, 'ООО Вектор', 'Санкт-Петербург');

-- Заказы
CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    employee_id INTEGER,
    customer_id INTEGER,
    amount INTEGER,
    order_date DATE
);

INSERT INTO orders (id, employee_id, customer_id, amount, order_date) VALUES
(1, 1, 1, 15000, '2024-01-15'),
(2, 1, 3, 22000, '2024-02-03'),
(3, 1, 1, 18000, '2024-03-10'),
(4, 2, 2, 45000, '2024-01-20'),
(5, 2, 4, 38000, '2024-02-14'),
(6, 3, 5, 12000, '2024-01-25'),
(7, 3, 6, 9500,  '2024-03-05'),
(8, 4, 3, 60000, '2024-01-30'),
(9, 4, 7, 52000, '2024-02-18'),
(10, 4, 1, 48000, '2024-03-22'),
(11, 5, 2, 8000,  '2024-02-10'),
(12, 5, 5, 11000, '2024-03-15');














