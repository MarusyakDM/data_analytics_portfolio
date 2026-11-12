DROP TABLE IF EXISTS transactions;

-- 1. Создаем таблицу транзакций
CREATE TABLE transactions (
	transaction_id INTEGER PRIMARY KEY,
    client_id INTEGER,
	transaction_date TIMESTAMP,
    amount INTEGER
);
-- 2. Заполняем транзакции
INSERT INTO transactions (transaction_id, client_id, transaction_date, amount) VALUES

(1, 101, '2024-05-01 10:00:00', 5000),
(2, 101, '2024-05-01 14:30:00', 9500),
(3, 101, '2024-05-01 18:15:00', 8000),
(4, 102, '2024-05-01 09:00:00', 50000),
(5, 103, '2024-05-02 11:00:00', 1500),
(6, 104, '2024-05-02 12:00:00', 9000),
(7, 104, '2024-05-02 13:00:00', 9000),
(8, 104, '2024-05-02 14:00:00', 9000),
(9, 105, '2024-05-03 10:00:00', 12000),
(10, 105, '2024-05-04 10:00:00', 12000),
(11, 105, '2024-05-05 10:00:00', 12000),
(12, 101, '2024-05-03 15:00:00', 7000);

select * from transactions;