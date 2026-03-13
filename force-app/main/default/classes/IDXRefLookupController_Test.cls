/*
 * @author:			Ayush Agrawal <ayush.agrawal@monash.edu>
 * @description:	Invoke the target class and check for a non-empty response.
 * @group:			Student Admin
 */

@isTest(isParallel=true)
private class IDXRefLookupController_Test {
    @isTest
    static void testErrorFreeExecution() {
        Test.startTest();
        
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                               'Complete',
                                                               '{"results":[{"type":"id-xref","accountType":"person","disabled":0,"identifiers":{"accountName":"aagr0003","monashObjectID":"f40360c8-aeeb-4bed-838e-bda85368369d","monashPersonID":"1dcde2e1-16c4-4e7b-bb8a-cc236182ac28","organizationalRelationships":["OR0017","OR0014","OR0003","OR0001","OR0041","OR0044"],"monashAccountID":"rimolqjxsd","monashAccountNumber":1343420,"monashPrivacyMail":"rimolqjxsd@p.monash.edu","mail":"Ayush.Agrawal@monash.edu","sapEmployeeID":"01140427"},"_links":{"employee":{"href":"/v1/hr-controlled/employees/01140427"},"userDirectory":{"href":"/v1/userdirectory/searches/aagr0003"},"self":{"href":"/v2/id-xref/id?monashObjectID=f40360c8-aeeb-4bed-838e-bda85368369d"}}}]}',
                                                               null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        String response = IDXRefLookupController.lookupIDXRef('sapEmployeeID', '01140427');
        
        Test.stopTest();
        
        Boolean responseIsEmpty = false;
        if(String.isEmpty(response)) {
            responseIsEmpty = true;
        }
        
        System.assertEquals(false, responseIsEmpty, 'IDXRefLookupController.lookupIDXRef is not working as expected.');
    }
}