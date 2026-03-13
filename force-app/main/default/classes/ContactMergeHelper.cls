/*******************************************************************************
* @author       Russell Cadapan
* @date         26/11/2020
* @description  Helper class for ContactMergeWizard LWC
* @revision     1.0
*               Relate EPCP-869
*               Paul Victoriano 23.Apr.2021 - add inherited sharing context to get parent class context 
*               Ven Vairavan 24.Apr.2024 - Retrieve CRMID on search contacts [EPCP-3375]
*******************************************************************************/

public inherited sharing class ContactMergeHelper {
    /**
     * mapCompareAccount Merge Field Values from Account
     * @param  masterAcc masterAcc description
     * @param  childAcc  childAcc description
     */
    public static Account mapCompareAccount(Account masterAcc, Account childAcc) {
        Map<String, Schema.DescribeFieldResult> fieldMetadataMap;
        Account_Merge_Mapping__mdt mdtConfig;

        Map<String, Object> masterFieldsToValue = masterAcc.getPopulatedFieldsAsMap();
        Map<String, Object> childFieldsToValue = childAcc.getPopulatedFieldsAsMap();
        //Add fields from Master and Child populated
        Set<String> strFields = new Set<String>();
        strFields.addAll(masterFieldsToValue.keySet());
        strFields.addAll(childFieldsToValue.keySet());
        Map<String, Account_Merge_Mapping__mdt> mdtAccountMapping = new Map<String, Account_Merge_Mapping__mdt>();
        List<Account_Merge_Mapping__mdt> allMDTPersonMapp = Account_Merge_Mapping__mdt.getall().values();
        for (Account_Merge_Mapping__mdt mdt : allMDTPersonMapp) {
            mdtAccountMapping.put(mdt.SObjectField__c, mdt);
        }
        //Retrieve Populated fields of contacts
        if (mdtAccountMapping.isEmpty() == false && strFields.isEmpty() == false) {

            fieldMetadataMap = populateFieldMetadata(Account.getSObjectType().getDescribe(), strFields);

            for (String sFields : strFields) {
                //Reset the Metadata
                mdtConfig = null;
                // booleans will never be null, only true / false.  so separate logic to handle this data type
                Schema.DescribeFieldResult dfr = fieldMetadataMap.get(sFields);
                if (mdtAccountMapping.containsKey(sFields) && sFields != 'Id') {
                    mdtConfig = mdtAccountMapping.get(sFields);
                }
                //Begin Field Compare and populate
                masterAcc = (Account) fileLevelMapping(sFields,
                                                       dfr,
                                                       masterAcc,
                                                       childAcc,
                                                       mdtConfig,
                                                       mdtConfig?.Boolean_AND__c,
                                                       mdtConfig?.No_Null_Check_Values__c);
            }
        }
        return masterAcc;
    }
    /**
     * mapCompareContact Merge Field Values from Contact
     * @param  masterCon masterCon description
     * @param  childCon  childCon description
     */
    public static Contact mapCompareContact(Contact masterCon, Contact childCon) {
        Map<String, Schema.DescribeFieldResult> fieldMetadataMap;
        Person_Merge_Mapping__mdt mdtConfig;

        Map<String, Object> masterFieldsToValue = masterCon.getPopulatedFieldsAsMap();
        Map<String, Object> childFieldsToValue = childCon.getPopulatedFieldsAsMap();
        //Add fields from Master and Child populated
        Set<String> strFields = new Set<String>();
        strFields.addAll(masterFieldsToValue.keySet());
        strFields.addAll(childFieldsToValue.keySet());
        Map<String, Person_Merge_Mapping__mdt> mdtPersonMapping = new Map<String, Person_Merge_Mapping__mdt>();
        List<Person_Merge_Mapping__mdt> allMDTPersonMapp = Person_Merge_Mapping__mdt.getall().values();
        for (Person_Merge_Mapping__mdt mdt : allMDTPersonMapp) {
            mdtPersonMapping.put(mdt.SObjectField__c, mdt);
        }
        //Retrieve Populated fields of contacts
        if (mdtPersonMapping.isEmpty() == false && strFields.isEmpty() == false) {

            fieldMetadataMap = populateFieldMetadata(Contact.getSObjectType().getDescribe(), strFields);

            for (String sFields : strFields) {
                //Reset the Metadata
                mdtConfig = null;
                // booleans will never be null, only true / false.  so separate logic to handle this data type
                Schema.DescribeFieldResult dfr = fieldMetadataMap.get(sFields);
                if (mdtPersonMapping.containsKey(sFields) && sFields != 'Id') {
                    mdtConfig = mdtPersonMapping.get(sFields);
                }
                //Begin Field Compare and populate
                masterCon = (Contact) fileLevelMapping(sFields,
                                                       dfr,
                                                       masterCon,
                                                       childCon,
                                                       mdtConfig,
                                                       mdtConfig?.Boolean_AND__c,
                                                       mdtConfig?.No_Null_Check_Values__c);
            }
        }
        return masterCon;
    }
    @TestVisible
    private static SObject fileLevelMapping(String sFields,
                                            Schema.DescribeFieldResult dfr,
                                            SObject parentSObj,
                                            SObject targSObj,
                                            Object mdtConfig,
                                            Boolean booleanAND,
                                            Boolean noNullCheckValues) {
        if(dfr.isCalculated() == false) {
            if (sFields != 'Id' && dfr.getType() == Schema.DisplayType.BOOLEAN) {
                if(mdtConfig != null) {
                    // Boolean AND
                    if (booleanAND) {
                        if (Boolean.valueOf(parentSObj.get(sFields)) && Boolean.valueOf(targSObj.get(sFields))) {
                            // apply Boolean AND positive logic
                            parentSObj.put(sFields, true);
                        } else {
                            // apply Boolean AND negative  logic
                            parentSObj.put(sFields, false);
                        }
                    } else {
                        // Boolean OR
                        if (Boolean.valueOf(parentSObj.get(sFields)) || Boolean.valueOf(targSObj.get(sFields))) {
                            // apply Boolean AND positive logic
                            parentSObj.put(sFields, true);
                        } else {
                            // apply Boolean AND negative  logic
                            parentSObj.put(sFields, false);
                        }
                    }
                }
            } else if (sFields != 'Id' && dfr.getType() == Schema.DisplayType.MULTIPICKLIST) {

                //Merge All Multi PickList Values Together
                Set<String> strCombined = new Set<String>();
                if(parentSObj.get(sFields) != null) {
                    String strm = (String)parentSObj.get(sFields);
                    strCombined.addAll(strm.split(';'));
                }
                if(targSObj.get(sFields) != null) {
                    String strc = (String)targSObj.get(sFields);
                    strCombined.addAll(strc.split(';'));
                }
                String scomNew = String.join(new List<String>(strCombined),';');
                parentSObj.put(sFields, scomNew);
            } else {
                //Checks if Field is Updateable from describe
                // Boolean isUpdateable = mapConFieldUpdateAccess.get(sFields).getDescribe().isUpdateable();
                //Exclude Id field and non updateable
                // if (mdtPersonMapping.containsKey(sFields) && isUpdateable && sFields != 'Id') {
                //Begin Compare from MDT Mapping ----
                //Replaces Master Values with Child no null checks
                if (mdtConfig != null && noNullCheckValues != null && noNullCheckValues == true) {
                    parentSObj.put(sFields, targSObj.get(sFields));
                } else {
                    //Replaces Null check on Master before replacing with child
                    if (parentSObj.get(sFields) == null && targSObj.get(sFields) != null) {
                        parentSObj.put(sFields, targSObj.get(sFields));
                    }
                }
            }
        }
        return parentSObj;
    }
    /**
     * Retrieves map of Field + DescribeFieldResult for Contact, used to determine actions based on field level metadata
    */
    public static Map<String, Schema.DescribeFieldResult> populateFieldMetadata(
        Schema.DescribeSObjectResult dsor, Set<String> fields) {
        Map<String, Schema.DescribeFieldResult> fieldMetadataMap;
        Map<String, Schema.SObjectField> objectFields = dsor.fields.getMap();

        if (fieldMetadataMap != null) {
            fieldMetadataMap.clear();
        } else {
            fieldMetadataMap = new Map<String, Schema.DescribeFieldResult>();
        }

        // iterate over the requested fields and get the describe info for each one.
        // add it to a map with field name as key
        for(String field : fields) {
            // skip fields that are not part of the object
            if (objectFields.containsKey(field)) {
                Schema.DescribeFieldResult dr = objectFields.get(field).getDescribe();
                // add the results to the map to be returned
                fieldMetadataMap.put(field, dr);
            }
        }
        //
        return fieldMetadataMap;
    }
    /*
    * Method Name: getContacts
    * Description: method to query Contact and Account records
    * Return: List<Contact> - list of contact records and fields
    */
    public static List<Contact> getContacts(String firstName, String lastName, String email, String personId, Set<Id> contactIds) {
        // TO DO: make the field configurable (i.e. fieldset, custom metadata, etc.)
        String searchString = 'SELECT Id, Name, FirstName, LastName, Email, Monash_Email_Address__c, Personal_Email__c, Person_ID__c, Birthdate, Account.Id, Account.Name, LastModifiedDate, MobilePhone, Contact_Profile__c, Account.RecordType.Name,Previous_Monash_ID__c,Exclude_From_Merge__c,CRM_Id__c FROM Contact WHERE ';

        List<String> filterString = new List<String>();

        if(!contactIds.isEmpty()) {
            filterString.add('Id IN: contactIds');
        }
        else {
            // First and Last Name criteria
            if(String.isNotBlank(firstName) && String.isNotBlank(lastName)) {
                String fName = String.escapeSingleQuotes(firstName.trim().replace('*','%'));
                String lName = String.escapeSingleQuotes(lastName.trim().replace('*','%'));

                String fNameFilterOperator = fName.contains('%') ? 'LIKE:' : '=:';
                String lNameFilterOperator = lName.contains('%') ? 'LIKE:' : '=:';

                String nameFilter = '(FirstName '+ fNameFilterOperator+'fName AND LastName '+lNameFilterOperator+'lName)';
                filterString.add(nameFilter);
            }
            // Email criteria
            if(String.isNotBlank(email)) {
                String emailaddress = '%' +email.trim() + '%';
                filterString.add('(Email LIKE:emailaddress OR Monash_Email_Address__c LIKE:emailaddress OR Personal_Email__c LIKE:emailaddress)');
            }
            // Person Id criteria
            if(String.isNotBlank(personId)) {
                String prsnid = personId.trim();
                filterString.add('Person_Id__c =: prsnid');
            }
        }

        // All filter assembly
        for(String s: filterString) {
            searchString += s + ' AND ';
        }
        Set<String> excludedConRecTypes = new Set<String> {
            Constants.CONTACT_PARTNER_RECORDTYPE_DEV_NAME,
            Constants.CONTACT_AGENCY_RECORDTYPE_DEV_NAME
        };
        // Remove last OR string entry
        searchString += 'SAP_Staff_Id__c = NULL AND Record_Type_Developer_Name__c !=: excludedConRecTypes';

        // Database query
        List<sObject> result = Database.query(searchString);

        // Parsing to Contact sObject
        List<Contact> contactRecords = (List<Contact>) result;

        return contactRecords;
    }

    /*
    * Method Name: findDuplicateContacts
    * Description: method to find duplicates and their match confidence
    * Return: Map<Id, Decimal> - map of duplicate contact id and their match confidence in decimal
    */
    public static Map<Id, DuplicateFieldInfo> findDuplicateContacts(Set<Id> contactIds) {
        Map<Id, DuplicateFieldInfo> mapConfidence = new Map<Id,DuplicateFieldInfo>();
        List<Datacloud.FindDuplicatesResult> duplicateResult = Datacloud.FindDuplicatesByIds.findDuplicatesByIds(new List<Id>(contactIds));
        for (Datacloud.FindDuplicatesResult findDupeResult : duplicateResult) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        DuplicateFieldInfo dfi = new DuplicateFieldInfo(
                            matchRecord.getFieldDiffs(),
                            matchResult.getRule(),
                            matchRecord.getMatchConfidence()
                        );
                        if(mapConfidence.containsKey(matchRecord.getRecord().Id)) {
                            DuplicateFieldInfo dfiMP = mapConfidence.get(matchRecord.getRecord().Id);
                            if(dfiMP != null ) {
                                String ruleEx = dfiMP.dupRuleName;
                                Decimal dcmConf = 0;
                                if(dfiMP.matchConfidence != null) {
                                    dcmConf = Decimal.valueOf(dfiMP.matchConfidence);
                                }
                                //Priority Match overrides other Rules
                                if(matchResult.getRule() == 'Contact_Perfect_Match' ||
                                        (matchResult.getRule() == 'Contact_Potential_Match' &&
                                         ruleEx != 'Contact_Perfect_Match' &&
                                         (matchRecord.getMatchConfidence() > dcmConf)) ) {
                                    mapConfidence.put(matchRecord.getRecord().Id, dfi);
                                }
                            }
                        } else {
                            mapConfidence.put(matchRecord.getRecord().Id, dfi);
                        }
                    }
                }
            }
        }

        return mapConfidence;
    }
    /**
     * @description         Find any of the email addresses on the new contact (Personal email, Monash Email & Email) matches
     *                      with any of the email addresses on one or more existing contacts (Personal email, Monash Email & Email)
     * @param               String s_email
     * @return              Set<Id> contactIds
     */
    public static Set<Id> findPotentialDuplicateContactsByEmail(String emailStr) {
        Set<Id> contactIds = new Set<Id>();

        if (String.isNotBlank(emailStr)) {
            List<Email__c> emails = [SELECT Id, Contact__c FROM Email__c WHERE Name =:emailStr];
            if(emails.isEmpty() == false) {
                for(Email__c em:emails) {
                    contactIds.add(em.Contact__c);
                }
            }
        }
        return contactIds;
    }

    /**
     * @description         Find contact who has a Name contact point matching with the first and last name search parameter
     * @param               String s_email
     * @return              Set<Id> contactIds
     */
    public static Set<Id> findPotentialDuplicateContactsByName(String fname, String lname) {
        Set<Id> contactIds = new Set<Id>();

        if (String.isNotBlank(lname)) {
            List<Name__c> names = [SELECT Id, Contact__c FROM Name__c WHERE Last_Name__c =: lname AND First_Name__c =: fname];
            if(names.isEmpty() == false) {
                for(Name__c nm: names) {
                    contactIds.add(nm.Contact__c);
                }
            }
        }
        return contactIds;
    }

    /*
    * Method Name: dateFormatter
    * Description: method to format date field values to String
    * Return: Map<Id, Decimal> - map of duplicate contact id and their match confidence in decimal
    */
    public static String dateFormatter(DateTime inputDate) {
        
        return dateFormatter(inputDate, false);
    }
    public static String dateFormatter(DateTime inputDate, Boolean asFD) {
        String formattedDateString;

        if(inputDate != null) {
            if(asFD){
                formattedDateString = inputDate.format('yyyy MMMMM dd hh:mm aaa');
            }else{
                formattedDateString = inputDate.day() + '/' + inputDate.month() + '/' + inputDate.year();
            }
        }
        return formattedDateString;
    }

    /*
    * Method Name: queryAllObjectFields
    * Description: method to query all fields from an sObject
    * Return: List<sObject> - list of sObjects
    */
    public static List<sObject> queryAllObjectFields(Set<Id> recordIds) {

        // get a sample of record id from the param
        Id rId = new List<Id>(recordIds)[0];

        // access schema
        DescribeSObjectResult describeResult = rId.getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

        // Get all of the fields on the object
        Set<String> fieldNames = new Set<String>();
        for(Schema.SObjectField sfld :fieldMap.values()) {
            Schema.DescribeFieldResult dfr = sfld.getDescribe();
            String fldStrName = dfr.getLocalName();
            //Shift to Describe checking
            if(sfld.getDescribe().isCalculated() == false &&
                    sfld.getDescribe().isUpdateable()) {
                //Validate for Exclusion fields
                if(describeResult.getName() == 'Account' &&
                        excludedAccountFields.contains(fldStrName) == false) {
                    fieldNames.add(fldStrName);
                } else if(describeResult.getName() != 'Account') {
                    fieldNames.add(fldStrName);
                }
            }
        }

        // Build a Dynamic Query String.
        String soqlQuery = 'SELECT '+ String.join(new List<String>(fieldNames),',')  +' FROM ' + describeResult.getName() + ' WHERE Id IN: recordIds';

        // Need to return a generic list of sObject because we don't necessarily know exactly what the object is.
        List<sObject> records = Database.query(soqlQuery);

        //SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, records);

        //return securityDecision.getRecords();
        return records;
    }

    private static Set<String> excludedAccountFields = new Set<String> {'IsPartner','IsCustomerPortal'};

}