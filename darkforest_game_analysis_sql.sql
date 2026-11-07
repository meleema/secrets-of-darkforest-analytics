/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Яровая Мария Васильевна 
 * Дата: 03.11.2026г.
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным: 
SELECT 
	-- Считаю общее количество игроков, зарегистрированных в игре, по первичному ключу id
	COUNT(id) AS total_users_cnt,
	-- Считаю количество платящих игроков. Для этого рассматриваю столбец payer (1 - платящий, 0 - не платящий). 
	-- Использую функцию SUM(), так как поле payer является бинарным (в ином случае такой подход не сработает).
	SUM(payer) AS paying_users_cnt,
	-- Использую функцию AVG(), так как поле payer является бинарным (в ином случае такой подход не сработает). Это даст долю игроков
	ROUND(AVG(payer)::numeric, 4) AS share_paying_users,
	ROUND(AVG(payer)::numeric * 100, 2) AS share_paying_users_pct
-- Рассматриваю таблицу fantasy.users, так как там содержится информация о зарегистрированных пользователях (в
-- том числе информация о том, является ли игрок платящим или нет)
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT 
	-- Вывожу название рас
	r.race,
	-- Для каждой расы считаю количество платящих пользователей 
	SUM(payer) AS cnt_paying_users_race,
	-- Для каждой расы считаю общее количество пользователей 
	COUNT(id) AS total_users_race,
	-- Для каждой расы считаю долю платящих игроков среди всех зарегистрированных пользователей  
	ROUND(SUM(payer)::numeric / COUNT(id), 4) AS share_paying_users_race,
	ROUND(SUM(payer)::numeric / COUNT(id) * 100, 2) AS share_paying_users_race_pct
-- Для данной задачи использую таблицу users (чтобы получить информацию о зарегистрированных пользователях) и таблицу race (чтобы получить название расы)
FROM fantasy.users AS u
-- Использую левое присоединение таблиц (чтобы не потерять информацию о пользователях), в качестве левой таблицы выступает users, в качестве правой - race, 
-- соединяю по ключу race_id (данное поле связывает эти таблицы, для таблицы race - это первичный ключ, для таблицы users - внешний ключ)
LEFT JOIN fantasy.race AS r ON u.race_id = r.race_id
-- Группирую по расам, чтобы для каждой отдельной группы получить общее кол-во пользователей и кол-во платящих пользователей 
GROUP BY r.race
-- Сортирую по полю share_paying_users_race в порядке убывания
ORDER BY share_paying_users_race DESC;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount: 
-- С УЧЕТОМ ПОКУПОК С НУЛЕВОЙ СТОИМОСТЬЮ
SELECT 
	-- Считаю общее количество покупок 
	-- В данной таблице: одна строка - отдельная покупка
	-- Значит количество покупок буду считать по полю transaction_id - идентификатору покупки
	COUNT(transaction_id) AS total_transactions_cnt,
	-- Далее считаю суммарную стоимость всех покупок
	-- Так как каждая строка - отдельная покупка, при помощи функции SUM() просуммирую значения поля amount
	SUM(amount) AS total_amount,
	-- При помощи функций MIN() и MAX() нахожу минимальную и максимальную стоимость покупки
	MIN(amount) AS min_amount,
	MAX(amount) AS max_amount,
	-- Среднее значение стоимости вычисляю при помощи функции AVG() по полю amount
	ROUND(AVG(amount)::numeric, 2) AS avg_amount,
	-- Медиану рассчитываю как 50-й процентиль
	-- amount — денежная сумма, величина по сути непрерывная, и медиана здесь нужна как статистическая оценка центра. 
	-- Поэтому PERCENTILE_CONT уместнее: он даёт медиану с интерполяцией.
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)::numeric,2) AS median_amount,
	-- Рассчитываю стандартное отклонение функцией STDDEV() по полю amount
	ROUND(STDDEV(amount)::numeric,2) AS std_amount
-- Рассматриваю таблицу events, так как она содержит информацию о покупках
FROM fantasy.events;

-- БЕЗ УЧЕТА ПОКУПОК С НУЛЕВОЙ СТОИМОСТЬЮ
SELECT 
	-- Считаю общее количество покупок 
	-- В данной таблице: одна строка - отдельная покупка
	-- Значит количество покупок буду считать по полю transaction_id - идентификатору покупки
	COUNT(transaction_id) AS total_transactions_cnt,
	-- Далее считаю суммарную стоимость всех покупок
	-- Так как каждая строка - отдельная покупка, при помощи функции SUM() просуммирую значения поля amount
	SUM(amount) AS total_amount,
	-- При помощи функций MIN() и MAX() нахожу минимальную и максимальную стоимость покупки
	MIN(amount) AS min_amount,
	MAX(amount) AS max_amount,
	-- Среднее значение стоимости вычисляю при помощи функции AVG() по полю amount
	ROUND(AVG(amount)::numeric, 2) AS avg_amount,
	-- Медиану рассчитываю как 50-й процентиль
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)::numeric,2) AS median_amount,
	-- Рассчитываю стандартное отклонение функцией STDDEV() по полю amount
	ROUND(STDDEV(amount)::numeric,2) AS std_amount
-- Рассматриваю таблицу events, так как она содержит информацию о покупках
FROM fantasy.events
WHERE amount > 0;

-- 2.2: Аномальные нулевые покупки: 
SELECT 
	-- Считаю абсолютное количество покупок с нулевой стоимостью
	-- Считаю строки, где amount = 0, через FILTER
	COUNT(*) FILTER (WHERE amount = 0) AS zero_amount_cnt,
	-- Общее число покупок 
	COUNT(*) AS total_amounts,
	-- Считаю долю покупок с нулевой стоимостью от общего числа покупок 
	-- доля покупок с нулевой стоимостью от общего числа покупок = (количество покупок с amount = 0)/(общее число покупок)
	ROUND(COUNT(*) FILTER (WHERE amount = 0)::numeric/COUNT(*),4) AS share_zero_amount,
	ROUND(COUNT(*) FILTER (WHERE amount = 0)::numeric/COUNT(*)*100,2) AS share_zero_amount_pct
-- Рассматриваю таблицу events, так как она содержит информацию о покупках
FROM fantasy.events;

-- Дополнительное исследование природы нулевых покупок:
SELECT 
    e.item_code,
    i.game_items,
    COUNT(*) AS zero_tx_cnt,
    -- Проверяем, сколько из них имели продавца (передачи между игроками)
    COUNT(e.seller_id) AS with_seller_cnt
FROM fantasy.events AS e
LEFT JOIN fantasy.items AS i ON e.item_code = i.item_code
WHERE e.amount = 0
GROUP BY e.item_code, i.game_items;

-- 2.3: Популярные эпические предметы:(ИСПРАВЛЕНО: amount > 0)
SELECT 
	-- Вывожу названия эпических предметов для наглядности 
	i.game_items,
	-- Считаю количество покупок для каждого эпического предмета. Абсолютное количество внутриигровых продаж
	COUNT(e.transaction_id) AS items_amount_cnt,
	-- Теперь считаю долю продаж каждого предмета от всех продаж
	-- Все продажи считаю при помощи оконной функции. В качестве окна беру все предметы: SUM(COUNT(e.transaction_id)) OVER() 
	ROUND(COUNT(e.transaction_id)::numeric/(SUM(COUNT(e.transaction_id)) OVER()),4) AS share_items_amount,
	ROUND(COUNT(e.transaction_id)::numeric/(SUM(COUNT(e.transaction_id)) OVER()) * 100,2) AS share_items_amount_pct,
	-- Считаю долю игроков, которые хотя бы раз покупали этот предмет от общего числа внутриигровых покупателей 
	-- Количество покупателей по каждому предмету считаю как COUNT(DISTINCT e.id)
	-- Чтобы посчитать общее число внутриигровых покупателей, пользуюсь подзапросом SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount > 0
	ROUND(COUNT(DISTINCT e.id)::numeric/(SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount > 0),4) AS share_items_users,
	ROUND(COUNT(DISTINCT e.id)::numeric/(SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount > 0)*100,2) AS share_items_users_pct
-- Рассматриваю таблицы events (содержит информацию о покупках) и items (чтобы получить названия эпических предметов)
FROM fantasy.events AS e
-- Присоединяю items для получения названий эпических предметов 
-- Использую левое присоединение таблиц (чтобы не потерять информацию о покупках), в качестве левой таблицы выступает events, в качестве правой - items
LEFT JOIN fantasy.items AS i ON e.item_code = i.item_code  
-- Исключаю покупки с нулевой стоимостью (не помогают зарабатывать внутриигровую валюту «райские лепестки»)
WHERE e.amount > 0
-- Группирую по названиям эпических предметов, чтобы получить информацию для каждого 
GROUP BY i.game_items
-- Сортирую по популярности
ORDER BY items_amount_cnt DESC;

-- Дополнительно: проверка востребованности ассортимента (все ли предметы каталога покупались)
SELECT 
    COUNT(*) AS total_catalog_items,
    -- Сколько из них покупали за деньги:
    (SELECT COUNT(DISTINCT item_code) FROM fantasy.events WHERE amount > 0) AS bought_items_cnt
FROM fantasy.items;

-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа: (ИСПРАВЛЕНО: добавила агрегацию покупок до уровня игроков, добавлено округление)
-- CTE для получения информации (числа покупок и общей стоимости) для каждого отдельного игрока, который совершал покупки
WITH users_events AS(
	SELECT
		id,
		COUNT(transaction_id) AS purchases_cnt,
		SUM(amount) AS total_spent
	FROM fantasy.events
	WHERE amount > 0
	GROUP BY id
)
SELECT 
	-- Для наглядности вывожу название каждой расы
	r.race,
	-- Считаю общее количество зарегистрированных пользователей (из таблицы users)
	COUNT(u.id) AS total_users,
	-- Считаю количество игроков, совершивших покупки (из таблицы events)
	COUNT(e.id) AS total_buyers,
	-- Считаю долю покупателей (total_buyers) от зарегистрированных пользователей (total_users) для каждой расы
	ROUND(COUNT(e.id)::numeric/COUNT(u.id),4) AS share_buyers_users,
	ROUND(COUNT(e.id)::numeric/COUNT(u.id)*100,2) AS share_buyers_users_pct,
	-- Считаю долю платящих игроков среди игроков, которые совершили внутриигровые покупки
	-- Количество платящих игроков считаю как COUNT(CASE WHEN u.payer = 1 THEN e.id END) (те пользователи, которые являются платящими (u.payer = 1) 
	-- и совершали покупку (e.id))
	ROUND(COUNT(CASE WHEN u.payer = 1 THEN e.id END)::numeric/COUNT(e.id),4) AS share_payer_users,
	ROUND(COUNT(CASE WHEN u.payer = 1 THEN e.id END)::numeric/COUNT(e.id)*100,2) AS share_payer_users_pct,
	-- Среднее количество покупок на одного игрока, совершившего внутриигровые покупки
	ROUND(SUM(e.purchases_cnt)::numeric/COUNT(e.id),4) AS avg_purchases_per_buyer,
	-- Средняя стоимость одной покупки на одного игрока, совершившего внутриигровые покупки
	ROUND(SUM(e.total_spent)::numeric/SUM(e.purchases_cnt),4) AS avg_amount_per_buyer,
	-- Средняя суммарная стоимость всех покупок на одного игрока, совершившего внутриигровые покупки
	ROUND(SUM(e.total_spent)::numeric/COUNT(e.id),4) AS avg_total_spend_per_buyer
-- Рассматриваю три таблицы для данной задачи
-- users: содержит информацию о всех зарегистрированных пользователях
-- race: содержит названия рас
-- users_events: CTE, информация о пользователях, которые совершали покупки, о количестве их покупок и суммарной стоимости 
FROM fantasy.users AS u
-- Использую левое присоединение (чтобы не потерять информацию о зарегистрированных пользователях)
-- В качестве левой таблицы выступает users, в качестве правой race
LEFT JOIN fantasy.race AS r ON u.race_id = r.race_id
-- Использую левое присоединение (чтобы не потерять информацию о зарегистрированных пользователях)
-- В качестве левой таблицы выступает users, в качестве правой events
LEFT JOIN users_events AS e ON u.id = e.id 
-- Группирую по расам персонажей, чтобы получить информацию для каждой расы
GROUP BY r.race
ORDER BY total_buyers;
