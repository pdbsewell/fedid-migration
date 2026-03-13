public class UnitOfferingServices {

    private static final String keydelimiter = '_';
    private static final String namedelimiter = '/';

    public class PopulateUnitOfferingName extends TriggerAbstract {

        public override void execute() {
            for(Unit_Offering__c iUO : (List<Unit_Offering__c>) Trigger.new) {
                iUO.Name = getUniqueName(iUO);
                iUO.UO_Unique_key__c = getUniqueKey(iUO);
            }
        }
    }

 	public static String getUniqueName(Unit_Offering__c uo) {
		return getUniqueName(uo.unit_code__c, uo.Unit_Version__c, uo.Academic_Year__c, uo.Teaching_Period__c, uo.Location__c, uo.Unit_Class__c);
    }
    
    public static String getUniqueName(String Unit_Code, String Unit_Version, String Academic_Year, String Teaching_Period, String Location, String Unit_Class) {
    	Return Unit_Code + '-' + Unit_Version + namedelimiter + Academic_Year + namedelimiter + Teaching_Period + namedelimiter + Location + namedelimiter + Unit_Class;
    }
    
    public static String getUniqueKey (ibdUnitAttempt__e iEvent){
        
        return getUniqueKey(iEvent.Unit_Code__c, String.valueOf(Integer.valueOf(iEvent.Unit_Version__c))
                          , iEvent.Calendar_Type__c, iEvent.CI_Sequence_Number__c, iEvent.Location__c, iEvent.Unit_Class__c);
    }

    public static String getUniqueKey(Unit_Offering__c uo) {
		return getUniqueKey(uo.unit_code__c, uo.Unit_Version__c, uo.calendar_type__c, uo.ci_sequence_number__c, uo.Location__c, uo.Unit_Class__c);
    }

    public static String getUniqueKey(String Unit_Code, String Unit_Version, String Calendar_Type, String CI_Sequence_Number, String Location, String Unit_Class) {
    	Return Unit_Code + '-' + Unit_Version + keydelimiter + Calendar_Type + keydelimiter + CI_Sequence_Number + keydelimiter + Location + keydelimiter + Unit_Class;
    }
}