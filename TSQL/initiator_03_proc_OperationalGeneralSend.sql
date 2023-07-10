-- =============================================
-- Author:		<Zahra Saffarpour>
-- Create date: <5/21/2023>
-- Version:		<3.0.0.0>
-- Description:	<>
-- Input Parameters:
-- @Data:
-- =============================================
CREATE OR ALTER PROCEDURE ssbs.proc_OperationalGeneralSend
(
	@Data AS XML
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @myConversationHandle UNIQUEIDENTIFIER;
        DECLARE @myMessage NVARCHAR(MAX);

        SET @myMessage = CAST(@Data AS NVARCHAR(MAX));

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
    END CATCH;
    --PRINT @myMessage;
END;
GO