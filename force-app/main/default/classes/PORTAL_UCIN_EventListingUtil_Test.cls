/**
 * @author Zachary Soohoo, UC Innovation
 * @date 11/1/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test Class for PORTAL_UCIN_EventListingUtil
 */
@isTest(isParallel=true)
public class PORTAL_UCIN_EventListingUtil_Test {

    @IsTest
    public static void test_createEventListing()
    {
        // Testing process builder invocation
        test.startTest();

        String rId= Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ERDA_Event').getRecordTypeId();
        Campaign c = new Campaign();
        c.Areas_of_Interest__c = 'Education;Art and Design;Indigenous Communities and Culture';
        c.Description = 'This is a test of the Process Builder';
        c.Event_City__c = 'Westminster';
        c.Event_Country__c = 'Australia';
        c.Event_End_DateTime__c = System.now().addMonths(1);
        c.Event_URL__c = 'https://www.google.com';
        c.Name = 'Test event listing';
        c.Online_Event__c = true;
        c.Externally_Visible__c = true;
        c.Event_Zip__c = '90001';
        c.Event_Start_DateTime__c = System.now();
        c.Event_State__c = 'California';
        c.Event_Street__c = '210 Trade Street';
        c.RecordTypeId = rId;
        insert c;
        
        Campaign c2 = c.clone(false, true);
        c2.Description = 'Second event';
        c2.Online_Event__c = false;
        c2.Name = 'Eman';
        c2.Areas_of_Interest__c = 'Education';
        insert c2;
        
        c.Description = 'This is a test of the update process';
        update c;
        
        test.stopTest();
        
        String idsToQuery = String.valueOf(c.Id) + ', ' + String.valueOf(c2.Id);
		String queryString = 'SELECT Id, Areas_of_Interest__c, Associated_Event__c, Body_Content__c, City__c, Country__c, End_Date_Time__c, Event_URL__c, ';
        queryString += 'Name, Online_Event__c, Postal_Code__c, Start_Date_Time__c, State__c, Street__c FROM Listing__c';
        List<Listing__c> listingResults = Database.query(queryString);

        for(Listing__c evnt : listingResults) {
           	if(evnt.Associated_Event__c == c.Id){
                System.assertEquals(c.Name, evnt.Name);
                System.assertEquals(c.Event_Street__c, evnt.Street__c);
                System.assertEquals(c.Description, evnt.Body_Content__c);
            } else if(evnt.Associated_Event__c == c2.Id) {
                System.assertEquals(c2.Online_Event__c, evnt.Online_Event__c);
                System.assertEquals(c2.Areas_of_Interest__c, evnt.Areas_of_Interest__c);
                System.assertEquals(c2.Description, evnt.Body_Content__c);
            }
        }
    }
}