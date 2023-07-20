--==Create Message
USE SSBSInitiator;
CREATE MESSAGE TYPE [http://sqldeep.com/uat/messages/request/operational/general_message/v0.3]
AUTHORIZATION [dbo]
VALIDATION = WELL_FORMED_XML;

CREATE MESSAGE TYPE [http://sqldeep.com/uat/messages/response/operational/general_message/v0.3]
AUTHORIZATION [dbo]
VALIDATION = WELL_FORMED_XML;
GO
--===================Create Contract 
USE SSBSInitiator;
CREATE CONTRACT [http://sqldeep.com/uat/contracts/operational/general_contract/v0.3] AUTHORIZATION [dbo]
(
    [http://sqldeep.com/uat/messages/request/operational/general_message/v0.3] SENT BY INITIATOR,
    [http://sqldeep.com/uat/messages/response/operational/general_message/v0.3] SENT BY TARGET
);
GO
--===================Create queues
USE SSBSInitiator;
GO
CREATE QUEUE [ssbs].[Queue_OperationalGeneralSender]
WITH STATUS = ON,
     RETENTION = OFF
ON [FG_Queue];
GO
--===================Create Service 
USE SSBSInitiator;
CREATE SERVICE [http://sqldeep.com/uat/services/operational/general_sender/v0.3]
AUTHORIZATION dbSSBSSender_Operational --[dbo] 
ON QUEUE [ssbs].[Queue_OperationalGeneralSender]
(
    [http://sqldeep.com/uat/contracts/operational/general_contract/v0.3]
);
GO
