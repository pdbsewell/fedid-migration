/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
private class ZkipGetAllGuestsResponse_Test {
	static testMethod void testErrorFreeExecution() {
        Test.startTest();
        
        ZkipGetAllGuestsResponse.parse('{"data": [{"type": "", "id": "", "attributes": {"first-name": "", "last-name": "", "contact-details": {"organization": "", "country-code": "", "phone-number": "", "email": ""}, "notification-emails": [""], "note": "", "total-guests": 1, "plus-ones-checked": 1, "main-guest-checked": true, "status": "", "custom-field-values": [{"custom-field-id": 1, "field-name": "", "value": ""}]}, "relationships": {"guest-list": {"links": {"self": "", "related": ""}, "data": {"type": "", "id": ""}}, "custom-fields": {}}, "links": {"self": ""}}]}');
        
        Test.stopTest();
    }
}