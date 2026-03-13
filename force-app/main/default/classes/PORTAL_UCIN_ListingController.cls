/**
 * @author Sulung Chandra, UC Innovation
 * @date 8/28/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Controller for PORTAL_UCIN Listing components
 */
public without sharing class PORTAL_UCIN_ListingController {
    
    
    public class MyEventWrapper {
        @AuraEnabled
        public Listing__c eventDetails{ get; set; }
        @AuraEnabled
        public String status{ get; set; }

        public MyEventWrapper(Listing__c eventDetails, String status) {
            this.eventDetails = eventDetails;
            this.status = status;
        }
    }
    
        /**
    * Retrieve a list of Listing given a record type, a Category, 
    * sorting criteria and the maximum number of records to be returned
    *
    * @param: recordTypeDeveloperName       The record type of the listing being searched for
    * @param: category                      The Category of the listing being searched for
    * @param: maxNumberOfRecords            The maximum number of Listings to be returned
    */
    @AuraEnabled
    public static List<Listing__c> getListings(String recordTypeDeveloperName, String category, Integer maxNumberOfRecords) {
        List<Listing__c> listingList = new List<Listing__c>();
        List<String> SelectList = new List<String>();
        List<String> wheresList = new List<String>();
        String query = '';
        String orderByString = 'LastModifiedDate Desc';
        
        SelectList.add('Id');
        SelectList.add('Name');
        SelectList.add('Title_URL__c');
        SelectList.add('Header_Content__c');
        SelectList.add('Header_Image_from_URL__c');
        SelectList.add('Header_Video_URL__c');
        SelectList.add('Category__c');
        SelectList.add('Body_Content__c');
        
        wheresList.add('RecordType.DeveloperName=:recordTypeDeveloperName');
        wheresList.add('Category__c=:category');
        
        query = 'Select ' + String.join(SelectList, ',') + ' From Listing__c Where ' + String.join(wheresList, ' And ') + ' Order By ' + orderByString + ' Limit :maxNumberOfRecords';
        
        listingList = Database.query(query);
        
        for(Listing__c li : listingList) {
            li.Header_Content__c = PORTAL_UCIN_Utils.replaceSelectedText(li.Header_Content__c);
            li.Body_Content__c = PORTAL_UCIN_Utils.replaceSelectedText(li.Body_Content__c);
        }
        
        return listingList;
    }


        /**
    * Retrieve a map of Listing given a record type, a list of keys/Categories, 
    * and the maximum number of records to be returned
    *
    * @param: recordTypeAPIName     The record type of the listings being searched for
    * @param: keys                  A list of comma seperated categories which are also used as keys in the return map
    * @param: maxRecords            The maximum number of Listings to be returned
    */
    @AuraEnabled
    public static Map<String, Listing__c> getListingMap(String recordTypeAPIName, String keys, Integer maxRecords) {
        Map<String, Listing__c> listingMap = new Map<String, Listing__c>();
        List<Listing__c> listings = new List<Listing__c>();
        List<String> keyList = new List<String>();
        String query = '';
        keyList = keys.split(',');
        query = 'SELECT Name, Header_Content__c, Header_Image_from_URL__c, Header_Video_URL__C, Body_Content__c, Category__c FROM Listing__c WHERE ' + 
            'RecordType.DeveloperName=:recordTypeAPIName AND Category__c IN :keyList Order By LastModifiedDate Desc LIMIT :maxRecords';
        
        listings = Database.query(query);

        //Remove extraneous tags added in Rich text and the resulting Listing to the return map associated with appropriate category
        for(Listing__c listing : listings) {
            for(Integer i = 0; i < keyList.size(); i++) {
                if(!listingMap.containsKey(keyList.get(i)) && listing.Category__c.equals(keyList.get(i))) {
                    listing.Header_Content__c = PORTAL_UCIN_Utils.replaceSelectedText(listing.Header_Content__c);
                    listing.Body_Content__c = PORTAL_UCIN_Utils.replaceSelectedText(listing.Body_Content__c);
                    listingMap.put(keyList.get(i), listing);
                    break;
                }
            }
        }
        return listingMap;
    }
    
    /**
    * Retrieve a list of event Listings given the record type and the maximum number to display
    *
    * @param: recordTypeAPIName       		The record type of the listing being searched for
    * @param: maxRecords            The maximum number of Listings to be returned
    */
    @AuraEnabled
    public static List<Listing__c> getEventList(String recordTypeAPIName, Integer maxRecords) {
        List<Listing__c> listings = new List<Listing__c>();
        List<String> areasOfInterest;
        DateTime dtTwoHours = System.now().addHours(2);
        String query = '';

        Id contactId = getContactId();
        areasOfInterest = getAreasOfInterest(contactId);
               

        query = 'SELECT Name, Header_Content__c, Header_Image_from_URL__c, Header_Video_URL__C, Body_Content__c, ' + 
            	'City__c, Country__c, Postal_Code__c, State__c, Street__c, Areas_of_Interest__c, Online_Event__c, ' +
            	'Start_Date_Time__c, End_Date_Time__c, Event_URL__c, Type__c FROM Listing__c WHERE ' + 
            'RecordType.DeveloperName=:recordTypeAPIName AND (End_Date_Time__c > :dtTwoHours OR End_Date_Time__c = null) Order By Start_Date_Time__c Asc LIMIT :maxRecords';
        
        listings = Database.query(query);
		
        
        return organizeListings(listings, areasOfInterest);
    }

    /**
    * Retrieve a list of event Listings and their status for a user given the record type and the maximum number to display
    *
    * @param: recordTypeAPIName       		The record type of the listing being searched for
    * @param: maxRecords            The maximum number of Listings to be returned
    */
    @AuraEnabled
    public static List<MyEventWrapper> getMyEventList(String recordTypeAPIName, Integer maxRecords) {
        List<CampaignMember> campaignMemberList = new List<CampaignMember>();
         List<String> areasOfInterest;
        List<MyEventWrapper> returnList = new List<MyEventWrapper>();
        List<Id> eventIds = new List<Id>();
        DateTime dtTwoHours = System.now().addHours(2);
        
        Id contactId = getContactId();        
        if(contactId == null) {
            return null;
        }
        areasOfInterest = getAreasOfInterest(contactId);

        //Retrieve the list of events a user has signed up for
        campaignMemberList = [SELECT id, Contact.Name, Campaign.Parent_ERDA_Event__r.Name, Campaign.Parent_ERDA_Event__r.Id, Status 
                    FROM CampaignMember
                    WHERE Status IN ('Confirmed', 'Unconfirmed', 'CheckedIn') AND ContactId = :contactId];
        for(CampaignMember mem : campaignMemberList) {
            eventIds.add(mem.Campaign.Parent_ERDA_Event__r.Id);
        }
        //Retrieve the listings for the Events the user has signed up for


        List<Listing__c> beforeToday = new List<Listing__c>();
        List<Listing__c> afterToday = new List<Listing__c>();
        Boolean isBefore = true;
        for(Listing__c evnt : [SELECT Id, Name, Body_Content__c, City__c, Country__c, State__c, Street__c, Areas_of_Interest__c, 
                                     Online_Event__c, Start_Date_Time__c, End_Date_Time__c, Associated_Event__c, Event_URL__c, Type__c
                                     FROM Listing__c 
                                     WHERE Associated_Event__c IN :eventIds ORDER BY Start_Date_Time__c Asc]) {
            if(isBefore && (evnt.End_Date_Time__c < dtTwoHours)) {
                beforeToday.add(evnt);
            } else {
                isBefore = false;
                afterToday.add(evnt);
            }
        }  
        List<Listing__c> tempList = organizeListings(beforeToday, areasOfInterest);
        tempList.addAll(organizeListings(afterToday, areasOfInterest));


        //listings = organizeListings(listings, areasOfInterest);
        //Construct the list of Event Listings and associated user status to be returned
        for(Listing__c lis : tempList) {
            for(CampaignMember m : campaignMemberList) {
                if(m.Campaign.Parent_ERDA_Event__r.Id == lis.Associated_Event__c) {
                    MyEventWrapper eventToAdd = new MyEventWrapper(lis, m.Status);
                    returnList.add(eventToAdd);
                    break;
                }
            }
        }
        
        return returnList;
    }
    
    /**
    * Search for a list of events based on areas of interest being searched for
    *
    * @param: searchTerms       		The areas of interest being searched for 
    */
    @AuraEnabled
    public static List<Listing__c> SERVER_searchEvents(String searchTerms){
        List<Listing__c> returnList = new List<Listing__c>();
        DateTime dtTwoHours = System.now().addHours(2);
        Set<String> aoiToQuerySet = new Set<String>();
        Set<String> namestoQuerySet = new Set<String>();

        //seperate the search string into a list of individual words to search for
        searchTerms = searchTerms.replaceAll(',', '');
        searchTerms = String.escapeSingleQuotes(searchTerms);
        searchTerms = searchTerms.toLowerCase();
        String[] splitTerms = searchTerms.split(' ');

        List<Schema.PicklistEntry> pleList = Contact.Volunteer_Areas_of_Interest__c.getDescribe().getPicklistValues();

        for (string searchTerm: splitTerms) {
            // for each search term, look for all applying picklist entries that match and add to set of AOIs to query for
            for(Schema.PicklistEntry picklistEntry : pleList) {
                if(picklistEntry.getLabel().toLowerCase().contains(searchTerm)) {
                    aoiToQuerySet.add('\'' + picklistEntry.getLabel() + '\'');
                }
            }

            // For each search term, search for name to match it
            namestoQuerySet.add('%' + searchTerm + '%');
        }

        String whereClause = 'RecordType.DeveloperName=\'Event\' AND (End_Date_Time__c >  :dtTwoHours  OR End_Date_Time__c = null) AND ';

        whereClause += '(Name LIKE: namesToQuerySet';
        if (!aoiToQuerySet.isEmpty()) {
            whereClause += ' OR Areas_of_Interest__c includes (' + String.Join(new List<String>(aoiToQuerySet), ',') + ')';
        }
        whereClause += ')';

        system.debug('whereclause' + whereClause);
        
        String eventListingQuery = 'SELECT Id, Name, Body_Content__c, City__c, Country__c, State__c, Street__c, Areas_of_Interest__c, '
                        + 'Online_Event__c, Start_Date_Time__c, End_Date_Time__c, Associated_Event__c, Event_URL__c , Type__c '
                        + 'FROM Listing__c WHERE '
                        + whereClause
                        + ' ORDER BY Start_Date_Time__c Asc LIMIT 999';
        returnList = Database.query(eventListingQuery);

        Id contactId = getContactId();

        return organizeListings(returnList, getAreasOfInterest(contactId));
    }

    /**
    * Retrieve map of event types to the picture associated to the type.
    * Assumption is that all files will live under a listing of name 'Event Pictures'
    * Name of the picture must be equal to the type of event
    *
    * @return: Map of event type string to content version id
    */
    @AuraEnabled
    public static Map<String, ID> SERVER_searchEventPicture(){
        Map<String, ID> eventTypeToContentVersionIDMap = new Map<String, ID>();

        List<Listing__c> eventPictureListing = [SELECT ID FROM Listing__c WHERE name = 'Event Pictures' LIMIT 1];

        if (!eventPictureListing.isEmpty()) {
            // Get all files linked to this specific listing
            List<ContentDocumentLink> cdlList = [SELECT ID, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:eventPictureListing[0].Id];
            Set<Id> contentDocumentIdSet = new Set<Id>();

            for (ContentDocumentLink eachLink: cdlList) {
                contentDocumentIdSet.add(eachLink.ContentDocumentId);
            }

            // Get all of the latest content versions for each file
            List<ContentVersion> cvList = [SELECT ID, ContentDocument.Title FROM ContentVersion WHERE ContentDocumentID IN: contentDocumentIDSet AND IsLatest = true];

            // Construct map of file record's title to ID of latest version
            for (ContentVersion eachCV: cvList) {
                eventTypeToContentVersionIDMap.put(eachCV.ContentDocument.Title, eachCV.ID);
            }
        }

        // Will return empty map if there are no listings
        return eventTypeToContentVersionIDMap;
    }

    @AuraEnabled
    public static String SERVER_getBaseUrl () {
        return PORTAL_CommunityUtils.getBaseUrl();
    } 

    /**
    * Retrieve the ACS URL stored in the URLs custom setting
    *
    * @return: String - ACS URL stored in the URLs custom setting
    */
    @AuraEnabled
    public static String getACSURL () {
        return URLs__c.getOrgDefaults().Login_Anyone_SSO_ACS_URL__c;
    } 

    private static List<Listing__c> organizeListings(List<Listing__c> listings, List<String> areasOfInterest) {
        List<Listing__c> noAreaOfInterestListings = new List<Listing__c>();
        List<Listing__c> returnList = new List<Listing__c>();
        Map<String, List<Listing__c>> areaOfInterestToListingListMap = new Map<String, List<Listing__c>>();
        for(Listing__c listing : listings) {
            listing.Body_Content__c = PORTAL_UCIN_Utils.replaceSelectedText(listing.Body_Content__c);
        }

        if(areasOfInterest == null) {
            return listings;
        }

        for(String area : areasOfInterest) {
            areaOfInterestToListingListMap.put(area, new List<Listing__c>());
        }     

        for(Listing__c listing : listings) {
            Boolean isAreaOfInterestFound = false;
            for(String area : areasOfInterest) {
                if(listing.Areas_of_Interest__c != null && listing.Areas_of_Interest__c.contains(area)){
                    areaOfInterestToListingListMap.get(area).add(listing);
                    isAreaOfInterestFound = true;
                    break;
                }
            }
            if(!isAreaOfInterestFound) {
                noAreaOfInterestListings.add(listing);
            }
        }

        for(String area : areasOfInterest) {
            returnList.addAll(areaOfInterestToListingListMap.get(area));
        }
        returnList.addAll(noAreaOfInterestListings);
        return returnList;
    }

    private static List<String> getAreasOfInterest(Id contactId) {
        List<String> areasOfInterest;
        if(contactId != null) {
            Contact cont = [SELECT Id, Volunteer_Areas_of_Interest__c FROM Contact WHERE Id = :contactId];
            if(cont.Volunteer_Areas_of_Interest__c != null) {
                areasOfInterest = cont.Volunteer_Areas_of_Interest__c.split(';');
            }
        }
        return areasOfInterest;

    }

    private static Id getContactId() {
        Id userId = UserInfo.getUserId();
        
        User usr = [SELECT Id,
                    ContactId, 
                    Name
                    FROM User
                    WHERE Id = :userId];
        
        return usr.ContactId; 
    }
}