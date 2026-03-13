public class ContactPointAffiliationServices {
    
   /*
    * @author Martin Cadman
    * @date   29.05.2023
    * @description Build a human friend name for a contact point affiliation.
    *              The name consists of fields from the vaious relationships. It is not unique but should be helpful when viewed per contact
    *              CRM Id + Account OrgUnit + Affiliation Type + CPA Type
    */
	public class buildName extends TriggerAbstract {
		Set<id> contactIds = new Set<id>();
		Set<id> affiliationIds = new Set<id>();
	
		public override void process(SObject rec) {
			Contact_Point_Affiliation__c newCPA = (Contact_Point_Affiliation__c)rec;

            records.add(newCPA);
            contactIds.add(newCPA.Contact__c);
            affiliationIds.add(newCPA.Affiliation__c);
        }

        public override void process(SObject rec, SObject oldRec) {
			Contact_Point_Affiliation__c newCPA = (Contact_Point_Affiliation__c)rec;

            records.add(newCPA);
            contactIds.add(newCPA.Contact__c);
            affiliationIds.add(newCPA.Affiliation__c);
        }
        
        public override void execute() {   
            try {
                if (!records.isEmpty()) {
                    Set<Contact_Point_Affiliation__c> sCPA = new Set<Contact_Point_Affiliation__c>((List<Contact_Point_Affiliation__c>)records);

//                    This approach did not work for new records, so individual queries are required
//                    map<id, Contact_Point_Affiliation__c> mCPA = new Map<id, Contact_Point_Affiliation__c>([select id, name, affiliation__c, affiliation__r.recordtype.name, contact__r.crm_id__c, affiliation__r.account__r.Callista_Org_Unit_Code__c, 
//                                                                      type__c, classification__c
//                                                                 from Contact_Point_Affiliation__c where id in :sCPA]);

                    Map<id, Contact> mc = new Map<id, Contact>([select id, crm_id__c from contact where id in :contactIds]);
                    Map<id, Affiliation__c> ma = new Map<id, Affiliation__c>([select id, account__r.Callista_Org_Unit_Code__c, recordtype.name 
                                                 from affiliation__c 
                                                where id IN :affiliationIds]);
                    
                    for (Contact_Point_Affiliation__c uCPA : sCPA) {
                        if (mc.containsKey(uCPA.contact__c)) {
                            uCPA.name = mc.get(uCPA.contact__c).crm_id__c;
                        } 
                        if (ma.containsKey(uCPA.affiliation__c)) {
                            // Org Unit may not always be relevant to the affiliation
                            String ou = ma.get(uCPA.affiliation__c).account__r.Callista_Org_Unit_Code__c;
                            If (String.isNotEmpty(ou)) {
                            	uCPA.name += '/' + ou;
                            }
                        	uCPA.name += '/' + ma.get(uCPA.affiliation__c).recordtype.name;
                        } 

                        if (cpaIsMixed(uCPA)) {
                            uCPA.name += '/Mixed';
                        } else { 
                            uCPA.name += '/' + uCPA.type__c;
                        }
                    }                    
                }
			} catch (Exception ex) {
				logUtilityException.logException(ex);
            }        
        }
    }

   /*
    * @author Martin Cadman
    * @date   29.05.2023
    * @description If the feature switch is enabled, this before-trigger method will generate a unique key based on the affiltion and an individual contact point.
    *              The feature switch also stops the validation rule from firing, limiting the number of CP lookups to one.
    */
	public class buildUniqueId extends TriggerAbstract {
		Feature_Switch__c fs = Feature_Switch__c.getInstance();

		public override void process(SObject rec) {
			if (fs.Generate_UK_for_CPA__c) {
    			records.add(rec);
            }
        }

        public override void process(SObject rec, SObject oldRec) {
			Contact_Point_Affiliation__c newCPA = (Contact_Point_Affiliation__c)rec;
            Contact_Point_Affiliation__c oldCPA = (Contact_Point_Affiliation__c)oldRec;
            
            if (fs.Generate_UK_for_CPA__c) {
                if (CommonUtilities.fieldHasChanged('phone__c', newCPA, oldCPA) ||
                    CommonUtilities.fieldHasChanged('email__c', newCPA, oldCPA) ||
                    CommonUtilities.fieldHasChanged('address__c', newCPA, oldCPA) ||
                    CommonUtilities.fieldHasChanged('affiliation__c', newCPA, oldCPA) ||
                    String.isEmpty(newCPA.composite_key__c)) {
	                records.add(newCPA);
                }
            }
        }

        public override void execute() {   
            try {
                if (!records.isEmpty()) {
                    Set<Contact_Point_Affiliation__c> CPAs = new Set<Contact_Point_Affiliation__c>((List<Contact_Point_Affiliation__c>)records);
                    for (Contact_Point_Affiliation__c cpa : CPAs) {
						cpa.composite_Key__c = String.valueOf(cpa.affiliation__c);
                        Switch on cpaGetType(cpa) {
                            when 'phone' {
								cpa.composite_Key__c += cpa.phone__c;
                            }
                            when 'address' {
								cpa.composite_Key__c += cpa.address__c;
                            }
                            when 'email' {
                                cpa.composite_Key__c += cpa.email__c;
                            }
                            when else {
                                cpa.composite_Key__c = cpa.id; // This will never happen
                            }
                        }
                    }                        
                }
			} catch (Exception ex) {
				logUtilityException.logException(ex);
            }
        }
    }
    
    
    // Helper to determine the type of CPA a record is based
    public static String cpaGetType (Contact_Point_Affiliation__c cpa) {
        if (cpaIsType(cpa,'email__c'))  {return 'email';}
        if (cpaIsType(cpa,'phone__c')) {return 'phone';}
        if (cpaIsType(cpa,'address__c')) {return 'address';}
        return '';
    }

    // Helper to determine the type of CPA a record is based on field population
    public static boolean cpaIsType (Contact_Point_Affiliation__c cpa, String field) {
        if (String.isNotEmpty((String)cpa.get(field))) {
            return true;
		}
        return false;
    }
    
	// Helper to determine if the CPA record mixed (legacy)
    public static boolean cpaIsMixed (Contact_Point_Affiliation__c cpa) {
		Integer n = 0;
        if (cpaIsType(cpa,'email__c'))  {n++;}
        if (cpaIsType(cpa,'phone__c')) {n++;}
        if (cpaIsType(cpa,'address__c')) {n++;}
        return (n>1);
    }
}