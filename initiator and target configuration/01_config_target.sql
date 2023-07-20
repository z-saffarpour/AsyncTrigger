--Target
USE master;
GO
--=Step 6:=====================================================================================================================================
CREATE ENDPOINT Host_Endpoint
       STATE = STARTED
       AS TCP ( LISTENER_PORT = 4740,LISTENER_IP=ALL)
       FOR SERVICE_BROKER (AUTHENTICATION = WINDOWS, ENCRYPTION = SUPPORTED ALGORITHM AES );
GO
--=Step 7:=====================================================================================================================================
ALTER DATABASE SSBSTarget SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;
GO
SELECT name, service_broker_guid, is_broker_enabled, is_honor_broker_priority_on,is_trustworthy_on 
FROM sys.databases WHERE name = 'SSBSTarget';
GO
--=Step 8:=====================================================================================================================================
ALTER DATABASE SSBSTarget SET TRUSTWORTHY ON
GO
--=Step 9:=====================================================================================================================================
USE SSBSTarget
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'myPassword';
GO
--=Step 10:=====================================================================================================================================
DROP USER IF EXISTS dbSSBSReciever_Operational
CREATE USER dbSSBSReciever_Operational WITHOUT LOGIN;
GO
--DROP CERTIFICATE dbSSBSReciever_Operational
CREATE CERTIFICATE dbSSBSReciever_Operational 
       AUTHORIZATION dbSSBSReciever_Operational
       WITH SUBJECT = 'Certificate For Target',
       EXPIRY_DATE = N'12/31/2050';
GO
BACKUP CERTIFICATE dbSSBSReciever_Operational
       TO FILE = N'C:\Source\SSBS\dbSSBSReciever_Operational.cer';
GO
--===============================
ALTER DATABASE SSBSTarget ADD FILEGROUP FG_Queue
GO
ALTER DATABASE SSBSTarget ADD FILEGROUP FG_AX
GO
--===============================
USE SSBSTarget
GO
CREATE SCHEMA ssbs AUTHORIZATION dbo
GO
CREATE SCHEMA ax AUTHORIZATION dbo
GO