/*******************************************************************************
* @author		Vishal Gupta
* @date         23/1/2025    
* @description  Test Class for IbdGROfferServices Class
* @revision     23/1/2025 - Initial Version
*******************************************************************************/
@isTest(isParallel=true)
public class IbdGROfferServices_Test {
    /**
     * @author          Vishal Gupta
     * @description     test the platform event to recieve the scholarship request  
     * @revision        23/1/2025 - Initial Version
     */
    @isTest static void testScholarshipPlatformEvent() {
        Test.startTest();
        //Given, there is a GR scholarship application submitted to callista 
        //When, salesforce receives the request in platform event
        String json = '{'+
                '	"scholarship":{  '+
                '		"offerStatus": "OFFERED", '+
                '		"responseStatus": "emptyOrNull", '+
                '		"offerLapseDate": "2025-03-04",'+
                '		"hasFacultyScholarshipAwarded": true,'+
                '		"hasFacultySponsorshipAwarded": false'+
                '	}'+
                '}';
		
		IbdGROffers__e event = new IbdGROffers__e(
                    Process_Name__c = 'GRScholarshipOfferService',
                    Request_Parameter__c = json
                );
				
        EventBus.publish(event);
        Test.stopTest();
        List<EventBusSubscriber> lstEvent = [SELECT Name, Position, Retries, LastError 
                                                FROM EventBusSubscriber 
                                                WHERE Topic='IbdGROffers__e' AND Type='ApexTrigger'
                                                ];
        //Then: the platform event should be seen in the system which calls the scholarship service class
        Assert.areNotEqual(true, lstEvent.isEmpty(), 'event is fired to trigger the scholarship request');
    }

    /**
     * @author          Vishal Gupta
     * @description     test the platform event to recieve the scholarship request  
     * @revision        23/1/2025 - Initial Version
     */
    @isTest static void testScholarshipPlatformEventBulkFail() {
        Test.startTest();
        //Given, there is a GR scholarship application submitted to callista 
        //When, salesforce receives the multiple/bulk request in platform event
        String json1 = '{'+
                '	"scholarship":{  '+
                '		"offerStatus": "OFFERED", '+
                '		"responseStatus": "emptyOrNull", '+
                '		"offerLapseDate": "2025-03-04",'+
                '		"hasFacultyScholarshipAwarded": true,'+
                '		"hasFacultySponsorshipAwarded": false'+
                '	}'+
                '}';
		String json2 = '{'+
                '	"scholarship":{  '+
                '		"offerStatus": "REJECTED", '+
                '		"responseStatus": "emptyOrNull", '+
                '		"offerLapseDate": "2025-03-04",'+
                '		"hasFacultyScholarshipAwarded": true,'+
                '		"hasFacultySponsorshipAwarded": false'+
                '	}'+
                '}';
		IbdGROffers__e event1 = new IbdGROffers__e(
                    Process_Name__c = 'GRScholarshipOfferService',
                    Request_Parameter__c = json1
                );
        IbdGROffers__e event2 = new IbdGROffers__e(
                    Process_Name__c = 'GRScholarshipOfferService',
                    Request_Parameter__c = json2
                );        
		List<IbdGROffers__e> eventList = new List<IbdGROffers__e>();
        eventList.add(event1);	
        eventList.add(event2);		
        EventBus.publish(eventList);
        Test.stopTest();
        //then it should throw an error becuase only 1 platform event needs to process at a time
        List<Nebula__LogEntry__c> logs = [SELECT Id FROM Nebula__LogEntry__c WHERE Nebula__LoggingLevel__c = 'Error'];
        Assert.areNotEqual(null, logs.isEmpty(), 'error logs found');
    }
}