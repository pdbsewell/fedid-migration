/**
 * @description Phone Trigger Handler
 *
 * @author P.Victoriano
 * @date 03/14/19
 *
 * @revision
 * 	2020-01-22 - Russell Cadapan - Refined the FindNewPrimary logic
 * 	2020-04-02 - Nick Guia - Added FindNewParentChannel
 *  2020-06-15 - J.Mapanao - Added EvaluateIfCanSetPrimary
 *  2020-06-23 - J.Mapanao - Changed using Person360RollUpUtility to new Person360RollUpServices.PerformRollUp().run
 *  2020-07-19 - J.Mapanao - Updated FindNewParentChannel class to allow end dating callista source when contact is non student
 *  2020-07-20 - Stefan Scheit - Added 'is active' field changes into scope for triggering of a roll-up
 *  2022-11-02 - Martin Cadman - Stopped recacluation of primary for when deleting non-primary records
 *  2023-02-03 - Peter Sewell  - Trigger rollup if phone.Verification_Status__c is updated
 *  2023-03-13 - Martin Cadman - Added a check to ensure the channel is active in FindNewParentChannel
 *  2024-09-20 - Martin Cadman - Check for empty keyUID when recalulating the primary
 **/
public class PhoneTriggerHandler {
    
	public class formatMobile extends TriggerAbstract {
		Set<Phone__c> mobiles = new Set<Phone__c>(); // Mobile numbers to processes
		Set<Phone__c> phones  = new Set<Phone__c>(); // Phone numbers to processes

        public override void process(SObject record) {
            Phone__c phone = (Phone__c) record;

            if (phone != null) {
                if (phone.Type__c == 'Mobile' || phone.Type__c == 'Undefined') {
					mobiles.add(phone);
                } else {
					phones.add(phone);                    
                }
            }  
        }

		public override void process(SObject record, SObject oldRec) {
            Phone__c oldPhone = (Phone__c) oldRec;
            Phone__c phone = (Phone__c) record;

            if (phone != null) {
                if (phone.Type__c == 'Mobile' || phone.Type__c == 'Undefined') {
                    if (commonUtilities.fieldHasChanged('Name', phone, oldPhone)
                        || commonUtilities.fieldHasChanged('Country_Code__c', phone, oldPhone) 
                        || commonUtilities.fieldHasChanged('Type__c', phone, oldPhone) 
                        || commonUtilities.fieldHasChanged('Key_UID__c', phone, oldPhone)) {
                            mobiles.add(phone);
                        }
                } else {
                    if (commonUtilities.fieldHasChanged('Name', phone, oldPhone)) {
                        phones.add(phone);
                    }
                }
            }
        }

        public override void execute() {
			string phoneNumber;
            if (!mobiles.isEmpty()) {
                for (Phone__c mp : mobiles) {
                    phoneServices.formatPhoneWrapper fpw = phoneServices.initiatePhoneFormat(mp.Name);
                    If (fpw.formatted) {
                        mp.Name = fpw.phoneNumber;
                        mp.country_code__c = fpw.countryCode;
                        if (fpw.countryName!=null) {
                            Country_Attribute__c c = countryServices.getCountry(fpw.countryName);
                            mp.country__c = c?.id;
                        }
                    } else {
                        mp.Name = phoneServices.tidyPhone(mp.name);
                        mp.country_code__c = null;
                        mp.country__c = null;
                    }
            	}
        	}
            
            if (!phones.isEmpty()) {
                for (Phone__c p : phones) {
                    p.name = phoneServices.tidyPhone(p.name);
            	}
        	}
    	}
    }
    
    /**
	 * @description Processes the Rollup Logic
	 */
	public class RollUpLogic extends TriggerAbstract {
		@TestVisible
		private Boolean isRollUpEnabled = Person360Muting__c.getInstance().Enable_Roll_Up__c;
        private Boolean forceRollup     = Person360Muting__c.getInstance().Enable_Force_Rollup__c;
		Set<String> contactIds = new Set<String>();
		/**
		 * @description Retrieves individual records
		 */
		public override void process(SObject record) {
			if (isRollUpEnabled != null && isRollUpEnabled) {
				if (record.get('Contact__c') != null) {
                    contactIds.add((String)record.get('Contact__c'));
                }
			}
		}
		/**
		 * @description Process records on After Update event
		 */
		public override void process(SObject record, SObject oldRec) {
			if (isRollUpEnabled != null && isRollUpEnabled) {
				Phone__c phone = (Phone__c) record;
				Phone__c oldPhone = (Phone__c) oldRec;
				//recItm Roll up logic compare
				if ((forceRollup) 
                 || ( phone.Key_UID__c != oldPhone.Key_UID__c
                     || phone.Name != oldPhone.Name 
                     || phone.Verification_Status__c != oldPhone.Verification_Status__c 
                     || phone.Start_Date__c != oldPhone.Start_Date__c 
                     || phone.Classification__c != oldPhone.Classification__c 
                     || phone.Type__c != oldPhone.Type__c 
                     || phone.Is_Primary__c != oldPhone.Is_Primary__c 
                     || phone.Is_Active__c != oldPhone.Is_Active__c)
                   ) {
					if (record.get('Contact__c') != null) {
                        contactIds.add((String)record.get('Contact__c'));
                    }
				}
			}
		}
		/**
		 * @description Post Processing Logic
		 */
		public override void execute() {
			try{
				if (isRollUpEnabled != null && isRollUpEnabled && contactIds != null && !contactIds.isEmpty()) {
					//Invoke rollup logic
					Person360RollUpServices.invokeRollUp(contactIds, new List<String>{'Phone__c'});
				}
			}
			catch(Exception e){
				LogUtilityException.logException(e);
			}
			finally{
				LogUtilityException.getLimits();
			}

		}
	}
	/**
	 * @description Defaults the Start Date if Blank
	 */
	public class DefaultStartDate extends TriggerAbstract {
		/**
		 * @description Before insert process for Start Date
		 */
		public override void process(SObject record) {
			Person360Helper.setDefaultDate(Phone__c.Start_Date__c, record);
		}
	}
	/**
	 * @description Untoggles Is Primary flag to other records
	 */
	public class TogglePrimary extends TriggerAbstract {
		@TestVisible
		private Set<Id> contactIds = new Set<Id>();
		@TestVisible
		private Set<Id> recordIds = new Set<Id>();

		public TogglePrimary() {}

        public TogglePrimary(Set<Id> pConIds) {
            contactIds = (pConIds != null) ? pConIds : new Set<Id>();
        }

		/**
		 * @description Collects Contact Ids on After Insert
		 */
		public override void process(SObject record) {
			Phone__c phone = (Phone__c)record;
			if (phone.Is_Primary__c == true) {
				contactIds.add(phone.Contact__c);
				recordIds.add(phone.Id);
			}
		}
		/**
		 * @description Collect Contact Ids on After Update
		 */
		public override void process(SObject record, SObject oldRec) {
			Phone__c phone = (Phone__c)record;
			Phone__c oldphone = (Phone__c)oldRec;
			if (phone.Is_Primary__c == true &&
			        phone.Is_Primary__c != oldphone.Is_Primary__c) {
				contactIds.add(phone.Contact__c);
				recordIds.add(phone.Id);
			}
		}
		/**
		 * @description Untoggles Primary flag to false on other records
		 */
		public override void execute() {
			try{
				if (!contactIds.isEmpty()) {
					//Get All Primary excluding Current Records
					List<Phone__c> phones = [
						SELECT Id, Is_Primary__c FROM Phone__c
						WHERE Contact__c IN:contactIds
						AND Id NOT IN:recordIds
						AND Is_Primary__c = TRUE];

					if (phones.size() > 0) {
						//Toggle Primary to False
						for (Phone__c rec : phones) {
							rec.Is_Primary__c = false;
						}
						Triggers.bypass('FindNewPrimary');
						update phones;
						Triggers.clearBypass('FindNewPrimary');
					}
				}
			}
			catch(Exception e){
				LogUtilityException.logException(e);
			}
		}
	}

	/**
	 * @description Processes the Is_Active__c logic
	 */
	public class ToggleIsActive extends TriggerAbstract {
		// Processing Is_Active__c Functionality Class
		Person360ToggleIsActiveHelper helper = new Person360ToggleIsActiveHelper();
		/**
		 * @description Process record on BEFORE INSERT event
		 */
		public override void process(SObject record) {
			helper.init(record);
			helper.evaluateIsActiveFieldValue(record);
		}
		/**
		 * @description Process records on BEFORE UPDATE event
		 */
		public override void process(SObject record, SObject oldRec) {
			Phone__c phone = (Phone__c)record;
			Phone__c oldPhone = (Phone__c)oldRec;
			// Check if new value is different from old value
			if (phone.Start_Date__c != oldPhone.Start_Date__c ||
			        phone.End_Date__c != oldPhone.End_Date__c ||
					phone.Is_Deleted__c != oldPhone.Is_Deleted__c ||
			        phone.Is_Active__c != oldPhone.Is_Active__c) {
				helper.init(phone);
				helper.evaluateIsActiveFieldValue(phone, oldPhone);
			}
		}
	}

	/**
	 * @description GIVEN   Contact record have multiple child phone records
	 *              WHEN    User delete the primary phone record
	 *              THEN    Select the latest phone record
	 *              AND     set the Is_Primary__c to true
	 * @revision
	 * 	JAN.22.2020 Russell Cadapan - refined filter criteria of updated records
	 * 								- moved the calculation logic into PhoneServices class for re-use purposes
	 */
	public class FindNewPrimary extends TriggerAbstract {
		@TestVisible
		private Set<Id> phoneIds = new Set<Id>();
		@TestVisible
		private Set<Id> contactIds = new Set<Id>();

		public FindNewPrimary() {}

        public FindNewPrimary(Set<Id> pConIds) {
            contactIds = (pConIds != null) ? pConIds : new Set<Id>();
        }

		/**
		 * @description Process records on AFTER INSERT and DELETE event
		 */
		public override void process(SObject record) {
			Phone__c phone = (Phone__c)record;

            // Filter out deleted non-primary records. Primary will not change as a result of removing a non-primary.
            if ((trigger.isDelete != true ) || (trigger.isDelete == true && phone.Is_Primary__c == true)){
	            contactIds.add(phone.Contact__c);
            }
		}

		/**
		 * @description Process records on AFTER UPDATE event
		 */
		public override void process(SObject record, SObject oldRec) {
			Phone__c phone = (Phone__c)record;
			Phone__c phoneOld = (Phone__c)oldRec;

			// Check if new value is different from old value (if IsPrimary has changed, if IsActive has changed, or if the phone has been deleted/undeleted)
			if ((phone.Is_Primary__c != phoneOld.Is_Primary__c) || 
                (phone.Is_Active__c != phoneOld.Is_Active__c) || 
                (phone.Is_Deleted__c != phoneOld.Is_Deleted__c)  || 
                (phone.Start_Date__c != phoneOld.Start_Date__c) ||
                (phone.Key_UID__c == null)) {
				contactIds.add(phone.Contact__c);
			}
		}
		/**
		 * @description Perform Post Processing logic
		 */
		public override void execute() {

			// execute service method to calculate which Phone record should be primary
			try {
				if (!contactIds.isEmpty()) {
					PhoneServices.calculatePrimary(contactIds);
				}
			} catch(Exception e) {
                nebula.logger.error('Contact Id data set\r\r + ' + json.serializePretty(contactIds));
                nebula.logger.exception(e.getMessage(), e);
            }
		}
	}
	/**
	 * @description Processes the Is_Active__c logic
	 */
	public class SetIsActiveEndDate extends TriggerAbstract {
		/**
		 * @description Process records on BEFORE UPDATE event
		 */
		public override void process(SObject record, SObject oldRec) {
			Phone__c rec = (Phone__c)record;
			Phone__c recOld = (Phone__c)oldRec;
			// Check if new value is different from old value
			if (rec.Is_Active__c &&
			        rec.End_Date__c != null &&
			        rec.Is_Active__c != recOld.Is_Active__c) {
				rec.End_Date__c = null;
			}else if (rec.Is_Active__c == false &&
			        rec.Is_Active__c != recOld.Is_Active__c) {
				rec.End_Date__c = Date.today();
			}
		}
	}

    public class PopulateHash extends TriggerAbstract {
		/**
		 * @description Process record on BEFORE INSERT event
		 */
		public override void process(SObject record) {
			Phone__c recItm = (Phone__c)record;
            if (recItm.type__c == 'Mobile' || recItm.type__c == 'Undefined') {
                recItm.Name = phoneServices.formatPhone(recItm.Name);
            }
            Set<String> keySet = phoneServices.buildPhoneKeySet(recItm);
			//Populate Hash Id
			recItm.Key_UID__c = Person360Helper.generatePerson360Key(keySet);
		}
		/**
		 * @description Process records on BEFORE UPDATE event
		 */
		public override void process(SObject record, SObject oldRec) {
			Phone__c recItm = (Phone__c)record;
			Phone__c oldrecItm = (Phone__c)oldRec;
			// Has anything important changed?
            if (String.isNotBlank(recItm.Name)) {
			    if ((recItm.Contact__c != oldrecItm.Contact__c) ||
			        (recItm.Type__c != oldrecItm.Type__c) ||
			        (recItm.Name != oldrecItm.Name) || 
               		(oldrecItm.Key_UID__c == null)) {

                    // The phone number must be reformatted, which includes the possibility of adding a country code etc., before the hash is generated 
                    if (recItm.type__c == 'Mobile' || recItm.type__c == 'Undefined') {
                        recItm.Name = phoneServices.formatPhone(recItm.Name);
                    }
                    Set<String> keySet = phoneServices.buildPhoneKeySet(recItm);
                    // Replace the Hash with new values
                    recItm.Key_UID__c = Person360Helper.generatePerson360Key(keySet);
                }
            }
		}
	}
    
	/**
	 * @description Check Record Is Active and perform necessary defaults
	 */
	public class CheckIsActive extends TriggerAbstract {
		/**
		 * @description Before insert process
		 */
		public override void process(SObject record) {
			Phone__c phone = (Phone__c) record;
			resetPrimary(phone);
		}

		/**
		 * @description Before update process
		 */
		public override void process(SObject record, SObject oldRecord) {
			Phone__c phone = (Phone__c) record;
			resetPrimary(phone);
		}

		private void resetPrimary(Phone__c phoneRecord){
			if(!phoneRecord.Is_Active__c && phoneRecord.Is_Primary__c){
				phoneRecord.Is_Primary__c = false;
			}
		}
	}

	/**
	 * @description Process for re-parenting Phone records to a different Channel.
	 * 	This is mainly when  Channel record got deleted from source (Callista)
	 */
	public class FindNewParentChannel extends TriggerAbstract {

		List<Phone__c> phoneList = new List<Phone__c>();
		List<Phone__c> phoneToFilterList = new List<Phone__c>();
		Set<Id> contactIds = new Set<Id>();

		/**
		 * @description On before insert, find new parent channel if :
		 * 	- Phone is not Active and
		 * 	- Channel is not null (to know the source / original parent channel)
		 */
		public override void process(SObject record) {
			Phone__c phoneRec = (Phone__c) record;
			if(!phoneRec.Is_Active__c && phoneRec.Channel__c != null) {
				phoneList.add(phoneRec);
			}
		}

		/**
		 * @description On before update, find new parent channel if :
		 * 	- Phone is not Active and
		 * 	- Channel is not null and has changed
		 */
		public override void process(SObject record, SObject oldRecord) {
			Phone__c newPhone = (Phone__c) record;
			Phone__c oldPhone = (Phone__c) oldRecord;

			if(!newPhone.Is_Active__c
			   && CommonUtilities.fieldHasChanged('Is_Active__c', newPhone, oldPhone)
			   && newPhone.Channel__c != null)
			{
				if (newPhone.Contact__c != null) {
                    contactIds.add(newPhone.Contact__c);
                }
                phoneToFilterList.add(newPhone);
			}
		}

		public override void execute() {
			if (!phoneToFilterList.isEmpty() && !contactIds.isEmpty()) {
	            Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id, Is_Student__c FROM Contact WHERE Id IN: contactIds]);
                if (!contactMap.isEmpty()) {
                    Map<Id,Phone__c> phoneMap  = new Map<Id, Phone__c>([select id from phone__c where id in :phoneToFilterList and channel__r.is_active__c = true]);
                    for (Phone__c loopPhone : phoneToFilterList) {
                        // Acceptance Criteria:
                        // A contact point of a non-student with source=Callista can be end-dated
                        // and remains end-dated despite an active Channel (lookup) record, i.e. the email remains active in the Channel record.
                        // This is to prevent find new channel when contact point end dated for non-student
                        if (phoneMap.containsKey(loopPhone.id)
                            && contactMap.containsKey(loopPhone.Contact__c)
                            && contactMap.get(loopPhone.Contact__c).Is_Student__c == false
                            && loopPhone.Source__c == 'Callista') {
                            continue;
                        } else {
                            phoneList.add(loopPhone);
                        }
                    }
                    if(!phoneList.isEmpty()) {
                        Set<String> channelSourceFields = new Set<String> {
                            'Mobile_Phone__c',
                            'Phone__c',
                            'Phone_2__c'
                        };
                        ChannelEventUtility.findNewContactPointChannel(phoneList, channelSourceFields);
                    }
                }
            }
		}
	}

	/**
     * @description When Contact is not a student and when user selected a primary, do not deselect
     */
    public class EvaluateIfCanSetPrimary extends TriggerAbstract {

        Set<Id> contactIds = new Set<Id>();
        Map<Id, Phone__c> phoneRecords = new Map<Id, Phone__c>();
        Map<Id, List<Phone__c>> conIdAndRecordsMap = new  Map<Id, List<Phone__c>>();
        /**
         * Process record on BEFORE INSERT event
         */
        public override void process(SObject record) {
            Phone__c newPhone = (Phone__c) record;
            if (newPhone.Is_Primary__c == true) {
				Person360Helper.setUserOrSystemToPrimarySetBy(newPhone);
                contactIds.add(newPhone.Contact__c);
                if (!conIdAndRecordsMap.containsKey(newPhone.Contact__c)) {
                    conIdAndRecordsMap.put(newPhone.Contact__c, new List<Phone__c>{newPhone});
                } else {
                    conIdAndRecordsMap.get(newPhone.Contact__c).add(newPhone);
                }
            }
        }
        /**
         * @description Process records on BEFORE UPDATE event
         */
        public override void process(SObject record, SObject oldRecord) {
            Phone__c newPhone = (Phone__c) record;
            Phone__c oldPhone = (Phone__c) oldRecord;
            if (newPhone.Is_Primary__c != oldPhone.Is_Primary__c && newPhone.Is_Primary__c == true) {
				Person360Helper.setUserOrSystemToPrimarySetBy(newPhone);
                contactIds.add(newPhone.Contact__c);
                phoneRecords.put(newPhone.Id, newPhone);
                if (!conIdAndRecordsMap.containsKey(newPhone.Contact__c)) {
                    conIdAndRecordsMap.put(newPhone.Contact__c, new List<Phone__c>{newPhone});
                } else {
                    conIdAndRecordsMap.get(newPhone.Contact__c).add(newPhone);
                }
			}
			// Always set newPhone.Primary_set_by__c to blank when newPhone.Is_Primary__c == false
            else if (newPhone.Is_Primary__c == false) {
                newPhone.Primary_set_by__c = '';
            }
        }

        public override void execute() {
            if(!contactIds.isEmpty() && !phoneRecords.isEmpty()) {
                for (Contact con : [SELECT Id, Is_Student__c,
                                    (SELECT Id, Is_Primary__c, Primary_set_by__c FROM Phones__r WHERE Is_Active__c = true AND Is_Primary__c = true AND Id NOT IN: phoneRecords.keySet())
                                    FROM Contact WHERE Id IN: contactIds]) {
                    Boolean isPrimarySetByUser = false;
                    for(Phone__c iEmail : con.Phones__r) {
                        if (iEmail.Primary_set_by__c == 'user') {
                            isPrimarySetByUser = true;
                            break;
                        }
                    }
                    for (Phone__c sObj : conIdAndRecordsMap.get(con.Id)) {
                        if ((!con.Is_Student__c && isPrimarySetByUser && UserInfo.getUserName().toLowerCase().contains(Person360Helper.automatedProcessUserName))) {
                            sObj.Is_Primary__c = false;
                            sObj.Primary_set_by__c = '';
                        }
                    }
                }
            }
        }
    }
}