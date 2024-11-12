--Database overview
--1
SELECT * 
FROM products

--2
SELECT COUNT(id) AS 'product_count'
FROM products

--3
SELECT DISTINCT brand
FROM products

--4
SELECT DISTINCT category, COUNT(category) as 'number_of_products_per_category'
FROM products
GROUP BY category

--Brand analysis
--5
SELECT brand,n_of_loves 
FROM products
ORDER BY n_of_loves DESC

--6
SELECT brand,SUM(n_of_reviews) AS total_reviews, SUM(n_of_loves) AS total_loves , AVG(review_score) AS avg_review_score
FROM products
GROUP BY brand
ORDER BY total_reviews DESC ;


--7
SELECT brand,  name, n_of_loves AS loves, n_of_reviews AS total_reviews
FROM products
ORDER BY total_reviews DESC


CREATE FUNCTION avg_per_category(@category VARCHAR(50))
RETURNS FLOAT
AS
BEGIN
    DECLARE @avg_n_of_reviews FLOAT;

    SELECT @avg_n_of_reviews = AVG(n_of_reviews) 
    FROM products
    WHERE category = @category; 

    RETURN @avg_n_of_reviews; 
END;

--Ratings and Reviews

--8
SELECT TOP 15 p1.category, p1.brand, p1.name, p1.review_score, p1.n_of_loves , p1.n_of_reviews
FROM products p1
WHERE n_of_reviews > dbo.avg_per_category(category)  AND review_score > 4
ORDER BY review_score DESC, n_of_loves DESC;

--9
SELECT TOP 10 brand, name , n_of_loves
FROM products
ORDER BY n_of_loves DESC

--10
SELECT TOP 10 brand, name, review_score , n_of_reviews
FROM products
ORDER BY  n_of_reviews DESC

--11
CREATE PROCEDURE reviews_to_loves
AS
BEGIN
SELECT TOP 15 category, brand, name, price, n_of_reviews, review_score, n_of_reviews, n_of_loves,
    CASE 
        WHEN n_of_loves = 0 THEN 0.0
        ELSE (CAST(n_of_reviews AS DECIMAL) / n_of_loves) * 100
    END AS reviews_to_loves_ratio
FROM products
ORDER BY reviews_to_loves_ratio DESC;
END

EXEC reviews_to_loves

--12
CREATE PROCEDURE loved_products
AS 
BEGIN
    SELECT p1.category, p1.brand, p1.name, p1.price, p1.n_of_reviews, p1.review_score, p1.n_of_loves
    FROM products p1
    WHERE p1.n_of_loves IN (
        SELECT TOP 5 p2.n_of_loves
        FROM products p2
        WHERE p1.category = p2.category
        ORDER BY p2.n_of_loves DESC
    )
    ORDER BY p1.category, p1.n_of_loves DESC;
END;

EXEC loved_products

--13
CREATE PROCEDURE reviews_to_loves_per_category
AS
BEGIN
    SELECT p1.category, p1.brand, p1.name, p1.price, p1.n_of_reviews, p1.review_score, p1.n_of_loves,
	 CASE 
        WHEN p1.n_of_loves = 0 THEN 0.0
        ELSE (CAST(p1.n_of_reviews AS DECIMAL) / p1.n_of_loves) * 100
    END AS reviews_to_loves_ratio
    FROM products p1
    WHERE  p1.review_score > 4 AND p1.n_of_reviews > dbo.avg_per_category(p1.category) AND (
          SELECT COUNT(*)
          FROM products p2
          WHERE p2.category = p1.category 
            AND p2.review_score > 4
            AND p2.n_of_reviews > dbo.avg_per_category(p2.category) 
            AND p2.review_score > p1.review_score
      ) < 10
   ORDER BY p1.category ,reviews_to_loves_ratio DESC;
END;

EXEC reviews_to_loves_per_category

--14
CREATE PROCEDURE rated_products
AS 
BEGIN
    SELECT p1.category, p1.brand, p1.name, p1.price, p1.n_of_reviews, p1.review_score, p1.n_of_loves 
    FROM products p1
    WHERE p1.review_score > 4
      AND p1.n_of_reviews > dbo.avg_per_category(p1.category) 
      AND (
          SELECT COUNT(*)
          FROM products p2
          WHERE p2.category = p1.category 
            AND p2.review_score > 4
            AND p2.n_of_reviews > dbo.avg_per_category(p2.category) 
            AND p2.review_score > p1.review_score
      ) < 5
    ORDER BY p1.category, p1.review_score DESC;
END;
EXEC rated_products


--15
CREATE PROCEDURE top_rated_gems
AS
BEGIN
SELECT p1.category, p1.brand, p1.name, p1.price, p1.n_of_reviews,p1.review_score, p1.n_of_loves
FROM products p1
WHERE p1.review_score > 4 AND p1.n_of_reviews > dbo.avg_per_category(p1.category)
  AND p1.n_of_loves IN (
   
        SELECT TOP 5 p2.n_of_loves
        FROM products p2
        WHERE p1.category = p2.category
        AND p2.review_score > 4 AND  p2.n_of_reviews > dbo.avg_per_category(p2.category)
        ORDER BY p2.n_of_loves DESC, p2.review_score DESC
        
    
)
ORDER BY p1.category, p1.n_of_loves DESC,  p1.review_score DESC;
END;

EXEC top_rated_gems

--16

SELECT * 
INTO high_rated_products
FROM products
WHERE review_score = 5 AND n_of_reviews > 10  

--17
SELECT *
INTO highest_rated_category_based
FROM products p
WHERE p.n_of_reviews > dbo.avg_per_category(p.category)
AND p.review_score = (
    SELECT MAX(p1.review_score)
    FROM products p1
    WHERE p1.category = p.category AND p1.n_of_reviews > dbo.avg_per_category(p1.category)
);


SELECT *
INTO top_rated_products
FROM (
    SELECT * FROM high_rated_products
    UNION
    SELECT * FROM highest_rated_category_based
) AS top_rated_result;

SELECT * from top_rated_products
ORDER BY review_score DESC

--18
CREATE PROCEDURE budget_list
AS
BEGIN
SELECT p1.category, p1.brand, p1.name, p1.price, p1.n_of_reviews, p1.review_score, p1.n_of_loves
FROM products p1
WHERE p1.review_score > 4 AND p1.n_of_reviews > dbo.avg_per_category(p1.category)
  AND p1.price IN (
      SELECT TOP 10 p2.price
      FROM products p2
      WHERE p2.category = p1.category AND p2.review_score > 4 AND p2.n_of_reviews > dbo.avg_per_category(p2.category) 
      ORDER BY p2.price
  )
  AND p1.price < (
      SELECT AVG(p3.price)
      FROM products p3
      WHERE p3.category = p1.category AND p3.review_score > 4 AND n_of_reviews > dbo.avg_per_category(p3.category)
	  )
ORDER BY p1.category, p1.price ASC;
END

EXEC budget_list

--19
SELECT brand, SUM(n_of_reviews) AS total_reviews, SUM(n_of_loves) AS total_loves
INTO brands
FROM products
GROUP BY brand;

SELECT TOP 10 brand, total_reviews, total_loves
INTO most_purchased
FROM brands
ORDER BY total_reviews DESC;

SELECT TOP 10 brand, total_reviews, total_loves
INTO most_loved
FROM brands
ORDER BY total_loves DESC;

CREATE VIEW view_popular_brands
AS
SELECT p.brand, p.total_reviews AS purchased_reviews, l.total_loves AS most_desired
FROM most_purchased p
INNER JOIN most_loved l ON p.brand = l.brand;
GO

SELECT * FROM view_popular_brands

--Product pricing 
--20
SELECT category, AVG(price) AS avg_price, SUM(price * n_of_loves) AS potential_sales
FROM products
GROUP BY category
ORDER BY potential_sales DESC;

--21
SELECT category, MIN(price) AS min_price, MAX(price) AS max_price, AVG(price) AS avg_price
FROM products
GROUP BY category
ORDER BY category;

--Makeup Product Analysis
--22
SELECT id , category, brand, name , price, n_of_loves , n_of_reviews , review_score , size 
INTO makeup
FROM products
WHERE category IN ('Blotting Papers', 'Face Primer', 'Foundation', 'Highlighter', 'Setting Spray & Powder', 'Tinted Moisturizer' ,'BB & CC Cream')
ORDER BY category;

CREATE VIEW high_rated_makeup
AS
SELECT TOP 10 category, brand, name , price, n_of_loves , review_score, n_of_reviews
FROM makeup 
WHERE review_score > 4 AND n_of_reviews > 10
ORDER BY n_of_loves DESC
GO

SELECT * FROM high_rated_makeup