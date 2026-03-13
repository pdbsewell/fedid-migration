/**
 * @author Ibrahim Rumi
 * @date 24-05-2021
 * @group Event Management
 * @description class to handle attendee Registration status change
 *   24-05-2021  Ibrahim Rumi    - EPBBS-1375 added method cancelRelatedAttendeeRegistration to handle cancellation of event registration by attendees
 *   24-05-2021  Ibrahim Rumi    - EPBBS-1856 added method AutoRegisterWaitlistedAttendee to auto change the status from pending to registered
 *   17-06-2021  Ibrahim Rumi    - EPBBS-1888 removed methods cancelRelatedAttendeeRegistration and AutoRegisterWaitlistedAttendee.
 *   17-06-2021  Ibrahim Rumi    - EPBBS-1888 added methods handleStatusChange,run and generateDAOMap. 
 *   24-06-2021  Ibrahim Rumi    - EPBBS-2019 updated handleStatusChange() method to handle status change from Pending to registered
 *   08-02-2022  Ibrahim Rumi    - EPBBS-2427 updated handleStatusChange() method to use attendeegroupid to process group cancellation
 **/
public virtual inherited sharing class BTAttendeeRegistrationStatusManager {

    @TestVisible
    protected Map<Id, conference360__Attendee__c> oldAttendeeMap;
    @TestVisible
    protected Map<Id, conference360__Attendee__c> newAttendeeMap;
    @TestVisible
    private Map<Id, BTEventAttendeeDAO> evntAttDAOMap;
    
    /**
    * @description constructor accepts old and new attendeemap and generates the eventattendeedaolist
    **/
    public BTAttendeeRegistrationStatusManager(Map<Id, conference360__Attendee__c> oldAttendee, Map<Id, conference360__Attendee__c> newAttendee) {

        if(oldAttendee != null && newAttendee != null && !oldAttendee.isEmpty() && !newAttendee.isEmpty()) {
            this.oldAttendeeMap = oldAttendee;
            this.newAttendeeMap = newAttendee;
            this.evntAttDAOMap = new Map<Id, BTEventAttendeeDAO>();
        } else {
            throw new BTAttendeeRegistrationStatusManagerException('Invalid null or empty parameter');
        }
    }

    /**
     * @description runs the methods orderly 
     */
    public void run() {
        generateDAOMap().handleStatusChange();
    }

    @TestVisible
    private BTAttendeeRegistrationStatusManager generateDAOMap() {
        this.evntAttDAOMap = new BTEventAttendeeDAOHelper(this.newAttendeeMap.values()).generateEventAttendeeDAOMap();
        return this;
    }
    
    /**
    * @description analyze the registration status change and handle only when the required status change occurs
    */
    private BTAttendeeRegistrationStatusManager handleStatusChange() {

        if(this.evntAttDAOMap != null && !this.evntAttDAOMap.isEmpty()) {

            String oldAttendeeStatus;
            String newAttendeeStatus;
            conference360__Attendee__c attendee;

            //for cancellations
            Set<Id> attendeeGroupSet = new Set<Id>();

            for(BTEventAttendeeDAO iDao : this.evntAttDAOMap.values()) {
                attendee = iDao.getAttendee();
                newAttendeeStatus = attendee.conference360__Registration_Status__c;
                oldAttendeeStatus = this.oldAttendeeMap.get(attendee.Id).conference360__Registration_Status__c;

                //null check status
                if(String.isNotBlank(newAttendeeStatus) && String.isNotBlank(oldAttendeeStatus)) {
                    
                    if(oldAttendeeStatus == BTAttendeeServices.REG_STATUS_WL_PENDING && 
                        newAttendeeStatus == BTAttendeeServices.REG_STATUS_PENDING) 
                    {
                        /**
                         * IF status is updated :
                         * FROM - 'Waitlisted - Pending'
                         * TO - 'Pending'
                         */
                        BTAttendeeServices.processAttendeeWaitlisting(iDao);

                    } else if(oldAttendeeStatus == BTAttendeeServices.REG_STATUS_REGISTERED && 
                            newAttendeeStatus == BTAttendeeServices.REG_STATUS_CANCELLED) 
                    {
                        /**
                         * IF status is updated :
                         * FROM - 'Registered'
                         * TO - 'Canceled'
                         * AND is a Primary Registrant
                         */
                        if(attendee.is_Primary_Registrant__c && attendee.conference360__Attendee_Group__c != null) {
                            attendeeGroupSet.add(attendee.conference360__Attendee_Group__c);
                        }
                    } else if(oldAttendeeStatus == BTAttendeeServices.REG_STATUS_PENDING && 
                            newAttendeeStatus == BTAttendeeServices.REG_STATUS_REGISTERED)
                    {
                        /**
                         * IF status is updated :
                         * FROM - 'Pending'
                         * TO - 'Registered'
                         * AND Registration status reason is
                         * Pending Waitlist Registration
                         */
                        if(attendee.Registration_status_reason__c == BTAttendeeServices.REG_STATUS_REASON_PENDING_WL_REG){
                            attendee.Registration_status_reason__c = '';
                        }
                    }
                }
            }

            if(!attendeeGroupSet.isEmpty()) {
                List<conference360__Attendee__c> cancelList = BTAttendeeServices.processAttendeeCancellation(attendeeGroupSet);
                update cancelList;
            }
        }

		return this;
    }

    
    public class BTAttendeeRegistrationStatusManagerException extends Exception { }
}