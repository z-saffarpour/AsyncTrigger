USE SSBSTarget
GO
--=================
ALTER QUEUE [ssbs].[Queue_GeneralReciever]
WITH STATUS = ON,
     RETENTION = OFF,
     ACTIVATION
     (
         PROCEDURE_NAME = [ssbs].[proc_GeneralRecieve],
         EXECUTE AS OWNER,
         MAX_QUEUE_READERS = 1,
         STATUS = ON
     );
GO

SELECT *
FROM [ssbs].[Queue_GeneralReciever];
GO
