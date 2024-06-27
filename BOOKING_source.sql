SELECT * FROM raw.Review
WHERE Reviewer_id = '7836';
--đổi tên cột 
sp_rename 'raw.Hotel.id', 'id_hotel', 'COLUMN';

sp_rename 'raw.Review.id', 'id_hotel', 'COLUMN';

sp_rename 'raw.Province.id_province', 'province_id', 'COLUMN';

sp_rename 'raw.Review.id_province', 'province_id', 'COLUMN';
-- thêm cột province_id
ALTER TABLE raw.review
ADD id_province INT;
-- thêm giá trị vào province_id
UPDATE raw.Review
SET raw.Review.province_id = raw.Hotel.province_id
FROM raw.Review
INNER JOIN raw.Hotel ON raw.Review.id_hotel = raw.Hotel.id_hotel;

-- thêm cột day
ALTER TABLE raw.Review
ADD day INT;

UPDATE raw.Review
SET review_day = CAST(SUBSTRING(review_date, CHARINDEX('ngày', review_date) + 4, CHARINDEX('Tháng', review_date) - CHARINDEX('ngày', review_date) - 4) AS INT)
WHERE CHARINDEX('ngày', review_date) > 0;

-- lập cột id_date
ALTER TABLE raw.Review
ADD id_date INT;

UPDATE raw.Review
SET id_date = CONCAT(review_year, 
                    RIGHT('00' + review_month, 2), 
                    RIGHT('00' + review_day, 2))
WHERE ISNUMERIC(review_year) = 1
  AND ISNUMERIC(review_month) = 1
  AND ISNUMERIC(review_day) = 1;

-- lập bảng raw.reviewer
SELECT DISTINCT reviewer_name, reviewer_country
INTO raw.Reviewer
FROM raw.Review;
-- thêm cột reviewer_id
ALTER TABLE raw.Reviewer
ADD Reviewer_id INT;

-- Cập nhật giá trị của cột reviewer_id
WITH RankedReviewers AS (
  SELECT 
    CONCAT(reviewer_name, '_', reviewer_country) AS reviewer_identifier,
    DENSE_RANK() OVER (ORDER BY reviewer_name, reviewer_country) AS reviewer_id
  FROM raw.Reviewer
)
UPDATE r
SET r.reviewer_id = rr.reviewer_id
FROM raw.Reviewer AS r
JOIN RankedReviewers AS rr
ON CONCAT(r.reviewer_name, '_', r.reviewer_country) = rr.reviewer_identifier;

-- thêm giá trị vào reviewer_id vào bảng raw.Review
ALTER TABLE raw.Review
ADD Reviewer_id INT;
-- thêm giá trị
UPDATE r
SET r.Reviewer_id = rr.Reviewer_id
FROM raw.Review AS r
JOIN raw.Reviewer AS rr
ON r.Reviewer_name = rr.Reviewer_name AND r.Reviewer_country = rr.Reviewer_country;

ALTER TABLE raw.Review
ALTER COLUMN Reviewer_id INT FIRST;

-- Tạo bảng raw.language
CREATE TABLE raw.language (
    language_id INT IDENTITY(1,1) PRIMARY KEY,
    language VARCHAR(255) NOT NULL
);

-- Insert dữ liệu vào bảng raw.language từ bảng raw.Review và lọc sao cho không có giá trị trùng
INSERT INTO raw.language (language)
SELECT DISTINCT langugage
FROM raw.Review
WHERE langugage IS NOT NULL;

-- thêm cột language_id vào bảng review
sp_rename 'raw.Review.langugage', 'language_code', 'COLUMN';

ALTER TABLE raw.Review
ADD language_id INT;

UPDATE raw.Review
SET raw.Review.language_id = raw.language.language_id
FROM raw.Review
JOIN raw.language ON raw.Review.language_code = raw.language.language;

-- thêm review_id
ALTER TABLE raw.Review
ADD review_id INT IDENTITY(1,1) PRIMARY KEY;

-- Tạo bảng raw.language
CREATE TABLE raw.room (
    roomtype_id INT IDENTITY(1,1) PRIMARY KEY,
    roomtype_id VARCHAR(255) NOT NULL
);

-- Insert dữ liệu vào bảng raw.language từ bảng raw.Review và lọc sao cho không có giá trị trùng
INSERT INTO raw.language (language)
SELECT DISTINCT langugage
FROM raw.Review
WHERE langugage IS NOT NULL;

-- Tạo bảng raw.room
CREATE TABLE raw.room (
    room_id INT IDENTITY(1,1) PRIMARY KEY,
    room_type VARCHAR(255) NOT NULL
);

-- Insert dữ liệu vào bảng raw.room từ bảng raw.Review và lọc sao cho không có giá trị trùng
INSERT INTO raw.room (room_type)
SELECT DISTINCT room_type
FROM raw.Review
WHERE room_type IS NOT NULL;

-- tạo bảng raw.ks
SELECT DISTINCT id_hotel, province_id
INTO raw.Khachsan
FROM raw.Review;
-- thêm cột vào bảng
ALTER TABLE raw.khachsan
ADD [total_reviews] bigint,
    [hotel_name] nvarchar(500),
    [display_location] nvarchar(500),
    [city] nvarchar(200),
    [address] nvarchar(500),
    [photos_url] nvarchar(500),
    [page_name] nvarchar(200),
    [score] float;
-- thêm giá trị vào bảng
UPDATE ks
SET
    ks.hotel_name = h.hotel_name,
    ks.display_location = h.display_location,
    ks.city = h.city,
    ks.address = h.address,
    ks.score = h.score,
    ks.total_reviews = h.total_reviews,
    ks.photos_url = h.photos_url,
    ks.page_name = h.page_name
FROM raw.khachsan ks
JOIN raw.hotel h ON ks.id_hotel = h.id_hotel;

drop table dbo.[fact.review]

-- tạo bảng raw.date
SELECT DISTINCT id_date
INTO raw.Date
FROM raw.Review;

ALTER TABLE raw.Date
ADD [review_year] int,
    [review_month] int,
    [review_day] int,
    [review_date] nvarchar(500)

Update d
set
	d.[review_year]=r.[review_year],
	d.[review_month]=r.[review_month],
	d.[review_day]=r.[review_day],
	d.[review_date]=r.[review_date]
from raw.Date d
join raw.Review r on d.id_date=r.id_date

-- thêm cột 
ALTER TABLE raw.review
ADD  rental_month INT,
	 rental_year INT;

-- Cập nhật dữ liệu trong các cột mới từ cột rental_date
UPDATE raw.Review
SET rental_month = SUBSTRING(rental_date, CHARINDEX('Tháng ', rental_date) + LEN('Tháng '), CHARINDEX('-', rental_date) - CHARINDEX('Tháng ', rental_date) - LEN('Tháng '));

UPDATE raw.Review
SET rental_year = RIGHT(rental_date, 4);
-- lập id_rental_date
ALTER TABLE raw.Review
ADD id_rental_date AS CONCAT(rtrim(rental_month), rtrim(rental_year));

-- Tạo bảng raw.rentaldate
CREATE TABLE raw.rentaldate (
    id_rental_date NVARCHAR(24)
);

-- Thêm dữ liệu vào bảng raw.rentaldate từ bảng raw.Review
INSERT INTO raw.rentaldate (id_rental_date)
SELECT DISTINCT CONCAT(rtrim(rental_month), rtrim(rental_year))
FROM raw.Review;

-- Thêm dữ liệu vào bảng raw.rentaldate từ bảng raw.Review
ALTER TABLE [raw].[rentaldate]
ADD  rental_month INT,
	 rental_year INT;

Update re
set
	re.[rental_month]=r.[rental_month],
	re.[rental_year]=r.[rental_year]
from raw.rentaldate re
join raw.Review r on re.id_rental_date=r.id_rental_date

-- tạo bảng raw.roomtype
CREATE TABLE raw.roomtype (
    [room_type] NVARCHAR(1000) 
);

INSERT INTO raw.roomtype (room_type)
SELECT DISTINCT room_type
FROM raw.Review;

ALTER TABLE raw.roomtype
ADD roomtype_id INT IDENTITY(1,1) PRIMARY KEY;

-- tạo bảng raw.traveltype
CREATE TABLE raw.traveltype (
    [travel_type] NVARCHAR(1000) 
);

INSERT INTO raw.traveltype (travel_type)
SELECT DISTINCT travel_type
FROM raw.Review;

ALTER TABLE raw.traveltype
ADD traveltype_id INT IDENTITY(1,1) PRIMARY KEY;

-- thêm cột id_rentaldate; id_roomtype và id_Traveltype vào bảng raw.Review
ALTER TABLE [raw].[review]
ADD  traveltype_id INT,
	 roomtype_id INT;

Update r
set
	r.[traveltype_id]=t.[traveltype_id]
from raw.Review r
join raw.traveltype t on r.travel_type=t.travel_type

Update r
set
	r.[roomtype_id]=ro.[roomtype_id]
from raw.Review r
join raw.roomtype ro on r.room_type=ro.room_type

EXEC sp_help '[raw].[rentaldate]';
EXEC sp_help '[raw].[review]';

ALTER TABLE [raw].[rentaldate]
ALTER COLUMN [id_rental_date] VARCHAR(24);


select * from raw.Review
where Review_id='305'

drop table [dbo].[fact.review]

-- Tạo bảng raw_time
CREATE TABLE raw_time (
    id_date INT PRIMARY KEY,
    full_date DATE
);

-- Thêm dữ liệu từ 1/1/2019 đến 31/12/2022
INSERT INTO raw_time (id_date, full_date)
SELECT
    CONVERT(INT, FORMAT(DATEADD(DAY, t1.n, '2019-01-01'), 'yyyyMMdd')) AS id_date,
    DATEADD(DAY, t1.n, '2019-01-01') AS full_date
FROM
    (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
     FROM master.dbo.spt_values
    ) t1
WHERE
    DATEADD(DAY, t1.n, '2019-01-01') BETWEEN '2019-01-01' AND '2022-12-31';

-- Thêm cột day, month, year vào bảng raw_time
ALTER TABLE raw_time
ADD day INT,
    month INT,
    year INT;

-- Cập nhật dữ liệu cho cột day, month, year
UPDATE raw_time
SET day = DATEPART(DAY, full_date),
    month = DATEPART(MONTH, full_date),
    year = DATEPART(YEAR, full_date);

EXEC sp_rename 'raw_time.full_date', 'Date', 'COLUMN';

-- Thêm cột month_id vào bảng raw_time
ALTER TABLE [raw].[Review]
drop column rental_time;

ALTER TABLE raw.review
ADD rental_time varchar(50);


UPDATE raw.review
SET rental_time = rental_date;

UPDATE raw.Review
SET rental_time = 
    CASE 
        WHEN LEN(SUBSTRING(rental_time, 7, 2)) = 1
            THEN CONCAT('0', SUBSTRING(rental_time, 7, 6), SUBSTRING(rental_time, 16, 4))
        ELSE
            CONCAT(ISNULL(SUBSTRING(rental_time, 7, 7), ''), SUBSTRING(rental_time, 16, 4))
    END
WHERE rental_time LIKE 'tháng %';

ALTER TABLE raw.Review
drop column rental_month;
--thêm cột
ALTER TABLE raw.Review
ADD new_month_rental VARCHAR(2);

UPDATE raw.Review
SET new_month_rental = SUBSTRING(rental_month, CHARINDEX(' ', rental_month) + 1, LEN(rental_month) - CHARINDEX(' ', rental_month))
WHERE rental_month LIKE 'tháng %';

SELECT rental_month, new_month_rental
FROM raw.Review;

EXEC sp_rename 'raw.Review.new_month_rental', 'rental_month', 'COLUMN';

UPDATE raw.Review
SET rental_day = '1';

-- delete cột null
DELETE FROM raw.review_en1
WHERE dislike = 'Nothing ??';

DELETE FROM raw.review_en1
WHERE dislike is null;

DELETE FROM raw.review_en1
WHERE dislike = 'non';

DELETE FROM raw.review_en1
WHERE dislike = 'no';

DELETE FROM raw.review_en1
WHERE dislike = '.';

DELETE FROM raw.review_en1
WHERE dislike = 'na';

DELETE FROM raw.review_en1
WHERE dislike = 'nothing at all';

-- xây dựng bảng dislike
UPDATE e
SET e.dislike = r.dislike
FROM raw.review_en1 e
JOIN raw.Review r ON e.review_id = r.review_id
WHERE r.langugage IN ('en', 'en-us');

alter table [raw].[review_en1]
add dislike varchar(max)

CREATE TABLE raw.review_en1 (
    review_id INT);

INSERT INTO raw.review_en1 (review_id)
SELECT review_id
FROM raw.review;
