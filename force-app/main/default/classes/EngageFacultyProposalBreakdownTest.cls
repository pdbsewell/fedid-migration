@IsTest
public class EngageFacultyProposalBreakdownTest {
    
    /**
     * @Update the Related faculties on Opportunity Faculties are created
    */
	@isTest
    public static void testFacultyProposalBreakdown() {
     
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'tuser000@amamama.com',
             Username = 'tuser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );
        
        insert u;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ascend_Admin_User'];
		insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
        
        System.runAs(u) {
            // given :  when a Linked Opportunity exists
            Contact con = new Contact(LastName = 'testCon');
            insert con;
            
            Id rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Proposal' AND SObjectType = 'Opportunity'][0].Id;
            Id rt2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'Contact_Assignment'][0].Id;
            
            ucinn_ascendv2__Assignment__c assignment = new ucinn_ascendv2__Assignment__c(ucinn_ascendv2__Assigned_Relationship_Manager_User__c = u.Id, 
                                                                                         ucinn_ascendv2__Contact__c = con.Id,
                                                                                         ucinn_ascendv2__Assignment_Type__c = 'Alumni Manager',
                                                                                         ucinn_ascendv2__Assignment_Start_Date__c = Date.Today(),
                                                                                         RecordTypeId = rt2);
            insert assignment;
            
            Opportunity opp = new Opportunity(Name = 'Opp', ucinn_ascendv2__Contact__c = con.Id, StageName = 'Planned', CloseDate = Date.Today(), RecordTypeId = rt);
            Faculty_Proposal_Breakdown__c fpb = new Faculty_Proposal_Breakdown__c();
            
            insert opp;

            // when :  when a Faculty is linked

            Test.startTest();
            
            fpb.Proposal__c = opp.Id;
            fpb.Faculty__c = 'Faculty of Arts';
            
            insert fpb;

            Test.stopTest();
            
            // then : The Related Faculty is updated
            Opportunity oppAfter = [SELECT Related_Faculties__c FROM Opportunity WHERE ID =: opp.Id][0];
            
            System.assert(oppAfter.Related_Faculties__c != null);
            system.assertEquals(oppAfter.Related_Faculties__c, 'Faculty of Arts');
        }
    }
	
}