SELECT 
	myCE.conversation_handle, 
	myCE.is_initiator, 
	myService.name AS 'local service',
	myCE.far_service,
	myServiceContract.name 'contract', 
	myCE.state_desc
FROM sys.conversation_endpoints AS myCE
LEFT JOIN sys.services AS myService ON myCE.service_id = myService.service_id
LEFT JOIN sys.service_contracts AS myServiceContract ON myCE.service_contract_id = myServiceContract.service_contract_id;
/*
DECLARE @myHandle UNIQUEIDENTIFIER;
DECLARE myCursor CURSOR FOR
	SELECT myCE.conversation_handle
	FROM sys.conversation_endpoints AS myCE
	LEFT JOIN sys.services AS myService ON myCE.service_id = myService.service_id
	LEFT JOIN sys.service_contracts AS myServiceContract ON myCE.service_contract_id = myServiceContract.service_contract_id
	WHERE state = 'DI'
OPEN myCursor;
FETCH NEXT FROM myCursor
INTO @myHandle;
WHILE @@FETCH_STATUS = 0
BEGIN
    END CONVERSATION @myHandle --WITH CLEANUP;
    FETCH NEXT FROM myCursor INTO @myHandle;
END;
CLOSE myCursor;
DEALLOCATE myCursor;
*/
