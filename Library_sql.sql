-- Task 1: Insert a new book
INSERT INTO books (isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

-- Task 2: Update member address
UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';
SELECT * FROM members;

-- Task 3: Delete from issued_status
DELETE FROM issued_status
WHERE issued_id = 'IS121';

-- Task 4: Retrieve books issued by employee 'E101'
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: Members who issued more than one book
SELECT 
    ist.issued_emp_id,
    e.emp_name,
    COUNT(*) AS issue_count
FROM issued_status AS ist
JOIN employees AS e ON e.emp_id = ist.issued_emp_id
GROUP BY ist.issued_emp_id, e.emp_name
HAVING COUNT(*) > 1;

-- Task 6: Create a summary table (CTAS style)
CREATE TABLE book_cnts AS
SELECT 
    b.isbn,
    b.book_title,
    COUNT(ist.issued_id) AS no_issued
FROM books AS b
JOIN issued_status AS ist ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;
SELECT * FROM book_cnts;

-- Task 7: Books in category 'Classic'
SELECT * FROM books
WHERE category = 'Classic';

-- Task 8: Total rental income by category
SELECT
    b.category,
    SUM(b.rental_price) AS total_income,
    COUNT(*) AS issued_count
FROM books AS b
JOIN issued_status AS ist ON ist.issued_book_isbn = b.isbn
GROUP BY b.category;

-- Task 9: Members registered in the last 180 days
SELECT * FROM members
WHERE reg_date >= CURDATE() - INTERVAL 180 DAY;

INSERT INTO members (member_id, member_name, member_address, reg_date)
VALUES
('C118', 'sam', '145 Main St', '2024-06-01'),
('C119', 'john', '133 Main St', '2024-05-01');

-- Task 10: Employees with their manager’s name and branch details
SELECT 
    e1.*,
    b.manager_id,
    e2.emp_name AS manager
FROM employees AS e1
JOIN branch AS b ON b.branch_id = e1.branch_id
JOIN employees AS e2 ON b.manager_id = e2.emp_id;

-- Task 11: Books with rental price > 7
CREATE TABLE books_price_greater_than_seven AS
SELECT * FROM books
WHERE rental_price > 7;

SELECT * FROM books_price_greater_than_seven;

-- Task 12: Books not returned yet
SELECT 
    DISTINCT ist.issued_book_name
FROM issued_status AS ist
LEFT JOIN return_status AS rs ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL;

SELECT * FROM return_status;

-- Task 13: Identify Members with Overdue Books
SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    DATEDIFF(CURDATE(), ist.issued_date) AS over_dues_days
FROM issued_status AS ist
JOIN members AS m ON m.member_id = ist.issued_member_id
JOIN books AS bk ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND DATEDIFF(CURDATE(), ist.issued_date) > 30
ORDER BY ist.issued_member_id;

-- Task 14: Update Book Status on Return
UPDATE books
SET status = 'yes'
WHERE isbn IN (
    SELECT ist.issued_book_isbn
    FROM return_status AS rs
    JOIN issued_status AS ist ON rs.issued_id = ist.issued_id
);

-- Task 15: Branch Performance Report
CREATE TABLE branch_reports AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(DISTINCT ist.issued_id) AS number_book_issued,
    COUNT(DISTINCT rs.return_id) AS number_of_book_return,
    SUM(bk.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN employees AS e ON e.emp_id = ist.issued_emp_id
JOIN branch AS b ON e.branch_id = b.branch_id
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
JOIN books AS bk ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.manager_id;

-- Task 16: Create Active Members Table (CTAS)
CREATE TABLE active_members AS
SELECT * FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= CURDATE() - INTERVAL 2 MONTH
);

-- Task 17: Top 3 Employees by Book Issues
SELECT 
    e.emp_name,
    b.branch_id,
    b.branch_name,
    COUNT(ist.issued_id) AS no_book_issued
FROM issued_status AS ist
JOIN employees AS e ON e.emp_id = ist.issued_emp_id
JOIN branch AS b ON e.branch_id = b.branch_id
GROUP BY e.emp_id, e.emp_name, b.branch_id, b.branch_name
ORDER BY no_book_issued DESC
LIMIT 3;

-- Task 19: Stored Procedure to Issue Book if Available
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

        SELECT CONCAT('Book issued successfully for ISBN: ', p_issued_book_isbn) AS message;
    ELSE
        SELECT CONCAT('Book unavailable for ISBN: ', p_issued_book_isbn) AS message;
    END IF;
END //
DELIMITER ;