-- =============================================
-- Author:		<Zahra Saffarpour>
-- Create date: <5/21/2023>
-- Version:		<3.0.0.0>
-- Description:	<>
-- =============================================
CREATE OR ALTER PROCEDURE [ssbs].[proc_GeneralRecieve]
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @myMessageType_Host VARCHAR(256);
    DECLARE @myConversationHandle_Host UNIQUEIDENTIFIER;
    DECLARE @myMessageBody_Host XML;
    DECLARE @myStandardCommitCount INT;
    DECLARE @myCurrentTransactionCount INT;

    SET @myStandardCommitCount = 100;
    SET @myCurrentTransactionCount = 0;

    WHILE (1 = 1)
    BEGIN
        BEGIN TRANSACTION;
        WAITFOR
        (
            RECEIVE TOP (1) @myMessageType_Host = message_type_name,
                            @myMessageBody_Host = CAST(message_body AS XML),
                            @myConversationHandle_Host = conversation_handle
            FROM [ssbs].[Queue_GeneralReciever]
        ),
        TIMEOUT 1000; --milisecond
        IF ( @@ROWCOUNT = 0 OR @myMessageBody_Host IS NULL )
        BEGIN
            ROLLBACK TRANSACTION;
            BREAK;
        END;
        ELSE
        BEGIN
            --=====================
            --General Request
            --=====================
            IF @myMessageType_Host = ''
            BEGIN
                DECLARE @myData AS XML;
                DECLARE @myOperation VARCHAR(10);
                DECLARE @myTableName NVARCHAR(50);
                SET @myData = @myMessageBody_Host;

                CREATE TABLE #DataHeaderViaXML
                (
                    OPERATIONDATETIME DATETIME NOT NULL,
                    OPERATION VARCHAR(10) NOT NULL,
                    TABLENAME VARCHAR(50) NOT NULL
                );

                --Extract Request Header Parameters
                INSERT INTO #DataHeaderViaXML (OPERATIONDATETIME, OPERATION, TABLENAME)
                SELECT myData.[Header].value( '@OPERATIONDATETIME[1]', 'DATETIME' ) AS OPERATIONDATETIME,
                       myData.[Header].value( '@OPERATION', 'VARCHAR(10)' ) AS OPERATION,
                       myData.[Header].value( '@TABLENAME', 'VARCHAR(50)' ) AS TABLENAME
                FROM @myData.nodes('/OKD365') AS myData(Header);

                -- Execute SP For Recieve Data !!!!!!
                SELECT TOP (1)
                       @myOperation = UPPER( OPERATION ),
                       @myTableName = UPPER( TABLENAME )
                FROM #DataHeaderViaXML;
                BEGIN TRY
                    IF @myTableName = UPPER( 'myTable' )
                    BEGIN
                        PRINT @myData;
                        PRINT @myOperation;
                    END;
                    END CONVERSATION @myConversationHandle_Host;
                    DROP TABLE #DataHeaderViaXML;
                END TRY
                BEGIN CATCH

                END CATCH;
            END;
            --=====================
            --End Conversation Request
            --=====================
            IF @myMessageType_Host = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
            BEGIN
                END CONVERSATION @myConversationHandle_Host;
            END;

            --=====================
            --Commit Transactions in Batch mode with @myStandardCommitCount base
            --=====================
            SET @myCurrentTransactionCount = @myCurrentTransactionCount + 1;
            IF @myCurrentTransactionCount >= @myStandardCommitCount
            BEGIN
                COMMIT;
                SET @myCurrentTransactionCount = 0;
                BEGIN TRANSACTION;
            END;
        END;
        COMMIT;
    END;
END;