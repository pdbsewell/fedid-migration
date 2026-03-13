/**
 * @author Zachary Soohoo, UC Innovation
 * @date 11/1/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Kicked off from process builder to create listing from campaigns
 */
global class PORTAL_UCIN_EventListingUtil {
	@InvocableMethod(label='Create Event Listing from Campaign')
    global static void createEventListing(List<Id> campaignIds) {
        String campaignQuery = 'SELECT Id, Areas_of_Interest__c, Description, Event_City__c, Event_Country__c, Event_End_DateTime__c, ';
        campaignQuery += 'Event_URL__c, Name, Online_Event__c, OwnerId, Event_Zip__c, Event_Start_DateTime__c, Event_State__c, Event_Street__c,Type ';
        campaignQuery += 'FROM Campaign WHERE Id in :campaignIds';
        
        List<Campaign> campaignList = Database.query(campaignQuery);
        
        List<Listing__c> listOfListingsToAdd = new List<Listing__c>();
		List<Listing__c> listOfListingsToUpdate = new List<Listing__c>();
		Map<Id, Listing__c> campaignToListingMap = new Map<Id, Listing__c>();
        
		// Look for existing listing records that are connected to any of these campaigns. 
		List<Listing__c> existingListings = [SELECT ID,Associated_Event__c FROM Listing__c WHERE Associated_Event__c IN: campaignIds];

		for (Listing__c eachListing: existingListings) {
			// Create a map of campaign ID to listing record
			campaignToListingMap.put(eachListing.Associated_Event__c, eachListing);
		}

		// If any of these campaigns have an associated listing, update that listing. If not, create a new listing.
        for(Campaign cam : campaignList) {
			if (campaignToListingMap.containsKey(cam.ID)) {
				Listing__c listingToUpdate = campaignToListingMap.get(cam.ID);
				listingToUpdate = setListingRecord(cam, listingToUpdate);
				listOfListingsToUpdate.add(listingToUpdate);
			} else {
				Listing__c listingToAdd = new Listing__c();
				listingToAdd = setListingRecord(cam, listingToAdd);
				listOfListingsToAdd.add(listingToAdd);
			}
        }
        insert listOfListingsToAdd;
		update listOfListingsToUpdate;
    }

	private static Listing__c setListingRecord(Campaign cam, Listing__c listingToSet) {
		listingToSet.Areas_of_Interest__c = cam.Areas_of_Interest__c;
		listingToSet.Associated_Event__c  = cam.Id;
		listingToSet.Body_Content__c = cam.Description;
		listingToSet.City__c = cam.Event_City__c;
		listingToSet.Country__c = cam.Event_Country__c;
		listingToSet.End_Date_Time__c = cam.Event_End_DateTime__c;
		listingToSet.Event_URL__c = cam.Event_URL__c;
		listingToSet.Name = cam.Name;
		listingToSet.Online_Event__c = cam.Online_Event__c;
		listingToSet.OwnerId = cam.OwnerId;
		listingToSet.Postal_Code__c = cam.Event_Zip__c;
		listingToSet.RecordTypeId = Schema.SObjectType.Listing__c.getRecordTypeInfosByDeveloperName().get('Event').getRecordTypeId();
		listingToSet.Start_Date_Time__c = cam.Event_Start_DateTime__c;
		listingToSet.State__c = cam.Event_State__c;
		listingToSet.Street__c = cam.Event_Street__c;
		listingToSet.Type__c = cam.Type;

		return listingToSet;
	}
}