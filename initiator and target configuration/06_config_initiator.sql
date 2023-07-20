USE SSBSInitiator
GO
--===================Start Conversation from initiator side
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

        BEGIN DIALOG CONVERSATION @myConversationHandle
        FROM SERVICE [http://sqldeep.ir/uat/services/operational/general_sender/v0.3]
        TO SERVICE 'http://sqldeep.ir/uat/services/operational/general_reciever/v0.3'
        ON CONTRACT [http://sqldeep.ir/uat/contracts/operational/general_contract/v0.3]
        WITH ENCRYPTION = ON;

        SEND ON CONVERSATION @myConversationHandle
        MESSAGE TYPE [http://sqldeep.ir/uat/messages/request/operational/general_message/v0.3](@myMessage);
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
    END CATCH;
    PRINT @myMessage;
END;
GO