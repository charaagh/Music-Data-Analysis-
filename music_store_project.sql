--- who is the senior most employee based on job title
SELECT TRIM(CONCAT(first_name, last_name))
FROM employee
WHERE reports_to is null

--- which countries have most invoices
SELECT COUNT(*), billing_country
FROM invoice
GROUP BY billing_country
ORDER BY COUNT(*) DESC
LIMIT 1

--- what are the top 3 total values of invoices
SELECT total
FROM invoice
ORDER BY totaL DESC
LIMIT 3

-- best city for musical fest
SELECT SUM(total), billing_city
FROM invoice
GROUP by billing_city
ORDER BY SUM(total) DESC
LIMIT 3

--- best customer, buyed the most
SELECT SUM(total) AS totts, CONCAT(first_name, last_name) AS name
FROM customer
RIGHT JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY name
ORDER BY totts DESC
LIMIT 1

--- email, first_name, last_name, genre of all rock list, order by email A-Z
SELECT DISTINCT customer.first_name, customer.last_name, customer.email
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
WHERE track_id IN (
	SELECT track_id 
	FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)

ORDER BY email

--- artist that have written most rock songs, artist name ,total track count of top 10 bands

SELECT COUNT(*) AS track_count, artist.name, artist.artist_id 
FROM artist
JOIN album ON artist.artist_id = album.artist_id
JOIN track ON track.album_id = album.album_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY track_count DESC
LIMIT 10

--- track name > avg(song length) show name and millisecond >> order by desc song length
SELECT track.name, track.milliseconds 
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track) 
ORDER BY milliseconds DESC


--- find the amount spent by customers on best selling artist, return artist name, total amount
WITH baap_artist AS (
	SELECT artist.artist_id, artist.name AS artist_name, 
	       SUM(invoice_line.unit_price * invoice_line.quantity) AS total_revenue
	FROM artist
	JOIN album ON album.artist_id = artist.artist_id
	JOIN track ON album.album_id = track.album_id
	JOIN invoice_line ON invoice_line.track_id = track.track_id
	GROUP BY artist.artist_id, artist.name
)

SELECT 
    customer.customer_id, 
    customer.first_name, 
    customer.last_name, 
    baap_artist.artist_name,
    SUM(invoice_line.unit_price * invoice_line.quantity) AS total_revenue
FROM 
    invoice
JOIN 
    customer ON customer.customer_id = invoice.customer_id
JOIN 
    invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN 
    track ON track.track_id = invoice_line.track_id
JOIN 
    album ON album.album_id = track.album_id
JOIN 
    baap_artist ON baap_artist.artist_id = album.artist_id
GROUP BY 
    customer.customer_id, 
    customer.first_name, 
    customer.last_name, 
    baap_artist.artist_name
ORDER BY 
    total_revenue DESC;


--- counrty wise most popular genre

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


--- customer that spent most money, country wise

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;


WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1
