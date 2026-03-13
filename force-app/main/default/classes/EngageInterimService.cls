/**
 * @author          Mark Johnson: UC Innovation
 * @description     Changes fields on interim load. This allows for easy processing by the interim batch process.
 * @revision        10/09/2019 - Mark Johnson - Initial version
 * @revision		10/21/2019 - Mark Johnson - Remove alumni contact profile default from the RE record type.
 * @revision		12/30/2019 - Charlie Park - Add updateReviewTransactionWithContact class.
 * @revision		07/06/2022 - Chaldrin Cruz - Add populateAddressType function Zkipster rcord type.
 * @revision		07/06/2022 - Inderpal D - PENGAGE-2658 Format the Phone number to prevent KeyUID Error on Phone Object.
 */

public class EngageInterimService {
	
	/*******************************************************************************
	* @author       Charlie Park - UC Innovation
	* @date         18/2/20
	* @description  Blank update on interims that have default name. Managed Package trigger should update to appropriate name.
					Bandage fix for issue where managed package is not updating these default names to their correct names on after insert call.
	*******************************************************************************/
    public class blankUpdateOnInterim implements Triggers.Handler {
        public void run() {            
			List<ucinn_ascendv2__Interim__c> interimsToUpdate = [SELECT ID,ucinn_ascendv2__Interim_Name_Auto_Number__c,Name FROM Ucinn_ascendv2__Interim__c WHERE ID IN: trigger.newMap.keySet() AND name = '[Default Name]'];

			for (ucinn_ascendv2__Interim__c eachInterim: interimsToUpdate) {
				eachInterim.Name = eachInterim.ucinn_ascendv2__Interim_Name_Auto_Number__c;
			}

			ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Interim__c ', false);
			update interimsToUpdate;
			ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Interim__c ', true);
        }
    }

	/*******************************************************************************
	* @author       Inderpal Dhanoa
	* @date         22/02/2023
	* @description  Format the Mobile number as per the logic on the Phone Object.
	*******************************************************************************/
	public class formatMobile extends TriggerAbstract {
		Set<ucinn_ascendv2__Interim__c> updateInterims = new Set<ucinn_ascendv2__Interim__c>(); // Phone numbers to processes
		Set<Id> s_relRecTypes = new Set<Id>();

		public formatMobile(){
			if(s_relRecTypes.isEmpty()){
				for(RecordType rectyp : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ucinn_ascendv2__Interim__c' AND DeveloperName IN ('Update_Your_Details', 'Online_Donation_Interface')]){
					s_relRecTypes.add(rectyp.Id);
				}
			}
		}

        public override void process(SObject record) {
            ucinn_ascendv2__Interim__c interim = (ucinn_ascendv2__Interim__c) record;
            if (interim != null && s_relRecTypes.contains(interim.recordTypeId) && String.isNotBlank(interim.ucinn_ascendv2__Phone_1__c)) {
                interim.ucinn_ascendv2__Phone_1__c = interim.ucinn_ascendv2__Phone_1__c.replaceAll('[^\\d+\\h]|(?!^)\\+',''); // remove anything that shouldn't be there
				updateInterims.add(interim);
            }  
        }

		public override void process(SObject record, SObject oldRec) {
            ucinn_ascendv2__Interim__c oldInterim = (ucinn_ascendv2__Interim__c) oldRec;
            ucinn_ascendv2__Interim__c newInterim = (ucinn_ascendv2__Interim__c) record;
			if (newInterim != null && s_relRecTypes.contains(newInterim.recordTypeId) && String.isNotBlank(newInterim.ucinn_ascendv2__Phone_1__c) && newInterim.ucinn_ascendv2__Phone_1__c != oldInterim.ucinn_ascendv2__Phone_1__c) {
                newInterim.ucinn_ascendv2__Phone_1__c = newInterim.ucinn_ascendv2__Phone_1__c.replaceAll('[^\\d+\\h]|(?!^)\\+',''); // remove anything that shouldn't be there
				updateInterims.add(newInterim);
            } 
        }

        public override void execute() {
            if (!updateInterims.isEmpty()) {
                for (ucinn_ascendv2__Interim__c mp : updateInterims) {
                    phoneServices.formatPhoneWrapper fpw = phoneServices.initiatePhoneFormat(mp.ucinn_ascendv2__Phone_1__c);
                    mp.ucinn_ascendv2__Phone_1__c = fpw.phoneNumber;
            	}
        	}
    	}
    }

	/*******************************************************************************
	* @author       Charlie Park - UC Innovation
	* @date         12/30/2019 
	* @description  Assign contact to the review transaction once interim is completed.
	*******************************************************************************/
    public class updateReviewTransactionwithContact implements Triggers.Handler {
        public void run() {     
			List<ucinn_ascendv2__Interim__c> triggerNew = (List<Ucinn_ascendv2__Interim__c>) Trigger.New;
			Map<Id, ucinn_ascendv2__Interim__c> newMap = new Map<Id, ucinn_ascendv2__Interim__c>();
			for (ucinn_ascendv2__Interim__c interim : triggerNew) {
				newMap.put(interim.Id, interim);
			}

			// Querying to get the review transaction related list, which should only be one for each interim.
			List<ucinn_ascendv2__Interim__c> interimList = [SELECT Id, ucinn_ascendv2__Contact__c,
																(SELECT Id, ucinn_ascendv2__Contact__c
																	FROM ucinn_ascendv2__Review_Transactions_v2_Interim__r
																	WHERE ucinn_ascendv2__Contact__c = null AND
																		ucinn_ascendv2__Status__c <> 'Posted')
															FROM ucinn_ascendv2__Interim__c
															WHERE Id IN :triggerNew];

			List<ucinn_ascendv2__Review_Transaction_v2__c> reviewTransactionToUpdateList = new List<ucinn_ascendv2__Review_Transaction_v2__c>();
			
			for (ucinn_ascendv2__Interim__c interim : interimList) {
				if (interim.ucinn_ascendv2__Review_Transactions_v2_Interim__r != null && !interim.ucinn_ascendv2__Review_Transactions_v2_Interim__r.isEmpty()) {
					ucinn_ascendv2__Review_Transaction_v2__c revTrans = interim.ucinn_ascendv2__Review_Transactions_v2_Interim__r.get(0);
					if (newMap.get(interim.Id).ucinn_ascendv2__Contact__c != null && newMap.get(interim.Id).ucinn_ascendv2__Status__c == 'Completed') {
						// Need to get it from map instead of from query since ucinn_ascendv2__Contact__c would be old value.
						revTrans.ucinn_ascendv2__Contact__c = newMap.get(interim.Id).ucinn_ascendv2__Contact__c;
						reviewTransactionToUpdateList.add(revTrans);
					}
				}
			}
			
			update reviewTransactionToUpdateList;
        }
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Run slightly different logic based on record type
	*******************************************************************************/
	public class populateInterimForProcessing implements Triggers.Handler {
		public void run() {
			Map<String, Schema.RecordTypeInfo> recordTypeInfo = Ucinn_ascendv2__Interim__c.getSOBjectType().getDescribe().getRecordTypeInfosByDeveloperName();

			for (Ucinn_ascendv2__Interim__c interim : (List<Ucinn_ascendv2__Interim__c>) Trigger.New) {
				if (interim.RecordTypeId == recordTypeInfo.get('Raisers_Edge_Interface').getRecordTypeId()) {
					processRaisersEdgeInterims(interim);
                } else if (interim.RecordTypeId == recordTypeInfo.get('Zkipster_Interface').getRecordTypeId()) {
                    processZkipsterInterims(interim);
                } else if (interim.RecordTypeId == null && String.isNotEmpty(interim.RE_ID__c)) {
					interim.RecordTypeId = recordTypeInfo.get('Raisers_Edge_Interface').getRecordTypeId();
					processRaisersEdgeInterims(interim);
				}
			}
		}

         /*******************************************************************************
        * @author       Mark Johnson - UC Innovation
        * @date         10/9/2019 
        * @description  Change initial load preferred and type values on RE interims. Populate default contact profile of Alumni.
        *******************************************************************************/
		public void processRaisersEdgeInterims(Ucinn_ascendv2__Interim__c interimRecord) {
			populateREPreferredFields(interimRecord);
			populateRETypes(interimRecord);
			populateREClassifications(interimRecord);
			//populateDefaultValues(interimRecord); Remove this call for time being.
		}
        
         /*******************************************************************************
        * @author       Mark Johnson - UC Innovation
        * @date         10/9/2019 
        * @description  Change initial load preferred and type values on Zkipster interims.
        *******************************************************************************/
		public void processZkipsterInterims(Ucinn_ascendv2__Interim__c interimRecord) {
			populateREPreferredFields(interimRecord);
			populateRETypes(interimRecord);
			populateREClassifications(interimRecord);
			populateAddressType(interimRecord);
		}
        
         /*******************************************************************************
        * @author       Mark Johnson - UC Innovation
        * @date         10/9/2019 
        * @description  Populate default contact profile of Alumni.
        *******************************************************************************/
		public void populateDefaultValues(Ucinn_ascendv2__Interim__c interimRecord) {
			if (String.isEmpty(interimRecord.Contact_Profile__c)) interimRecord.Contact_Profile__c = 'Alumni';
		}
        
         /*******************************************************************************
        * @author       Mark Johnson - UC Innovation
        * @date         10/9/2019 
        * @description  Populate first email/phone/address index field to be preferred.
        *******************************************************************************/
		public void populateREPreferredFields(Ucinn_ascendv2__Interim__c interimRecord) {
			if (String.isNotEmpty(interimRecord.Ucinn_ascendv2__Phone_1__c)) {
				interimRecord.Ucinn_ascendv2__Preferred_Phone__c = 'Phone 1';
			}
			if (String.isNotEmpty(interimRecord.Ucinn_ascendv2__Email_1__c)) {
				interimRecord.Ucinn_ascendv2__Preferred_Email__c = 'Email 1';
			}
			if (String.isNotEmpty(interimRecord.Ucinn_ascendv2__Address_1_Line_1__c)) {
				interimRecord.Ucinn_ascendv2__Preferred_Address__c = 'Address 1';
			}
		}

        /*******************************************************************************
        * @author       Mark Johnson - UC Innovation
        * @date         10/9/2019 
        * @description  Populate types based on mapping given by Travis, specifically for RE.
        *******************************************************************************/
		public void populateRETypes(Ucinn_ascendv2__Interim__c interimRecord) {
			if (String.isNotEmpty(interimRecord.Ucinn_ascendv2__Phone_1__c)) {
				interimRecord.Ucinn_ascendv2__Phone_1_Type__c = 'Mobile';
			}
			if (String.isNotEmpty(interimRecord.Ucinn_ascendv2__Phone_2__c)) {
				interimRecord.Ucinn_ascendv2__Phone_2_Type__c = 'Landline';
			}
			if (String.isNotEmpty(interimRecord.Ucinn_ascendv2__Phone_3__c)) {
				interimRecord.Ucinn_ascendv2__Phone_3_Type__c = 'Undefined';
			}
			if (String.isNotEmpty(interimRecord.Ucinn_ascendv2__Phone_4__c)) {
				interimRecord.Ucinn_ascendv2__Phone_4_Type__c = 'Other';
			}
			if (String.isNotEmpty(interimRecord.Ucinn_ascendv2__Phone_5__c)) {
				interimRecord.Ucinn_ascendv2__Phone_5_Type__c = 'Assistant';
			}
		}
        
        /*******************************************************************************
        * @author       Mark Johnson - UC Innovation
        * @date         10/9/2019 
        * @description  Populate classifications based on mapping given by Travis, specifically for RE.
        *******************************************************************************/
		public void populateREClassifications(Ucinn_ascendv2__Interim__c interimRecord) {
			if (String.isNotEmpty(interimRecord.Ucinn_ascendv2__Email_1__c)) {
				interimRecord.Ucinn_ascendv2__Email_1_Type__c = 'Private';
			}
			if (String.isNotEmpty(interimRecord.Ucinn_ascendv2__Email_2__c)) {
				interimRecord.Ucinn_ascendv2__Email_2_Type__c = 'Private';
			}
			if (String.isNotEmpty(interimRecord.Email_3__c)) {
				interimRecord.Email_3_Type__c = 'Business';
			}
		}

        /*******************************************************************************
        * @author       Chaldrin Cruz - UC Innovation
        * @date         07/05/2019 
        * @description  Populate type
        *******************************************************************************/
		public void populateAddressType(Ucinn_ascendv2__Interim__c interimRecord) {
			if (String.isNotEmpty(interimRecord.ucinn_ascendv2__Address_1_Line_1__c) && String.isEmpty(interimRecord.ucinn_ascendv2__Address_1_Type__c)) {
				interimRecord.ucinn_ascendv2__Address_1_Type__c = 'Mailing';
			}
			if (String.isNotEmpty(interimRecord.ucinn_ascendv2__Address_2_Line_1__c) && String.isEmpty(interimRecord.ucinn_ascendv2__Address_2_Type__c)) {
				interimRecord.ucinn_ascendv2__Address_2_Type__c = 'Billing';
			}
			if (String.isNotEmpty(interimRecord.ucinn_ascendv2__Address_3_Line_1__c) && String.isEmpty(interimRecord.ucinn_ascendv2__Address_3_Type__c)) {
				interimRecord.ucinn_ascendv2__Address_3_Type__c = 'Physical';
			}
		}
	}
}