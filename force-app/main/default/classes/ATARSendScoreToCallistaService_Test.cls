/*****************************************************************************************************************
* @author      : Sethu Venna
* @date        : 18/03/2025
* @description : Test class for ATARSendScoreToCallistaService
* @revision    : 18/03/2025 - Initial Version
*****************************************************************************************************************/
@IsTest(isParallel=true)
public class ATARSendScoreToCallistaService_Test {
    
    @IsTest
    public static void testATARSendScoreToCallistaService() {
        // Create test data

        // Create test data

        Country_Attribute__c ca = new Country_Attribute__c(Name = 'AUSTRALIA');
        insert ca;

        Contact newContact = new Contact();
        newContact.FirstName = 'FN in testATARCalloutFromTrigger';
        newContact.LastName = 'LN in testATARCalloutFromTrigger';
        newContact.Person_ID_unique__c = '123456';
        insert newContact;

        Qualification__c qual = new Qualification__c();
        qual.Callista_Code__c = 'Y12';
        qual.Qualification_Name__c = 'Year 12 All Australia';
        insert qual;

        Contact_Qualification__c conQual = new Contact_Qualification__c();
        conQual.Person_ID__c = '123456';
        conQual.Qualification__c = qual.Id;
        conQual.Contact__c = newContact.Id;
        conQual.Qualification_Country__c = ca.Id;
        conQual.RecordTypeId = ContactQualificationServices.SECONDARY_EDU_RECORD_TYPE_ID;
        insert conQual;
        
        // Create a mock response
        ATARScoreHTTPCalloutMock mockResp = new ATARScoreHTTPCalloutMock();
        mockResp.responseCode = 200;
        
        Test.setMock(HttpCalloutMock.class, mockResp);
        
        // Execute the service
        Test.startTest();
        ATARSendScoreToCallistaService service = new ATARSendScoreToCallistaService(conQual);
        service.createRequestBody();
        service.sendMessage();
        service.handleResponse();
        Test.stopTest();
        
        // Verify the response
        Assert.areEqual(
            200,
            service.httpResponseCode, 
            'Expecting a 200 STATUS OK'
        );
        
    }
}