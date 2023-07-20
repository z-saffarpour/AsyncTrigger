--Initiator
USE master;
GO
--=Step 1:=====================================================================================================================================
CREATE ENDPOINT Host_Endpoint
       STATE = STARTED
       AS TCP ( LISTENER_PORT = 4740,LISTENER_IP= ALL)
       FOR SERVICE_BROKER (AUTHENTICATION = WINDOWS, ENCRYPTION = SUPPORTED ALGORITHM AES );
GO
--=Step 2:=====================================================================================================================================
ALTER DATABASE SSBSInitiator SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;
GO
SELECT name, service_broker_guid, is_broker_enabled, is_honor_broker_priority_on,is_trustworthy_on 
FROM sys.databases WHERE name = 'SSBSInitiator';
GO
--=Step 3:=====================================================================================================================================
ALTER DATABASE SSBSInitiator SET TRUSTWORTHY ON;
GO
--=Step 4:=====================================================================================================================================
USE SSBSInitiator
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'myPassword';
GO
--=Step 5:=====================================================================================================================================
CREATE USER dbSSBSSender_Operational WITHOUT LOGIN;
GO
CREATE CERTIFICATE dbSSBSSender_Operational
       AUTHORIZATION dbSSBSSender_Operational
       WITH SUBJECT = N'Certificate For Initiator',
       EXPIRY_DATE = N'12/31/2050';
GO
BACKUP CERTIFICATE dbSSBSSender_Operational
       TO FILE = N'C:\Source\SSBS\dbSSBSSender_Operational.cer';
GO
--===============================
ALTER DATABASE SSBSInitiator ADD FILEGROUP FG_Queue
GO
--===============================
USE SSBSInitiator
GO
CREATE SCHEMA ssbs AUTHORIZATION dbo