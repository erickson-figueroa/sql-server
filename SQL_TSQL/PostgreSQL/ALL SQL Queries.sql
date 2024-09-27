---------------------------------------------------------------
-- Queries to table creation  
---------------------------------------------------------------

CREATE TABLE users (
    user_id character varying(5) PRIMARY KEY,
    username VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    created_at TIMESTAMP
);

CREATE TABLE posts (
    post_id character varying(5) PRIMARY KEY,
    user_id character varying(5) REFERENCES users(user_id),
    content TEXT,
    title VARCHAR(255),
    updated_at TIMESTAMP
);

CREATE TABLE comments (
    comment_id character varying(5),
    user_id character varying(5) REFERENCES users(user_id),
    post_id character varying(5) REFERENCES posts(post_id),
    comment_content TEXT,
    commented_at TIMESTAMP
);

-- Creating the table blog_data to import the CSV file
CREATE TABLE blog_data (
    user_id VARCHAR(50),
    username VARCHAR(50),
    email VARCHAR(255),
    password VARCHAR(50),
    created_at TIMESTAMP,
    post_id VARCHAR(50),
    content TEXT,
    title VARCHAR(255),
    updated_at TIMESTAMP,
    comments VARCHAR(255)
);


-----------------------------------------------------------------------------
-- Queries to populate, clean and split the data in each corresponding table  
-----------------------------------------------------------------------------


-- Inserting data to each table based on "blog_data table"
-- The blog_data table previosly created has the CSV data rows

-- Insert into users table
INSERT INTO users (user_id, username, email, password, created_at)
SELECT user_id, username, email, password, created_at FROM blog_data;


-- Insert into posts table
INSERT INTO posts (post_id, user_id, content, title, updated_at)
SELECT post_id, user_id, content, title, updated_at FROM blog_data;


-- Create a temporary table to clean and get the comments string by user_id
CREATE TEMPORARY TABLE temp_comment_string (
original_comment VARCHAR(255) NULL,
comment_id VARCHAR(50) NULL,
user_id VARCHAR(50) NULL,
post_id VARCHAR(50) NULL,
comment_content VARCHAR(255) NULL,
commented_at VARCHAR(50) NULL
);

-- Insert data with more than user_id in the same comment string
INSERT INTO temp_comment_string (original_comment, comment_id, user_id, post_id, comment_content, commented_at)
WITH SplitComments AS (
    SELECT
comments,    
user_id,
   post_id,
        SPLIT_PART(comments, '|', 1) AS comment_part_1,
        SPLIT_PART(comments, '|', 2) AS comment_part_2
    FROM
        blog_data
    WHERE
        comments LIKE '%|%'

)
SELECT
    comments AS original_comment,
'cid' || SPLIT_PART(comment_part_1, 'cid', 2) AS comment_id,
user_id,
post_id,
REGEXP_REPLACE(comment_part_1, '2024.*$', '') AS comment_content,
REGEXP_REPLACE(comment_part_1, '^.*?(\d{4}-\d{2}-\d{2} \d{2}:\d{2}).*$', '\1') AS commented_at
FROM
    SplitComments

UNION ALL

SELECT
    comments AS original_comment,
'cid' || SPLIT_PART(comment_part_2, 'cid', 2) AS comment_id,
user_id,
post_id,
REGEXP_REPLACE(comment_part_2, '2024.*$', '') AS comment_content,
REGEXP_REPLACE(comment_part_2, '^.*?(\d{4}-\d{2}-\d{2} \d{2}:\d{2}).*$', '\1') AS commented_at
FROM
    SplitComments;

--------------------------------------------------------------------------------------------------------------


-- Insert data with only one user_id in the same comment string
INSERT INTO temp_comment_string (original_comment, comment_id, user_id, post_id, comment_content, commented_at)

WITH SplitComments AS (
    SELECT
comments,    
user_id,
   post_id,
        SPLIT_PART(comments, '|', 1) AS comment_part_1,
        SPLIT_PART(comments, '|', 2) AS comment_part_2
    FROM
        blog_data
    WHERE
        comments NOT LIKE '%|%'

)
SELECT
    comments AS original_comment,
'cid' || SPLIT_PART(comment_part_1, 'cid', 2) AS comment_id,
user_id,
post_id,
REGEXP_REPLACE(comment_part_1, '2024.*$', '') AS comment_content,
REGEXP_REPLACE(comment_part_1, '^.*?(\d{4}-\d{2}-\d{2} \d{2}:\d{2}).*$', '\1') AS commented_at
FROM
    SplitComments

UNION ALL

SELECT
    comments AS original_comment,
'cid' || SPLIT_PART(comment_part_2, 'cid', 2) AS comment_id,
user_id,
post_id,
REGEXP_REPLACE(comment_part_2, '2024.*$', '') AS comment_content,
REGEXP_REPLACE(comment_part_2, '^.*?(\d{4}-\d{2}-\d{2} \d{2}:\d{2}).*$', '\1') AS commented_at
FROM
    SplitComments;


-- Delete rows where comment_content and comented_at is empty after insert
DELETE FROM temp_comment_string WHERE comment_content = '' OR commented_at = ''  


-- Finally, insert in the comments table the clean data
INSERT INTO comments (comment_id, user_id, post_id, comment_content, commented_at)
SELECT
    comment_id,
user_id,
post_id,
TRIM(BOTH ' ' FROM comment_content) AS comment_content,
commented_at::timestamp AS commented_at --> casting to avoid datetime error convertion
FROM temp_comment_string;


-----------------------------------------------------------------------------
-- Queries for the CRUD operations  
-----------------------------------------------------------------------------

-- Retrieve all users
SELECT * FROM users

-- Retrieve all posts
SELECT * FROM posts

-- Retrieve all commends
SELECT * FROM comments

-- Update a user email
UPDATE  users
SET email = 'sarah@gmail.com'
WHERE username = 'sarah_c' and user_id = 'uid1';


-- Deleting a user
DELETE FROM comments WHERE TRIM(BOTH ' ' FROM comment_id)  = 'cid4';


-- Testing duplicate values:

-- Inserting a duplicate user_id we will receive an error
-- of violation constrain, because is the primary key
-- and do not permit duplicates rows in the column: user_id

INSERT INTO users (user_id, username, email, password)
VALUES ('uid5', 'John_d', 'john@go.com', 'password123');
