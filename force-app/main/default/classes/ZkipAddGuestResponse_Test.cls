/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
private class ZkipAddGuestResponse_Test {
	static testMethod void testErrorFreeExecution() {
        Test.startTest();
        
        ZkipAddGuestResponse.parse('{"links": {"self": "", "related": ""}, "data": {"type": "", "id": "", "attributes": {"first-name": "", "last-name": "", "contact-details": {"organization": "", "country-code": "", "phone-number": "", "email": ""}, "notification-emails": [""], "notification-phone-numbers": "", "note": "", "total-guests": 1, "plus-ones-checked": 1, "main-guest-checked": true, "status": "", "seating-map-details": {"seating-color": "", "seating-color-rgb": "", "table-label": null, "seat-label": null}, "custom-field-values": []}, "relationships": {"guest-list": {"links": {"self": "", "related": ""}, "data": {"type": "", "id": "", "attributes": {}, "relationships": {}}}, "custom-fields": {"links": {"self": "", "related": ""}}}}}');
        
        Test.stopTest();
    }
}