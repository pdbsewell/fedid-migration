/**
 * @author Ibrahim Rumi
 * @date 24-05-2021
 * @group Event Management
 * @description class to generate Event-Attendee-EventSettingsDAOlist when list of attendees is passed
 *   17.01.2022  Ibrahim Rumi    - EPBBS-2379 GetExistingContactsforEvents method to fetch all attendees in an event
 **/
public inherited sharing class BTEventAttendeeDAOHelper {

	@TestVisible
	private Set<Id> eventIdSet;
	@TestVisible
	private Map<Id,Id> eventsByEventSettingIds;
	@TestVisible
	private List<conference360__Attendee__c> attendeList;
	@TestVisible
	private Map<Id, conference360__Event__c> eventMap;
	@TestVisible
	private Map<Id, conference360__Event_Settings__c> eventSettingMap;

	/**
	 * @description constructor to init collections and build attendee map
	 **/
	public BTEventAttendeeDAOHelper(List<conference360__Attendee__c> attList) {

		if(attList != null && !attList.isEmpty()) {
			this.attendeList = attList;
            this.eventIdSet = new Set<Id>();
            this.eventMap = new Map<Id, conference360__Event__c>();
            this.eventsByEventSettingIds = new Map<Id, Id>();

            for(conference360__Attendee__c att : attList){
                this.eventIdSet.add(att.conference360__Event__c);
            }
        } else {
            throw new BTEventAttendeeDAOHelperException('Invalid null or empty parameter');
        }
    }

    /**
     * @description executable method to generate list of BTEventAttendeeDAO
     * @return List<BTEventAttendeeDAO>
     */
    public List<BTEventAttendeeDAO> generateEventAttendeeDAO() {
    	List<BTEventAttendeeDAO> eventAttendeeDAOList = selectEvents()
                                                        .selectEventSettings()
                                                        .buildDAOList();
        return eventAttendeeDAOList;
    }

    /**
     * @description executable method to generate a map of BTEventAttendeeDAO
     * @return Map<Id, BTEventAttendeeDAO>
     */
    public Map<Id, BTEventAttendeeDAO> generateEventAttendeeDAOMap() {
    	Map<Id, BTEventAttendeeDAO> daoMap = selectEvents()
                                            .selectEventSettings()
                                            .buildDAOMap();
        return daoMap;
    }

    /**
    * @description query Events to fetch the corresponding Event Settings and the required Event fields
    */
    public BTEventAttendeeDAOHelper selectEvents() {
        //[EPBBS-2030] - Included Winning_Affiliation__c field in query
        for(conference360__Event__c evnt: [SELECT Id, Audience_Type__c, conference360__Event_Settings__c, 
                                           conference360__Event_Start_Date_Time_GMT__c, conference360__Attendee_Limit__c,
                                           conference360__Remaining_Capacity__c, Winning_Affiliation__c  
                                        FROM conference360__Event__c
                                        WHERE Id IN: this.eventIdSet])
        {
            this.eventMap.put(evnt.Id,Evnt);
            this.eventsByEventSettingIds.put(evnt.Id, evnt.conference360__Event_Settings__c);     
        }
        return this;
    }
    
    /**
    * @description query Event Settings to fetch the corresponding event settings fields
    */
    public BTEventAttendeeDAOHelper selectEventSettings(){
        this.eventSettingMap = new Map<Id, conference360__Event_Settings__c>(
        	[SELECT Id, Validate_Attendee_Registration__c, Skip_Pending_for_Waitlisting__c, waitlist_registration_expiry__c
                FROM conference360__Event_Settings__c 
                WHERE Id IN: this.eventsByEventSettingIds.values()]
        );
        return this;
    }
    

    /**
     * @description generate map of BTEventAttendeeDAO
     */
    @TestVisible
    private Map<Id, BTEventAttendeeDAO> buildDAOMap() {
        Map<Id, BTEventAttendeeDAO> daoMap = new Map<Id, BTEventAttendeeDAO>();

        for(conference360__Attendee__c iAtt : this.attendeList) {
            conference360__Event__c btEvent = this.eventMap.get(iAtt.conference360__Event__c);
            conference360__Event_Settings__c btEventSetting = this.eventSettingMap.get(btEvent.conference360__Event_Settings__c);
            BTEventAttendeeDAO dao = new BTEventAttendeeDAO(btEvent, iAtt, btEventSetting);
            daoMap.put(iAtt.Id, dao);
        }

        return daoMap;
    }
    
    /**
     * @description generate List of BTEventAttendeeDAO. This is needed
     * if Attendees are processed in a Before Trigger context
     */
    @TestVisible
    private List<BTEventAttendeeDAO> buildDAOList() {
        List<BTEventAttendeeDAO> daoList = new List<BTEventAttendeeDAO>();
        for(conference360__Attendee__c iAtt : this.attendeList) {
            conference360__Event__c btEvent = this.eventMap.get(iAtt.conference360__Event__c);
            conference360__Event_Settings__c btEventSetting = this.eventSettingMap.get(btEvent.conference360__Event_Settings__c);
            BTEventAttendeeDAO dao = new BTEventAttendeeDAO(btEvent, iAtt, btEventSetting);
            daoList.add(dao);
        }
        return daoList;
    }
    
     /**
     * @description generate a map of events and its assocated attendees
     */
    public Map<Id, Set<Id>> getExistingRegisteredContactsforEvents() {
        
        Map<Id, Set<Id>> attendeeMap = new Map<Id, Set<Id>>();
        BTAttendeeSelector bas = new BTAttendeeSelector();
        
        List<conference360__Attendee__c> attendees = bas.selectExistingAttendeesByEventIds(this.eventIdSet);
        
        for(conference360__Attendee__c att: attendees){
            if(string.isNotBlank(att.conference360__Registration_Status__c) && 
               att.conference360__Registration_Status__c == BTAttendeeServices.REG_STATUS_REGISTERED){
                if(attendeeMap.containsKey(att.conference360__Event__c)) {
                    Set<Id> contactIdSet = attendeeMap.get(att.conference360__Event__c);
                    contactIdSet.add(att.conference360__Contact__c);
                    attendeeMap.put(att.conference360__Event__c, contactIdSet);
                } else {
                    attendeeMap.put(att.conference360__Event__c, new Set<Id> { att.conference360__Contact__c });
                }
            }
            
        }
        return attendeeMap;
    }

    public class BTEventAttendeeDAOHelperException extends Exception { }

}