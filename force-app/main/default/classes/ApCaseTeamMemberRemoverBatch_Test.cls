/**
 * @author       Tom Gangemi
 * @description  Scheduled batch job to remove old CaseTeamMembers from Academic Progress cases
 * @group        Test
 * @revision     2022-11-10 - Tom Gangemi - SA-1800 - Initial version
 *               2023-08-02 - Tom Gangemi - SA-2317 - Re-add commented out test lines
 */
@isTest
public class ApCaseTeamMemberRemoverBatch_Test {
    @isTest static void testRemovalOfCaseTeamMembers() {
        TriggerCommon.disableTrigger('Case');

        final Integer numCasesPerContact = 5;
        final Integer numUsers = 2;

        Contact cont1 = new Contact(FirstName='FN1', LastName='LN1', Email='fn1.ln1@example.com');
        Contact cont2 = new Contact(FirstName='FN2', LastName='LN2', Email='fn2.ln2@example.com');
        Contact[] contacts = new Contact[]{cont1, cont2};
        insert contacts;

        Id apRt = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Academic_Progress_Assessment').getRecordTypeId();

        // create cases that are older than cutoff
        Datetime lastModDate = ApCaseTeamMemberRemoverBatch.CUTOFF_DATETIME.addDays(-1);
        Case[] cases = new Case[0];
        for(Contact c :contacts) {
            for(Integer i = 0; i < numCasesPerContact; i++) {
                cases.add(new Case(
                    RecordTypeId = apRt, ContactId = c.Id, Service_End_Time__c = lastModDate
                ));
            }
        }

        // create a case that is more recent than cutoff
        Case recentCase = cases[0].clone();
        recentCase.ContactId = cont1.Id;
        recentCase.Service_End_Time__c = ApCaseTeamMemberRemoverBatch.CUTOFF_DATETIME.addDays(1);
        cases.add(recentCase);
        insert cases;

        // get two standard, active users to use as members
        User[] users = [
            SELECT Id
            FROM User WHERE IsActive = TRUE AND ProfileId IN (SELECT Id FROM Profile WHERE UserType = 'Standard' )
            LIMIT :numUsers
        ];

        // assign users as members of all the cases
        Id ctrId = [SELECT Id FROM CaseTeamRole WHERE Name = 'Support' LIMIT 1].Id;
        CaseTeamMember[] ctms = new CaseTeamMember[0];
        for(Case c :cases) {
            for(User u :users) {
                ctms.add(new CaseTeamMember(
                    ParentId = c.Id, MemberId = u.Id, TeamRoleId = ctrId
                ));
            }
        }
        insert ctms;

        Test.startTest();
        System.schedule('ApCaseTeamMemberRemoverBatch_Test', '0 0 7 * * ?', new ApCaseTeamMemberRemoverBatch());
        Database.executeBatch(new ApCaseTeamMemberRemoverBatch());
        Test.stopTest();

        CaseTeamMember[] result1 = [SELECT Id FROM CaseTeamMember WHERE Parent.ContactId = :cont1.Id];
        CaseTeamMember[] result2 = [SELECT Id FROM CaseTeamMember WHERE Parent.ContactId = :cont2.Id];

        Assert.areEqual((numCasesPerContact+1)*numUsers, result1.size(), 'Contact 1 should have retained CTMs');
        Assert.areEqual(0, result2.size(), 'Contact 2 should have all CTMs removed');
    }
}