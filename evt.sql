-- Create Events table to store event definitions
CREATE TABLE Events (
    EventID INT PRIMARY KEY IDENTITY(1,1),
    EventName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    Periodicity NVARCHAR(20) NOT NULL, -- 'daily', 'monthly', 'quarterly', etc.
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT CHK_Periodicity CHECK (Periodicity IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly'))
);

-- Create Sources table to store data sources
CREATE TABLE Sources (
    SourceID INT PRIMARY KEY IDENTITY(1,1),
    SourceName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedAt DATETIME2 DEFAULT GETDATE()
);

-- Create EventStages table for possible event stages
CREATE TABLE EventStages (
    StageID INT PRIMARY KEY IDENTITY(1,1),
    StageName NVARCHAR(50) NOT NULL,  -- e.g., 'preliminary', 'revised', 'final'
    Description NVARCHAR(MAX),
    CONSTRAINT UQ_StageName UNIQUE (StageName)
);

-- Create EventOccurrences table to store actual event data
CREATE TABLE EventOccurrences (
    OccurrenceID BIGINT PRIMARY KEY IDENTITY(1,1),
    EventID INT NOT NULL,
    SourceID INT NOT NULL,
    StageID INT NOT NULL,
    EventTimestamp DATETIME2 NOT NULL,  -- When the event occurred
    ExpectedValue DECIMAL(18,4),        -- The value associated with the event
    PublishTimestamp DATETIME2 NOT NULL, -- When the data was published
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_EventOccurrences_Events FOREIGN KEY (EventID) REFERENCES Events(EventID),
    CONSTRAINT FK_EventOccurrences_Sources FOREIGN KEY (SourceID) REFERENCES Sources(SourceID),
    CONSTRAINT FK_EventOccurrences_Stages FOREIGN KEY (StageID) REFERENCES EventStages(StageID)
);

-- Create indexes for better query performance
CREATE INDEX IX_EventOccurrences_EventID ON EventOccurrences(EventID);
CREATE INDEX IX_EventOccurrences_EventTimestamp ON EventOccurrences(EventTimestamp);
CREATE INDEX IX_EventOccurrences_Composite 
    ON EventOccurrences(EventID, EventTimestamp, SourceID, StageID);

-- Example query to get event occurrences for a specific event
GO
CREATE PROCEDURE GetEventOccurrences
    @EventID INT,
    @StartDate DATETIME2,
    @EndDate DATETIME2,
    @StageID INT = NULL
AS
BEGIN
    SELECT 
        e.EventName,
        eo.EventTimestamp,
        eo.ExpectedValue,
        eo.PublishTimestamp,
        s.SourceName,
        es.StageName
    FROM EventOccurrences eo
    JOIN Events e ON eo.EventID = e.EventID
    JOIN Sources s ON eo.SourceID = s.SourceID
    JOIN EventStages es ON eo.StageID = es.StageID
    WHERE eo.EventID = @EventID
        AND eo.EventTimestamp BETWEEN @StartDate AND @EndDate
        AND (@StageID IS NULL OR eo.StageID = @StageID)
    ORDER BY eo.EventTimestamp, eo.PublishTimestamp;
END
