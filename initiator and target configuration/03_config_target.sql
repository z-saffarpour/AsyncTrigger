--==Create Message 
USE SSBSTarget
GO
CREATE MESSAGE TYPE [http://sqldeep.com/uat/messages/request/operational/general_message/v0.3]
AUTHORIZATION [dbo]
VALIDATION = WELL_FORMED_XML;

CREATE MESSAGE TYPE [http://sqldeep.com/uat/messages/response/operational/general_message/v0.3]
AUTHORIZATION [dbo]
VALIDATION = WELL_FORMED_XML;
GO
--===================Create Contract 
USE SSBSTarget;
CREATE CONTRACT [http://sqldeep.com/uat/contracts/operational/general_contract/v0.3] AUTHORIZATION [dbo]
(
    [http://sqldeep.com/uat/messages/request/operational/general_message/v0.3] SENT BY INITIATOR,
    [http://sqldeep.com/uat/messages/response/operational/general_message/v0.3] SENT BY TARGET
);
GO
--===================Create queues
USE SSBSTarget
GO
CREATE QUEUE [ssbs].[Queue_GeneralReciever]
WITH STATUS = ON,
     RETENTION = OFF
ON [FG_Queue];
GO
--===================Create Service 
USE SSBSTarget;
CREATE SERVICE [http://sqldeep.com/uat/services/operational/general_reciever/v0.3]
AUTHORIZATION dbSSBSReciever_Operational --[dbo] 
ON QUEUE [ssbs].[Queue_GeneralReciever]
(
    [http://sqldeep.com/uat/contracts/operational/general_contract/v0.3]
);
GO