-- ST1501 CA2 Task c) - Data Warehouse creation (star schema)
-- Class 2B21 Group 05
CREATE DATABASE CA2DW2B2105;
USE CA2DW2B2105;

-- Date dimension, day-level granularity as instructed
CREATE TABLE DimDate (
    DateKey INT AUTO_INCREMENT PRIMARY KEY,   -- surrogate key
    FullDate DATE NOT NULL UNIQUE,
    Day INT NOT NULL,
    DayOfWeek VARCHAR(10) NOT NULL,
    IsWeekend BOOLEAN NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(10) NOT NULL,
    Quarter INT NOT NULL,
    Year INT NOT NULL
);

CREATE TABLE DimMember (
    MemberKey INT AUTO_INCREMENT PRIMARY KEY, -- surrogate key
    MemberID CHAR(10) NOT NULL,               -- natural key
    Name VARCHAR(100) NOT NULL,
    Gender CHAR(1) NOT NULL,
    Occupation VARCHAR(50) NULL,
    RegistrationDate DATE NOT NULL,
    TierName VARCHAR(20) NOT NULL,            -- denormalised tier attributes (star schema)
    TierLevel INT NOT NULL,
    BorrowLimit INT NOT NULL
);

CREATE TABLE DimStaff (
    StaffKey INT AUTO_INCREMENT PRIMARY KEY,  -- surrogate key
    StaffID CHAR(10) NOT NULL,                -- natural key
    Name VARCHAR(100) NOT NULL,
    Gender CHAR(1) NOT NULL,
    EmploymentType VARCHAR(20) NOT NULL,
    Department VARCHAR(50) NOT NULL,
    StartDate DATE NOT NULL
);

CREATE TABLE DimBook (
    BookKey INT AUTO_INCREMENT PRIMARY KEY,   -- surrogate key
    BookID CHAR(10) NOT NULL,                 -- natural key
    Title VARCHAR(200) NOT NULL,
    Author VARCHAR(100) NOT NULL,
    Genre VARCHAR(50) NOT NULL,
    MinTierName VARCHAR(20) NOT NULL,
    MinTierLevel INT NOT NULL
);

-- Fact table: one row per completed loan transaction (borrowed and returned)
CREATE TABLE FactLoan (
    LoanKey INT AUTO_INCREMENT PRIMARY KEY,   -- surrogate key
    MemberKey INT NOT NULL,
    StaffKey INT NOT NULL,
    BookKey INT NOT NULL,
    BorrowDateKey INT NOT NULL,
    ReturnDateKey INT NOT NULL,
    CopySeqNo INT NOT NULL,                   -- degenerate dimension
    LoanDurationDays INT NOT NULL,            -- return date - borrow date
    DaysBeforeDue INT NOT NULL,               -- due date - return date (negative = late)
    IsLate BOOLEAN NOT NULL,
    FOREIGN KEY (MemberKey) REFERENCES DimMember(MemberKey),
    FOREIGN KEY (StaffKey) REFERENCES DimStaff(StaffKey),
    FOREIGN KEY (BookKey) REFERENCES DimBook(BookKey),
    FOREIGN KEY (BorrowDateKey) REFERENCES DimDate(DateKey),
    FOREIGN KEY (ReturnDateKey) REFERENCES DimDate(DateKey)
);
