/**
 * @author         Martin Cadman 
 * @description    Basic field handling on Emergency Contact object 
 * @revision
 * 21/05/2024      Martin Cadman - Initial version
 * 01/07/2024      Martin Cadman - Add support for channel linking, including an alternative name field
 */
public without sharing class EmergencyContactServices {
    
    Public class manageEmailFields extends TriggerAbstract {
        List <Emergency_Contact__c> ecList = new List<Emergency_Contact__c>();

		// Add records of interest on insert        
        public override void process(SObject record) {
            Emergency_Contact__c ec = (Emergency_Contact__c)record;

            if (ec.Email_Address__c == ec.Alternate_Email_Address__c) {
	            ec.Alternate_Email_Address__c=null;
            }
        }

		// Add records of interest on update
        public override void process(SObject record, SObject oldRec) {
            Emergency_Contact__c ec = (Emergency_Contact__c)record;
 
            if (ec.Email_Address__c == ec.Alternate_Email_Address__c) {
	            ec.Alternate_Email_Address__c=null;
            }
        }

		// Only run in the before context        
        public override void execute() {
        }
    }


    /*
     * @description Apply the contact/phone treatment to the phone fields on the EC record
     */
    Public class managePhoneFields extends TriggerAbstract {
        List <Emergency_Contact__c> ecList = new List<Emergency_Contact__c>();

        /*
         * @description Add records of interest on insert        
         * @param record sObject supplied by the trigger handler
         */
        public override void process(SObject record) {
            Emergency_Contact__c ec = (Emergency_Contact__c)record;

            if (String.isNotBlank(ec.mobile_phone__c) || String.isNotBlank(ec.Alternate_Phone__c)) {
	            ecList.add(ec);
            }
        }

        /*
         * @description Add records of interest on update  
         * @param record sObject supplied by the trigger handler
         * @param oldRec sObject supplied by the trigger handler
         */
        public override void process(SObject record, SObject oldRec) {
            Emergency_Contact__c ec = (Emergency_Contact__c)record;
            Emergency_Contact__c oldec = (Emergency_Contact__c)oldRec;

            if ((String.isNotBlank(ec.mobile_phone__c) && commonUtilities.fieldHasChanged('Mobile_Phone__c', ec, oldec))
             || (String.isNotBlank(ec.Alternate_Phone__c) && commonUtilities.fieldHasChanged('Alternate_Phone__c', ec, oldec))) {
                ecList.add(ec);
            }

        }
        
        public override void execute() {
            phoneServices.formatPhoneWrapper fpw;

            for (Emergency_Contact__c ec : ecList) {
                fpw = phoneServices.initiatePhoneFormat(ec.Mobile_Phone__c);
                if (fpw.formatted) {
                    ec.Mobile_Phone__c=fpw.phonenumber;    
                } else {
                    ec.Mobile_Phone__c=fpw.rawphoneNumber;
                }

                fpw = phoneServices.initiatePhoneFormat(ec.Alternate_Phone__c);
                if (fpw.formatted) {
                    ec.Alternate_Phone__c=fpw.phonenumber;    
                } else {
                    ec.Alternate_Phone__c=fpw.rawphoneNumber;
                }

                if (ec.Alternate_Phone__c==ec.Mobile_Phone__c) {
                    ec.Alternate_Phone__c=null;
                }
            }
        }
    }
    
    /*
     * @description Apply the contact treatment to the name-like fields on the EC record
     */
    Public class manageNameFields extends TriggerAbstract {
        List <Emergency_Contact__c> ecList = new List<Emergency_Contact__c>();
        
        /*
         * @description Add records of interest on insert  
         * @param record sObject supplied by the trigger handler
         */
        public override void process(SObject record) {
            Emergency_Contact__c ec = (Emergency_Contact__c)record;
			ecList.add(ec);
        }
        
        /*
         * @description Add records of interest on update  
         * @param record sObject supplied by the trigger handler
         * @param oldRec sObject supplied by the trigger handler
         */
        Public override void process(SObject record, SObject oldRec) {
            Emergency_Contact__c ec = (Emergency_Contact__c)record;
            Emergency_Contact__c oldec = (Emergency_Contact__c)oldRec;
            
            if ((String.isNotBlank(ec.First_Name__c) && commonUtilities.fieldHasChanged('First_Name__c', ec, oldec))
                || (String.isNotBlank(ec.Last_Name__c) && commonUtilities.fieldHasChanged('Last_Name__c', ec, oldec))
                || (String.isNotBlank(ec.Relationship__c) && commonUtilities.fieldHasChanged('Relationship__c', ec, oldec))
                || (String.isNotBlank(ec.Emergency_Contact_Name__c ) && commonUtilities.fieldHasChanged('Emergency_Contact_Name__c', ec, oldec))) {
                    ecList.add(ec);
                }
            
        }
        
        public override void execute() {
            for (Emergency_Contact__c ec : ecList) {
                ec.First_name__c = contactServices.toProperCase(ec.first_name__c);
                ec.Last_name__c = contactServices.toProperCase(ec.last_name__c);
                ec.Emergency_Contact_Name__c = contactServices.toProperCase(ec.Emergency_Contact_Name__c);
                ec.Relationship__c = contactServices.toProperCase(ec.relationship__c);
            }
        }
    }

	/*
	 * @description 
	 * Re-use the contact point approach for generating a unique key
	 * 
	 * Uses Contact Id, Relationship, Firstname, Lastname or the name supplied from Callista
	 */    
    public class PopulateHash extends TriggerAbstract {
        List <Emergency_Contact__c> ecList = new List<Emergency_Contact__c>();

        /*
         * @description Add records of interest on insert  
         * @param record sObject supplied by the trigger handler
         */
        public override void process(SObject record) {
            Emergency_Contact__c ec = (Emergency_Contact__c)record;
			ecList.add(ec);            
        }

        /*
         * @description Add records of interest on update  
         * @param record sObject supplied by the trigger handler
         * @param oldRec sObject supplied by the trigger handler
         */
        public override void process(SObject record, SObject oldrec) {
            Emergency_Contact__c ec = (Emergency_Contact__c)record;
            Emergency_Contact__c oldec = (Emergency_Contact__c)oldRec;
            
            if (commonUtilities.fieldHasChanged('First_Name__c', ec, oldec)
                || commonUtilities.fieldHasChanged('Last_Name__c', ec, oldec)
                || commonUtilities.fieldHasChanged('Emergency_contact_name__c', ec, oldec)
                || commonUtilities.fieldHasChanged('Relationship__c', ec, oldec)
                || String.isBlank(ec.key_UID__c)) {
				ecList.add(ec);            
	        }
        }

        public override void execute() {
            Set<String> keySet = new Set<String>();
            
            for (Emergency_Contact__c ec : ecList) {
                keySet = buildECKeySet(ec);
            	ec.Key_UID__c = Person360Helper.generatePerson360Key(keySet);
            }
        }

    }

   /*
	* @description Build the set of fields used to generate the hash key
	* @param ec A populated emergency contact record
    *
    * We strip the fields back to alpha only. Changes of case or the addition of punctuation should not affect the unique key.
	*/    
    public static Set<String> buildECKeySet(Emergency_Contact__c ec) {
		return buildECKeySet(ec.Contact__c, ec.relationship__c, ec.first_name__c, ec.last_name__c, ec.Emergency_Contact_Name__c);
    }

   /*
    * @description Build the set of fields used to generate the hash key
    * @param contactID A Contact Id
    * @param rel The relationship
    * @param fn Firstname - null for Callista supplied ec records
    * @param ln Lastname - null for Callista supplied ec records
    * @param fln The callista emergency contact name
    */
    public static Set<String> buildECKeySet(String contactID, String rel, String fn, string ln, string fln) {
        Set<String> keySet = new Set<String> {contactID};
        keySet.add(rel?.toLowercase().replaceAll('[^a-zA-Z]','').replaceAll('[$sS]', ''));
        keySet.add(fn?.toLowercase().replaceAll('[^a-zA-Z]','')); 
        keySet.add(ln?.toLowercase().replaceAll('[^a-zA-Z]',''));
        keySet.add(fln?.toLowercase().replaceAll('[^a-zA-Z]',''));
		return keySet;
    }
}