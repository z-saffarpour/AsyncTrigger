USE SSBSInitiator;
GO
--=Step 12:=====================================================================================================================================
DROP USER IF EXISTS dbSSBSReciever_Operational
CREATE USER dbSSBSReciever_Operational WITHOUT LOGIN;
GO
CREATE CERTIFICATE dbSSBSReciever_Operational
   AUTHORIZATION dbSSBSReciever_Operational
   FROM FILE = N'\\SRV0072.sqldeep.ir\Source\SSBS\dbSSBSReciever_Operational.cer'
GO
--===================Create Route
USE SSBSInitiator;
CREATE ROUTE [http://sqldeep.com/uat/route/operational/general_reciever/v0.3] --Route_OperationalGeneralReciever
WITH
SERVICE_NAME = 'http://sqldeep.com/uat/services/operational/general_reciever/v0.3',
--BROKER_INSTANCE = 'dfe65cca-d719-43d2-a2fa-9185b8265b4a', -- SELECT NEWID()
ADDRESS = 'TCP://SRV0072.sqldeep.ir:4740'; -- مشخصات سرور گیرنده اطلاعات
GO
USE msdb;
CREATE ROUTE [http://sqldeep.com/uat/route/operational/general_sender/v0.3] --Route_OperationalGeneralSender
WITH
SERVICE_NAME = 'http://sqldeep.com/uat/services/operational/general_sender/v0.3',
--BROKER_INSTANCE = 'dfe65cca-d719-43d2-a2fa-9185b8265b4a', -- SELECT NEWID()
ADDRESS = 'LOCAL';
GO
--===================Create Remote Service Binding
USE SSBSInitiator;
CREATE REMOTE SERVICE BINDING [http://sqldeep.com/uat/remoteservicebinding/operational/general_reciever/v0.3] --RemoteServiceBinding_OperationalGeneral
TO SERVICE N'http://sqldeep.com/uat/services/operational/general_reciever/v0.3'
WITH USER = dbSSBSReciever_Operational;
GO
--===================Grant permissions
USE SSBSInitiator;
GRANT SEND
ON SERVICE::[http://sqldeep.com/uat/services/operational/general_sender/v0.3]
TO  PUBLIC;

GRANT SEND
ON SERVICE::[http://sqldeep.com/uat/services/operational/general_sender/v0.3]
TO  dbSSBSReciever_Operational;
GO