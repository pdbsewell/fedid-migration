/**
 * @author Nick Guia
 * @description Service class for Unit Attempt object. Contains all the Trigger logic. 
 * @history
 * 	NOV.26.2018 	Nick Guia 	- Created initial version
 *  APR.02.2019     Nick Guia   - Modified IUA Name format
 *                              - Added PopulateUnitAttemptExt, getUniqueName(), getUniqueExt()
 */
public class UnitAttemptServices {

    /**
     * @description prepopulates the Name field with the following format: 
     * PERSON_ID/COURSE_CD/UNIT_CD/CAL_TYPE/ACADEMIC_YEAR
     */
	public class PopulateUnitAttemptName extends TriggerAbstract {
    
        public override void execute() {
            for(Unit_Attempt__c iUA : (List<Unit_Attempt__c>) Trigger.new) {
                iUA.Name = getUniqueName(iUA);
            }
        }
    }
    
    /**
     * @description prepopulates the SUA_External_ID__c field (only if blank) on 
     *  before insert with the following format: PERSON_ID-COURSE_CD-UNIT_CD-CAL_TYPE-CI_SEQUENCE_NUMBER
     */
    public class PopulateUnitAttemptExt extends TriggerAbstract {

        public override void execute() {
            for(Unit_Attempt__c iUA : (List<Unit_Attempt__c>) Trigger.new) {
                if(String.isBlank(iUA.SUA_External_ID__c)) {
                    iUA.SUA_External_ID__c = getUniqueExt(iUA);
                }
            }
        }
    }

    /**
     * @description returns a formatted Unit Attempt Name value
     * @param ua : Unit Attempt record
     */
    public static String getUniqueName(Unit_Attempt__c ua) {
        return getUniqueName(ua.Student_Person_ID__c, 
                            ua.Course_Code__c, 
                            ua.Unit_Code__c, 
                            ua.Teaching_Period__c, 
                            ua.Academic_Year__c,
                            ua.Deleted_In_Source__c);
    }

    
    /**
     * @description returns a formatted Unit Attempt Name value
     * @param personId : Person ID of related contact
     * @param courseCd : Course Code
     * @param unitCd : Unit Code
     * @param acadYr : Academic Year
	 * @param teachingPeriod : Semester number
	 * @param dis: deleted in source flag
	*/
    public static String getUniqueName(String personId, String courseCd, String unitCd, String teachingPeriod, String acadYr, Boolean dis) {
		String name;
        if (dis) {
             name = '[Pending Delete] ' + unitCd + '/' + acadYr + '-' + teachingPeriod;
         } else {
	         name = personId + '/' + courseCd + '/' + unitCd + '/' + acadYr + '-' + teachingPeriod;
         }
        
        return name;
     }

    /**
     * @description returns a formatted Unit Attempt SUA_External_Id__c value
     * @param ua : Unit Attempt record
     */
    public static String getUniqueExt(Unit_Attempt__c ua) {
        return getUniqueExt(ua.Student_Person_ID__c, 
                            ua.Course_Code__c, 
                            ua.Unit_Code__c, 
                            ua.Calendar_Type__c, 
                            ua.CI_Sequence_Number__c);
    }

    /**
     * @description returns a formatted Unit Attempt SUA_External_Id__c value
     * @param personId : Person ID of related contact
     * @param courseCd : Course Code
     * @param unitCd : Unit Code
     * @param calType : Calendar Type
     * @param ciSeq : CI Sequence Number
     */
    public static String getUniqueExt(String personId, String courseCd, String unitCd, 
                                        String calType, String ciSeq) 
    {
        return personId + '-' + courseCd + '-' + unitCd + '-' + calType + '-' + ciSeq;
    }
    
    /**
     * Maintain the results published date field - before context
     * 
     * The field is set to the time when a new outcome date is received.
     * 
     **/
    public class PublishedDate extends TriggerAbstract {
		Set<Unit_Attempt__c> attempts = new Set<Unit_Attempt__c>(); 

		// Insert 
        public override void process(SObject record) {
            Unit_Attempt__c sua = (Unit_Attempt__c)record;
            if (sua.Outcome_Date__c != null) {
	            attempts.add(sua);
            }
        }

        // Update 
		public override void process(SObject record, SObject oldRec) {
            Unit_Attempt__c tobesua = (Unit_Attempt__c)record;
            Unit_Attempt__c asissua = (Unit_Attempt__c)oldRec;

            // Has the date change?
            if(tobesua.Outcome_Date__c != asissua.Outcome_Date__c) {
	            attempts.add(tobesua);
            }
        }

        public override void execute() {
            if (!attempts.isEmpty()) {
                for (Unit_Attempt__c sua : attempts) {    
					sua.Published_Date__c = date.today();
                }
            }
        }
    }
    
    /**
     * 
     * Unit Offerings can arrive in UniCRM after the SUA record. This method allows a simple update on the SUA to align the two records, rather than reimporting
     * 
     **/
    public class assignUnitOffering extends TriggerAbstract {
        Set<Unit_Attempt__c> attempts = new Set<Unit_Attempt__c>(); 
        Map<String, Unit_Offering__c> unitOfferings = new Map<String, Unit_Offering__c>();

        public override void process(SObject record) {
            Unit_Attempt__c sua = (Unit_Attempt__c)record;
            if (sua.Unit_Offering__c == null || (sua.Unit_Offering__c != null && sua.Teaching_Responsibility__c == null )) {
 				unitOfferings.put(unitOfferingServices.getUniqueKey(sua.Unit_Code__c,String.valueOf(Integer.valueOf(sua.Unit_Version__c)),sua.Calendar_Type__c,sua.CI_Sequence_Number__c, sua.Location__c, sua.Unit_Class__c),null); // No offering id at this point, just the unique keys
                attempts.add(sua);
            }
        }

        // Update 
		public override void process(SObject record, SObject oldRec) {
            Unit_Attempt__c tobesua = (Unit_Attempt__c)record;
            Unit_Attempt__c asissua = (Unit_Attempt__c)oldRec;

            // Has the date change or is teaching responsibility empty
            if (tobesua.Unit_Offering__c == null 
               || tobesua.Unit_Offering__c != asissua.Unit_Offering__c 
               || (tobesua.Unit_Offering__c != null && tobesua.Teaching_Responsibility__c == null )) {
				unitOfferings.put(unitOfferingServices.getUniqueKey(tobesua.Unit_Code__c,String.valueOf(Integer.valueOf(tobesua.Unit_Version__c)),tobesua.Calendar_Type__c,tobesua.CI_Sequence_Number__c, tobesua.Location__c, tobesua.Unit_Class__c),null); // No offering id at this point, just the unique keys
 	            attempts.add(tobesua);
            }
        }

        public override void execute() {
			String uoKey;
            if (!attempts.isEmpty() && !unitOfferings.isEmpty()) {
                // All Unit Offerings of interest
                for (Unit_Offering__c uo :[select id, UO_Unique_Key__c, Teaching_Responsibility__c from unit_offering__c where UO_Unique_Key__c in :unitOfferings.keySet()]) {
                    unitOfferings.put(uo.UO_Unique_Key__c, uo);
                }

                for (Unit_Attempt__c sua: attempts) {
					uoKey = UnitOfferingServices.getUniqueKey(sua.Unit_Code__c, String.valueOf(Integer.valueOf(sua.Unit_Version__c)), sua.Calendar_Type__c, sua.CI_Sequence_Number__c, sua.Location__c, sua.Unit_Class__c);
            		if (unitOfferings.get(uoKey)!= null) {
                        sua.Unit_Offering__c = unitOfferings.get(uoKey).id;
                        sua.Teaching_Responsibility__c = unitOfferings.get(uoKey).Teaching_Responsibility__c;
                    }
                }
            }
        }
    }
}