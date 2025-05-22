SET NOCOUNT ON;

-- 1. Создание временных таблиц для тестовых данных
IF OBJECT_ID('tempdb..#EmployeeData') IS NOT NULL DROP TABLE #EmployeeData;
IF OBJECT_ID('tempdb..#WorkStatusData') IS NOT NULL DROP TABLE #WorkStatusData;
IF OBJECT_ID('tempdb..#AnalizData') IS NOT NULL DROP TABLE #AnalizData;
IF OBJECT_ID('tempdb..#OrganizationData') IS NOT NULL DROP TABLE #OrganizationData;
IF OBJECT_ID('tempdb..#SelectTypeData') IS NOT NULL DROP TABLE #SelectTypeData;
IF OBJECT_ID('tempdb..#TemplateTypeData') IS NOT NULL DROP TABLE #TemplateTypeData;
IF OBJECT_ID('tempdb..#PrintTemplateData') IS NOT NULL DROP TABLE #PrintTemplateData;
IF OBJECT_ID('tempdb..#WorksData') IS NOT NULL DROP TABLE #WorksData;
IF OBJECT_ID('tempdb..#WorkItemData') IS NOT NULL DROP TABLE #WorkItemData;

-- 2. Генерация базовых данных
CREATE TABLE #EmployeeData (
    Id_Employee INT IDENTITY(1,1),
    Login_Name VARCHAR(50),
    Name VARCHAR(50),
    Patronymic VARCHAR(50),
    Surname VARCHAR(50),
    Email VARCHAR(50),
    Post VARCHAR(50),
    CreateDate DATETIME,
    Archived BIT,
    IS_Role BIT,
    Role INT
);

INSERT INTO #EmployeeData (Login_Name, Name, Patronymic, Surname, Email, Post, CreateDate, Archived, IS_Role, Role)
SELECT 
    'user' + CAST(n AS VARCHAR(10)),
    'Name' + CAST(n AS VARCHAR(10)),
    'Patronymic' + CAST(n AS VARCHAR(10)),
    'Surname' + CAST(n AS VARCHAR(10)),
    'user' + CAST(n AS VARCHAR(10)) + '@example.com',
    CASE n % 3 
        WHEN 0 THEN 'Manager' 
        WHEN 1 THEN 'Analyst' 
        ELSE 'Technician' 
    END,
    GETDATE(),
    0,
    0,
    0
FROM (SELECT TOP 10 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.objects) AS nums;

CREATE TABLE #WorkStatusData (
    StatusID SMALLINT IDENTITY(1,1),
    StatusName VARCHAR(255)
);

INSERT INTO #WorkStatusData (StatusName)
VALUES ('New'), ('In Progress'), ('Completed'), ('Cancelled'), ('On Hold');

CREATE TABLE #AnalizData (
    ID_ANALIZ INT IDENTITY(1,1),
    IS_GROUP BIT,
    MATERIAL_TYPE INT,
    CODE_NAME VARCHAR(50),
    FULL_NAME VARCHAR(255),
    Price DECIMAL(8,2)
);

INSERT INTO #AnalizData (IS_GROUP, MATERIAL_TYPE, CODE_NAME, FULL_NAME, Price)
SELECT 
    CASE WHEN n % 5 = 0 THEN 1 ELSE 0 END,
    n % 3,
    'CODE' + CAST(n AS VARCHAR(10)),
    'Analysis ' + CAST(n AS VARCHAR(10)),
    100.00 + (n * 10.50)
FROM (SELECT TOP 20 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.objects) AS nums;

CREATE TABLE #OrganizationData (
    ID_ORGANIZATION INT IDENTITY(1,1),
    ORG_NAME VARCHAR(255),
    Email VARCHAR(255)
);

INSERT INTO #OrganizationData (ORG_NAME, Email)
VALUES 
    ('Org1', 'org1@example.com'),
    ('Org2', 'org2@example.com'),
    ('Org3', 'org3@example.com'),
    ('Org4', 'org4@example.com'),
    ('Org5', 'org5@example.com');

CREATE TABLE #SelectTypeData (
    Id_SelectType INT IDENTITY(1,1),
    SelectType VARCHAR(50)
);

INSERT INTO #SelectTypeData (SelectType)
VALUES ('Type1'), ('Type2'), ('Type3');

CREATE TABLE #TemplateTypeData (
    Id_TemplateType INT IDENTITY(1,1),
    TemlateVal VARCHAR(50),
    Comment VARCHAR(255)
);

INSERT INTO #TemplateTypeData (TemlateVal, Comment)
VALUES 
    ('Template1', 'Standard Template'),
    ('Template2', 'Custom Template'),
    ('Template3', 'Advanced Template');

CREATE TABLE #PrintTemplateData (
    Id_PrintTemplate INT IDENTITY(1,1),
    TemplateName VARCHAR(255),
    CreateDate DATETIME,
    Ext VARCHAR(10),
    Id_TemplateType INT
);

INSERT INTO #PrintTemplateData (TemplateName, CreateDate, Ext, Id_TemplateType)
SELECT 
    'Template' + CAST(n AS VARCHAR(10)),
    GETDATE(),
    '.pdf',
    (n % 3) + 1
FROM (SELECT TOP 5 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.objects) AS nums;

CREATE TABLE #WorksData (
    Id_Work INT IDENTITY(1,1),
    IS_Complit BIT,
    CREATE_Date DATETIME,
    MaterialNumber DECIMAL(8,2),
    FIO VARCHAR(255),
    Id_Employee INT,
    ID_ORGANIZATION INT,
    StatusId SMALLINT,
    Is_Del BIT,
    Price DECIMAL(8,2)
);

;WITH Numbers AS (
    SELECT TOP 50000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects a
    CROSS JOIN sys.objects b
)
INSERT INTO #WorksData (IS_Complit, CREATE_Date, MaterialNumber, FIO, Id_Employee, ID_ORGANIZATION, StatusId, Is_Del, Price)
SELECT 
    CASE WHEN n % 10 = 0 THEN 1 ELSE 0 END,
    DATEADD(DAY, -n % 365, GETDATE()),
    CAST(n AS DECIMAL(8,2)) / 100,
    'Client' + CAST(n AS VARCHAR(10)),
    (n % 10) + 1,
    (n % 5) + 1,
    (n % 5) + 1,
    CASE WHEN n % 100 = 0 THEN 1 ELSE 0 END,
    500.00 + (n % 100 * 10.00)
FROM Numbers;

CREATE TABLE #WorkItemData (
    ID_WORKItem INT IDENTITY(1,1),
    CREATE_DATE DATETIME,
    Is_Complit BIT,
    Id_Employee INT,
    ID_ANALIZ INT,
    Id_Work INT,
    Is_Print BIT,
    Is_Select BIT,
    Is_NormTextPrint BIT,
    Price DECIMAL(8,2),
    Id_SelectType INT
);

INSERT INTO #WorkItemData (CREATE_DATE, Is_Complit, Id_Employee, ID_ANALIZ, Id_Work, Is_Print, Is_Select, Is_NormTextPrint, Price, Id_SelectType)
SELECT 
    DATEADD(DAY, -n % 365, GETDATE()),
    CASE WHEN n % 3 = 0 THEN 1 ELSE 0 END,
    (n % 10) + 1,
    (n % 20) + 1,
    w.Id_Work,
    1,
    0,
    1,
    100.00 + (n % 20 * 5.00),
    (n % 3) + 1
FROM #WorksData w
CROSS APPLY (
    SELECT TOP (2 + ABS(CHECKSUM(NEWID()) % 3)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects
) AS items;

-- 3. Вставка тестовых данных в реальные таблицы
BEGIN TRANSACTION;

INSERT INTO Employee (Login_Name, Name, Patronymic, Surname, Email, Post, CreateDate, Archived, IS_Role, Role)
SELECT Login_Name, Name, Patronymic, Surname, Email, Post, CreateDate, Archived, IS_Role, Role
FROM #EmployeeData;

INSERT INTO WorkStatus (StatusName)
SELECT StatusName FROM #WorkStatusData;

INSERT INTO Analiz (IS_GROUP, MATERIAL_TYPE, CODE_NAME, FULL_NAME, Price)
SELECT IS_GROUP, MATERIAL_TYPE, CODE_NAME, FULL_NAME, Price
FROM #AnalizData;

INSERT INTO Organization (ORG_NAME, Email)
SELECT ORG_NAME, Email FROM #OrganizationData;

INSERT INTO SelectType (SelectType)
SELECT SelectType FROM #SelectTypeData;

INSERT INTO TemplateType (TemlateVal, Comment)
SELECT TemlateVal, Comment FROM #TemplateTypeData;

INSERT INTO PrintTemplate (TemplateName, CreateDate, Ext, Id_TemplateType)
SELECT TemplateName, CreateDate, Ext, Id_TemplateType
FROM #PrintTemplateData;

INSERT INTO Works (
    IS_Complit, CREATE_Date, MaterialNumber, FIO, Id_Employee, 
    ID_ORGANIZATION, StatusId, Is_Del, Price
)
SELECT 
    IS_Complit, CREATE_Date, MaterialNumber, FIO, Id_Employee, 
    ID_ORGANIZATION, StatusId, Is_Del, Price
FROM #WorksData;

INSERT INTO WorkItem (
    CREATE_DATE, Is_Complit, Id_Employee, ID_ANALIZ, Id_Work, 
    Is_Print, Is_Select, Is_NormTextPrint, Price, Id_SelectType
)
SELECT 
    CREATE_DATE, Is_Complit, Id_Employee, ID_ANALIZ, Id_Work, 
    Is_Print, Is_Select, Is_NormTextPrint, Price, Id_SelectType
FROM #WorkItemData;

COMMIT TRANSACTION;

-- 4. Проверка сгенерированных данных
SELECT 'Employee Count' AS TableName, COUNT(*) AS RecordCount FROM Employee;
SELECT 'WorkStatus Count' AS TableName, COUNT(*) AS RecordCount FROM WorkStatus;
SELECT 'Analiz Count' AS TableName, COUNT(*) AS RecordCount FROM Analiz;
SELECT 'Organization Count' AS TableName, COUNT(*) AS RecordCount FROM Organization;
SELECT 'SelectType Count' AS TableName, COUNT(*) AS RecordCount FROM SelectType;
SELECT 'TemplateType Count' AS TableName, COUNT(*) AS RecordCount FROM TemplateType;
SELECT 'PrintTemplate Count' AS TableName, COUNT(*) AS RecordCount FROM PrintTemplate;
SELECT 'Works Count' AS TableName, COUNT(*) AS RecordCount FROM Works;
SELECT 'WorkItem Count' AS TableName, COUNT(*) AS RecordCount FROM WorkItem;

-- 5. Тестирование функции F_WORKS_LIST
DECLARE @StartTime DATETIME = GETDATE();
SELECT * FROM dbo.F_WORKS_LIST(3000, 1);
SELECT DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS ExecutionTime_MS;

-- 6. Скрипт очистки (использовать с осторожностью)
/*
BEGIN TRANSACTION;
DELETE FROM WorkItem;
DELETE FROM Works;
DELETE FROM PrintTemplate;
DELETE FROM TemplateType;
DELETE FROM SelectType;
DELETE FROM Organization;
DELETE FROM Analiz;
DELETE FROM WorkStatus;
DELETE FROM Employee;
COMMIT TRANSACTION;
*/
