# Writing SSBS Applications Across Instances – Getting Environments Ready

SQL Server Service Broker (SSBS) allows you to write asynchronous, decoupled, distributed, persistent, reliable, scalable and secure queuing/message based applications within the database itself. Arshad Ali shows you how to write an SSBS application when the Initiator and Target are in two different databases on two different SQL Server instances.
Introduction
SQL Server Service Broker (SSBS) is a new architecture (introduced with SQL Server
2005 and enhanced further in SQL Server 2008 and SQL Server 2008 R2) which
allows you to write asynchronous, decoupled, distributed, persistent, reliable,
scalable and secure queuing/message based applications within the database
itself.
In my previous couple of articles, I introduced you SQL Server Service Broker, what it is, how it works, its different  components and how are they related to each other. Then I talked about writing SSBS application when both Initiator (Sender) and Target (Receiver) are in same database and SSBS application when both Initiator (Sender) and Target (Receiver) are in different databases on the same SQL Server instance. Now let’s move on and see how to write an SSBS application when the Initiator and Target are in two different databases on two different SQL Server instances (machines).
Problem Statement
In this example, once again I will take the same problem statement as my last articles but this time the Initiator and Target will be in different databases on two different SQL Server instances (machines).
There are two applications, one is the Order application (uses SSBSInitiatorDB database) and another one is the Inventory application (uses SSBSTargetDB database). Before accepting any order from the users, the Order application needs to make sure that the product, which is being ordered is available in the store but for that, the Order application does not want to wait. The Order application will request to check the product stock availability status asynchronously and will continue doing its other work. On the other side, the
Inventory application will listen to the request coming into the queue, process it and respond back to the Order application, again asynchronously.
When Initiator and Target are in different databases on the different SQL Server instances
As I said before, depending on the arrangement of Initiator and Target, the architecture can be categorized into three categories:
The behavior in scenario A and B above is almost same.
In these cases, SSBS optimizes performance by writing messages directly to the Target Queue. Although if while writing a message to the Target Queue, it encounters any problem (for example the Target service is not available, Target Queue is disabled, etc.) it keeps that message in the sys.transmission_queue table temporarily so that it can push the message to Target Queue once it is
available. Also, in these cases, no network is involved and hence no network encryption is required for these scenarios. However, this is not the case in third scenario; you need to do encryption when communicating across instances or network, more detail follows in this article later.
In this example, I will demonstrate how you will be creating an SSBS application when Initiator and Target are in different databases on two different SQL Server instances (machines).
Although we can enable Service Broker for an existing database and create SSBS objects in it, for simplicity I will be creating new databases, on the two different SQL Server instances for this demonstration.
What I am doing in the script below is creating a database, which will act like an Initiator. Then I am enabling Service Broker on it. Before that, I need to create an endpoint so that SSBS can communicate outside of the SQL Server instance. An endpoint, a SQL Server object, is required so that SSBS can establish/communicate with network addresses when sending/receiving messages across SQL Server instances. By default, there is no endpoint available in SQL Server, hence you need to create one explicitly to communicate outside of theSQL Server instance. This endpoint supports TCP communication protocol and listens on a specific port number (default is 4022). For more information about endpoint, click here.
These endpoints must be in STARTED state so that SSBS can send and receive messages over the network. If for some reason, you want to temporarily pause the communication you can set the state to STOPPED, with ALTER ENDPOINT command, in which case SSBS would not be able to receive messages from outside the current instance or send message to outside the current instance.
Next, I creating a master key and a user, which will be used by the certificate for encryption and making remote connections. Then I create certificate, which will be used for encrypting messages. The certificate needs to backed up and restored (or created from an existing partner’s certificate) at the other communicating partner so that the messages can be decrypted by the receiver of the message. The location, which you specify for backing up/restoring the certificate must be accessible by the account under which the database engine is running.
Finally I create two message types and a contract and then I create an Initiator queue, which will hold the responses (messages) sent back by the Target to the Initiator and Initiator service which will be tied to this queue and will act like an initiator endpoint.
Across instances - Setting up Initiator – Part 1
USE master;
GO
--An endpoint is required so that SSBS can establise/communicate 
--with network addresses when sending messages across SQL Server instances
--These endpoints must be in STARTED mode so that SSBS can send and 
--receive message over the network.
IF EXISTS (SELECT * FROM sys.endpoints WHERE name = N'SSBSInitiatorEP')
     DROP ENDPOINT SSBSInitiatorEP;
GO
--You can notice I have specified Windows authentication and hence
--SSBS will uses Windows authentication connections to send messages 
CREATE ENDPOINT SSBSInitiatorEP
       STATE = STARTED
       AS TCP ( LISTENER_PORT = 4022 )
       FOR SERVICE_BROKER (AUTHENTICATION = WINDOWS );
GO
--Create Initiator database for this learning session, it will help you to do 
--clean up easily, you can create SSBS objects in any existing database
--also but you need to drop all objects individually if you want to do
--clean up of these objects than dropping a single database
IF EXISTS(SELECT TOP 1 1 FROM sys.databases WHERE name = 'SSBSInitiatorDB')
       DROP DATABASE SSBSInitiatorDB
GO
CREATE DATABASE SSBSInitiatorDB
GO
--By default a database will have service broker enabled, which you can verify 
--with is_broker_enabled column of the below resultset
SELECT name, service_broker_guid, is_broker_enabled, is_honor_broker_priority_on 
FROM sys.databases WHERE name = 'SSBSInitiatorDB'
GO
--If your database is not enabled for Service Broker becuase you have 
--changed the default setting in Model database, even then you can enable
--service broker for a database with this statement
ALTER DATABASE SSBSInitiatorDB
      SET ENABLE_BROKER;
      --WITH ROLLBACK IMMEDIATE
GO
----To disable service broker for a database
--ALTER DATABASE SSBSInitiatorDB
--      SET DISABLE_BROKER;
--GO
--You need to mark database TRUSTWORTHY so that it can 
--access resource beyond the scope of this database
ALTER DATABASE SSBSInitiatorDB SET TRUSTWORTHY ON
GO
USE SSBSInitiatorDB;
GO
--Creating master key and an user which will be used by certificate 
--for encryption and making remote connections
--Change the strong password for your master key as appropriate
--You can query sys.symmetric_keys to get information 
--abou the database database master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'abcd!@#$5678';
GO
CREATE USER SSBSInitiatorUser WITHOUT LOGIN;
GO
--Creating certificate which will be used for encrypting messages. 
CREATE CERTIFICATE SSBSInitiatorCert
       AUTHORIZATION SSBSInitiatorUser
       WITH SUBJECT = N'Certificate For Initiator',
       EXPIRY_DATE = N'12/31/2012';
GO
--The certificate needs to backed up and restored at the other communicating 
--partner so that the messages can be decrypted by the receiver of the message. 
--The location which you specify for backing up/restoring certificate must be 
--accessible by the account under which database engine is running.
BACKUP CERTIFICATE SSBSInitiatorCert
       TO FILE = N'\MKTARALIW2K8R2SharedSQLCertificatesSSBSInitiatorCert.cer';
GO
--Create message types which will allow valid xml messages to be sent
--and received, SSBS validates whether a message is well formed XML 
--or not by loading it into XML parser
--Please use XML validation only when required as it has performance overhead 
CREATE MESSAGE TYPE
       [//SSBSLearning/ProductStockStatusCheckRequest]
       VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE
       [//SSBSLearning/ProductStockStatusCheckResponse]
       VALIDATION = WELL_FORMED_XML;
GO
--Create a contract which will be used by Service to validate
--what message types are allowed for Initiator and for Target.
--As because communication starts from Initiator hence 
--SENT BY INITIATOR or SENT BY ANY is mandatory
CREATE CONTRACT [//SSBSLearning/ProductStockStatusCheckContract]
      ([//SSBSLearning/ProductStockStatusCheckRequest]
       SENT BY INITIATOR,
       [//SSBSLearning/ProductStockStatusCheckResponse]
       SENT BY TARGET
      );
GO
--A Target can also send messages back to Initiator and hence
--you can create a queue for Initiator also
CREATE QUEUE dbo.SSBSLearningInitiatorQueue WITH STATUS = ON;
GO
--Likewsie you would need to create a service which will sit 
--on top of Initiator queue and used by Target to send messages
--back to Initiator
CREATE SERVICE [//SSBSLearning/ProductStockStatusCheck/InitiatorService]
       AUTHORIZATION SSBSInitiatorUser
       ON QUEUE dbo.SSBSLearningInitiatorQueue
       ([//SSBSLearning/ProductStockStatusCheckContract])
GO
Before creating a database, which will act like a Target and enabling Service Broker on it, create an endpoint on the target (as we did with Initiator side) so that the target SSBS can communicate outside of the SQL Server instance. This endpoint must be in STARTED state so that SSBS can send and receive messages over the network.
Next, create a master key and a user, which will be used by the certificate for encryption and making remote connections. Then create a target certificate, which will be used for encrypting messages while sending response messages back to Initiator. The target certificate needs to backed up and restored (or created from the existing partner’s certificate) at the other communicating partner (Initiator), so that the messages can be decrypted by the receiver (Initiator) of the message. The location, which you specify for backing up/restoring the certificate must be accessible by the account under which the database engine is running.
Finally, create the Target queue, which will hold the request (messages) sent by the Initiator to the Target and the Target service, which will be tied to this queue and will act like a target endpoint.
Please note, because this message type and contract will be shared by both the Initiator and Target, they will have the same definitions at both places.
Across instances - Setting up Target – Part 1
USE master;
GO
--An endpoint is required so that SSBS can establise/communicate 
--with network addresses when sending messages across SQL Server instances
--These endpoints must be in STARTED mode so that SSBS can send and 
--receive message over the network.
IF EXISTS (SELECT * FROM master.sys.endpoints WHERE name = N'SSBSTargetEP')
     DROP ENDPOINT SSBSTargetEP;
GO
--You can notice I have specified Windows authentication and hence
--SSBS will uses Windows authentication connections to send messages 
CREATE ENDPOINT SSBSTargetEP
       STATE = STARTED
       AS TCP ( LISTENER_PORT = 4022 )
       FOR SERVICE_BROKER (AUTHENTICATION = WINDOWS );
GO
--Create target database for this learning session, it will help you to do 
--clean up easily, you can create SSBS objects in any existing database
--also but you need to drop all objects individually if you want to do
--clean up of these objects than dropping a single database
IF EXISTS(SELECT TOP 1 1 FROM sys.databases WHERE name = 'SSBSTargetDB')
       DROP DATABASE SSBSTargetDB
GO
CREATE DATABASE SSBSTargetDB
GO
--By default a database will have service broker enabled, which you can verify 
--with is_broker_enabled column of the below resultset
SELECT name, service_broker_guid, is_broker_enabled, is_honor_broker_priority_on 
FROM sys.databases WHERE name = 'SSBSTargetDB'
GO
--If your database is not enabled for Service Broker becuase you have 
--changed the default setting in Model database, even then you can enable
--service broker for a database with this statement
ALTER DATABASE SSBSTargetDB
      SET ENABLE_BROKER;
      --WITH ROLLBACK IMMEDIATE
GO
----To disable service broker for a database
--ALTER DATABASE SSBSTargetDB
--      SET DISABLE_BROKER;
--GO
--You need to mark database TRUSTWORTHY so that it can 
--resource beyond the scope of this database
ALTER DATABASE SSBSTargetDB SET TRUSTWORTHY ON
GO
USE SSBSTargetDB;
GO
--Creating master key and an user which will be used by certificate 
--for encryption and making remote connections
--Change the strong password for your master key as appropriate
--You can query sys.symmetric_keys to get information 
--abou the database database master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'abcd!@#$5678';
GO
CREATE USER SSBSTargetUser WITHOUT LOGIN;
GO
--Creating certificate which will be used for encrypting messages. 
CREATE CERTIFICATE SSBSTargetCert 
       AUTHORIZATION SSBSTargetUser
       WITH SUBJECT = 'Certificate For Target',
       EXPIRY_DATE = N'12/31/2012';
GO
--The certificate needs to backed up and restored at the other communicating 
--partner so that the messages can be decrypted by the receiver of the message. 
--The location which you specify for backing up/restoring certificate must be 
--accessible by the account under which database engine is running.
BACKUP CERTIFICATE SSBSTargetCert
       TO FILE = N'\MKTARALIW2K8R2SharedSQLCertificatesSSBSTargetCert.cer';
GO
--Create message types which will allow valid xml messages to be sent
--and received, SSBS validates whether a message is well formed XML 
--or not by loading it into XML parser 
CREATE MESSAGE TYPE
       [//SSBSLearning/ProductStockStatusCheckRequest]
       VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE
       [//SSBSLearning/ProductStockStatusCheckResponse]
       VALIDATION = WELL_FORMED_XML;
GO
--Create a contract which will be used by Service to validate
--what message types are allowed for Initiator and for Target.
--As because communication starts from Initiator hence 
--SENT BY INITIATOR or SENT BY ANY is mandatory
CREATE CONTRACT [//SSBSLearning/ProductStockStatusCheckContract]
      ([//SSBSLearning/ProductStockStatusCheckRequest]
       SENT BY INITIATOR,
       [//SSBSLearning/ProductStockStatusCheckResponse]
       SENT BY TARGET
      );
GO
--Create a queue which is an internal physical table to hold 
--the messages passed to the service, by default it will be 
--created in default file group, if you want to create it in 
--another file group you need to specify the ON clause with 
--this statement. You can use SELECT statement to query this 
--queue or special table but you can not use other DML statement
--like INSERT, UPDATE and DELETE. You need to use SEND and RECEIVE
--commands to send messages to queue and receive from it
CREATE QUEUE dbo.SSBSLearningTargetQueue WITH STATUS = ON;
GO
--Create a service, which is a logical endpoint which sits on top 
--of a queue on which either message is sent or received. With 
--Service creation you all specify the contract which will be
--used to validate message sent on that service
CREATE SERVICE [//SSBSLearning/ProductStockStatusCheck/TargetService]
       AUTHORIZATION SSBSTargetUser
       ON QUEUE dbo.SSBSLearningTargetQueue
       ([//SSBSLearning/ProductStockStatusCheckContract]);
GO
Next, on the Initiator, create a user and import the target certificate so that encrypted messages (response) from target can be decrypted by the Initiator.
Next, create routes. A route is a mapping or a means to locate the target service while sending messages and to locate the initiating service while sending the response back. You can create a route using the CREATE ROUTE command and bind it with the remote service.
When the initiator and target services are in the same instance of SQL Server, no remote service binding is necessary but as in this case, we have the initiator and target services in two different instances and hence we need Remote Service Binding. Remote service binding defines the security credentials to use to communicate with a target/remote service.

Across instances - Setting up Initiator – Part 2
USE SSBSInitiatorDB;
GO
CREATE USER SSBSTargetUser WITHOUT LOGIN;
GO
--Resotring target certifacts so that message received
--from target can be decrypted
CREATE CERTIFICATE SSBSTargetCert 
   AUTHORIZATION SSBSTargetUser
   FROM FILE = N'\MKTARALIW2K8R2SharedSQLCertificatesSSBSTargetCert.cer'
GO
--A route is a mapping or a means to locate the target service while sending messages
--Creating a route to locate the target instance service
IF EXISTS (SELECT * FROM sys.routes WHERE name = N'SSBSTargetRoute')
     DROP ROUTE SSBSTargetRoute;
GO
CREATE ROUTE SSBSTargetRoute
       WITH SERVICE_NAME = N'//SSBSLearning/ProductStockStatusCheck/TargetService',
       ADDRESS = N'TCP://MKTARALIW2K8R2:4022';
GO
USE msdb
GO
IF EXISTS (SELECT * FROM sys.routes WHERE name = N'SSBSInitiatorRoute')
     DROP ROUTE SSBSInitiatorRoute;
GO
--Creating a route to locate the local instance service
CREATE ROUTE SSBSInitiatorRoute
       WITH SERVICE_NAME = N'//SSBSLearning/ProductStockStatusCheck/InitiatorService',
       ADDRESS = N'LOCAL';        
GO
USE SSBSInitiatorDB
GO
--Creating remote service binding that associates the SSBSTargetUser 
--with the target service route
CREATE REMOTE 
       SERVICE BINDING SSBSRemoteServiceBindingForTarget
       TO SERVICE N'//SSBSLearning/ProductStockStatusCheck/TargetService'
       WITH USER = SSBSTargetUser;
GO
Now, on the Target, create a user and import the Initiator certificate so that encrypted messages (request) from Initiator can be decrypted by the Target.
Next, create routes. A route is a mapping or a means to locate the Initiator service while sending response messages back. You can create a route using the CREATE ROUTE command and bind it with the remote Initiator service.
When the initiator and target services are in the same instance of SQL Server, no remote service binding is necessary but as in this case, we have initiator and target services in two different instances and hence we need Remote Service Binding. Remote service binding defines the security credentials to use to communicate with a target/remote service. I am also granting SEND permission to
SSBSInitiatorUser user to send the message to Target service.

Across instances - Setting up Target – Part 2
USE SSBSTargetDB
GO
CREATE USER SSBSInitiatorUser WITHOUT LOGIN;
GO
--Resotring initiator certifacts so that message received
--from initiator can be decrypted
CREATE CERTIFICATE SSBSInitiatorCert
   AUTHORIZATION SSBSInitiatorUser
   FROM FILE = N'\MKTARALIW2K8R2SharedSQLCertificatesSSBSInitiatorCert.cer';
GO
--A route is a mapping or a means to locate the target service while sending messages
--Creating a route to locate the target instance service
IF EXISTS (SELECT * FROM sys.routes WHERE name = N'SSBSInitiatorRoute')
     DROP ROUTE SSBSInitiatorRoute;
GO
CREATE ROUTE SSBSInitiatorRoute
       WITH SERVICE_NAME = N'//SSBSLearning/ProductStockStatusCheck/InitiatorService',
       ADDRESS = N'TCP://ARSHAD-LAPPY:4022';
GO
USE msdb
GO
--Creating a route to locate the local instance service
IF EXISTS (SELECT * FROM sys.routes WHERE name = N'SSBSTargetRoute')
     DROP ROUTE SSBSTargetRoute;
GO
CREATE ROUTE SSBSTargetRoute
       WITH SERVICE_NAME = N'//SSBSLearning/ProductStockStatusCheck/TargetService',
       ADDRESS = N'LOCAL';        
GO
USE SSBSTargetDB
GO
--Grant SEND permission to the user created above to send message 
--to target service
GRANT SEND 
       ON SERVICE::[//SSBSLearning/ProductStockStatusCheck/TargetService]
       TO SSBSInitiatorUser;
GO
--Creating remote service binding that associates the SSBSTargetUser 
--with the target service route
CREATE REMOTE 
       SERVICE BINDING SSBSRemoteServiceBindingForInitiator
       TO SERVICE N'//SSBSLearning/ProductStockStatusCheck/InitiatorService'
       WITH USER = SSBSInitiatorUser;
GO
Conclusion
In this first article of this series of writing SQL Server Service Broker (SSBS) Applications across Instances I step by step emonstrated how you can set up Initiator, Target and create routes between them. In the next article I will demonstrate how to verify the configuration when both Initiator and Target are in different SQL Server instances, how to communicate between them and how to monitor the conversation status between them.
Resources
MSDN SQL Server Service Broker
MSDNCreating Service Broker Objects
MSDNCreating Service Broker Message Types
MSDNCREATE QUEUE (Transact-SQL)
MSDNContracts

https://www.databasejournal.com/ms-sql/writing-ssbs-applications-across-instances-getting-environments-ready/
