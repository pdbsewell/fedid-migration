/**
 * @author Nick Guia
 * @date 18-01-2021
 * @group Event Management
 * @description Trigger handler for conference360__Form_Submission__c object (Blackthorn)
 **/
public with sharing class BTFormSubmissionTriggerHandler {

	public static final String STATUS_IN_PROGRESS = 'In Progress';
	public static final String STATUS_SUBMITTED = 'Submitted';
	public static final String STATUS_ERROR = 'Error';

	/**
	 * @description creates the Person360 records for the Contact that
	 * was linked to the Attendee
	 */
	public class CreateAttendeeContactPerson360 extends TriggerAbstract {

		private BTFormSubmissionP360Helper helper = new BTFormSubmissionP360Helper();

		public override void process(SObject sobj) {
			conference360__Form_Submission__c newObj = (conference360__Form_Submission__c) sobj;
			//process record if no custom form elements found
			this.helper.collectNoCustomFormElement(newObj);
		}

		public override void process(SObject sobj, SObject oldRec) {
			conference360__Form_Submission__c newObj = (conference360__Form_Submission__c) sobj;
			conference360__Form_Submission__c oldObj = (conference360__Form_Submission__c) oldRec;

			/**
			 * PROCESS IF:
			 *  - Event is not null
			 *  - Attendee is not null
			 *  - Status is = "Submitted"
			 * 	- Processed = TRUE
			 */
			if(newObj.conference360__Event__c != null &&
			   newObj.conference360__Attendee__c != null &&
			   newObj.conference360__Status__c.equalsIgnoreCase(STATUS_SUBMITTED) &&
			   newObj.conference360__Processed__c != oldObj.conference360__Processed__c &&
			   newObj.conference360__Processed__c)
			{
				this.helper.collectFormSubmissionDetails(newObj);
			}
		}

		public override void execute() {
			try {
				this.helper.createPerson360();
			} catch(Exception e) {
				LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
			} finally {
				LogUtilityException.getLimits();
			}
        }
    }
}