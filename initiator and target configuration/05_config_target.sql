USE SSBSTarget
GO
--=Step 16:=====================================================================================================================================
--DROP CERTIFICATE dbSSBSSender_Operational
DROP USER IF EXISTS dbSSBSSender_Operational
CREATE USER dbSSBSSender_Operational WITHOUT LOGIN;
GO
CREATE CERTIFICATE dbSSBSSender_Operational
   AUTHORIZATION dbSSBSSender_Operational
   FROM FILE = N'\\SRV0071.sqldeep.ir\Source\SSBS\dbSSBSSender_Operational.cer';
GO

--===================Create Route
USE SSBSTarget;
CREATE ROUTE [http://sqldeep.com/uat/route/operational/general_sender/v0.3] --Route_GeneralSender
WITH
SERVICE_NAME = 'http://sqldeep.com/uat/services/operational/general_sender/v0.3',
--BROKER_INSTANCE = 'dfe65cca-d719-43d2-a2fa-9185b8265b4a',
ADDRESS = 'TCP://SRV0071.sqldeep.ir:4740'; -- مشخصات سرور فرستنده دیتا
GO
USE msdb;
CREATE ROUTE [http://sqldeep.com/uat/route/operational/general_reciever/v0.3] --Route_OperationalGeneralReciever
WITH
SERVICE_NAME = 'http://sqldeep.com/uat/services/operational/general_reciever/v0.3',
--BROKER_INSTANCE = 'dfe65cca-d719-43d2-a2fa-9185b8265b4a', -- SELECT NEWID()
ADDRESS = 'LOCAL';
GO
--===================Create Remote Service Binding
USE SSBSTarget;
CREATE REMOTE SERVICE BINDING [http://sqldeep.ir/uat/remoteservicebinding/operational/general_sender/v0.3] --RemoteServiceBinding_General
TO SERVICE N'http://sqldeep.ir/uat/services/operational/general_sender/v0.3'
WITH USER = dbSSBSSender_Operational;
GO
--===================Grant permissions
USE SSBSTarget;
GRANT SEND
ON SERVICE::[http://sqldeep.ir/uat/services/operational/general_reciever/v0.3]
TO  PUBLIC;

GRANT SEND
ON SERVICE::[http://sqldeep.ir/uat/services/operational/general_reciever/v0.3]
TO dbSSBSSender_Operational;
GO
