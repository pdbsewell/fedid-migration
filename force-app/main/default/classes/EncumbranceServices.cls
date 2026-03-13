/*
 * @author          Martin Cadman
 * @description     Contains all the trigger handlers for Encumbrance
 * @history         12/07/2018 - Martin Cadman - Initial version
 *                  28/03/2019 - Martin Cadman - Support for deleted in source flag
 */
public class EncumbranceServices {
    
    /*
     * Follow the pattern of building a record name from fields supplied (by Callista)
     * 
     * Since we soft delete these records, and an overnight job purges them, we prefix Pending Delete to the record for a delete operation.
     */
    public class PopulateEncumbranceName extends TriggerAbstract {
        Public override void process(sObject rec){
            Encumbrance__c en = (Encumbrance__c)rec;
            en.Name = getUniqueName(en);
        } 
    
        Public override void process(sObject rec, sObject oldRec){
			Encumbrance__c en = (Encumbrance__c)rec;
            Encumbrance__c oen = (Encumbrance__c)oldRec;
            
            // Apart from DIS, none of these fields are expected to be updated
            // If they are updated directly in UniCRM, the unqiue key is not changed automatically
			if (commonUtilities.fieldHasChanged('Person_ID__c', en, oen)
                || commonUtilities.fieldHasChanged('enc_category__c', en, oen)
                || commonUtilities.fieldHasChanged('enc_type__c', en, oen)
                || commonUtilities.fieldHasChanged('eff_type__c', en, oen)
                || commonUtilities.fieldHasChanged('Deleted_In_Source__c', en, oen)) {            
                en.Name = getUniqueName(en);
            }
        } 
    
        // We are only operating in the before context
        public override void execute() {
        }
    }

    // Build a good descriptive name from the Object 
    public static String getUniqueName(Encumbrance__c en) {
        return getUniqueName(en.Person_ID__c, en.enc_category__c , en.enc_type__c, en.eff_type__c, en.Deleted_In_Source__c);
    }
    
    // Build a good descriptive name from the fields 
    public static String getUniqueName(String personId, String encCat, String encType, String effectType, Boolean dis) {
		String name;
        
        if (dis) {
            name = '[Pending Delete] ' + personId;
        } else {
			name = personId;
            if (encCat != null) {name += '/' + encCat;}
            if (encType != null) {name += '/' + encType;}
            if (effectType != null) {name += '/' + effectType;}
        }
        
        return name;
     }
    
    /*
    * All field updates on after triggers
    */
    public class updateFields extends TriggerAbstract {
        public override void execute() {

            Encumbrance__c[] uList;
            // This runs in the 'before' context, so no update is required...
            uList = EncumbranceServices.isActive((List<Encumbrance__c>)Trigger.new);

            // ...unless it's an undelete            
            if (Trigger.isUndelete) {            
                // on one line to full code coverage - update can't tested after an undelete as you can't update a delete record
                if (uList.size() > 0) { update uList; }
            }
        }
    }

   /* 
    * Recalculate the isActive__c flag status of an Encumbrance
    * - only look at the effect dates
    * - expiry date is exclusive
    */
    public static Encumbrance__c[] isActive (Encumbrance__c[] eList){
        Encumbrance__c[] uList = new List<Encumbrance__c>();
        
        try {
            for (Encumbrance__c e: eList) {
    
                // The deleted in source flag is updated by the inbound platform event. It can not be turned off (unchecked) via the platform event.
                // By setting the expired dates here, the isActive flag is processed as usual.
                if (e.deleted_in_source__c == TRUE ) {
                    if (e.eff_expiry_date__c == NULL || e.eff_expiry_date__c > System.today()) {
                        e.eff_expiry_date__c = System.today();
                        e.enc_expiry_date__c = System.today();
                        if (e.eff_start_date__c == NULL) { 
                            e.eff_start_date__c = System.today(); // data tidy up if required.
                        }
                        if (e.enc_start_date__c == NULL) { 
                            e.enc_start_date__c = System.today(); // data tidy up if required.
                        }
                    }
                }
                
                if (e.eff_start_date__c != NULL ) {
                    if (e.eff_start_date__c <= System.today() && (e.eff_expiry_date__c == NULL || e.eff_expiry_date__c > System.today())) {
                        if (!e.isActive__c) {
                            e.isActive__c = TRUE;
                            uList.add(e);            
                        }
                    } else {
                        if(e.isActive__c) {
                            e.isActive__c = FALSE;
                            uList.add(e);            
                        }
                    }
                }
            }
            return uList;
            
        } catch (Exception ex) {
            return null;
        }
}
    
   /*
    * A handler for future dated encumbrances
    * TODO Create a scheduled/batchable version that also implements the hard deletes
    */
    public static void validateisActive() {
        Encumbrance__c[] outList;
        Encumbrance__c[] inList = [SELECT id, eff_start_date__c, eff_expiry_date__c, isActive__c 
                                     FROM Encumbrance__c 
                                    WHERE isActive__c = TRUE 
                                      AND eff_expiry_date__c <= TODAY LIMIT 200];
    
        if (inList.size() > 0) {
            outList = isActive(inList);
            if (outList.size() > 0) update outList;
        }
    }
}