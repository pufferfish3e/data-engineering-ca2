create database CA2OLTP;
use CA2OLTP;
-- change db name accordingly

CREATE TABLE MembershipTier (
    TierID CHAR(10) PRIMARY KEY,
    TierName VARCHAR(20) NOT NULL,
    TierLevel INT NOT NULL,
    BorrowLimit INT NOT NULL
);

CREATE TABLE Member (
    MemberID CHAR(10) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Contact VARCHAR(100) NOT NULL,
    DOB DATE NOT NULL,
    Gender CHAR(1) NOT NULL,
    Occupation VARCHAR(50) NULL,
    RegistrationDatetime DATETIME NOT NULL,
    TierID CHAR(10) NOT NULL,
    FOREIGN KEY (TierID) REFERENCES MembershipTier(TierID)
);

CREATE TABLE Staff (
    StaffID CHAR(10) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Contact VARCHAR(100) NOT NULL,
    Gender CHAR(1) NOT NULL,
    EmploymentType VARCHAR(20) NOT NULL,
    StartDate DATE NOT NULL,
    Department VARCHAR(50) NOT NULL,
    DOB DATE NOT NULL
);

CREATE TABLE Book (
    BookID CHAR(10) PRIMARY KEY,
    Title VARCHAR(200) NOT NULL,
    Author VARCHAR(100) NOT NULL,
    Genre VARCHAR(50) NOT NULL,
    MinTierID CHAR(5) NOT NULL,
    FOREIGN KEY (MinTierID) REFERENCES MembershipTier(TierID)
);

CREATE TABLE BookCopy (
    BookID CHAR(10) NOT NULL,
    CopySeqNo INT NOT NULL,
    Status VARCHAR(20) NOT NULL,
    PRIMARY KEY (BookID, CopySeqNo),
    FOREIGN KEY (BookID) REFERENCES Book(BookID)
);

CREATE TABLE Loan (
    MemberID CHAR(10) NOT NULL,
    StaffID CHAR(10) NOT NULL,
    BookID CHAR(10) NOT NULL,
    CopySeqNo INT NOT NULL,
    StartDatetime DATETIME NOT NULL,
    DueDate DATE NOT NULL,
    ReturnDatetime DATETIME NULL,
    PRIMARY KEY (MemberID, BookID, CopySeqNo, StartDatetime),
    FOREIGN KEY (MemberID) REFERENCES Member(MemberID),
    FOREIGN KEY (StaffID) REFERENCES Staff(StaffID),
    FOREIGN KEY (BookID, CopySeqNo) REFERENCES BookCopy(BookID, CopySeqNo)
);

