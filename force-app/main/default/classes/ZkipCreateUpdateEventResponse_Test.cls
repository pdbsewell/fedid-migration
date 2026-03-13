/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
private class ZkipCreateUpdateEventResponse_Test {
	static testMethod void testErrorFreeExecution() {
        Test.startTest();
        
        ZkipCreateUpdateEventResponse.parse('{"links": {"self": "", "related": ""}, "data": {"type": "", "id": "", "attributes": {"name": "", "event-type": "", "date": "", "date-utc": "", "end-date": "", "end-date-utc": "", "timezone": "", "timezone-universal-id": "", "location": "", "location-address": {"address-line": "", "city": "", "state": "", "zip": "", "country": "", "latitude": 10.0, "longitude": 10.0}, "add-ons": {"seating-charts-enabled": true, "picture-source-enabled": true, "badge-print-enabled": true, "rsvp-enabled": true}}, "relationships": {"guest-lists": {"links": {"self": "", "related": ""}}, "custom-fields": {"links": {"self": "", "related": ""}, "data": [{"type": "", "id": ""}]}}}}');
        
        Test.stopTest();
    }
}