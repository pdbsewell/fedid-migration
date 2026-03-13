/*
 * Generic functions for the support of Unit Set Attempt (created from the ibdUnitSetAttempt integration)
 */
public class UnitSetAttemptServices {
    /**
     * @description prepopulates the Name field with the following format: 
     */
	public class PopulateUnitSetAttemptName extends TriggerAbstract {
        Public override void process(sObject rec){
            Unit_Set_Attempt__c susa = (Unit_Set_Attempt__c)rec;
            susa.Name = getUniqueName(susa);
        } 
    
        Public override void process(sObject rec, sObject oldRec){
			Unit_Set_Attempt__c susa = (Unit_Set_Attempt__c)rec;
            Unit_Set_Attempt__c osusa = (Unit_Set_Attempt__c)oldRec;
            
            // Apart from DIS, none of these fields are expected to be updated
            // If they are updated directly in UniCRM, the unqiue key is not changed automatically
			if (commonUtilities.fieldHasChanged('Person_ID__c', susa, osusa)
                || commonUtilities.fieldHasChanged('Course_Code__c', susa, osusa)
                || commonUtilities.fieldHasChanged('Code__c', susa, osusa)
                || commonUtilities.fieldHasChanged('Deleted_On_Source__c', susa, osusa)) {            
                susa.Name = getUniqueName(susa);
            }
        } 

        // We are only operating in the before context
        public override void execute() {
        }
    }

    /**
	 * @description returns a formatted Unit Attempt Name value
	 * @param ua : Unit Attempt record
	 */
    public static String getUniqueName(Unit_Set_Attempt__c usa) {
        return getUniqueName(usa.Person_ID__c
                           , usa.Course_Code__c
                           , usa.Code__c
                           , usa.Deleted_On_Source__c);
    }
    
    /**
     * @description returns a formatted Unit Attempt Name value
     * @param personId : Person ID of related contact
     * @param courseCd : Course Code
     * @param unitCd : Unit Code
     * @param acadYr : Academic Year
	 * @param teachingPeriod : Semester number
	 * @param dis: deleted on source flag
	*/
    public static String getUniqueName(String personId, String courseCd, String unitSetCd, Boolean dos) {
		String name;

        name = personId + '/' + courseCd + '/' + unitSetCd;

        if (dos) {
             name  = '[Pending Delete] ' + name;
         } 
        return name;
     }

    
}