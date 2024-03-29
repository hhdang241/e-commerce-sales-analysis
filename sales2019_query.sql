USE master;

-- Nhập dữ liệu từ file

CREATE TABLE sales2019 (
	`Order ID` INT,
    Product CHAR(100),
    `Quantity Ordered` SMALLINT,
    `Price Each` DOUBLE,
	`Order Date` DATETIME,
	`Purchase Address` CHAR(100)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales2019.csv' 
INTO TABLE sales2019 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Phân tích dữ liệu

-- Q: Tháng nào có doanh số cao nhất? Doanh số tháng đó là bao nhiêu?

SELECT
	EXTRACT(MONTH FROM `Order Date`) AS `month`,
    ROUND(SUM(`Quantity Ordered` * `Price Each`)) AS sales
FROM sales2019
GROUP BY EXTRACT(MONTH FROM `Order Date`)
ORDER BY sales DESC
LIMIT 1;

/*
A:
Tháng 12 có doanh số cao nhất với doanh số là 4613443$
Giả thuyết về lí do tháng 12 có doanh số cao nhất:
- Tháng 12 là tháng cuối năm, có các dịp lễ quan trọng như Giáng Sinh, Năm Mới,...
- Các hãng điện tử lớn thường ra mắt sản phẩm vào quý 3
- ...
*/

-- Q: Thành phố nào có doanh số cao nhất?

SELECT
	TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(`Purchase Address`, ',', 2), ',', -1)) AS city,
    ROUND(SUM(`Quantity Ordered` * `Price Each`)) AS sales
FROM sales2019
GROUP BY TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(`Purchase Address`, ',', 2), ',', -1))
ORDER BY sales DESC
LIMIT 1;

/*
A:
San Francisco có doanh số cao nhất
Giả thuyết về lí do San Francisco có doanh số cao nhất:
- Silicon Valley toạ lạc ở đây
- Ở đây có nhiều kỹ sư hơn bình thường nên có nhu cầu cao về đồ công nghệ
- ...
*/

-- Q: Doanh nghiệp cần chiếu quảng cáo vào khung thời gian nào để tăng khả năng mua hàng của khách hàng?

SELECT
	EXTRACT(HOUR FROM `Order Date`) AS `hour`,
    COUNT(DISTINCT `Order ID`) AS number_of_orders
FROM sales2019
GROUP BY EXTRACT(HOUR FROM `Order Date`)
ORDER BY number_of_orders DESC;

/*
A:
Ta có thể thấy khung giờ 11h - 13h và 18h - 20h có số lượng đơn hàng nhiều nhất, dễ hiểu vì đây là khung giờ nghỉ trưa (11h - 13h) và khung giờ sau khi đi làm về (18h - 20h)
Để hiệu quả hơn, ta sẽ tìm thông tin cho từng thành phố
*/

SELECT
	TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(`Purchase Address`, ',', 2), ',', -1)) AS city,
	EXTRACT(HOUR FROM `Order Date`) AS `hour`,
    COUNT(*) AS number_of_orders
FROM sales2019
GROUP BY
	TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(`Purchase Address`, ',', 2), ',', -1)),
    EXTRACT(HOUR FROM `Order Date`)
ORDER BY 1, number_of_orders DESC;

/*
Nhìn chung, hầu hết thành phố đều có cùng khung giờ có số lượng đơn hàng nhiều nhất
Doanh nghiệp có thể chạy quảng cáo khoảng 30 đến 60 phút trước đó, tức là 10h30 và 17h30
*/

-- Q: Những sản phẩm nào thường được bán cùng nhau?
WITH product_pair AS (
	SELECT
		s1.`Order ID`,
		s1.`Product` AS product_1,
		s2.`Product` AS product_2,
		LEAST(s1.`Quantity Ordered`, s2.`Quantity Ordered`) AS quantity_ordered
	FROM sales2019 s1 JOIN sales2019 s2 ON s1.`Order ID` = s2.`Order ID` AND s1.`Product` < s2.`Product`
)
SELECT
	product_1,
	product_2,
    SUM(quantity_ordered) AS quantity_ordered
FROM product_pair
GROUP BY product_1, product_2
ORDER BY 3 DESC;

/*
A:
iPhone và Lightning Charging Cable được mua cùng nhau nhiều nhất, theo sau đó là Google Phone và USB-C Charging Cable
Biết được điều này, doanh nghiệp có thể bán combo bao gồm cặp sản phẩm thường được mua cùng nhau, kèm với 1 sản phẩm khác ít bán chạy hơn để đẩy nhanh doanh số của sản phẩm ít bán chạy kia
Hoặc doanh nghiệp có thể đính kèm giảm giá khi mua các cặp sản phẩm này để kích cầu tiêu dùng
*/

-- Q: Sản phẩm nào được bán nhiều nhất? Giả thuyết của bạn về lí do sản phẩm này được bán nhiều nhất là gì?

SELECT Product, SUM(`Quantity Ordered`) AS quantity_ordered
FROM sales2019
GROUP BY Product
ORDER BY 2 DESC;

/*
A:
Sản phẩm được bán nhiều nhất là AAA Batteries (4-pack), theo sau đó là AA Batteries (4-pack)
Giả thuyết về lí do các sản phẩm này được bán nhiều nhất:
- Giá cả, thương hiệu, chất lượng sản phẩm,...
- Do không có dữ liệu để kiểm chứng giả thuyết và thương hiệu và chất lượng sản phẩm, ta tạm thời bỏ qua 2 yếu tố này
- Vậy yếu tố giá cả có ảnh hưởng thế nào đến số lượng bán ra của sản phẩm?
*/

SELECT
	DISTINCT `Product`,
    `Price Each`
FROM sales2019
ORDER BY `Price Each`;

/*
Ta có thể thấy, 2 sản phẩm được bán nhiều nhất lại có giá thấp nhất
Cùng với sự cần thiết của sản phẩm Batteries trong đời sống hằng ngày, đây có thể là những lí do khiến AAA Batteries (4-pack) và AA Batteries (4-pack) được bán nhiều nhất
*/

-- Xoá table

DROP TABLE sales2019;
