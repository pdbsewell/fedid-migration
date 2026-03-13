@isTest(isParallel=false) // Test.getStandardPricebookId called on Opportunity trigger
public class FacultyProposalBreakdownService_Test {

    @isTest
    public static void testUpdateFaculties(){
        FacultyProposalBreakdownService fpbs = new FacultyProposalBreakdownService();

        Account acc1 = new Account(Name='Account 1');
        insert acc1;

        ucinn_ascendv2__Assignment__c assign1 = new ucinn_ascendv2__Assignment__c(ucinn_ascendv2__Account__c=acc1.Id, 
                                                                                  ucinn_ascendv2__Assignment_Type__c='Alumni Manager',
                                                                                  ucinn_ascendv2__Assignment_Start_Date__c=system.today(),
                                                                                  ucinn_ascendv2__Assigned_Relationship_Manager_User__c = UserInfo.getUserId());
        insert assign1;

        List<RecordType> recordTypeList = [SELECT Id, Name FROM RecordType WHERE Name='Proposal' LIMIT 1];

        Opportunity opp1 = new Opportunity(Name='opp1', AccountId=acc1.Id, StageName='Active', CloseDate=Date.today(), RecordTypeId=recordTypeList[0].Id);
        insert opp1;

        Faculty_Proposal_Breakdown__c fcb1 = new Faculty_Proposal_Breakdown__c(Proposal__c=opp1.Id, Faculty__c='Faculty of Engineering');
        insert fcb1;
    }
}