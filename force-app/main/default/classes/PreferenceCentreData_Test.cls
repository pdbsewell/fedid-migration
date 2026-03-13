@isTest(isParallel=true)
public class PreferenceCentreData_Test {
    @isTest
    static public void TestPreferenceCentreData() {
        Contact con1 = new Contact(LastName='Smith', FirstName='John');
        insert con1;

        Campaign camp1=new Campaign(Name='Test Campaign');
        insert camp1;

        CampaignMember cm1 = new CampaignMember(CampaignId=camp1.Id, ContactId=con1.Id);
        insert cm1;

        Test.startTest();

        PreferenceCentreData pcd = new PreferenceCentreData(con1.Id,'Global');
        cm1.Engagement_Scoring_Applied__c = true;
        con1.LastName = 'test name update';
        PreferenceCentreData.saveMemberships(new List<CampaignMember>{cm1});
        PreferenceCentreData.saveContact(con1);

        Test.stopTest();

        cm1 = [SELECT ID, Engagement_Scoring_Applied__c FROM CampaignMember WHERE ID =: cm1.ID];
        con1 = [SELECT ID, LastName FROM Contact WHERE ID =: con1.ID];

        System.assertEquals(cm1.Engagement_Scoring_Applied__c, true);
        System.assertEquals(con1.LastName, 'test name update');
    }
}