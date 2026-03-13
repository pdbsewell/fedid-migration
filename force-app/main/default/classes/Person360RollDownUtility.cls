/**
* @description Utility Class to RollDown Contact to Email, Phone, Address, Social
*
* @author P. Victoriano
* @date 07/03/2019
* 
* @revision 
* 04/05/2020  JM Mapanao - Added logic to whitelist StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION.name()
* 						   so that LogUtilityException will not bypass validation rule and create logs
* 13/03/2019	J.Mapanao - Added logic for not inserting grouptype with no changes
* 30/11/2019	Stefan Scheit - Added a switch for a forced rolldown
* 01/04/2022	Tom Gangemi   - Preferred First Name changes
*       2022	Martin Cadman - Added mobile phone formatting
* 23/01/2023	Martin Cadman - Split phone saving for mobile and non-mobile
* 06/02/2024	Martin Cadman - Remove duplicate phone numbers from roldown
* 05/03/2024	Jitender Padda - PFN bypass for MUM Staff contacts
* 20/03/2024	Martin Cadman - Chillax - bypass of a bypass added
* 10/10/2024    Martin Cadman - Updated removeUnchanged to use commonutilities.valueDiff to ensure case sensitive comparisons
*
**/
public virtual class Person360RollDownUtility {
    //Static variables that retain values on context
    @TestVisible
    private static List<Person_360_Mapping__mdt> mappingConfigs {get; set;}
    @TestVisible
    private static Map<String, Set<String>> sObjApiFieldApiMap {get; set;} // e.g Key = Name__c, Value = {First_Name__c, Last_Name__c, Title__c}
    @TestVisible
    private static Map<String, List<Person_360_Mapping__mdt>> groupTypeMap {get; set;}    
    
    private static final String EVENTTAG = 'Person360 Rolldown';

    //Setting to force a rolldown when values on Contact have NOT changed (force a copy/rolldown from Contact to ContactPoint objects i.e. Address__c, Email__c, Phone__c)
    private final Boolean isForceRolldownEnabled = Person360Muting__c.getInstance().Enable_Force_Rolldown__c;
    private final Boolean isRelaxed = Person360Muting__c.getInstance().Relax_Rollup_Bypass__c; // Added as a tactical work-around to faciliate a 'forced rollup'

    //Instantiated variables
    @TestVisible
    private Map<Id, Person360DAO> mapContactPerson {get; set;}
    @TestVisible
    private Map<Id, Contact> mExistingContactPerson {get; set;}
    @TestVisible
    private Map<String, Boolean> groupTypeAndHasAnyChangeMap {get; set;}
    @TestVisible
    private List<String> saveErrors {get; set;}

    // Set of ContactPoint QualifiedApiNames that will be bypassed
    private Set<String> bypassedContactPoints;

    //public variables
    public Map<Id, Contact> oldMap {get; set;}

    public Map<String, Address__c> mapKeyToAddress {get; set;}
    public Map<String, Phone__c> mapKeyToPhone {get; set;}
    public Map<String, Email__c> mapKeyToEmail {get; set;}
    private Map<String, Name__c> existingNamesByUID;

    //Constructor
    public Person360RollDownUtility() {

        mapContactPerson = new Map<Id, Person360DAO>();
        mExistingContactPerson = new Map<Id, Contact>();
        mapKeyToAddress = new Map<String, Address__c>();
        mapKeyToPhone = new Map<String, Phone__c>();
        mapKeyToEmail = new Map<String, Email__c>();
        oldMap = new Map<Id, Contact>();
        groupTypeAndHasAnyChangeMap = new Map<String, Boolean>();
        saveErrors = new List<String>();
        bypassedContactPoints = new Set<String>();
        existingNamesByUID  = new Map<String, Name__c>();

        //Init MDT mapping
        retrievePersonRollDownMapping();
    }

    /**
     * @description initialize Contact to Person360 for rolldown logic
     * @param  lcontacts The lits of contacts to process
     */
    public virtual void initialize360(List<Contact> lcontacts) {
        if (lcontacts != null) {
            if (!lcontacts.isEmpty()) {
                retrievePerson360ExistingRelatedRecords(lcontacts);

                Person360Muting__c muteSetting = Person360Muting__c.getInstance();
                if(muteSetting.Name_Roll_Down_Bypass__c != null &&
                    muteSetting.Name_Roll_Down_Bypass__c.containsIgnoreCase(UserInfo.getUserName()))
                {
                    this.bypassedContactPoints.add('Name__c');
                }

                for (Contact contact : lcontacts) {
                    Person360DAO dao = new Person360DAO();
                    //Check if DAO is already existing
                    if (mapContactPerson.containsKey(contact.Id)) {
                        dao = mapContactPerson.get(contact.Id);
                    }
                    //Start Processing
                    startMapping(dao, contact);
                    if (oldMap != null && !oldMap.isEmpty()) {
                        // Remove unchanged
                        removeUnchanged(dao, contact);
                    }

                    //formatName(dao);
                    formatAddressName(dao);
                    formatPhone(dao);

                    //Dao object
                    mapContactPerson.put(contact.Id, dao);
                }
            }
        }
    }

    /**
     * @description Process Records for Saving
     */
    public void processRecords() {
        Map<String, Name__c> names = new Map<String, Name__c>();
        Map<String, Email__c> emails = new Map<String, Email__c>();
        Map<String, Phone__c> phones = new Map<String, Phone__c>();
        Map<String, Address__c> addresses = new Map<String, Address__c>();
        Map<String, Social__c> socials = new Map<String, Social__c>();
        if (!mapContactPerson.isEmpty()) {
            for (Person360DAO dao : mapContactPerson.values()) {
                
                try {
                    //Push Names
                    if (dao.name != null) {
                        new NameTriggerHandler.PopulateHash().process(dao.name);
                        Name__c existingName = existingNamesByUID.get(dao.name.Key_UID__c);
                        if(existingName != null) {
                            // preserve start/end dates
                            if(existingName.Start_Date__c  != null) dao.name.Start_Date__c = existingName.Start_Date__c;
                            if(existingName.End_Date__c  != null) dao.name.End_Date__c = existingName.End_Date__c;  
                        }
                        names.put(dao.name.Key_UID__c, dao.name);
                    }
                } catch (Exception ex) {
                    nebula.logger.error(ex.getMessage(), dao.name).addTag(EVENTTAG);                    
                }

                try {
                    //Push Emails
                    if (!dao.emails.isEmpty()) {
                        for (Email__c email : dao.emails.values()) {
                            //Create Hash Key
                            new EmailTriggerHandler.PopulateHash().process(email);
                            email.Source__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                            if(dao.contactRec.Email_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN){
                                email.Source__c = Constants.CONTACT_POINT_SOURCE_THIRD_PARTY;
                            }
                            
                            // preserve these values from an existing record thru Key UID matching
                            if(mapKeyToEmail.containsKey(email.Key_UID__c)){
                                Date sDate = mapKeyToEmail.get(email.Key_UID__c).Start_Date__c;
                                Date eDate = mapKeyToEmail.get(email.Key_UID__c).End_Date__c;
                                
                                String verifStatus = mapKeyToEmail.get(email.Key_UID__c).Verification_Status__c;
                                String source = mapKeyToEmail.get(email.Key_UID__c).Source__c;

                                // preserve start/end dates
                                if(sDate != null) email.Start_Date__c = sDate;
                                if(eDate != null) email.End_Date__c = eDate;
                                
                                // preserve verification status for Undefined source of address
                                if(dao.contactRec.Email_Verification_Source__c != Constants.CONTACT_POINT_SOURCE_EXPERIAN){
                                    email.Verification_Status__c = verifStatus;
                                    email.Source__c = source;
                                }
                                
                            }
                            emails.put(email.Key_UID__c, email);
                        }
                    }
                } catch (Exception ex) {
                    nebula.logger.error(ex.getMessage(),dao.emails.values()).addTag(EVENTTAG);
                }

                //Push Phones
                try {
                    if (!dao.phones.isEmpty()) {
                        for (Phone__c phone : dao.phones.values()) {
                            if (String.isBlank(phone.Name)) {
			                    nebula.logger.warn('Trying to rolldown an empty phone', phone).addTag(EVENTTAG);
                            } else if (String.isNotBlank(phone.Name.replaceAll('[^0-9]',''))) { // will the value be stripped away to nothing
                                //Create Hash Key
                                new PhoneTriggerHandler.PopulateHash().process(phone);
                                
                                phone.Source__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                                
                                if((phone.Type__c != 'Mobile' && dao.contactRec.Phone_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN) ||
                                   (phone.Type__c == 'Mobile' && dao.contactRec.Mobile_Phone_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN)){
                                       phone.Source__c = Constants.CONTACT_POINT_SOURCE_THIRD_PARTY;
                                   }
                                
                                // preserve these values from an existing record thru Key UID matching
                                if(mapKeyToPhone.containsKey(phone.Key_UID__c)){
                                    Date sDate = mapKeyToPhone.get(phone.Key_UID__c).Start_Date__c;
                                    Date eDate = mapKeyToPhone.get(phone.Key_UID__c).End_Date__c;
                                    
                                    String verifStatus = mapKeyToPhone.get(phone.Key_UID__c).Verification_Status__c;
                                    String source = mapKeyToPhone.get(phone.Key_UID__c).Source__c;
                                    String type = mapKeyToPhone.get(phone.Key_UID__c).Type__c;

                                    // preserve start/end dates
                                    if(sDate != null) phone.Start_Date__c = sDate;
                                    if(eDate != null) phone.End_Date__c = eDate;
                                        
                                    // preserve verification status for Undefined source of address
                                    if((type != 'Mobile' && dao.contactRec.Phone_Verification_Source__c != Constants.CONTACT_POINT_SOURCE_EXPERIAN) ||
                                       (type == 'Mobile' && dao.contactRec.Mobile_Phone_Verification_Source__c != Constants.CONTACT_POINT_SOURCE_EXPERIAN)){
                                           phone.Verification_Status__c = verifStatus;
                                           phone.Source__c = source;
                                           phone.Type__c = type;
                                       }
                                }
                                
                                phones.put(phone.Key_UID__c, phone);
                            }
                        }
                    }
                } catch (Exception ex) {
                    nebula.logger.error(ex.getMessage(),dao.phones.values()).addTag(EVENTTAG);
                }

                //Push Address
                try {
                    if (!dao.addresses.isEmpty()) {
                        for (Address__c address : dao.addresses.values()) {
                            //Format Address Name to Concatenate
                            new AddressTriggerHandler.FormatAddressName().process(address);
                            //Create Hash Key
                            new AddressTriggerHandler.PopulateHash().process(address);
                            
                            address.Classification__c = address.Classification__c;
                            address.Source__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                            
                            if((address.Classification__c == 'Private' && dao.contactRec.Mailing_Address_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN) ||
                               (address.Classification__c != 'Private' && dao.contactRec.Other_Address_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN)){
                                   address.Source__c = Constants.CONTACT_POINT_SOURCE_THIRD_PARTY;
                               }
                            
                            // preserve these values from an existing record thru Key UID matching
                            if(mapKeyToAddress.containsKey(address.Key_UID__c)){
                                Date sDate = mapKeyToAddress.get(address.Key_UID__c).Start_Date__c;
                                Date eDate = mapKeyToAddress.get(address.Key_UID__c).End_Date__c;
                                String classification = mapKeyToAddress.get(address.Key_UID__c).Classification__c;
                                
                                String dpid = mapKeyToAddress.get(address.Key_UID__c).DPID__c;
                                String verifStatus = mapKeyToAddress.get(address.Key_UID__c).Verification_Status__c;
                                String source = mapKeyToAddress.get(address.Key_UID__c).Source__c;
                                
                                // preserve start/end dates
                                if(sDate != null) address.Start_Date__c = sDate;
                                if(eDate != null) address.End_Date__c = eDate;
                                
                                // preserve classification
                                address.Classification__c = classification;
                                
                                // preserve verification status for Undefined source of address
                                if((classification == 'Private' && dao.contactRec.Mailing_Address_Verification_Source__c != Constants.CONTACT_POINT_SOURCE_EXPERIAN) ||
                                   (classification != 'Private' && dao.contactRec.Other_Address_Verification_Source__c != Constants.CONTACT_POINT_SOURCE_EXPERIAN)){
                                       address.DPID__c = dpid;
                                       address.Verification_Status__c = verifStatus;
                                       address.Source__c = source;
                                   }
                            }
                            addresses.put(address.Key_UID__c, address);
                        }
                    }
                } catch (Exception ex) {
                    nebula.logger.error(ex.getMessage(),dao.phones.values()).addTag(EVENTTAG);
                }
                    
                //Push Socials
                if (!dao.socials.isEmpty()) {
                    for (Social__c social : dao.socials.values()) {
                        new SocialTriggerHandler.PopulateHash().process(social);
                        socials.put(social.Key_UID__c, social);
                    }
                }
            }
			
            // Allow rollup to occur as part of a contact point upsert
            // Large volumes could cause CPU limit breaches. 
            if (!isRelaxed) { 
                Triggers.bypass('RollUpLogic');
            } else {
                nebula.logger.fine('Relaxed rollup configuration enabled').addTag(EVENTTAG);
            }

            //Push changes to database
            if (!names.isEmpty()) {
                List<Database.UpsertResult> resultName = Database.upsert(names.values(), Name__c.Key_UID__c, false);
                parseRespponseFails(resultName, names.values());
            }
            if (!emails.isEmpty()) {
                List<Database.UpsertResult> resultEmail = Database.upsert(emails.values(), Email__c.Key_UID__c, false);
                parseRespponseFails(resultEmail, emails.values());
            }
            
            // Split phone types and save Mobiles last. This will generally result in the mobile becoming the primary as there will be a slightly more recent created date/time
            if (!phones.isEmpty()) {
                map<string, Phone__c> mobiles = new map<string, Phone__c>();
                map<string, Phone__c> other   = new map<string, Phone__c>();
                
                for (Phone__c p : phones.values()) {
                    if (p.Type__c == 'Mobile') {
                        mobiles.put(p.name+p.contact__c, p);
                    } else {
                        other.put(p.name+p.contact__c, p);
                    }
                }

                // Removes a phone number from the rolldown if it's the same as the mobile
                // At the moment this is will only happen if the numbers are exactly the same and are rolled down together (i.e. changed at the same time)
                for (Phone__c p : other.values()) {
					if (mobiles.containsKey(p.name+p.contact__c)) {
                        other.remove(p.name+p.contact__c);
                    }                    
                }
                
                List<Database.UpsertResult> resultPhone;
                
                if (!other.isEmpty()) {
                    resultPhone = Database.upsert(other.values(), Phone__c.Key_UID__c, false);
                    parseRespponseFails(resultPhone, other.values());
                }

                if (!mobiles.isEmpty()) {
                    resultPhone = Database.upsert(mobiles.values(), Phone__c.Key_UID__c, false);
                    parseRespponseFails(resultPhone, mobiles.values());
                }
            }

            if (!addresses.isEmpty()) {
                List<Database.UpsertResult> resultAdd = Database.upsert(addresses.values(), Address__c.Key_UID__c, false);
                parseRespponseFails(resultAdd, addresses.values());
            }
            if (!socials.isEmpty()) {
                List<Database.UpsertResult> resultSocial = Database.upsert(socials.values(), Social__c.Key_UID__c, false);
                parseRespponseFails(resultSocial, socials.values());
            }
            //
            Triggers.clearBypass('RollUpLogic');
        }
		nebula.logger.saveLog();
    }
    
    /**
     * @description
     * Parse response Fails
     * Included the upserted list so contact ids could be logged
     */
    @TestVisible
    private void parseRespponseFails(List<Database.UpsertResult> upsertResult, list<sObject> upsertList) {
        if (upsertResult != null) {
            Database.UpsertResult aResult = null;
            for (Integer i=0; i< upsertResult.size(); i++) {
            	aResult = upsertResult[i];
                //Has failure Capture
                if (aResult.isSuccess() == false) {
                    List<Database.Error> errs = aResult.getErrors();
                    if (errs != null && !errs.isEmpty()) {
                        for (Database.Error er : errs) {
                            nebula.Logger.warn(er.getStatusCode() + '\r' + er.getMessage(), upsertList[i]).addTag(EVENTTAG);
                        }
                        saveErrors.add(errs.get(0).getMessage());
                    }
                }
            }
        }
    }
    /**
     * Begin mapping from parsing MDT config with Contact populated fields
     */
    @TestVisible
    private void startMapping(Person360DAO dao, Contact contact) {
        //Retrieve Contact fields populated
        Map<String, Object> populatedContactFieldsByName = contact.getPopulatedFieldsAsMap();
        if (dao != null && mappingConfigs != null) {
            dao.contactRec = contact;

            //Process config mapping
            for (Person_360_Mapping__mdt mdt : mappingConfigs) {
                String sObjName = mdt.RollDownSObject__r.QualifiedApiName;
                String sFldName = mdt.RollDownField__r.QualifiedApiName;

                if (this.bypassedContactPoints.contains(mdt.RollDownSObject__r.QualifiedApiName)) {
                    // Contact point is bypassed
                    continue;
                }

                if (mdt.RollDirection__c == 'Up') {
                    // Mapping is for roll-up only, ignore
                    continue;
                }

//                if(hasFNameSplit && sFldName == 'Middle_Name__c') {
//                    // Don't override the rolldown of split Contact.First_Name__c
//                    continue;
//                }

                // Special case - Preferred First Name not supported for MUM Staff contacts
                if(sObjName == 'Name__c' && mdt.ContactSourceField__c == 'Preferred_Name__c'
                        && Person360Helper.isMUMStaffContact(contact))
                {
                    // Don't map
                    continue;
                }
                
                if (populatedContactFieldsByName.containsKey(mdt.ContactSourceField__c) || mdt.RollDownBlanks__c) {
                    
                    Object conFieldVal = populatedContactFieldsByName.get(mdt.ContactSourceField__c);
                    dao.initialize(sObjName, mdt.Label);

                    if(sObjName == 'Name__c' && mdt.ContactSourceField__c == 'First_Name__c') {
 						if (Person360Helper.nameCanBeSplit(String.valueOf(conFieldVal))) {
                            // Special case - Legal Name is split into First Name and Middle Name
                        	Person360Helper.splitLegalFirstNameIntoFirstAndMiddle(String.valueOf(conFieldVal), dao.name);
                        } else {
                            // Special handling for middle name. It isn't rolled down from, it's the legal first name
                            // This allows a middle name to be removed and honored in the roll up
                            // Staff are different
	                        dao.setFieldValue(sFldName, conFieldVal);
	                        dao.setFieldValue('Middle_Name__c', null);
                        }
                    } else {
                        // Regular field value mapping
                        dao.setFieldValue(sFldName, conFieldVal);
                    }
                    
                    //Fixed Mapping config for Primary - default to Primary Name and Address as compound
                    if ((mdt.IsPrimary__c || sObjName == 'Address__c') && sObjName != 'Name__c') {
                        dao.addFieldValue('Is_Primary__c', mdt.IsPrimary__c);
                    }
                    //Fixed Mapping config for Classification
                    if (String.isNotBlank(mdt.Classification__c)) {
                        dao.addFieldValue('Classification__c', mdt.Classification__c);
                    }
                    //Link contact to Person 360 objects
                    if (contact.Id != null) {
                        dao.addFieldValue('Contact__c', contact.Id);
                    }
                    //Fixed Mapping config for Classification
                    if (String.isNotBlank(mdt.Type__c)) {
                        dao.addFieldValue('Type__c', mdt.Type__c);
                    }
                    // Set Start Date of Name / Email / Phone / Address / Social to TODAY
                    dao.setFieldValue('Start_Date__c', Date.Today());
                    dao.setFieldValue('End_Date__c', null);
                }
                dao.clearCache();
            }
            nebula.logger.saveLog();
        }
    }

    /**
     * @description Remove unchanged records from DAO to avoid unnecessary DML
     */
    @TestVisible
    private void removeUnchanged(Person360DAO dao, Contact newContact) {
        // skip removal of unchanged values if a roll-down is enforced
        if (isForceRolldownEnabled) {
            nebula.logger.fine('Forced rolldown configration enabled',newContact).addTag(EVENTTAG);
            return;
        }
        //Retrieve Contact fields populated
        Map<String, Object> mapConFieldsPopulated = newContact.getPopulatedFieldsAsMap();
        Contact oldContact = oldMap.get(newContact.Id);

        for (String mdtLabel : groupTypeMap.keySet()) {
            Boolean hasAnyChange = false;
            for (Person_360_Mapping__mdt mdt : groupTypeMap.get(mdtLabel)) {
           
                if (mapConFieldsPopulated.containsKey(mdt.ContactSourceField__c) || mdt.RollDownBlanks__c) {
                    // EPCP-3937
                    // Make the comparison case sensitive to 
                    if (CommonUtilities.valueDiff(mapConFieldsPopulated.get(mdt.ContactSourceField__c),oldContact.get(mdt.ContactSourceField__c))){
                        hasAnyChange = true;
                        break;
                    }

                    if (CommonUtilities.valueDiff(mapConFieldsPopulated.get('Middlename'),oldContact.get('Middlename'))){
                        hasAnyChange = true;
                        break;
                    }

                }
            }
            groupTypeAndHasAnyChangeMap.put(mdtLabel, hasAnyChange);
        }

        // Remove Name__c from dao.name when name related fields have no change
        if (dao.name != null && groupTypeAndHasAnyChangeMap.get('Name') != true) {
            dao.name = null;
        }

        // When email related fields from Contact record has no change, remove the record in dao.emails
        if (dao.emails != null) {
            Map<String, Email__c> filteredEmails = new Map<String, Email__c>();
            for (String groupType : dao.emails.keySet()) {
                if (groupTypeAndHasAnyChangeMap.containsKey(groupType) && groupTypeAndHasAnyChangeMap.get(groupType) == true) {
                    filteredEmails.put(groupType, dao.emails.get(groupType));
                }
            }
            dao.emails = filteredEmails;
        }
        // When phone related fields from Contact record has no change, remove the record in dao.phones
        if (dao.phones != null) {
            Map<String, Phone__c> filteredPhones = new Map<String, Phone__c>();
            for (String groupType : dao.phones.keySet()) {
                if (groupTypeAndHasAnyChangeMap.containsKey(groupType) && groupTypeAndHasAnyChangeMap.get(groupType) == true) {
                    filteredPhones.put(groupType, dao.phones.get(groupType));
                }
            }
            dao.phones = filteredPhones;
        }
        // When address related fields from Contact record has no change, remove the record in dao.addresses
        if (dao.addresses != null) {
            Map<String, Address__c> filteredAddress = new Map<String, Address__c>();
            for (String groupType : dao.addresses.keySet()) {
                if (groupTypeAndHasAnyChangeMap.containsKey(groupType) && groupTypeAndHasAnyChangeMap.get(groupType) == true) {
                    filteredAddress.put(groupType, dao.addresses.get(groupType));
                }
            }
            dao.addresses = filteredAddress;
        }
    }

    /**
     * Format the Name field in Name record
     */
    /*
    @TestVisible
    private void formatName(Person360DAO dao) {
        if (dao.name != null) {
            String fullName = Person360Helper.formatName(dao.name.First_Name__c, dao.name.Middle_Name__c, dao.name.Last_Name__c);
            // Check if concatenated fullname is not empty or blank
            if (String.isNotBlank(fullName)) {
                //dao.name.put('Name', fullName);
            }
		}
    }
    */
    
    @TestVisible
    private void formatPhone(Person360DAO dao) {
        if (dao.phones != null) {
            for (Phone__c phoneRec : dao.phones.values()){
                if (phoneRec.type__c == 'Mobile') {
                    phoneRec.put('Name',PhoneServices.formatPhone(phoneRec.name));
                }
            }
        }
    }
    
    /**
     * Format the Name field in Address record
     */
    @TestVisible
    private void formatAddressName(Person360DAO dao) {
        if (dao.addresses != null) {
            for (Address__c addressRec : dao.addresses.values()) {
                String strStreetName = String.isNotBlank((String)addressRec.get('Street_Name__c')) ? (String)addressRec.get('Street_Name__c') : null;
                String strCity = String.isNotBlank((String)addressRec.get('City__c')) ? (String)addressRec.get('City__c') : null;
                String strState = String.isNotBlank((String)addressRec.get('State__c')) ? (String)addressRec.get('State__c') : null;
                String strCountry = String.isNotBlank((String)addressRec.get('Country2__c')) ? (String)addressRec.get('Country2__c') : null;
                String strClassification = String.isNotBlank((String)addressRec.get('Classification__c')) ? (String)addressRec.get('Classification__c') : null;

                String fullAddress = Person360Helper.formatAddressName(strStreetName, strCity, strState, strCountry);
                if (String.isNotBlank(fullAddress)) {
                    //addressRec.put('Name', fullAddress);
                    if(strClassification == 'Private' ) addressRec.put('Is_Primary__c', true);
                }
            }
        }
    }

    /**
     * Retrieve Custom Metadata mapping
     */
    @TestVisible
    private void retrievePersonRollDownMapping() {
        if (mappingConfigs == null) {
            mappingConfigs = [SELECT ContactSourceField__c, RollDirection__c, RollDownBlanks__c,
                                    Label, MasterLabel, IsPrimary__c,
                                    Classification__c, RollUpType__c, Type__c,
                                    RollDownSObject__c, RollDownField__c,
                                    RollDownField__r.QualifiedApiName,
                                    RollDownSObject__r.QualifiedApiName
                                    FROM Person_360_Mapping__mdt
                                    ORDER BY RollDownSObject__c, Label, ContactSourceField__c];
            if (mappingConfigs != null) {
                sObjApiFieldApiMap = new Map<String, Set<String>>();
                groupTypeMap = new Map<String, List<Person_360_Mapping__mdt>>();
                for (Person_360_Mapping__mdt prdmdt : mappingConfigs) {
                    // Get all api name fields of Person 360 objects
                    if (!sObjApiFieldApiMap.containsKey(prdmdt.RollDownSObject__r.QualifiedApiName)) {
                        sObjApiFieldApiMap.put(prdmdt.RollDownSObject__r.QualifiedApiName, new Set<String>());
                    }
                    sObjApiFieldApiMap.get(prdmdt.RollDownSObject__r.QualifiedApiName).add(prdmdt.RollDownField__r.QualifiedApiName);

                    // This contact field values will be use for contact query
                    if (String.isNotBlank(prdmdt.ContactSourceField__c)) {
                        if (!sObjApiFieldApiMap.containsKey('Contact')) {
                            sObjApiFieldApiMap.put('Contact', new Set<String>());
                        }
                        sObjApiFieldApiMap.get('Contact').add(prdmdt.ContactSourceField__c);
                    }

                    // Key = MasterLabel, Value = List<Person_360_Mapping__mdt>()
                    if (!groupTypeMap.containsKey(prdmdt.MasterLabel)) {
                        groupTypeMap.put(prdmdt.MasterLabel, new List<Person_360_Mapping__mdt>());
                    }
                    groupTypeMap.get(prdmdt.MasterLabel).add(prdmdt);
                }
            }
        }
    }
    
    /**
     * Retrieve Person 360 objects related to Contact
     */
    @TestVisible
    private void retrievePerson360ExistingRelatedRecords(List<Contact> lcontacts) {
        if (mappingConfigs != null) {

            String strQuery = 'SELECT Id';

            // Fields to query in Contact sObject
            if (sObjApiFieldApiMap.containsKey('Contact')) {
                for (String sContactFieldApi : sObjApiFieldApiMap.get('Contact')) {
                    strQuery += ',' + sContactFieldApi;
                }
            }

            // Inner query for child Name records of Contact
            if (sObjApiFieldApiMap.containsKey('Name__c')) {
                strQuery += ',(SELECT Id,Is_Primary__c,Start_Date__c,End_Date__c,Key_UID__c';
                for (String sNameFieldApi : sObjApiFieldApiMap.get('Name__c')) {
                    strQuery += ',' + sNameFieldApi;
                }
                strQuery += ' FROM Names__r)';
            }

            // Inner query for child Email records of Contact
            if (sObjApiFieldApiMap.containsKey('Email__c')) {
                strQuery += ',(SELECT Id';
                for (String sEmailFieldApi : sObjApiFieldApiMap.get('Email__c')) {
                    strQuery += ',' + sEmailFieldApi;
                }
                strQuery += ', Key_UID__c, Start_Date__c, End_Date__c, Source__c';
                strQuery += ' FROM Emails__r)';
            }

            // Inner query for child Phone records of Contact
            if (sObjApiFieldApiMap.containsKey('Phone__c')) {
                strQuery += ',(SELECT Id';
                for (String sPhoneFieldApi : sObjApiFieldApiMap.get('Phone__c')) {
                    strQuery += ',' + sPhoneFieldApi;
                }
                strQuery += ', Key_UID__c, Type__c, Start_Date__c, End_Date__c, Source__c';
                strQuery += ' FROM Phones__r)';
            }

            // Inner query for child Address records of Contact
            if (sObjApiFieldApiMap.containsKey('Address__c')) {
                strQuery += ',(SELECT Id';
                for (String sAddressFieldApi : sObjApiFieldApiMap.get('Address__c')) {
                    strQuery += ',' + sAddressFieldApi;
                }
                strQuery += ', Key_UID__c, Classification__c, Start_Date__c, End_Date__c, Source__c';
                strQuery += ' FROM Addresses__r)';
            }

            strQuery += ' FROM Contact WHERE Id IN: lcontacts';
            
            nebula.logger.debug(strQuery,lcontacts).addTag(EVENTTAG);
            mExistingContactPerson = new Map<Id, Contact>( (List<Contact>) Database.query(strQuery));
            //LogUtilityException.debug('trigger: ' + JSON.serializePretty(lcontacts));
            //LogUtilityException.debug('mExistingContactPerson: ' + JSON.serializePretty(mExistingContactPerson));
            // PENGAGE-640
            if(!mExistingContactPerson.isEmpty()) {
                for(Contact c: mExistingContactPerson.values()) {
                    for(Address__c address: c.Addresses__r) {
                        mapKeyToAddress.put(address.Key_UID__c, address);
                    }
                    for(Name__c n :c.Names__r) {
                        existingNamesByUID.put(n.Key_UID__c, n);
                    }
                    for(Phone__c p: c.Phones__r){
                        mapKeyToPhone.put(p.Key_UID__c, p);
                    }
                    for(Email__c e: c.Emails__r){
                        mapKeyToEmail.put(e.Key_UID__c, e);
                    }
                }
            }
        }
    }
}