# Library Management System using SQL

## Project Overview

**Project Title**: Library Management System  
**Level**: Intermediate  

This project demonstrates the implementation of a Library Management System using SQL. It includes creating and managing tables, performing CRUD operations, and executing advanced SQL queries. The goal is to showcase skills in database design, manipulation, and querying.

## Objectives

1. **Set up the Library Management System Database**: Create and populate the database with tables for branches, employees, members, books, issued status, and return status.  
2. **CRUD Operations**: Perform Create, Read, Update, and Delete operations on the data.  
3. **CTAS (Create Table As Select)**: Utilize CTAS to create new tables based on query results.  
4. **Advanced SQL Queries**: Develop complex queries to analyze and retrieve specific data.

## Project Structure

### 1. Database Setup

- **Database Creation**: Created a database named `library_db`.  
- **Table Creation**: Created tables for branches, employees, members, books, issued status, and return status. Each table includes relevant columns and relationships.

```sql
CREATE DATABASE library_db;
USE library_db;

DROP TABLE IF EXISTS branch;
CREATE TABLE branch (
  branch_id VARCHAR(10) PRIMARY KEY,
  manager_id VARCHAR(10),
  branch_address VARCHAR(30),
  contact_no VARCHAR(15)
);

DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
  emp_id VARCHAR(10) PRIMARY KEY,
  emp_name VARCHAR(30),
  position VARCHAR(30),
  salary DECIMAL(10,2),
  branch_id VARCHAR(10),
  FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

DROP TABLE IF EXISTS members;
CREATE TABLE members (
  member_id VARCHAR(10) PRIMARY KEY,
  member_name VARCHAR(30),
  member_address VARCHAR(30),
  reg_date DATE
);

DROP TABLE IF EXISTS books;
CREATE TABLE books (
  isbn VARCHAR(50) PRIMARY KEY,
  book_title VARCHAR(80),
  category VARCHAR(30),
  rental_price DECIMAL(10,2),
  status VARCHAR(10),
  author VARCHAR(30),
  publisher VARCHAR(30)
);

DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status (
  issued_id VARCHAR(10) PRIMARY KEY,
  issued_member_id VARCHAR(30),
  issued_book_name VARCHAR(80),
  issued_date DATE,
  issued_book_isbn VARCHAR(50),
  issued_emp_id VARCHAR(10),
  FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
  FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
  FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn)
);

DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status (
  return_id VARCHAR(10) PRIMARY KEY,
  issued_id VARCHAR(30),
  return_book_name VARCHAR(80),
  return_date DATE,
  return_book_isbn VARCHAR(50),
  FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);
```

### 2. CRUD Operations

- **Create**: Inserted sample records into the `books` table.  
- **Read**: Retrieved and displayed data from various tables.  
- **Update**: Updated records in the `employees` table.  
- **Delete**: Removed records from the `members` table as needed.

**Task 1. Create a New Book Record**
```sql
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;
```

**Task 2: Update an Existing Member's Address**
```sql
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';
```

**Task 3: Delete a Record from the Issued Status Table**
```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';
```

**Task 4: Retrieve All Books Issued by a Specific Employee**
```sql
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';
```

**Task 5: List Members Who Have Issued More Than One Book**
```sql
SELECT issued_member_id, COUNT(*)
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*) > 1;
```

### 3. CTAS (Create Table As Select)

**Task 6: Create Summary Tables**
```sql
CREATE TABLE book_issued_cnt AS
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) AS issue_count
FROM issued_status ist
JOIN books b ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;
```

### 4. Data Analysis & Findings

**Task 7: Retrieve All Books in a Specific Category**
```sql
SELECT * FROM books
WHERE category = 'Classic';
```

**Task 8: Find Total Rental Income by Category**
```sql
SELECT b.category, SUM(b.rental_price), COUNT(*)
FROM issued_status ist
JOIN books b ON b.isbn = ist.issued_book_isbn
GROUP BY b.category;
```

**Task 9: List Members Who Registered in the Last 180 Days**
```sql
SELECT * FROM members
WHERE reg_date >= CURDATE() - INTERVAL 180 DAY;
```

**Task 10: List Employees with Their Branch Manager's Name and Branch Details**
```sql
SELECT 
  e1.emp_id, e1.emp_name, e1.position, e1.salary, b.*, e2.emp_name AS manager
FROM employees e1
JOIN branch b ON e1.branch_id = b.branch_id
JOIN employees e2 ON e2.emp_id = b.manager_id;
```

**Task 11: Create a Table of Books with Rental Price Above a Threshold**
```sql
CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;
```

**Task 12: Retrieve the List of Books Not Yet Returned**
```sql
SELECT DISTINCT ist.issued_book_name
FROM issued_status ist
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;
```

## Advanced SQL Operations

**Task 13: Identify Members with Overdue Books**
```sql
SELECT 
  ist.issued_member_id, m.member_name, bk.book_title,
  ist.issued_date,
  DATEDIFF(CURDATE(), ist.issued_date) AS over_due_days
FROM issued_status ist
JOIN members m ON m.member_id = ist.issued_member_id
JOIN books bk ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND DATEDIFF(CURDATE(), ist.issued_date) > 30;
```

**Task 14: Update Book Status on Return**
(Use stored procedure in MySQL syntax)

```sql
DELIMITER //
CREATE PROCEDURE add_return_records (
  IN p_return_id VARCHAR(10),
  IN p_issued_id VARCHAR(10),
  IN p_book_quality VARCHAR(10)
)
BEGIN
  DECLARE v_isbn VARCHAR(50);
  DECLARE v_book_name VARCHAR(80);

  INSERT INTO return_status(return_id, issued_id, return_date, return_book_name, return_book_isbn)
  SELECT p_return_id, p_issued_id, CURDATE(), issued_book_name, issued_book_isbn
  FROM issued_status
  WHERE issued_id = p_issued_id;

  SELECT issued_book_isbn, issued_book_name INTO v_isbn, v_book_name
  FROM issued_status WHERE issued_id = p_issued_id;

  UPDATE books SET status = 'yes' WHERE isbn = v_isbn;
END //
DELIMITER ;
```

**Task 15: Branch Performance Report**
```sql
CREATE TABLE branch_reports AS
SELECT 
  b.branch_id, b.manager_id,
  COUNT(ist.issued_id) AS number_book_issued,
  COUNT(rs.return_id) AS number_of_book_return,
  SUM(bk.rental_price) AS total_revenue
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b ON e.branch_id = b.branch_id
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
JOIN books bk ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.manager_id;
```

**Task 16: Create a Table of Active Members**
```sql
CREATE TABLE active_members AS
SELECT * FROM members
WHERE member_id IN (
  SELECT DISTINCT issued_member_id
  FROM issued_status
  WHERE issued_date >= CURDATE() - INTERVAL 2 MONTH
);
```

**Task 17: Employees with Most Book Issues**
```sql
SELECT e.emp_name, b.*, COUNT(ist.issued_id) AS no_book_issued
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b ON e.branch_id = b.branch_id
GROUP BY e.emp_id
ORDER BY no_book_issued DESC
LIMIT 3;
```

**Task 19: Stored Procedure to Issue Book**
```sql
DELIMITER //
CREATE PROCEDURE issue_book (
  IN p_issued_id VARCHAR(10),
  IN p_issued_member_id VARCHAR(30),
  IN p_issued_book_isbn VARCHAR(30),
  IN p_issued_emp_id VARCHAR(10)
)
BEGIN
  DECLARE v_status VARCHAR(10);

  SELECT status INTO v_status FROM books WHERE isbn = p_issued_book_isbn;

  IF v_status = 'yes' THEN
    INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
    VALUES (p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id);

    UPDATE books SET status = 'no' WHERE isbn = p_issued_book_isbn;
  ELSE
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Book is currently not available';
  END IF;
END //
DELIMITER ;
```

## Reports

- **Database Schema**: Detailed table structures and relationships.  
- **Data Analysis**: Insights into book categories, employee salaries, member registration trends, and issued books.  
- **Summary Reports**: Aggregated data on high-demand books and employee performance.

## Conclusion

This project demonstrates the application of SQL skills in creating and managing a library management system. It includes database setup, data manipulation, and advanced querying, providing a solid foundation for data management and analysis.

## How to Use


2. **Set Up the Database**: Execute the SQL scripts in the `database_setup.sql` file to create and populate the database.  
3. **Run the Queries**: Use the SQL queries in the `analysis_queries.sql` file to perform the analysis.  
4. **Explore and Modify**: Customize the queries as needed to explore different aspects of the data or answer additional questions.

## Author - Zero Analyst

This project showcases SQL skills essential for database management and analysis. For more content on SQL and data analysis, connect with me through the following channels:


