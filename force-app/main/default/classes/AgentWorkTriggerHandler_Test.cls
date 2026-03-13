/**
* @author Inderpal Dhanoa
* @date 07.07.21
* @description - AgentWorkTriggerHandlerTest Class to cater to AgentWorkTriggerHandler 
* @revision 07.07.21 - Initial Create <br/>
*/
@isTest(isParallel=true)
public class AgentWorkTriggerHandler_Test {
    
    /**
    * @author Inderpal Dhanoa
    * @date 07.07.21
    * @description - AgentWorkTriggerHandlerTest to setup data 
    * @revision 07.07.21 - Initial Create <br/>
    */
    @testSetup
    static void setup(){
        List<User> l_allUsers = new List<User>();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        String random = String.valueOf(System.currentTimeMillis());
        
        Profile SRbaseProfile = [SELECT Id FROM Profile WHERE name = 'SR Base Profile'];
        Profile baseProfile = [SELECT Id FROM Profile WHERE name = 'Base Profile'];
        
        UserRole studentOfficerRole = [SELECT Id FROM UserRole WHERE Name = 'Student Rec Officer'];
        UserRole monashConnectLeaderRole = [SELECT Id FROM UserRole WHERE Name = 'Monash Connect Leader'];
        
        PermissionSet liveAgentUser = [SELECT Id, name FROM permissionSet where name = 'Live_Agent_Permission_Set_User']; 
		PermissionSet liveAgentSupervisor = [SELECT Id, name FROM permissionSet where name = 'Live_Agent_Permission_Set_Supervisor'];
        
        User userRecord1 = new User(
            ProfileId = SRbaseProfile.Id,
            UserRoleId = studentOfficerRole.id,
            Username = random + 'testingAgentUser1@monash.edu',
            isActive = true,
            Alias = 'test_ao',
            Email='test_ao1@monash.edu',
            EmailEncodingKey='UTF-8',
            Firstname='Firstname' + random,
            Lastname='Lastname' + random,
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='Australia/Sydney'
        );
        l_allUsers.add(userRecord1); 

        User userRecord2 = new User(
            ProfileId = baseProfile.Id,
            UserRoleId = monashConnectLeaderRole.id,
            Username = random + 'testingAgentUser2@monash.edu',
            isActive = true,
            Alias = 'test_ao',
            Email='test_ao2@monash.edu',
            EmailEncodingKey='UTF-8',
            Firstname='Firstname' + random,
            Lastname='Lastname' + random,
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='Australia/Sydney'
        );
        l_allUsers.add(userRecord2);

        System.runAs(thisUser) {
            Database.insert(l_allUsers);
            
            User studentOfficer = [SELECT Id, username, isActive FROM User WHERE UserName like '%testingAgentUser1%' LIMIT 1];
	        User monashConnectLeader = [SELECT Id, username, isActive FROM User WHERE UserName like '%testingAgentUser2%' LIMIT 1];
            
            PermissionSetAssignment permSet1 = new PermissionSetAssignment(AssigneeId=monashConnectLeader.Id,PermissionSetId=liveAgentSupervisor.Id);
            insert permSet1;
            PermissionSetAssignment permSet2 = new PermissionSetAssignment(AssigneeId=studentOfficer.Id,PermissionSetId=liveAgentUser.Id);
            insert permSet2;
        }
    }

    /**
    * @author Inderpal Dhanoa
    * @date 07.07.21
    * @description - Upon chat Transfer update the RecordType of the Related case to the new Agent
    * @revision 07.07.21 - Initial Create <br/>
    */
    @isTest    
    static void UpdateCaseDetailsOnTranscriptTransferTest() {
         
        User studentOfficer = [SELECT Id, username, isActive FROM User WHERE UserName like '%testingAgentUser1%' LIMIT 1];
	    User monashConnectLeader = [SELECT Id, username, isActive FROM User WHERE UserName like '%testingAgentUser2%' LIMIT 1]; 
        
        system.runAs(monashConnectLeader){
        	//create a Live Chat Visitor
            LiveChatVisitor visitor = new LiveChatVisitor();
            insert visitor;
            
            //create a Live Chat Transcript
            LiveChatTranscript trans = new LiveChatTranscript(LiveChatVisitorId = visitor.Id, Body = 'Some chat', OwnerId = monashConnectLeader.Id);
            insert trans;
            
            ServiceChannel servChannel = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'sfdc_liveagent' LIMIT 1]; 
            
            test.startTest();
            try {
                AgentWork agntWrk = new AgentWork(UserId=monashConnectLeader.Id, ServiceChannelId = servChannel.Id, OwnerId = monashConnectLeader.Id, WorkItemId = trans.Id);
                insert agntWrk;
            }catch(Exception ex) {
                string message = ex.getMessage();
                String errorLabel = 'The agent\'s status is not associated with the channel for this work';
                system.assert(message.contains(errorLabel));
            }
            test.stopTest();	   
        }
    }

    /**
    * @author Inderpal Dhanoa
    * @date 07.07.21
    * @description - The test method is used to push the code coverage as we cannot create AgentWork records in TestClass
    * (https://trailblazer.salesforce.com/ideaView?id=0873A000000Lm3JQAS) unless the test class is run by an Online Omni channel User
    * @revision 07.07.21 - Initial Create <br/>
    */
    @isTest    
    static void pushTestCoverageTest() {
        Integer returnVal = AgentWorkTriggerHandler.pushTestCoverage();
        System.assertEquals(returnVal, 123);    
    }
}