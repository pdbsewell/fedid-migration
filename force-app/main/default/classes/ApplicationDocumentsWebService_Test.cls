@IsTest
private class ApplicationDocumentsWebService_Test {

    @isTest 
    private static void testSuccess() {
        
        //Create a new Contact for testing
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        Date dtToday = Date.today();
        c.Birthdate = dtToday.addYears(-20);
        insert c;
        
        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Fee_Payment__c = true;
        insert app;

        CONTACT retCon = [SELECT CRM_Id__c FROM CONTACT WHERE ID=:c.id ];
        application__c retApp = [SELECT Id, Name FROM application__c WHERE ID=:app.id ];
                
        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'GET';
        rReq.params.put('applicationId',retApp.Name);
        RestContext.request = rReq;
        RestResponse response = new RestResponse(); // Create a new RestResponse
		RestContext.response = response; // Assign the new RestResponse to RestContext.response

        RestContext.request = rReq;
       
        Test.startTest();
           ApplicationDocumentsWebService.getDocumentChecklist();
        Test.stopTest();
        string responseString = RestContext.response.responseBody.toString();
        Assert.isTrue(responseString.containsIgnoreCase('Proof of Residency / Citizenship'), 'Get Document Checklist - Mandatory docs check - failed');
		Assert.isTrue([SELECT Id, Nebula__OriginLocation__c FROM Nebula__LogEntry__c].size()>0);

    }
}