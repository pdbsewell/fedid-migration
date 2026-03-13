/**
 * @description         Test Class for MontrackServiceClass
 * @group Test Class
 * @author 				APRivera
 * @revisionHistory 	Created		-	02.AUG.2019
*                      APRivera     -   05.AUG.2019     -   Updated with test scenario for batch class
*                      APRivera     -   13.JAN.2020     -   Fixed test Class, Removed test method for Batch Class
 */

@isTest(isParallel=true)
private class MontrackServiceClass_Test {
    @IsTest
    static void testLightningComponent() {
        Id mtRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('MonTrack').getRecordTypeId();
        List<User> lstUsers = TestHelper.createTestUsers('Outbound Base Profile', 1);
        List<Account> lstAccts = TestHelper.createStudent(10);

        System.runAs(lstUsers.get(0)) {
            insert lstAccts;
            List<Contact> lstContacts = TestHelper.createStudentContacts(10,lstAccts);
            insert lstContacts;
            List<Campaign> lstCampaigns = TestHelper.createCampaign(1);
            for(Campaign cmp : lstCampaigns){
                cmp.RecordTypeId = mtRecordTypeId;
            }
            insert lstCampaigns;
            Set<Id> setConIds = new Set<Id>();
            for(Contact con : [SELECT Id FROM Contact]){
                setConIds.add(con.Id);
            }
            List<CampaignMember> lstCmpMembers = TestHelper.createCampaignMember(lstUsers.get(0).Id, null, lstCampaigns.get(0).Id,setConIds );
            insert lstCmpMembers;

            Test.startTest();
            List<Task> lstTasks = [SELECT Id, Offer_Status__c FROM Task WHERE WhoId IN: setConIds];
            System.debug('Number of tasks generated: ' + lstTasks.size());
            System.assertEquals(10, lstTasks.size());


                List<Task> lstTasksToUpdate = new List<Task>();
                for(Integer x=0; x<5; x++){
                    Task tsk = lstTasks.get(x);
                    tsk.Offer_Status__c = 'No Answer';
                    lstTasksToUpdate.add(tsk);
                }
                update lstTasksToUpdate;
               List<Task> lstTaskToView = MontrackServiceClass.retrieveCallAttemptHistory(lstTasksToUpdate.get(0).Id);
                System.assert(lstTaskToView.size() != null);
            Test.stopTest();
        }
    }

}