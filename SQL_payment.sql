--Data checking
SELECT *
FROM dbo.Payment_2017
--115,035 rows
SELECT *
FROM dbo.Payment_2018
--245,709 rows
SELECT *
FROM dbo.table_status
SELECT *
FROM dbo.method_payment
SELECT *
FROM dbo.product

--Tạo Star schema 
ALTER TABLE dbo.Payment_2017
ADD FOREIGN KEY(payment_id) REFERENCES dbo.Method_payment (payment_id)
ALTER TABLE dbo.Payment_2017
ADD FOREIGN KEY(product_id) REFERENCES dbo.Product (product_id)
ALTER TABLE dbo.Payment_2017
ADD FOREIGN KEY(message_id) REFERENCES dbo.Table_status (message_id)
ALTER TABLE dbo.Payment_2018 
ADD FOREIGN KEY(payment_id) REFERENCES dbo.Method_payment (payment_id)
ALTER TABLE dbo.Payment_2018
ADD FOREIGN KEY(product_id) REFERENCES dbo.Product (product_id)
ALTER TABLE dbo.Payment_2018 
ADD FOREIGN KEY(message_id) REFERENCES dbo.Table_status (message_id)

---1.Data cleaning
--Cleaning irrelevant data
ALTER TABLE dbo.Payment_2017
DROP COLUMN bank_id,platform_id,app_version
ALTER TABLE dbo.Payment_2018
DROP COLUMN bank_id,platform_id,app_version
ALTER TABLE dbo.Product
DROP COLUMN online_offline

/* Sau khi xóa các cột không cần thiết trong bài báo cáo phân tích, bây giờ chúng ta kiểm tra dữ liệu theo từng bảng
Steps: Duplicates,Type convention,Syntax errors,Missing Values */
--Duplicates
/* Kiểm tra các giao dịch có ghi nhận trùng lặp hay không.
Thông tin khách hàng mỗi giao dịch chỉ ghi nhận 1 giá trị thời gian, kiểm tra có trùng hay không của 2 bảng fact: Payment_2017 và Payment_2018 */
--Syntax errors
/* Kiểm tra xem cùng một thông tin về message,payment,product,promotion,.. 
Có thông tin nào: (sai chính tả, lỗi nhập liệu) sẽ không tìm được thông tin từ bảng từ bảng Dimension */
--Missing Values
/* Những dữ liệu bị mất trong bảng */

--Table Payment_2017
--Duplicates
SELECT order_id,COUNT(customer_id) AS duplicates_orders
FROM dbo.Payment_2017
GROUP BY order_id
HAVING COUNT(customer_id) > 1

SELECT customer_id,transaction_date,COUNT(order_id) AS duplicate_orders_customers_over_time
FROM dbo.Payment_2017
GROUP BY customer_id,transaction_date
HAVING COUNT(order_id)> 1
--> không có giao dịch nào trùng lặp và không có khách hàng nào bị ghi nhận thời gian giao dịch trùng lặp
--Syntax errors
SELECT *
FROM dbo.Payment_2017
WHERE message_id NOT IN (SELECT message_id FROM dbo.Table_status)

SELECT *
FROM dbo.Payment_2017
WHERE payment_id NOT IN (SELECT payment_id FROM dbo.Method_payment)

SELECT *
FROM dbo.Payment_2017
WHERE product_id NOT IN (SELECT product_id FROM dbo.Product)

SELECT promotion_id
    ,SUM(discount_price) AS total_discount
FROM dbo.Payment_2017
GROUP BY promotion_id
ORDER BY total_discount ASC
--> không có thông tin nào bị sai hay lỗi nhập liệu 
--Missing Values
SELECT *
FROM dbo.Payment_2017
WHERE order_id IS NULL OR customer_id IS NULL OR product_id IS NULL OR payment_id IS NULL OR promotion_id IS NULL
    OR message_id IS NULL OR discount_price IS NULL OR final_price IS NULL OR transaction_date IS NULL
--> dữ liệu không có giá trị Null

--Table Payment_2018
--Duplicates
SELECT order_id,COUNT(customer_id) AS duplicates_orders
FROM dbo.Payment_2018
GROUP BY order_id
HAVING COUNT(customer_id) > 1

SELECT customer_id,transaction_date,COUNT(order_id) AS duplicate_orders_customers_over_time
FROM dbo.Payment_2018
GROUP BY customer_id,transaction_date
HAVING COUNT(order_id)> 1
--> không có giao dịch nào trùng lặp và không có khách hàng nào bị ghi nhận thời gian giao dịch trùng lặp
--Syntax errors
SELECT *
FROM dbo.Payment_2018
WHERE message_id NOT IN (SELECT message_id FROM dbo.Table_status)

SELECT *
FROM dbo.Payment_2018
WHERE payment_id NOT IN (SELECT payment_id FROM dbo.Method_payment)

SELECT *
FROM dbo.Payment_2018
WHERE product_id NOT IN (SELECT product_id FROM dbo.Product)

SELECT promotion_id
    ,SUM(discount_price) AS total_discount
FROM dbo.Payment_2018
GROUP BY promotion_id
ORDER BY total_discount ASC
--> không có thông tin nào bị sai hay lỗi nhập liệu 
--Missing Values
SELECT *
FROM dbo.Payment_2018
WHERE order_id IS NULL OR customer_id IS NULL OR product_id IS NULL OR payment_id IS NULL OR promotion_id IS NULL
    OR message_id IS NULL OR discount_price IS NULL OR final_price IS NULL OR transaction_date IS NULL
--> dữ liệu không có giá trị Null

--Table: Status
SELECT *
FROM dbo.Table_status

SELECT message_id
    ,COUNT([description]) AS duplicates_status
FROM dbo.Table_status
GROUP BY message_id
HAVING COUNT([description]) > 1
--> không có mã trạng thái giao dịch nào trùng lặp, lỗi nhập và missing data

--Table: Method_payment
SELECT *
FROM dbo.Method_payment
--> không có mã thanh toán nào trùng lặp, lỗi nhập liệu và missing data

--Table: Product
--Duplicates
SELECT *
FROM dbo.Product

SELECT product_id
    ,COUNT(sub_category) AS duplicates_product
FROM dbo.Product
GROUP BY product_id
HAVING COUNT(sub_category) > 1
--> không có mã sản phẩm nào trùng lặp là mỗi mã sản phẩm đính kèm một mô tả loại hình giao dịch sản phẩm
--Syntax errors
SELECT transaction_type
    ,COUNT(product_id) AS count_product
FROM dbo.Product
GROUP BY transaction_type

SELECT category
    ,COUNT(product_id) AS count_product
FROM dbo.Product
GROUP BY category

SELECT sub_category
    ,COUNT(product_id) AS count_product
FROM dbo.Product
GROUP BY sub_category
--> không có thông tin nào bị sai hay lỗi nhập liệu 
--Missing Values
SELECT *
FROM dbo.Product
WHERE product_id IS NULL OR transaction_type IS NULL OR category IS NULL OR sub_category IS NULL
--> dữ liệu không có giá trị Null


---2.Join Table
WITH table_join AS (
    SELECT table_fact.*
        ,pro.transaction_type, pro.category, pro.sub_category
        ,method.payment_method
        ,sta.[description]
    FROM (SELECT * FROM Payment_2017 UNION SELECT * FROM Payment_2018) AS table_fact --360,744 rows
    LEFT JOIN dbo.Product AS pro
        ON table_fact.product_id = pro.product_id
    LEFT JOIN dbo.Method_payment AS method
        ON table_fact.payment_id = method.payment_id
    LEFT JOIN dbo.Table_status AS sta
        ON table_fact.message_id = sta.message_id
)
--> Bảng sau khi JOIN lại ta có 360.744 dòng và 14 cột. Bây giờ ta kiểm tra lại dữ liệu sau khi JOIN có bị NULL hay không
SELECT *
FROM table_join
WHERE order_id IS NULL OR customer_id IS NULL OR product_id IS NULL OR payment_id IS NULL OR promotion_id IS NULL
    OR message_id IS NULL OR discount_price IS NULL OR final_price IS NULL OR transaction_date IS NULL
    OR transaction_type IS NULL OR category IS NULL OR sub_category IS NULL OR payment_method IS NULL or [description] IS NULL
--> không có giá trị NULL nào trong table_join

--Lưu kết quả JOIN thành 1 bảng để dễ thạo tác sau này
SELECT table_fact.*
    ,pro.transaction_type, pro.category, pro.sub_category
    ,method.payment_method
    ,sta.[description]
INTO table_join
FROM (SELECT * FROM Payment_2017 UNION SELECT * FROM Payment_2018) AS table_fact
LEFT JOIN dbo.Product AS pro
    ON table_fact.product_id = pro.product_id
LEFT JOIN dbo.Method_payment AS method
    ON table_fact.payment_id = method.payment_id
LEFT JOIN dbo.Table_status AS sta
    ON table_fact.message_id = sta.message_id


---3.Analyze Customer portrait
/* Overviews
SELECT top 10 * 
FROM table_join

SELECT YEAR(transaction_date) AS [year]
    ,COUNT(order_id) AS number_orders
    ,COUNT(distinct customer_id) AS number_customers
    ,SUM(discount_price) AS money_promotion
    ,SUM(CAST(final_price AS BIGINT)) AS total_money
    ,AVG(CAST(final_price AS float)) AS average_number_of_moneys_year
INTO overview
FROM table_join
GROUP BY YEAR(transaction_date)

SELECT *
    ,total_money / number_orders AS qư
FROM overview

SELECT YEAR(transaction_date) AS [year]
    ,payment_method
    ,COUNT(order_id) AS number_orders
    ,COUNT(distinct customer_id) AS number_customers
    ,SUM(discount_price) AS money_promotion
    ,SUM(CAST(final_price AS BIGINT)) AS total_money
    ,AVG(CAST(final_price AS float)) AS average_number_of_moneys_year
FROM table_join
GROUP BY YEAR(transaction_date),payment_method
ORDER BY YEAR(transaction_date),payment_method


 SELECT
    COUNT(CASE WHEN promotion_id = '0' THEN order_id END) OVER (PARTITION BY customer_id) AS orders_original
    ,COUNT(CASE WHEN promotion_id != '0' THEN order_id END) OVER (PARTITION BY customer_id) AS orders_promotion
    ,SUM(CAST(final_price AS BIGINT)) OVER (PARTITION BY customer_id) AS total_money
    ,SUM(CAST(discount_price AS BIGINT)) OVER (PARTITION BY customer_id) AS total_discount
    ,COUNT(CASE WHEN message_id = 1 THEN order_id END) OVER (PARTITION BY customer_id) AS orders_success
    ,COUNT(CASE WHEN message_id != 1 THEN order_id END) OVER (PARTITION BY customer_id) AS orders_fail
--INTO #table_cus
FROM table_join 
--> 12,771 KHÁCH HÀNG kèm các thông tin về giao dịch */



---3.1. Time Series data - when do transaction?
-- Quan sát xu hướng theo tháng trong suất 2 năm 
WITH table_original AS (
    SELECT customer_id,order_id,transaction_type,category,sub_category,[description]
        ,transaction_date
        ,YEAR(transaction_date) AS [year]
        ,MONTH(transaction_date) AS [month]
        ,DAY(transaction_date) AS [day_month]
        ,DATENAME(w,transaction_date) AS [name_day]
        ,DATEPART(HOUR,transaction_date) AS [hour]
    FROM table_join
    WHERE message_id = 1
)
SELECT [year],[month]
    ,COUNT(order_id) AS number_trans
FROM table_original
GROUP BY [year],[month]
ORDER BY [year],[month] ASC
/* giao dịch năm 2018 thực hiện nhiều hơn gấp 2 lần so với 2017 */
;
    --Product trend in 2018
    WITH table_original AS (
        SELECT customer_id,order_id,transaction_type,category,sub_category,[description]
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND YEAR(transaction_date) = 2018
    )
    SELECT transaction_type,category
        ,COUNT(order_id) AS number_trans
        ,(SELECT COUNT(order_id) FROM table_original) AS total_trans
        ,CAST(CAST(COUNT(order_id) AS FLOAT) / (SELECT COUNT(order_id) FROM table_original) AS DECIMAL(10,2)) AS [percent]
    FROM table_original
    GROUP BY transaction_type,category
    HAVING transaction_type = 'Payment'
    ORDER BY [number_trans] DESC 
;
    --the product trend is increasing in the last 6 months of the year
    WITH table_original AS (
        SELECT customer_id,order_id,transaction_type,category,sub_category,[description]
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 
        AND (transaction_date BETWEEN '2017-06-01' AND '2018-01-01') OR transaction_date > '2018-07-01'
    )
    SELECT transaction_type,category
        ,COUNT(order_id) AS number_trans
        ,(SELECT COUNT(order_id) FROM table_original) AS total_trans
        ,CAST(CAST(COUNT(order_id) AS FLOAT) / (SELECT COUNT(order_id) FROM table_original) AS DECIMAL(10,2)) AS [percent]
    FROM table_original
    GROUP BY transaction_type,category
    HAVING transaction_type = 'Payment'
    ORDER BY [number_trans] DESC 
;
    --From September to December 2018, specifically in December 2018: transaction of customers
    WITH table_original AS (
        SELECT customer_id,order_id,transaction_type,category,sub_category,[description]
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 
        AND transaction_date > '2018-12-01'
    )
    SELECT transaction_type,category
        ,COUNT(order_id) AS number_trans
        ,(SELECT COUNT(order_id) FROM table_original) AS total_trans
        ,CAST(CAST(COUNT(order_id) AS FLOAT) / (SELECT COUNT(order_id) FROM table_original) AS DECIMAL(10,2)) AS [percent]
    FROM table_original
    GROUP BY transaction_type,category
    HAVING transaction_type = 'Payment'
    ORDER BY [number_trans] DESC 

;
--average number_transactions per day per month
WITH table_original AS (
    SELECT customer_id,order_id,transaction_type,category,sub_category,[description]
        ,transaction_date
        ,YEAR(transaction_date) AS [year]
        ,MONTH(transaction_date) AS [month]
        ,DAY(transaction_date) AS [day_month]
        ,DATENAME(w,transaction_date) AS [name_day]
        ,DATEPART(HOUR,transaction_date) AS [hour]
    FROM table_join
    WHERE message_id = 1
)
,table_day_in_month AS (
    SELECT [month], [day_month]
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY [month],[day_month]
    -- ORDER BY [day_month] ASC 
)
SELECT [day_month]
    ,AVG(number_trans) AS avg_number_trans_day_month
FROM table_day_in_month
GROUP BY [day_month]
/* Quan sát xu hướng các ngày trong tháng. Lấy trung bình số lượng giao dịch của từng ngày trong 2 năm. 
Do có tháng thì có 30,31 ngày, tháng 2 chỉ có 28 ngày nên chỉ đếm số giao dịch thôi sẽ không phản ánh đúng xu hướng của khách hàng */
;
    --transactions on 11th of month
    WITH table_original AS (
        SELECT customer_id,order_id,transaction_type,category,sub_category,[description]
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND DAY(transaction_date) = 11 AND transaction_type = 'Payment'
    )
    SELECT category,sub_category
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY category,sub_category
    ORDER BY number_trans DESC

        --checking average Top-up account on 11th of month
        WITH table_original AS (
            SELECT customer_id,order_id,transaction_type,category,sub_category,[description]
                ,transaction_date
                ,YEAR(transaction_date) AS [year]
                ,MONTH(transaction_date) AS [month]
                ,DAY(transaction_date) AS [day_month]
                ,DATENAME(w,transaction_date) AS [name_day]
                ,DATEPART(HOUR,transaction_date) AS [hour]
            FROM table_join
            WHERE message_id = 1 AND transaction_type = 'Top-up account'
        )
        ,table_day_in_month AS (
            SELECT [month], [day_month]
                ,COUNT(order_id) AS number_trans
            FROM table_original
            GROUP BY [month],[day_month]
            -- ORDER BY [day_month] ASC 
        )
        SELECT [day_month]
            ,AVG(number_trans) AS avg_number_trans_day_month
        FROM table_day_in_month
        GROUP BY [day_month]
;
    --transactions on 10th - 22th of month
    WITH table_original AS (
        SELECT customer_id,order_id,transaction_type,category,sub_category,[description]
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND (DAY(transaction_date) BETWEEN 10 AND 22) AND transaction_type = 'Payment'
    )
    SELECT category,sub_category
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY category,sub_category
    ORDER BY number_trans DESC
;
--number_transactions by weekday
WITH table_original AS (
    SELECT customer_id, order_id, transaction_type, category, sub_category, [description]
        ,transaction_date
        ,YEAR(transaction_date) AS [year]
        ,MONTH(transaction_date) AS [month]
        ,DAY(transaction_date) AS [day_month]
        ,DATENAME(w,transaction_date) AS [name_day]
        ,DATEPART(HOUR,transaction_date) AS [hour]
    FROM table_join
    WHERE message_id = 1
)
,table_name_day AS (
    SELECT [name_day]
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY [name_day]
    -- ORDER BY [name_day] 
)
SELECT table_week.[name_day], table_name_day.number_trans
FROM table_week
LEFT JOIN table_name_day
    ON table_week.[name_day] = table_name_day.[name_day]
/* số giao dịch theo các ngày trong tuần */
--tạo bảng format: day in week
CREATE TABLE table_week(
    [name_day] VARCHAR(20) NOT NULL
    ,number_trans INT)

    INSERT INTO table_week 
    ([name_day]) VALUES ('Monday');
    INSERT INTO table_week 
    ([name_day]) VALUES ('Tuesday');
    INSERT INTO table_week 
    ([name_day]) VALUES ('Wednesday');
    INSERT INTO table_week 
    ([name_day]) VALUES ('Thursday');
    INSERT INTO table_week 
    ([name_day]) VALUES ('Friday');
    INSERT INTO table_week 
    ([name_day]) VALUES ('Saturday');
    INSERT INTO table_week 
    ([name_day]) VALUES ('Sunday')

    --transactions on weekend
    WITH table_original AS (
        SELECT customer_id, order_id, transaction_type, category, sub_category, [description]
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND transaction_type = 'Payment' AND category = 'Telco'
    )
    SELECT category,sub_category,[name_day]
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY category,sub_category,[name_day]
    ORDER BY number_trans DESC
    ;
    WITH table_original AS (
        SELECT customer_id, order_id, transaction_type, category, sub_category, [description]
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND transaction_type = 'Payment' AND category = 'Marketplace'
    )
    SELECT category,[name_day]
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY category,[name_day]
    ORDER BY number_trans DESC
    ;
    WITH table_original AS (
        SELECT customer_id, order_id, transaction_type, category, sub_category, [description],promotion_id
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND transaction_type = 'Payment' AND category = 'Billing' 
    )
    SELECT category,sub_category,[name_day]
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY category,sub_category,[name_day]
    ORDER BY number_trans DESC
    ;
    WITH table_original AS (
        SELECT customer_id, order_id, transaction_type, category, sub_category, [description],promotion_id
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND transaction_type = 'Payment' AND category = 'shopping' 
    )
    SELECT category,[name_day]
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY category,[name_day]
    ORDER BY number_trans DESC
    ;
    WITH table_original AS (
        SELECT customer_id, order_id, transaction_type, category, sub_category, [description],promotion_id
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND transaction_type = 'Payment' AND category = 'FnB' 
    )
    SELECT category,[name_day]
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY category,[name_day]
    ORDER BY number_trans DESC
    ;
    WITH table_original AS (
        SELECT customer_id, order_id, transaction_type, category, sub_category, [description],promotion_id
            ,transaction_date
            ,YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,DAY(transaction_date) AS [day_month]
            ,DATENAME(w,transaction_date) AS [name_day]
            ,DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND transaction_type = 'Payment' AND category = 'Movies' 
    )
    SELECT category,[name_day]
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY category,[name_day]
    ORDER BY number_trans DESC


--number_trans_by hours
WITH table_original AS (
    SELECT customer_id, order_id, transaction_type, category, sub_category, [description]
        , transaction_date
        , YEAR(transaction_date) AS [year]
        , MONTH(transaction_date) AS [month]
        , DAY(transaction_date) AS [day_month]
        , DATENAME(w,transaction_date) AS [name_day]
        , DATEPART(HOUR,transaction_date) AS [hour]
    FROM table_join
    WHERE message_id = 1
)
SELECT [hour]
    ,COUNT(order_id) AS number_trans
FROM table_original
GROUP BY [hour]
/* số giao dịch theo giờ trong ngày */
;
    --transactions from 9 to 11 AM
    WITH table_original AS (
        SELECT customer_id, order_id, transaction_type, category, sub_category, [description]
            , transaction_date
            , YEAR(transaction_date) AS [year]
            , MONTH(transaction_date) AS [month]
            , DAY(transaction_date) AS [day_month]
            , DATENAME(w,transaction_date) AS [name_day]
            , DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND (DATEPART(HOUR,transaction_date) BETWEEN 9 AND 11) AND transaction_type = 'Payment'
    )
    SELECT [hour],category
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY [hour],category
    ORDER BY category,number_trans DESC
;
    --transactions from 15 to 16 PM
    WITH table_original AS (
        SELECT customer_id, order_id, transaction_type, category, sub_category, [description]
            , transaction_date
            , YEAR(transaction_date) AS [year]
            , MONTH(transaction_date) AS [month]
            , DAY(transaction_date) AS [day_month]
            , DATENAME(w,transaction_date) AS [name_day]
            , DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND (DATEPART(HOUR,transaction_date) BETWEEN 15 AND 16) --AND transaction_type = 'Payment'
    )
    SELECT [hour],category
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY [hour],category
    ORDER BY category,number_trans DESC
;
    --transactions at 19 PM
    WITH table_original AS (
        SELECT customer_id, order_id, transaction_type, category, sub_category, [description]
            , transaction_date
            , YEAR(transaction_date) AS [year]
            , MONTH(transaction_date) AS [month]
            , DAY(transaction_date) AS [day_month]
            , DATENAME(w,transaction_date) AS [name_day]
            , DATEPART(HOUR,transaction_date) AS [hour]
        FROM table_join
        WHERE message_id = 1 AND DATEPART(HOUR,transaction_date) = 19 AND transaction_type = 'Payment'
    )
    SELECT [hour],category
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY [hour],category
    ORDER BY category,number_trans DESC
;
---3.2. Customer purchasing behavior
WITH table_original AS (
    SELECT customer_id, order_id, discount_price, final_price, transaction_type, category, sub_category, transaction_date
    FROM table_join
    WHERE message_id = 1
)
SELECT transaction_type
    ,COUNT(order_id) AS number_trans
    ,(SELECT COUNT(CAST(order_id AS FLOAT)) FROM table_original) AS total_trans
    , FORMAT(CAST(COUNT(order_id) AS FLOAT) / (SELECT COUNT(CAST(order_id AS FLOAT)) FROM table_original),'p') AS [percent]
FROM table_original
GROUP BY transaction_type
ORDER BY number_trans DESC
/* --> ta thấy các dạng giao dịch chuyển khoản thanh toán (payment) được thực hiện nhiều nhất chiếm 50% số lượng giao dịch
Sau đó là tới nạp tiền vào tài khoản (Top-up account) chiếm 32%, chuyển khoản ngân hàng (Bank Transfer) khoảng 15%.
Còn lại là các giao dịch rút tiền (Withraw) và thanh toán tín dụng (Credit Card Billing) */

WITH table_original AS (
    SELECT customer_id, order_id, discount_price, final_price, transaction_type, category, sub_category, transaction_date
    FROM table_join
    WHERE message_id = 1
)
SELECT transaction_type, category, sub_category
    ,COUNT(order_id) AS number_trans
FROM table_original
GROUP BY transaction_type,category,sub_category
ORDER BY transaction_type
/* Ta phân loại tiếp tục theo category và sub_category ta thấy
Bank Trasfer: là chuyển khoản, không có cấp độ phân loại category, sub_category nên để là Not Payment
Top-up account: là nạp tiền vào tài khoản, không có cấp độ phân loại category, sub_category nên để là Not Payment
Withdraw: là rút tiền khỏi tài khoản, không có cấp độ phân loại category, sub_category nên để là Not Payment
Credit Card Billing là thanh toán tín dụng, chỉ 1 phân loại là thanh toán tín dụng 
--> Chủ yếu hành vi thanh toán sản phẩm của khách hàng chỉ ở dạng giao dịch là Payment nên ta sẽ chỉ giữ lại các giao dịch Payment để tiếp tục phân tích */

WITH table_original AS (
    SELECT customer_id, order_id, discount_price, final_price, transaction_type, category, sub_category
    FROM table_join
    WHERE message_id = 1 AND transaction_type = 'Payment'
)
SELECT transaction_type, category, sub_category
    ,COUNT(order_id) AS number_trans
    ,(SELECT COUNT(CAST(order_id AS BIGINT)) FROM table_original) AS total_trans
    ,FORMAT(CAST(COUNT(order_id) AS FLOAT) / (SELECT COUNT(CAST(order_id AS BIGINT)) FROM table_original),'p') AS [percent]
FROM table_original
GROUP BY transaction_type,category,sub_category
ORDER BY number_trans DESC
/* Sản phẩm thuộc nhóm Telco chiếm hơn 60% lượng giao dịch của khách hàng
14% còn lại là các giao dịch Marketplace 
Nhóm Billing thanh toán các hóa đơn thì nhiều nhất là các hóa đơn tiền điện (9%)
15% còn lại là các giao dịch biên lai tiền nước, vé xem phim, internet, shopping tại cửa hàng tiện lợi,..
các sản phẩm thanh toán về đặt tour du lịch (Tour Booking),bảo hiểm (Insurance) ít lượng người quan tâm */


/* --> Ta nhận thấy Nhóm sản phẩm Telco,Marketplace,Billing chiếm khoảng 85% số lượng giao dịch trong 2 năm 2017,2018.
 Vậy phân tích theo tháng xem hành vi củ khách hàng thanh toán là như thế nào */

WITH table_original_date AS (
    SELECT customer_id, order_id, discount_price, final_price, transaction_type, category, sub_category, transaction_date
    FROM table_join
    WHERE message_id = 1 AND transaction_type = 'Payment' AND category IN ('Telco','Marketplace','Billing')
)
,table_month AS (
    SELECT YEAR(transaction_date) AS [year], MONTH(transaction_date) AS [month]
        ,category
        ,COUNT(order_id) AS number_trans
    FROM table_original_date
    GROUP BY YEAR(transaction_date),MONTH(transaction_date),category
    -- ORDER BY YEAR(transaction_date) ,MONTH(transaction_date) ASC
)
SELECT [year], [month]
    ,"Billing", "Marketplace", "Telco"
INTO #table_pivot
FROM table_month
PIVOT (
    SUM(number_trans) FOR category IN ("Billing","Marketplace","Telco")
) AS pivot_logic

--Phầm trăm tăng trưởng theo tháng của Telco 
WITH table_telco AS (
    SELECT [year], [month], Telco
        ,Telco_last_year = LAG(Telco,1) OVER (PARTITION BY [month] ORDER BY [month])
    FROM #table_pivot
)
SELECT [month], Telco, Telco_last_year
    ,FORMAT(CAST((Telco - Telco_last_year) AS FLOAT)/ Telco_last_year, 'p') AS Growth_percentage
FROM table_telco
WHERE Telco_last_year NOT LIKE 'NULL'


--Phầm trăm tăng trưởng theo tháng của Marketplace 
WITH table_marketplace AS (
    SELECT [year], [month], Marketplace
        ,Marketplace_last_year = LAG(Marketplace,1) OVER (PARTITION BY [month] ORDER BY [month])
    FROM #table_pivot
)
SELECT [month], Marketplace, Marketplace_last_year
    ,FORMAT(CAST((Marketplace - Marketplace_last_year) AS FLOAT)/ Marketplace_last_year, 'p') AS Growth_percentage
FROM table_marketplace
WHERE Marketplace_last_year NOT LIKE 'NULL'

--Phần trăm tăng trưởng theo tháng của Billing
WITH table_billing AS (
    SELECT [year], [month], Billing
        ,Billing_last_year = LAG(Billing,1) OVER (PARTITION BY [month] ORDER BY [month])
    FROM #table_pivot
)
SELECT [month], Billing, Billing_last_year
    ,FORMAT(CAST((Billing - Billing_last_year) AS FLOAT)/ Billing_last_year, 'p') AS Growth_percentage
FROM table_billing
WHERE Billing_last_year NOT LIKE 'NULL'

---3.3. Payment method of Customers
WITH table_original AS (
    SELECT customer_id, order_id, payment_method, transaction_date
    FROM table_join
    WHERE message_id = 1
)
SELECT payment_method
    ,COUNT(order_id) AS number_trans
    ,(SELECT count(order_id) FROM table_original) AS total_trans
    ,CAST(CAST(COUNT(order_id) AS FLOAT) / (SELECT count(order_id) FROM table_original) AS DECIMAL(10,2)) AS [percent]
FROM table_original
GROUP BY payment_method
/* Trong số các giao dịch thành công thì hình thức money in app được khách hàng ưu chuộng nhất- 50% trên tổng giao dịch
Banking account và local card mỗi phương thức chiếm khoảng 20% trên tổng giao dịch
10% còn lại là credit card và debit */
;

/* Xu hướng của số lượng giao dịch theo từng phương thức thanh toán (số lượng và phần trăm trên tổng) theo tháng */
WITH table_original AS (
    SELECT customer_id, order_id, payment_method, transaction_date
    FROM table_join
    WHERE message_id = 1
)
,table_month AS (
    SELECT payment_method
        ,YEAR(transaction_date) AS [year]
        ,MONTH(transaction_date) AS [month]
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY payment_method, YEAR(transaction_date), MONTH(transaction_date)
)
,table_pivot AS (
    SELECT [year], [month]
    ,"Banking account", "credit card", "debit card" , "local card", "money in app"
    FROM table_month
    PIVOT (
        SUM(number_trans) FOR payment_method IN ("Banking account","credit card","debit card" ,"local card","money in app")) AS pivot_logic
    -- ORDER BY [year],[month] ASC 
)
SELECT *
    ,SUM([Banking account] + [credit card] + [debit card] + [local card] + [money in app]) OVER (PARTITION BY [year],[month]) AS total_trans
    ,CAST(CAST([Banking account] AS FLOAT) / SUM([Banking account] + [credit card] + [debit card] + [local card] + [money in app]) OVER (PARTITION BY [year],[month]) AS DECIMAL(10,2)) AS banking_pct
    ,CAST(CAST([credit card] AS FLOAT) / SUM([Banking account] + [credit card] + [debit card] + [local card] + [money in app]) OVER (PARTITION BY [year],[month]) AS DECIMAL(10,2)) AS credit_pct
    ,CAST(CAST([debit card] AS FLOAT) / SUM([Banking account] + [credit card] + [debit card] + [local card] + [money in app]) OVER (PARTITION BY [year],[month]) AS DECIMAL(10,2)) AS debit_pct
    ,CAST(CAST([local card] AS FLOAT) / SUM([Banking account] + [credit card] + [debit card] + [local card] + [money in app]) OVER (PARTITION BY [year],[month]) AS DECIMAL(10,2)) AS local_pct
    ,CAST(CAST([money in app] AS FLOAT) / SUM([Banking account] + [credit card] + [debit card] + [local card] + [money in app]) OVER (PARTITION BY [year],[month]) AS DECIMAL(10,2)) AS moneyapp_pct
FROM table_pivot
;


---3.4. Promotion transaction trend
WITH table_original AS (
    SELECT customer_id, order_id, promotion_id, transaction_date
        ,CASE WHEN promotion_id = '0' THEN 'Non-promotion' ELSE 'Promotion' END AS segment
    FROM table_join
    WHERE message_id = 1
)
SELECT segment
    ,COUNT(order_id) AS number_trans
    ,(SELECT count(order_id) FROM table_original) AS total_trans
    ,CAST(CAST(COUNT(order_id) AS FLOAT) / (SELECT count(order_id) FROM table_original) AS DECIMAL(10,2)) AS [percent]
FROM table_original
GROUP BY segment
/* Promotion chiếm khoảng 9% trên tổng số giao dịch thành công */
;

-- Xu hướng của số lượng giao dịch khuyến mãi (số lượng và phần trăm trên tổng) theo tháng 
WITH table_original AS (
    SELECT customer_id, order_id, promotion_id, transaction_date
        ,CASE WHEN promotion_id = '0' THEN 'Non-promotion' ELSE 'Promotion' END AS segment
    FROM table_join
    WHERE message_id = 1
)
,table_month AS (
    SELECT segment
        ,YEAR(transaction_date) AS [year]
        ,MONTH(transaction_date) AS [month]
        ,COUNT(order_id) AS number_trans
    FROM table_original
    GROUP BY segment, YEAR(transaction_date), MONTH(transaction_date)
)
,table_pivot AS (
    SELECT [year], [month]
    ,"Non-promotion", "Promotion"
    FROM table_month
    PIVOT (
        SUM(number_trans) FOR segment IN ("Non-promotion","Promotion")) AS pivot_logic
    -- ORDER BY [year],[month] ASC 
)
SELECT *
    ,SUM([Non-promotion] + [Promotion]) OVER (PARTITION BY [year],[month]) AS total_trans
    ,CAST(CAST([Non-promotion] AS FLOAT) / SUM([Non-promotion] + [Promotion]) OVER (PARTITION BY [year],[month]) AS DECIMAL(10,2)) AS non_promotion_pct
    ,CAST(CAST([Promotion] AS FLOAT) / SUM([Non-promotion] + [Promotion]) OVER (PARTITION BY [year],[month]) AS DECIMAL(10,2)) AS promotion_pct
FROM table_pivot

;

    -- Analyze customers enjoying promotions
    WITH table_original AS (
        SELECT customer_id, order_id, promotion_id
            ,CASE WHEN promotion_id = '0' THEN 'Non-promotion' ELSE 'Promotion' END AS segment
        FROM table_join
        WHERE message_id = 1
    )
    SELECT segment 
        ,COUNT(DISTINCT CASE WHEN segment = 'Promotion' THEN customer_id END) AS customers_promotions
        ,(SELECT COUNT(DISTINCT customer_id) FROM table_original) AS total_customers
        ,CAST(COUNT(DISTINCT customer_id) AS FLOAT) / (SELECT COUNT(DISTINCT customer_id) FROM table_original) AS [percent]
    FROM table_original
    GROUP BY segment
    HAVING segment = 'Promotion'
    -->57% khách hàng sử dụng chương trình khuyến mãi để thanh toán giao dịch 
;

    -- Customers used the promotions - promotion transactions rate?
    WITH table_original AS (
        SELECT customer_id, order_id, promotion_id
        FROM table_join
        WHERE message_id = 1
    )
    ,table_count AS (
        SELECT DISTINCT customer_id
            ,COUNT(CASE WHEN promotion_id = '0' THEN order_id END) OVER (PARTITION BY customer_id) AS orders_normal
            ,COUNT(CASE WHEN promotion_id != '0' THEN order_id END) OVER (PARTITION BY customer_id) AS orders_promotion
        FROM table_original
    )
    ,table_percent_promotion AS (
        SELECT *
            ,CAST(CAST(orders_promotion AS FLOAT) / (orders_normal + orders_promotion ) AS DECIMAL(10,3)) AS promotion_per_customers
        FROM table_count
    )
    ,table_segment AS (
        SELECT customer_id,promotion_per_customers
            ,CASE WHEN promotion_per_customers = 0 THEN 'non_promotion'
                WHEN promotion_per_customers > 0 AND promotion_per_customers <=0.1 THEN '0-10%' 
                WHEN promotion_per_customers > 0.1 AND promotion_per_customers <=0.2 THEN '10-20%'
                WHEN promotion_per_customers > 0.2 AND promotion_per_customers <=0.3 THEN '20-30%'
                WHEN promotion_per_customers > 0.3 AND promotion_per_customers <=0.4 THEN '30-40%'
                WHEN promotion_per_customers > 0.4 AND promotion_per_customers <=0.5 THEN '40-50%'
                WHEN promotion_per_customers > 0.5 AND promotion_per_customers <=0.6 THEN '50-60%'
                WHEN promotion_per_customers > 0.6 AND promotion_per_customers <=0.7 THEN '60-70%'
                WHEN promotion_per_customers > 0.7 AND promotion_per_customers <=0.8 THEN '70-80%'
                WHEN promotion_per_customers > 0.8 AND promotion_per_customers <=0.9 THEN '80-90%'
                WHEN promotion_per_customers > 0.9 AND promotion_per_customers <=1 THEN '90-100%'
                END AS segment
        FROM table_percent_promotion
    )
    ,table_ingredient AS (
        SELECT segment 
            ,COUNT(customer_id) AS customers
        FROM table_segment
        GROUP BY segment
        -- ORDER BY segment ASC
    )
    ,table_pct_total AS (
        SELECT *
            ,(SELECT SUM(customers) FROM table_ingredient) AS total_customers
            ,FORMAT (CAST (customers AS FLOAT) / (SELECT SUM(customers) FROM table_ingredient), 'p') AS percent_groups_customer_promotion
        FROM table_ingredient
    )
    /* Tách nhóm hưởng khuyến mãi ra để tính % */
    ,table_promotion AS (
        SELECT *
        FROM table_ingredient
        WHERE segment != 'non_promotion'
    )
    SELECT *
        ,(SELECT SUM(customers) FROM table_promotion) AS total_customers
        ,FORMAT (CAST (customers AS FLOAT) / (SELECT SUM(customers) FROM table_promotion), 'p') AS percent_groups_customer_promotion
    FROM table_promotion
/* --> 28% khách hàng hưởng  dưới 10%  giao dịch khuyến mãi trong tổng số giao dịch của họ
    22% khách hàng áp dụng (10-20%) giao dịch khuyến mãi trong tổng số giao dịch
    Nhưng có một nhóm khách hàng các giao dịch của họ toàn là giao dịch khuyến mãi (11%)? --> kiểm tra */

;

    -- Customers benefit 90-100% promotion
    WITH table_original AS (
        SELECT customer_id, order_id, promotion_id
        FROM table_join
        WHERE message_id = 1
    )
    , table_count AS (
        SELECT DISTINCT customer_id
            ,COUNT(CASE WHEN promotion_id = '0' THEN order_id END) OVER (PARTITION BY customer_id) AS orders_normal
            ,COUNT(CASE WHEN promotion_id != '0' THEN order_id END) OVER (PARTITION BY customer_id) AS orders_promotion
        FROM table_original
    )
    ,table_percent_promotion AS (
        SELECT *
            ,CAST(CAST(orders_promotion AS FLOAT) / (orders_normal + orders_promotion ) AS DECIMAL(10,3)) AS promotion_per_customers
        FROM table_count
    )
    ,table_segment AS (
        SELECT customer_id, orders_normal, orders_promotion, promotion_per_customers
            ,CASE WHEN promotion_per_customers = 0 THEN 'non_promotion'
                WHEN promotion_per_customers > 0 AND promotion_per_customers <=0.1 THEN '0-10%' 
                WHEN promotion_per_customers > 0.1 AND promotion_per_customers <=0.2 THEN '10-20%'
                WHEN promotion_per_customers > 0.2 AND promotion_per_customers <=0.3 THEN '20-30%'
                WHEN promotion_per_customers > 0.3 AND promotion_per_customers <=0.4 THEN '30-40%'
                WHEN promotion_per_customers > 0.4 AND promotion_per_customers <=0.5 THEN '40-50%'
                WHEN promotion_per_customers > 0.5 AND promotion_per_customers <=0.6 THEN '50-60%'
                WHEN promotion_per_customers > 0.6 AND promotion_per_customers <=0.7 THEN '60-70%'
                WHEN promotion_per_customers > 0.7 AND promotion_per_customers <=0.8 THEN '70-80%'
                WHEN promotion_per_customers > 0.8 AND promotion_per_customers <=0.9 THEN '80-90%'
                WHEN promotion_per_customers > 0.9 AND promotion_per_customers <=1 THEN '90-100%'
                END AS segment
        FROM table_percent_promotion
    )
    ,table_customers AS (
        SELECT customer_id, orders_normal, orders_promotion
        FROM table_segment
        WHERE segment LIKE '90-100%'
    )
    SELECT orders_normal, orders_promotion
        ,COUNT(customer_id) AS number_cus
    FROM table_customers
    GROUP BY orders_normal,orders_promotion
    ORDER BY orders_normal

    /*Danh sách nhóm khách hàng hưởng khuyến mãi 90-100%: 
            1. Có khoảng 70% KH sử dụng giao dịch 1 lần rồi thôi (1 giao dịch KM và 0 giao dịch normal)
            2. 30% khách hàng còn lại họ săn khuyến mãi các giao dịch của họ toàn giao dịch khuyến mãi
        Tất cả họ chỉ thanh toán các giao dịch có khuyến mãi. 
        Có một số người giao dịch khuyến mãi của họ từ 10-20 giao dịch mà chỉ có 1 giao dịch bình thường
        Xem thử những sản phẩm họ mua là gì mà toàn là giao dịch khuyến mãi */

;
    --View details of transactions for this customer group
    WITH table_original AS (
        SELECT customer_id, order_id, promotion_id
        FROM table_join
        WHERE message_id = 1
    )
    ,table_count AS (
        SELECT DISTINCT customer_id
            ,COUNT(CASE WHEN promotion_id = '0' THEN order_id END) OVER (PARTITION BY customer_id) AS orders_normal
            ,COUNT(CASE WHEN promotion_id != '0' THEN order_id END) OVER (PARTITION BY customer_id) AS orders_promotion
        FROM table_original
    )
    ,table_percent_promotion AS (
        SELECT *
            ,CAST(CAST(orders_promotion AS FLOAT) / (orders_normal + orders_promotion ) AS DECIMAL(10,3)) AS promotion_per_customers
        FROM table_count
    )
    ,table_segment AS (
        SELECT customer_id, orders_normal, orders_promotion, promotion_per_customers
            ,CASE WHEN promotion_per_customers = 0 THEN 'non_promotion'
                WHEN promotion_per_customers > 0 AND promotion_per_customers <=0.1 THEN '0-10%' 
                WHEN promotion_per_customers > 0.1 AND promotion_per_customers <=0.2 THEN '10-20%'
                WHEN promotion_per_customers > 0.2 AND promotion_per_customers <=0.3 THEN '20-30%'
                WHEN promotion_per_customers > 0.3 AND promotion_per_customers <=0.4 THEN '30-40%'
                WHEN promotion_per_customers > 0.4 AND promotion_per_customers <=0.5 THEN '40-50%'
                WHEN promotion_per_customers > 0.5 AND promotion_per_customers <=0.6 THEN '50-60%'
                WHEN promotion_per_customers > 0.6 AND promotion_per_customers <=0.7 THEN '60-70%'
                WHEN promotion_per_customers > 0.7 AND promotion_per_customers <=0.8 THEN '70-80%'
                WHEN promotion_per_customers > 0.8 AND promotion_per_customers <=0.9 THEN '80-90%'
                WHEN promotion_per_customers > 0.9 AND promotion_per_customers <=1 THEN '90-100%'
                END AS segment
        FROM table_percent_promotion
    )
    ,table_customers AS (
        SELECT customer_id
        FROM table_segment
        WHERE segment LIKE '90-100%'
    )
    SELECT table_customers.customer_id, order_id, transaction_type, category, sub_category, payment_method, discount_price, final_price, transaction_date
    INTO #table_customers_promo_90_100
    FROM table_customers
    LEFT JOIN table_join
        ON table_customers.customer_id = table_join.customer_id
    WHERE table_join.message_id = 1
    -->TẠO BẢNG LOCAL

    WITH table_customers_promo_90_100 AS (
        SELECT transaction_type, category, sub_category
            ,COUNT(order_id) AS number_trans
        FROM #table_customers_promo_90_100
        GROUP BY transaction_type,category,sub_category
    )
    SELECT *
        ,(SELECT SUM(number_trans) FROM table_customers_promo_90_100) AS total_trans
        ,FORMAT(CAST(number_trans AS float) / (SELECT SUM(number_trans) FROM table_customers_promo_90_100),'p') AS [percent]
    FROM table_customers_promo_90_100
    ORDER BY  number_trans DESC
    /* Nhóm khách hàng săn giao dịch khuyến mãi:
        - 38% là các giao dịch nạp tiền điện thoại (Telco Card)
        - 15% là các giao dịch thanh toán tiền điện (Electricity)
        - 8% là các giao dịch mua sắm tại các cửa hàng
        - Còn lại là các giao dịch như mua vé xem phim, giao dịch trên sàn thương mại điện tử,mua vé máy bay, thanh toán nhà hàng,..  */
;

    --Conversion promotion transactions to normal transactions
    --B1: tạo data để xác định promotion và thứ tự promotion,normal va thứ tự thứ nhất
    WITH table_original AS (
        SELECT DISTINCT customer_id, order_id, transaction_date, promotion_id
            ,CASE WHEN promotion_id != '0' THEN 'promotion' ELSE 'normal' END AS segment
            ,LAG( CASE WHEN promotion_id != '0' THEN 'promotion' ELSE 'normal' END,1 ) OVER (PARTITION BY customer_id ORDER BY transaction_date) AS previous_segment
            ,ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY transaction_date) AS row_number
        FROM table_join
        WHERE message_id = 1
        -- ORDER BY customer_id, transaction_date
    )
    --B2: chọn mẫu là các khách hàng có giao dịch đầu tiên là promotion
    SELECT DISTINCT customer_id
    INTO #table_sample
    FROM table_original
    WHERE row_number = 1 AND segment = 'promotion' 

    --B3: từ mẫu (nhóm giao dịch đầu tiên là promotion) tìm các khách hàng có giao dịch lần sau là normal
    WITH table_original AS (
        SELECT DISTINCT customer_id, order_id, transaction_date, promotion_id
            ,CASE WHEN promotion_id != '0' THEN 'promotion' ELSE 'normal' END AS segment
            ,LAG( CASE WHEN promotion_id != '0' THEN 'promotion' ELSE 'normal' END,1 ) OVER (PARTITION BY customer_id ORDER BY transaction_date) AS previous_segment
            ,ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY transaction_date) AS row_number
        FROM table_join
        WHERE message_id = 1
        -- ORDER BY customer_id, transaction_date
    )
    SELECT #table_sample.customer_id, order_id, transaction_date,promotion_id, segment, previous_segment, row_number 
    INTO #table_join
    FROM table_original
    INNER JOIN #table_sample
        ON table_original.customer_id = #table_sample.customer_id
    
    SELECT COUNT(DISTINCT customer_id) AS customer_convert_pro_to_normal
        ,(SELECT COUNT(customer_id) FROM #table_sample) AS customer_sample
        ,FORMAT(CAST(COUNT(DISTINCT customer_id) AS FLOAT) / (SELECT COUNT(customer_id) FROM #table_sample),'p') AS ratio_retention_promotion
    FROM #table_join
    WHERE segment = 'normal' AND previous_segment = 'promotion' 
    /* do chạy CTE mà còn JOIN kèm điều kiện, executing query quá chậm nên tách thành table local cho cải thiện quá trình query */
    /* Tỷ lệ chuyển đổi khách hàng từ giao dịch promotion sang normal ở các giao dịch thành công là 58% */
;

---3.5. User Segmentation - RFM Segmentation
/*  Recency: Difference between each customer's last payment date and '2018-12-31'
    Frequency: Number of successful payment days of each customer
    Monetary: Total charged amount of each customer */

--Telco group
--B1: tính R,F,M của từng khách hàng
WITH table_original AS (
    SELECT customer_id, order_id, transaction_date, final_price
    FROM table_join
    WHERE message_id = 1 AND category = 'Telco'
)
,table_RFM AS (
    SELECT customer_id
        ,DATEDIFF (day, MAX (transaction_date), '2018-12-31') AS recency
        ,COUNT (DISTINCT CAST (transaction_date  AS DATE)) AS frequency -- đếm số ngày 
        ,SUM (final_price) AS monetary
    FROM table_original
    GROUP BY customer_id
)
--B2: tính percent rank của 3 giá trị R,F,M
,table_rank AS (
    SELECT * 
        ,PERCENT_RANK() OVER (ORDER BY recency ASC) AS recency_rank --recency càng nhỏ thì nhóm KH đó càng mới, tiềm năng
        ,PERCENT_RANK() OVER (ORDER BY frequency DESC) AS frequency_rank --frequency càng lớn phản ánh sự mật thiết của KH vs sp
        ,PERCENT_RANK() OVER (ORDER BY monetary DESC) AS monetary_rank --monetary càng lớn thì value nhóm KH đó mang lại càng cao
    FROM table_RFM
)
--B3: chia thành 4 tier
,table_tier AS (
    SELECT *
    ,CASE WHEN recency_rank <= 0.2 THEN 1
        WHEN recency_rank <= 0.4 THEN 2
        WHEN recency_rank <= 0.64 THEN 3
        ELSE 4 END AS recency_tier
    ,CASE WHEN frequency_rank <= 0.25 THEN 1
        WHEN frequency_rank <= 0.49 THEN 2
        WHEN frequency_rank <= 0.63 THEN 3
        ELSE 4 END AS frequency_tier 
    ,CASE WHEN monetary_rank <= 0.16 THEN 1
        WHEN  monetary_rank <= 0.46 THEN 2
        WHEN monetary_rank <= 0.75 THEN 3
        ELSE 4 END AS monetary_tier
    FROM table_rank
)
,table_score AS (
    SELECT *
        ,CONCAT(recency_tier,frequency_tier,monetary_tier) AS rfm_score
    FROM table_tier
)
--B4: Label các khách hàng theo score
,table_label AS (
    SELECT *
   , CASE WHEN rfm_score = 111 THEN 'Best Customers' -- KH tốt nhất
        WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customer' -- KH rời bỏ mà còn siêu tệ 
        WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers' -- KH cũng rời bỏ nhưng có valued
        WHEN rfm_score LIKE '21[1-4]' THEN 'Almost Lost' -- sắp lost những KH này
        WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal Customers'
        WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spenders' -- chi nhiều tiền
        WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New Customers' -- KH mới nên là giao dịch ít
        WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating' -- ngủ đông (trước đó từng rất là tốt )
        WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalists' -- có tiềm năng
        ELSE 'unknown' END AS segment
    FROM table_score
)
SELECT segment
    ,COUNT(DISTINCT customer_id) AS number_customers
    ,(SELECT COUNT(DISTINCT customer_id) FROM table_original) AS total_customers
    ,FORMAT(CAST(COUNT(DISTINCT customer_id) AS FLOAT) / (SELECT COUNT(DISTINCT customer_id) FROM table_original),'p') AS [percent]
FROM table_label
GROUP BY segment 
ORDER BY number_customers DESC  
;

--Marketplace group
--B1: tính R,F,M của từng khách hàng
WITH table_original AS (
    SELECT customer_id, order_id, transaction_date, final_price
    FROM table_join
    WHERE message_id = 1 AND category = 'Marketplace'
)
,table_RFM AS (
    SELECT customer_id
        ,DATEDIFF (day, MAX (transaction_date), '2018-12-31') AS recency
        ,COUNT (DISTINCT CAST (transaction_date  AS DATE)) AS frequency -- đếm số ngày 
        ,SUM (final_price) AS monetary
    FROM table_original
    GROUP BY customer_id
)
--B2: tính percent rank của 3 giá trị R,F,M
,table_rank AS (
    SELECT * 
        ,PERCENT_RANK() OVER (ORDER BY recency ASC) AS recency_rank --recency càng nhỏ thì nhóm KH đó càng mới, tiềm năng
        ,PERCENT_RANK() OVER (ORDER BY frequency DESC) AS frequency_rank --frequency càng lớn phản ánh sự mật thiết của KH vs sp
        ,PERCENT_RANK() OVER (ORDER BY monetary DESC) AS monetary_rank --monetary càng lớn thì value nhóm KH đó mang lại càng cao
    FROM table_RFM
)
--B3: chia thành 4 tier
,table_tier AS (
    SELECT *
    ,CASE WHEN recency_rank <= 0.25 THEN 1
        WHEN recency_rank <= 0.5 THEN 2
        WHEN recency_rank <= 0.75 THEN 3
        ELSE 4 END AS recency_tier
    ,CASE WHEN frequency_rank <= 0.15 THEN 1
        WHEN frequency_rank <= 0.4 THEN 2
        WHEN frequency_rank <= 0.6 THEN 3
        ELSE 4 END AS frequency_tier 
    ,CASE WHEN monetary_rank <= 0.18 THEN 1
        WHEN  monetary_rank <= 0.5 THEN 2
        WHEN monetary_rank <= 0.65 THEN 3
        ELSE 4 END AS monetary_tier
    FROM table_rank
)
,table_score AS (
    SELECT *
        ,CONCAT(recency_tier,frequency_tier,monetary_tier) AS rfm_score
    FROM table_tier
)
--B4: Label các khách hàng theo score
,table_label AS (
    SELECT *
   , CASE WHEN rfm_score = 111 THEN 'Best Customers' -- KH tốt nhất
        WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customer' -- KH rời bỏ mà còn siêu tệ 
        WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers' -- KH cũng rời bỏ nhưng có valued
        WHEN rfm_score LIKE '21[1-4]' THEN 'Almost Lost' -- sắp lost những KH này
        WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal Customers'
        WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spenders' -- chi nhiều tiền
        WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New Customers' -- KH mới nên là giao dịch ít
        WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating' -- ngủ đông (trước đó từng rất là tốt )
        WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalists' -- có tiềm năng
        ELSE 'unknown' END AS segment
    FROM table_score
)
SELECT segment
    ,COUNT(DISTINCT customer_id) AS number_customers
    ,(SELECT COUNT(DISTINCT customer_id) FROM table_original) AS total_customers
    ,FORMAT(CAST(COUNT(DISTINCT customer_id) AS FLOAT) / (SELECT COUNT(DISTINCT customer_id) FROM table_original),'p') AS [percent]
FROM table_label
GROUP BY segment 
ORDER BY number_customers DESC 
;

--Billing group
--B1: tính R,F,M của từng khách hàng
WITH table_original AS (
    SELECT customer_id, order_id, transaction_date, final_price
    FROM table_join
    WHERE message_id = 1 AND category = 'Billing'
)
,table_RFM AS (
    SELECT customer_id
        ,DATEDIFF (day, MAX (transaction_date), '2018-12-31') AS recency
        ,COUNT (DISTINCT CAST (transaction_date  AS DATE)) AS frequency -- đếm số ngày 
        ,SUM (final_price) AS monetary
    FROM table_original
    GROUP BY customer_id
)
--B2: tính percent rank của 3 giá trị R,F,M
,table_rank AS (
    SELECT * 
        ,PERCENT_RANK() OVER (ORDER BY recency ASC) AS recency_rank --recency càng nhỏ thì nhóm KH đó càng mới, tiềm năng
        ,PERCENT_RANK() OVER (ORDER BY frequency DESC) AS frequency_rank --frequency càng lớn phản ánh sự mật thiết của KH vs sp
        ,PERCENT_RANK() OVER (ORDER BY monetary DESC) AS monetary_rank --monetary càng lớn thì value nhóm KH đó mang lại càng cao
    FROM table_RFM
)
--B3: chia thành 4 tier
,table_tier AS (
    SELECT *
    ,CASE WHEN recency_rank <= 0.4 THEN 1
        WHEN recency_rank <= 0.55 THEN 2
        WHEN recency_rank <= 0.65 THEN 3
        ELSE 4 END AS recency_tier
    ,CASE WHEN frequency_rank <= 0.25 THEN 1
        WHEN frequency_rank <= 0.5 THEN 2
        WHEN frequency_rank <= 0.65 THEN 3
        ELSE 4 END AS frequency_tier 
    ,CASE WHEN monetary_rank <= 0.15 THEN 1
        WHEN  monetary_rank <= 0.4 THEN 2
        WHEN monetary_rank <= 0.6 THEN 3
        ELSE 4 END AS monetary_tier
    FROM table_rank
)
,table_score AS (
    SELECT *
        ,CONCAT(recency_tier,frequency_tier,monetary_tier) AS rfm_score
    FROM table_tier
)
--B4: Label các khách hàng theo score
,table_label AS (
    SELECT *
   , CASE WHEN rfm_score = 111 THEN 'Best Customers' -- KH tốt nhất
        WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customer' -- KH rời bỏ mà còn siêu tệ 
        WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers' -- KH cũng rời bỏ nhưng có valued
        WHEN rfm_score LIKE '21[1-4]' THEN 'Almost Lost' -- sắp lost những KH này
        WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal Customers'
        WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spenders' -- chi nhiều tiền
        WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New Customers' -- KH mới nên là giao dịch ít
        WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating' -- ngủ đông (trước đó từng rất là tốt )
        WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalists' -- có tiềm năng
        ELSE 'unknown' END AS segment
    FROM table_score
)
SELECT segment
    ,COUNT(DISTINCT customer_id) AS number_customers
    ,(SELECT COUNT(DISTINCT customer_id) FROM table_original) AS total_customers
    ,FORMAT(CAST(COUNT(DISTINCT customer_id) AS FLOAT) / (SELECT COUNT(DISTINCT customer_id) FROM table_original),'p') AS [percent]
FROM table_label
GROUP BY segment 
ORDER BY number_customers DESC 


---3.6.Retention customers of three groups product growth well
--Telco group
--B1: tìm ra first_time của từng khách hàng trong Telco Card
WITH table_first_month AS (
    SELECT customer_id, order_id, transaction_date
        ,MIN(MONTH(transaction_date)) OVER (PARTITION BY customer_id) AS first_month
    FROM table_join
    WHERE message_id = 1 AND category = 'Telco'
)
--B2: tính thời gian các giao dịch sau so với lần đầu là bao nhiêu tháng của từng khách hàng 
,table_subsequent_month AS (
    SELECT *
        ,MONTH(transaction_date) - first_month AS subsequent_month
    FROM table_first_month
)
--B3: group by theo first_month ;subsequent_month
,table_all AS (
    SELECT first_month AS acquisition_month
        ,subsequent_month
        ,COUNT(DISTINCT customer_id) AS retained_customers
    FROM table_subsequent_month
    GROUP BY first_month,subsequent_month
    -- ORDER BY acquisition_month,subsequent_month
)
--B4: tìm số khách hàng original của từng nhóm theo acquisition_month
,table_retention AS (
    SELECT *
        ,FIRST_VALUE(retained_customers) OVER (PARTITION BY acquisition_month ORDER BY subsequent_month) AS original_customers
        ,CAST(CAST(retained_customers AS FLOAT) / FIRST_VALUE(retained_customers) OVER (PARTITION BY acquisition_month ORDER BY subsequent_month) AS DECIMAL(10,2)) AS [percent]
    FROM table_all
)
--B5: PIVOT vẽ heatmap
SELECT acquisition_month,original_customers
    ,"0","1","2","3","4","5","6","7","8","9","10","11"
FROM (
    SELECT acquisition_month, subsequent_month, original_customers,[percent]
    FROM table_retention
) AS source_table
PIVOT(
    SUM([percent])
    FOR subsequent_month IN ("0","1","2","3","4","5","6","7","8","9","10","11")
) AS pivot_logic
ORDER BY acquisition_month

--Marketplace
--B1: tìm ra first_time của từng khách hàng trong Marketplace
WITH table_first_month AS (
    SELECT customer_id, order_id, transaction_date
        ,MIN(MONTH(transaction_date)) OVER (PARTITION BY customer_id) AS first_month
    FROM table_join
    WHERE message_id = 1 AND category = 'Marketplace'
)
--B2: tính thời gian các giao dịch sau so với lần đầu là bao nhiêu tháng của từng khách hàng
,table_subsequent_month AS (
    SELECT *
        ,MONTH(transaction_date) - first_month AS subsequent_month
    FROM table_first_month
)
--B3: group by theo first_month ;subsequent_month
,table_all AS (
    SELECT first_month AS acquisition_month
        ,subsequent_month
        ,COUNT(DISTINCT customer_id) AS retained_customers
    FROM table_subsequent_month
    GROUP BY first_month,subsequent_month
    -- ORDER BY acquisition_month,subsequent_month
)
--B4: tìm số khách hàng original của từng nhóm theo acquisition_month
,table_retention AS (
    SELECT *
        ,FIRST_VALUE(retained_customers) OVER (PARTITION BY acquisition_month ORDER BY subsequent_month) AS original_customers
        ,CAST(CAST(retained_customers AS FLOAT) / FIRST_VALUE(retained_customers) OVER (PARTITION BY acquisition_month ORDER BY subsequent_month) AS DECIMAL(10,2)) AS [percent]
    FROM table_all
)
--B5: PIVOT vẽ heatmap
SELECT acquisition_month,original_customers
    ,"0","1","2","3","4","5","6","7","8","9","10","11"
FROM (
    SELECT acquisition_month, subsequent_month, original_customers,[percent]
    FROM table_retention
) AS source_table
PIVOT(
    SUM([percent])
    FOR subsequent_month IN ("0","1","2","3","4","5","6","7","8","9","10","11")
) AS pivot_logic
ORDER BY acquisition_month

--Billing
--B1: tìm ra first_time của từng khách hàng trong Billing
WITH table_first_month AS (
    SELECT customer_id, order_id, transaction_date
        ,MIN(MONTH(transaction_date)) OVER (PARTITION BY customer_id) AS first_month
    FROM table_join
    WHERE message_id = 1 AND category = 'Billing'
)
--B2: tính thời gian các giao dịch sau so với lần đầu là bao nhiêu tháng của từng khách hàng 
,table_subsequent_month AS (
    SELECT *
        ,MONTH(transaction_date) - first_month AS subsequent_month
    FROM table_first_month
)
--B3: group by theo first_month ;subsequent_month
,table_all AS (
    SELECT first_month AS acquisition_month
        ,subsequent_month
        ,COUNT(DISTINCT customer_id) AS retained_customers
    FROM table_subsequent_month
    GROUP BY first_month,subsequent_month
    -- ORDER BY acquisition_month,subsequent_month
)
--B4: tìm số khách hàng original của từng nhóm theo acquisition_month
,table_retention AS (
    SELECT *
        ,FIRST_VALUE(retained_customers) OVER (PARTITION BY acquisition_month ORDER BY subsequent_month) AS original_customers
        ,CAST(CAST(retained_customers AS FLOAT) / FIRST_VALUE(retained_customers) OVER (PARTITION BY acquisition_month ORDER BY subsequent_month) AS DECIMAL(10,2)) AS [percent]
    FROM table_all
)
--B5: PIVOT vẽ heatmap
SELECT acquisition_month,original_customers
    ,"0","1","2","3","4","5","6","7","8","9","10","11"
FROM (
    SELECT acquisition_month, subsequent_month, original_customers,[percent]
    FROM table_retention
) AS source_table
PIVOT(
    SUM([percent])
    FOR subsequent_month IN ("0","1","2","3","4","5","6","7","8","9","10","11")
) AS pivot_logic
ORDER BY acquisition_month

--Promotion 
--B1: tìm ra first_time của từng khách hàng từ thanh toán Promotion
WITH table_first_month AS (
    SELECT customer_id, order_id, transaction_date,promotion_id
        ,MIN(MONTH(transaction_date)) OVER (PARTITION BY customer_id) AS first_month
    FROM table_join
    WHERE message_id = 1 AND promotion_id != '0'
)
--B2: tính thời gian các giao dịch sau so với lần đầu là bao nhiêu tháng của từng khách hàng
,table_subsequent_month AS (
    SELECT *
        ,MONTH(transaction_date) - first_month AS subsequent_month
    FROM table_first_month
)
--B3: group by theo first_month ;subsequent_month
,table_all AS (
    SELECT first_month AS acquisition_month
        ,subsequent_month
        ,COUNT(DISTINCT customer_id) AS retained_customers
    FROM table_subsequent_month
    GROUP BY first_month,subsequent_month
    -- ORDER BY acquisition_month,subsequent_month
)
--B4: tìm số khách hàng original của từng nhóm theo acquisition_month
,table_retention AS (
    SELECT *
        ,FIRST_VALUE(retained_customers) OVER (PARTITION BY acquisition_month ORDER BY subsequent_month) AS original_customers
        ,CAST(CAST(retained_customers AS FLOAT) / FIRST_VALUE(retained_customers) OVER (PARTITION BY acquisition_month ORDER BY subsequent_month) AS DECIMAL(10,2)) AS [percent]
    FROM table_all
)
--B5: PIVOT vẽ heatmap
SELECT acquisition_month,original_customers
    ,"0","1","2","3","4","5","6","7","8","9","10","11"
FROM (
    SELECT acquisition_month, subsequent_month, original_customers,[percent]
    FROM table_retention
) AS source_table
PIVOT(
    SUM([percent])
    FOR subsequent_month IN ("0","1","2","3","4","5","6","7","8","9","10","11")
) AS pivot_logic
ORDER BY acquisition_month

;

---3.7. The Success rate of transactions
SELECT DISTINCT
    YEAR(transaction_date) AS [year]
    ,MONTH(transaction_date) AS [month]
    ,COUNT(order_id) OVER (PARTITION BY YEAR(transaction_date),MONTH(transaction_date)) AS total_trans
    ,COUNT(CASE WHEN message_id = 1 THEN order_id END) OVER (PARTITION BY YEAR(transaction_date),MONTH(transaction_date)) AS trans_success
    ,FORMAT(CAST(COUNT(CASE WHEN message_id = 1 THEN order_id END) OVER (PARTITION BY YEAR(transaction_date),MONTH(transaction_date)) AS FLOAT)/ COUNT(order_id) OVER (PARTITION BY YEAR(transaction_date),MONTH(transaction_date)),'p') AS success_rate
FROM table_join
ORDER BY YEAR(transaction_date),MONTH(transaction_date) ASC

--Error trend 
SELECT YEAR(transaction_date) AS [year]
    ,MONTH(transaction_date) AS [month]
    ,[description]
    ,COUNT(order_id) AS number_trans
FROM table_join
WHERE message_id != 1 
GROUP BY YEAR(transaction_date),MONTH(transaction_date),[description]
ORDER BY YEAR(transaction_date),MONTH(transaction_date) ASC
;
    -- checking fraudulent transactions
    WITH table_fraudulent AS (
        SELECT YEAR(transaction_date) AS [year]
            ,MONTH(transaction_date) AS [month]
            ,[description]
            ,COUNT(order_id) AS number_trans
        FROM table_join
        WHERE message_id != 1 AND [description] LIKE '%fraudulent%'
        GROUP BY YEAR(transaction_date),MONTH(transaction_date),[description]
        -- ORDER BY YEAR(transaction_date),MONTH(transaction_date) ASC
    )
    SELECT [description],
        SUM(number_trans) AS total_fraudulent_trans
    FROM table_fraudulent
    GROUP BY [description]
;
    --fraudulent transactions for segment
    WITH table_original AS (
        SELECT customer_id, [description], order_id
            ,CASE WHEN promotion_id != '0' THEN 'promotion' ELSE 'normal' END AS segment
        FROM table_join
    )
    SELECT segment
        ,COUNT(CASE WHEN [description] LIKE '%fraudulent%' THEN order_id END ) AS fraud_trans
        ,(SELECT COUNT(order_id) FROM table_join WHERE [description] LIKE '%fraudulent%' ) AS total_fraudulent_trans
        ,CAST(CAST(COUNT(CASE WHEN [description] LIKE '%fraudulent%' THEN order_id END) AS FLOAT) / (select COUNT(order_id) from table_join WHERE [description] LIKE '%fraudulent%') AS FLOAT) AS [percent]
    FROM table_original
    GROUP BY segment
;
    --Customers use to paying fraudulent transactions
    WITH table_frau AS (
        SELECT customer_id
            ,COUNT(order_id) AS total_trans
            ,COUNT(CASE WHEN [description] LIKE '%fraudulent%' THEN order_id END ) AS fraud_trans
        FROM table_join
        -- WHERE customer_id IN (SELECT customer_id FROM table_join WHERE promotion_id != '0'  )
        GROUP BY customer_id
    )
    SELECT *
        ,CAST(CAST(fraud_trans AS FLOAT) / total_trans AS FLOAT) AS [percent]
    FROM table_frau
    WHERE fraud_trans != 0
    ORDER BY fraud_trans DESC














