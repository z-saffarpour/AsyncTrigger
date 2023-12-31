SELECT 
	myCE.conversation_handle, 
	myCE.is_initiator, 
	myService.name as 'local service',
	myCE.far_service,
	myServiceContract.name 'contract', 
	myCE.state_desc
FROM sys.conversation_endpoints AS myCE
LEFT JOIN sys.services AS myService ON myCE.service_id = myService.service_id
LEFT JOIN sys.service_contracts AS myServiceContract ON myCE.service_contract_id = myServiceContract.service_contract_id;
GO
SELECT transmission_status,* FROM sys.transmission_queue;
SELECT * FROM sys.dm_broker_connections
SELECT * FROM sys.dm_broker_forwarded_messages
/*
DECLARE @myHandle UNIQUEIDENTIFIER
SET @myHandle = '437EA9F6-78F4-ED11-9295-005056B761DC'
END CONVERSATION @myHandle WITH CLEANUP
*/
GO
/*
EXECUTE ssbs.proc_GeneralRecieve
GO
*/
/*
SELECT CAST(message_body AS xml),* FROM [ssbs].[Queue_GeneralReciever]
*/