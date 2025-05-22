ALTER FUNCTION [dbo].[F_WORKS_LIST] (
    @PageSize INT = 3000,
    @PageNumber INT = 1
)
RETURNS @RESULT TABLE
(
    ID_WORK INT,
    CREATE_Date DATETIME,
    MaterialNumber DECIMAL(8,2),
    IS_Complit BIT,
    FIO VARCHAR(255),
    D_DATE VARCHAR(10),
    WorkItemsNotComplit INT,
    WorkItemsComplit INT,
    FULL_NAME VARCHAR(101),
    StatusId SMALLINT,
    StatusName VARCHAR(255),
    Is_Print BIT
)
AS
BEGIN
    WITH WorkItemCounts AS (
        SELECT 
            wi.Id_Work,
            SUM(CASE WHEN wi.Is_Complit = 0 AND a.IS_GROUP = 0 THEN 1 ELSE 0 END) AS WorkItemsNotComplit,
            SUM(CASE WHEN wi.Is_Complit = 1 AND a.IS_GROUP = 0 THEN 1 ELSE 0 END) AS WorkItemsComplit
        FROM WorkItem wi
        INNER JOIN Analiz a ON wi.ID_ANALIZ = a.ID_ANALIZ
        WHERE a.IS_GROUP = 0
        GROUP BY wi.Id_Work
    )
    INSERT INTO @RESULT
    SELECT
        w.Id_Work,
        w.CREATE_Date,
        w.MaterialNumber,
        w.IS_Complit,
        w.FIO,
        CONVERT(VARCHAR(10), w.CREATE_Date, 104) AS D_DATE,
        COALESCE(wc.WorkItemsNotComplit, 0) AS WorkItemsNotComplit,
        COALESCE(wc.WorkItemsComplit, 0) AS WorkItemsComplit,
        RTRIM(COALESCE(e.SURNAME + ' ' + UPPER(LEFT(e.NAME, 1)) + '.' + 
              CASE WHEN e.PATRONYMIC = '' THEN '' ELSE UPPER(LEFT(e.PATRONYMIC, 1)) + '.' END, 
              e.LOGIN_NAME)) AS FULL_NAME,
        w.StatusId,
        ws.StatusName,
        CASE
            WHEN w.Print_Date IS NOT NULL OR
                 w.SendToClientDate IS NOT NULL OR
                 w.SendToDoctorDate IS NOT NULL OR
                 w.SendToOrgDate IS NOT NULL OR
                 w.SendToFax IS NOT NULL
            THEN 1
            ELSE 0
        END AS Is_Print
    FROM Works w
    LEFT JOIN WorkStatus ws ON w.StatusId = ws.StatusID
    LEFT JOIN WorkItemCounts wc ON w.Id_Work = wc.Id_Work
    LEFT JOIN Employee e ON w.Id_Employee = e.Id_Employee
    WHERE w.IS_DEL = 0
    ORDER BY w.Id_Work DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    RETURN;
END;