/*******************************************************************************
* @author       Ryan Wilson
* @date         21.Mar.2017         
* @description  test class for BMSMassSMSSendBatch_Test
* @revision     
*******************************************************************************/
@isTest(isParallel=true)
private class BMSMassSMSSendBatch_Test {
    
    @isTest static void SendSMSTest() {
        // Implement test code
        Campaign crmSMS = BMS_TestDataHelper.buildSampleCRMMassEmail('Sample Template');
        crmSMS.Type = 'SMS';
        insert crmSMS;

        String strCsvContent = 'MobilePhone'+'\r\n'+'61234567890'+'\r\n'+'61324567890'+'\r\n'+'61474567890'+'\r\n';
        Blob csvBlob = Blob.valueOf(strCsvContent);

        Attachment attachmentRec = new Attachment();
        attachmentRec.Body = csvBlob;
        attachmentRec.Name = 'fileName';
        attachmentRec.ParentId = crmSMS.Id;
        insert attachmentRec;

        MarketingCloudApp__c mcApp = new MarketingCloudApp__c();
        mcApp.Name = 'Credentials';
        mcApp.Client_ID__c = 'ssjhdsakhd882793879';
        mcApp.Client_Secret__c = 'sdhsaldhlhd7263535336';
        insert mcApp;

        Test.startTest();
        //Test SMS Token mock response
        SingleRequestMock fakeSMSSendResponse = new SingleRequestMock(202,
                                                 'Complete',
                                                 '{"tokenId": "ZUROcEpwLWJCMFNCRXRYZnFkb3lYZzo3Njox"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeSMSSendResponse);
        BMSSendSMSQueueable campaignMemberJob = new BMSSendSMSQueueable(attachmentRec.Id, crmSMS.Id);
        Id jobID = System.enqueueJob(campaignMemberJob);
        Test.stopTest();
    }

    @isTest static void getAccessTokenTest() {
        // Implement test code
        Campaign crmSMS = BMS_TestDataHelper.buildSampleCRMMassEmail('Sample Template');
        crmSMS.Type = 'SMS';
        insert crmSMS;

        String strCsvContent = 'MobilePhone'+'\r\n'+'61234567890'+'\r\n'+'61324567890'+'\r\n'+'61474567890'+'\r\n';
        Blob csvBlob = Blob.valueOf(strCsvContent);

        Attachment attachmentRec = new Attachment();
        attachmentRec.Body = csvBlob;
        attachmentRec.Name = 'fileName';
        attachmentRec.ParentId = crmSMS.Id;
        insert attachmentRec;

        MarketingCloudApp__c mcApp = new MarketingCloudApp__c();
        mcApp.Name = 'Credentials';
        mcApp.Client_ID__c = 'ssjhdsakhd882793879';
        mcApp.Client_Secret__c = 'sdhsaldhlhd7263535336';
        insert mcApp;

        Test.startTest();
        //Test Access Token mock response
        SingleRequestMock fakeTokenResponse = new SingleRequestMock(200,
                                                 'Complete',
                                                 '{"accessToken": "7sK3RHIaD2CsyCGDrMuwMLko","expiresIn": 3478}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeTokenResponse);
        Database.executeBatch(new BMSMassSMSSendBatch(attachmentRec.Id, crmSMS.Id), 1000);
        Test.stopTest();
    }
}