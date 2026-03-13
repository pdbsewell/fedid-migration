/**
 * @author          PwC
 * @description     This class contains trigger logic (handler classes) for the Contact object
 * @group           Service Class
 * @revision
 *                  15/10/2020 - Stefan Scheit     - Replace Async_Process__e with Contact_Event__e
 *                  18/05/2020 - J.Mapanao         - Added invokeReCalculateContactPrimaryContactPoints method, rePopulateHashFoAllContactPoints method,
 *                                                 - RePopulateHashFoAllContactPointsWrapper class and ContactServicesException class
 *                  13/02/2020 - Nick Guia         - Updated UpdatePrimaryEmail
 *                  23/01/2020 - Nick Guia         - Created UpdatePrimaryEmail class
 *                  29/10/2019 - P.Victoriano      - Replaced TestHelper.throwError to LogUtilityException.throwError <br/>
 *                  10/10/2019 - Stefan Scheit     - Updated logic to calucate Birthdate_Dup__c field (updateFields) <br/>
 *                  23/07/2019 - MJC               - Removed some of the deceased field validation <br/>
 *                  15/04/2019 - K Liew            - Added new method composeDecomposeBirthDeceasedDates() for project engage <br/>
 *                  17/05/2019 - Kristian Vegerano - Added UpdateSubmissionLocationCountry that will update all the contact's applications on mailing country change <br/>
 *                  20/03/2019 - Nick Guia         - Modified ComputeLeadGrade() to capture return value from invokeLeadGradingProcess() <br/>
 *                  12/02/2019 - Nick Guia         - Added ComputeLeadGrade() <br/>
 *                  16/10/2018 - Stefan Scheit     - Added birthdate_dup__c field population used in matching/duplication rules <br/>
 *                  15/07/2018 - Stefan Scheit     - Removed logic to generate dummy person id on contact on field Person_Id_unique__c (SF-1517) <br/>
 *                  10/07/2018 - Kristian Vegerano - IT account disabled logic added <br/>
 *                  22/05/2018 - Angelo Rivera     - Updated maintainEmailAddressHistory method to include Personal_Email__c (DCXCRM-1669) <br/>
 *                  13/03/2018 - Stefan Scheit     - Updated header and set OwnerId as part of addContactAccounts method (SF-947) <br/>
 *                  22/07/2020 - J.Mapanao         - Added InvokeRollUpContactPointsAsync
 *                  05/04/2021 - Vinothraja        - Added SyncPartnerUser Logic
 *                  22/06/2021 - Martin C          - Added queuable update of Contact lastmodified field (for survivors of a merge)
 *                  22/01/2022 - Inderpal D        - Added method to sync PRM Members (ENGAGEIE-1259)
 *                  10/02/2022 - Inderpal D        - Added method to sync PRM Members (ENGAGEIE-1317)
 *                  15/03/2022 - Martin C          - Added the default population of first_name__c (legal first name)
 *                  27/04/2022 - Martin C          - Removed 'updated' check for citizenship to ensure alignment between citizenship code and citizenship fields
 *                  27/04/2022 - Martin C          - Additional person id check when updating legal first name
 *                  12/05/2022 - Tom Gangemi       - SA-1477 - Update Name__c primary calculation to use AllocatePrimaryRecord
 *                  13/05/2022 - Inderpal D        - Reduce SOQL count PENGAGE-2346
 *                  02/11/2022 - Inderpal D        - Error handling for User Contact Sync PENGAGE-2527
 *                  02/11/2022 - Inderpal D        - Moving User Contact Sync from Queue to PlatFormEvent PENGAGE-2573
 *                  20/01/2023 - Martin C          - Minor change to stop a promoted preferred first name being used as the legal first name for mononymous individuals
 *                  13/02/2023 - Martin C          - Enhanced logic to allow tracking of the CRM Id across contact merges
 *                  13/03/2023 - Peter S           - Logic to recreate Apex managed ContactShares after a contact owner is changed 
 *                  21/03/2023 - Peter S           - Guard to avoid wasting time trying to recreate ContactShares if there are no in-scope contacts
 *                  28/04/2023 - Seeva Singh       - TO Update account record type name on a backend field of contact insertion and update. 
 *                  22/07/2023 - Martin Cadman     - Added muting rolldown option for custom setting specified record type(s)
 *                  12/01/2024 - Jitender Padda    - Updated functionalities to use BindExtended framework and optimised Person360RollDown
 *                  20/01/2024 - Martin Cadman     - Attempt to format all major phone numbers as if they were a mobile number (EPCP-3184)                 
 *                  16/04/2024 - Martin Cadman     - Moved propercase from inbound contact to contact services. This is now applied in the before trigger (EPCP-3354)
 *                  17/04/2024 - Martin Cadman     - Handle legal name changes for updates from SAP (EPCP-3373)
 *                  08/05/2024 - Martin Cadman     - Propercase includes lowercase check as well
 *                  21/09/2024 - Martin Cadman     - Added support to allow SAP to remove a middle name from the given name and have this correctly handled by Person360
 *                  10/10/2024 - Martin Cadman     - Changed maintainAccountName to use fieldHasChanged
 */
public without sharing class ContactServices {

    public static Id CONTACT_PROSPECTIVESTUDENT_REC_TYPE {
        get {
            if (CONTACT_PROSPECTIVESTUDENT_REC_TYPE == null) {
                CONTACT_PROSPECTIVESTUDENT_REC_TYPE = Schema.SObjectType.Contact
                .getRecordTypeInfosByName()
                .get('Prospective Student')
                .getRecordTypeId();
            }
            return CONTACT_PROSPECTIVESTUDENT_REC_TYPE;
        }
        set;
    }   
    
    /**
     * enable copy of info from enquiry onto new contact - allows contact to be saved via global action
     * post insert, copy field level info over to contact IF Copy_from_Enquiry is checked. done via case trigger post attachment of these contact records
     * 
     * Martin Cadman - Logic moved to updateFields method 
     */

    /*
    public class EnableCopyCaseInfoToContact extends TriggerAbstract {
        
        public override void process(SObject record) {
            Contact c = (Contact) record;
            if (c.Copy_from_Enquiry__c && c.lastname == null)
                c.lastname = 'temp_lastname'; // this enables contact to be stored, for post-insert processing.
            // copy name string fields to standard fields - used in global action to bypass standard layout validation
            if (c.First_Name__c > '')
                c.FirstName = c.First_Name__c;
            if (c.Last_Name__c > '')
                c.LastName = c.Last_Name__c;
        }
    }
    */

    /**
     * @description copy mapped fields from web case to contact.
     * Leverages some custom metadata to determine mappings (Case_to_Contact_Field_Mapping__mdt)
     * @param cases list of case records to be assessed for field mapping
     */
    public static void copyMappedFieldsToCaseContacts(List<case> cases) {
        list<contact> contacts = new list<contact>();

        // copy mapped fields from Case to a new contact record where id is set to case.contactId
        List<Case_to_Contact_Field_Mapping__mdt> fieldMappings = new List<Case_to_Contact_Field_Mapping__mdt>(
            [SELECT Id, Case_API_name__c, Contact_Field_API_name__c
            FROM Case_to_Contact_Field_Mapping__mdt where Use_in_webform_mapping__c = true]);
        for (case cse: cases) {
            contact cont = new contact(id = cse.contactId);
            string errMsg = '';
            for (Case_to_Contact_Field_Mapping__mdt fieldMapping : fieldMappings) {
                try {
                    if (cse.get(fieldMapping.Case_API_name__c) != null)
                        cont.put(fieldMapping.Contact_Field_API_name__c, cse.get(fieldMapping.Case_API_name__c));
                } catch (exception ex) {
                    errMsg = ex.getMessage();
                }
            }
            if (errMsg == '') {
                contacts.add(cont);
            } else {
                Exlog.write('ContactServices', 'copyMappedFieldsToCaseContacts', 'mapping to contact', 'This web case couldnt be mapped to contact:' + errMsg + ' -> ' + JSON.serialize(cse));
            }
        }
        
        try {
            //Update contacts
            if (!contacts.isEmpty()) {
            update contacts;
        	}	
        } catch (Exception e) {
            Nebula.Logger.error('ContactServices (copyMappedFieldsToCaseContacts) - An unexpected error occured while trying to update Contact', e);
        }
        Nebula.Logger.saveLog();
    }

    /**
     * @description Monitor email addresses for changes and store on aggregate texct field for matching purposes
     */
    public class maintainEmailAddressHistory extends TriggerAbstract {
        // insert - applies to all records hence not overriden

        // update
        public override void process(SObject record, SObject oldRec) {
            Contact nw = (Contact) record;
            Contact old = (Contact) oldRec;

            if ((
                CommonUtilities.fieldHasChanged('Email', nw, old) ||
                CommonUtilities.fieldHasChanged('Monash_Email_Address__c', nw, old) ||
                CommonUtilities.fieldHasChanged('Applicant_Email_Address__c', nw, old) ||
                CommonUtilities.fieldHasChanged('Personal_Email__c', nw, old) || // 22/05/2018 - Angelo Rivera - Included Personal_Email__c
                CommonUtilities.fieldHasChanged('bulkapi_Email_Addresses__c', nw, old))
            ) {
                records.add(nw);
            }
        }

        public override void execute() {
            List<contact> newContacts = (List<contact>) records;

            for (integer i = 0; i < newContacts.size(); i++) {
                Set<string> addresses = new Set<string>();
                // gather past addresses into a collection
                // stored historical addresses into a set
                if (newContacts[i].Email_addresses__c != null && newContacts[i].Email_addresses__c.indexOf(';') != -1) {
                    for (string address : newContacts[i].Email_addresses__c.split(';'))
                        addresses.add(address);
                }
                // addresses provided by bulk api
                if (
                    newContacts[i].bulkapi_Email_Addresses__c != null &&
                    newContacts[i].bulkapi_Email_Addresses__c.indexOf(';') != -1
                ) {
                    for (string address : newContacts[i].bulkapi_Email_Addresses__c.split(';'))
                        addresses.add(address);
                }
                if (newContacts[i].Email != null)
                    addresses.add(newContacts[i].Email);
                if (newContacts[i].Monash_Email_Address__c != null)
                    addresses.add(newContacts[i].Monash_Email_Address__c);
                if (newContacts[i].Applicant_Email_Address__c != null)
                    addresses.add(newContacts[i].Applicant_Email_Address__c);
                if (newContacts[i].Personal_Email__c != null)
                    addresses.add(newContacts[i].Personal_Email__c); // 22/05/2018 - Angelo Rivera - Included Personal_Email__c
                // aggregate historical or bulk api loaded into a set of single instances of email addresses
                if (!addresses.isEmpty()) {
                    newContacts[i].Email_addresses__c = '';
                    for (string addr : addresses)
                        newContacts[i].Email_addresses__c += addr + ';';
                }
            }
        }
    }
    
    /*******************************************************************************
     * @author       Inderpal
     * @date         2022-01-22
     * @description  Update Contact Team Member when Contact PRM is set or updated (ENGAGEIE-1259)
     *******************************************************************************/
    public class UpdateContactTeamMemberForPRM extends TriggerAbstract {
    
        public override void process(SObject record) {
            Contact newContactRec = (Contact)record;
            // Check if PRM field is added
            if(String.isNotBlank(newContactRec.ucinn_ascendv2__PRM__c)){
                records.add(record);
            }    
        }

        public override void process(SObject record, SObject oldRec) {
            Contact newContactRec = (Contact)record;
            Contact oldContactRec = (Contact)oldRec;
            // Check if PRM field is changed
            if(newContactRec.ucinn_ascendv2__PRM__c != oldContactRec.ucinn_ascendv2__PRM__c){
                records.add(record);
            }
        }
        
        /*
        * @description Run functionality logic
        */
        public override void execute() {   
            Contact cont = null;
            String sPRMRoleName = String.valueOf(Label.ContactPRMRoleName);
            Map<Id, Contact> oldContactMap = (Map<Id, Contact>)Trigger.oldMap;
            List<ContactTeam__c> contTeamMemberLst = new List<ContactTeam__c>();
            List<ContactTeam__c> contTeamDeleteLst  = new List<ContactTeam__c>();
            Set<Id> contIdsforDeletion = new Set<Id>();
            Set<Id> teamMemberIdsforDeletion = new Set<Id>();
            try {
                for(sObject loopRecord : records) {
                    cont = (Contact)loopRecord;
                    // new Contact has a PRM set, need to create a new (PRM) Contact Team Member record
                    if(cont.ucinn_ascendv2__PRM__c != null) {
                        contTeamMemberLst.add(createContactTeamPRM(cont.ucinn_ascendv2__PRM__c, cont.id, sPRMRoleName));  
                    }
                    // old Contact had a (different) PRM set, condition from process(), need to delete old (PRM) or Non PRM Contact Team Member record
                    if(oldContactMap != null ) { 
                        contIdsforDeletion.add(cont.id);
                        teamMemberIdsforDeletion.add(cont.ucinn_ascendv2__PRM__c);
                    }
                }
                // delete old (PRM) contact members first
                if(!contIdsforDeletion.isEmpty()){
                    contTeamDeleteLst.addAll(getContactTeamPRM(contIdsforDeletion, teamMemberIdsforDeletion, sPRMRoleName));
                    if(!contTeamDeleteLst.isEmpty()){
                      delete contTeamDeleteLst;
                    }
                }
                // then, create new (PRM) Contact team members
                if(!contTeamMemberLst.isEmpty()){
                    insert contTeamMemberLst;
                }
            } catch(exception ex){
                nebula.logger.error (ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
        
        /**
         * @description Create the ContactTeamMember record if Contact PRM field
         **/
        private ContactTeam__c createContactTeamPRM(Id UserId, Id contId, String sPRMRoleName) {
            ContactTeam__c contTeam = new ContactTeam__c();
           try{
                contTeam.Role__c = sPRMRoleName;
                contTeam.Team_Member__c = UserId;
                contTeam.Contact__c = contId;
            } catch (exception ex){
                nebula.logger.error (ex.getMessage(), ex);
            }
            return contTeam;
        }
        
        /**
         * @description Method to return a list of (PRM) and Non-PRM ContactTeamMember records for a set of Contact Ids
         */
        private List<ContactTeam__c> getContactTeamPRM(Set<Id> contIds, Set<Id> teamMemberIdsforDeletion, String sPRMRoleName) {
            List<ContactTeam__c> contTeamMemberDeleteList = new List<ContactTeam__c>();
            try{
                contTeamMemberDeleteList = [SELECT Id 
                                            FROM ContactTeam__c 
                                            WHERE Contact__c IN :contIds AND (Role__c = :sPRMRoleName OR Team_Member__c IN :teamMemberIdsforDeletion)];
            }catch(Exception ex){
                nebula.logger.error (ex.getMessage(), ex);
            }
            return contTeamMemberDeleteList;
        }
    }

    /**
     * @description monitor name for changes and store on parent accountto keep in sync
     */
    public class maintainAccountName extends TriggerAbstract {
        Map<Id, String> newAccountNamesById = new Map<Id, String>();
        
        public override void process(SObject newRec, SObject oldRec) {
            Contact newCon = (Contact)newRec;
            Contact oldCon = (Contact)oldRec;

            if (CommonUtilities.valueDiff(newCon.FirstName, oldCon.FirstName)
                || CommonUtilities.valueDiff(newCon.LastName, oldCon.LastName)) {
                String newName = newCon.LastName;
                if (String.isNotBlank(newCon.FirstName) && newCon.FirstName != '-' ){
                    newName = newCon.FirstName + ' ' + newCon.LastName;
                }
                newAccountNamesById.put(oldCon.AccountId, newName);
            }
        }

        public override void execute() {   
            try {
                if (!newAccountNamesById.isEmpty()) {
                    Id accountRT = CommonServices.recordTypeId('Account', AccountServices.ACCOUNT_INDIVIDUAL_TYPE);
                    // only retrieve accts that are people accounts and that have a name change
                    Account[] accountsForUpdate = [SELECT Name FROM Account WHERE Id IN :newAccountNamesById.keySet() AND RecordTypeId = :accountRT];
                    for(Account a :accountsForUpdate) {
                        a.Name = newAccountNamesById.get(a.Id);
                    }
                    if (accountsForUpdate.size() > 0) {
                        update accountsForUpdate;
                    }
                }
            } Catch (Exception ex) {
                nebula.logger.error (ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }

    /**
     * @description copy multiselect values over to free text field
     * update on 6-5-16 - only copies over the [values], not the complete label as there would have
     * been too many characters potentially to fit in 255 char field
     */
    public class copyMultiselectToTextField extends TriggerAbstract{

        public override void process(SObject record) {
            copyField((Contact) record);
        }

        public override void process(SObject record, SObject oldRec) {
            copyField((Contact) record);
        }

        public void copyField(Contact c) {
            string v = (c.Contact_Profile__c != null) ? c.Contact_Profile__c : '';
            c.Contact_Profiles_Selected__c = '';
            while (v != null && v > '' && v.indexOf('[') != -1) {
                c.Contact_Profiles_Selected__c += v.substringBetween('[', ']') + ';';
                v = v.substringAfter(']');
            }
        }
    }
    
    /**
     * @description for contacts inserted with no parent account, adds one of type 'Individual'
     */
    public class AddContactAccounts extends TriggerAbstract {

        public override void execute() {
            List<Account> newAccounts = new List<Account>();
            Map<integer, integer> contactIndex = new Map<integer, integer>(); // maps new account list to original contact record
            List<Contact> contacts = (List<Contact>) records;

            for (integer index = 0; index < contacts.size(); index++) {
                if (contacts[index].AccountId == null) {
                    // insert a new Account prior to Contact creation
                    String firstName = (contacts[index].firstName == null) ? '' : contacts[index].firstName;
                    newAccounts.add(
                        new Account(
                            Name = firstName + ' ' + contacts[index].lastName,
                            OwnerId = contacts[index].ownerId,
                            RecordTypeId = CommonServices.RecordTypeId(
                                'Account',
                                AccountServices.ACCOUNT_INDIVIDUAL_TYPE
                            )
                        )
                    );
                    contactIndex.put(newAccounts.size() - 1, index);
                }
            }

            // if accounts to be added, bulk insert and then place new account ids onto new contacts prior to insertion
            if (!newAccounts.isEmpty()) {
                // no try..catch as accommodating partial fail
                Database.SaveResult[] saveResults = Database.insert(newAccounts, false);
                for (integer index = 0; index < saveResults.size(); index++) {
                    if (LogUtilityException.throwError('accountInsert') || !saveResults[index].isSuccess()) {
                        String errorMessage = '';
                        for (Database.Error err : saveResults[index].getErrors())
                            errorMessage += err.getMessage();
                        // append an error to affected contact record
                        contacts[contactIndex.get(index)].addError(LABEL.CONTACT_INSERT_ERROR + errorMessage);
                    } else {
                        // link new contact record to the newly inserted Account record
                        contacts[contactIndex.get(index)].AccountId = newAccounts[index].Id;
                    }
                }
            }
        }
    }

    /**
     * removes Accounts of type Individual that have been left over from Individual Contact record deletions
     */

    /* Commented out to remove code coverage requirements as this is no longer called from the trigger
    public class cleanUpOrphanAccounts implements Triggers.Handler {
        public void run() {

            Set<Id> oldAccountIds = new Set<Id>();
            for (Contact contact : (List<Contact>)Trigger.old) {
                if (contact.AccountId != null) oldAccountIds.add(contact.AccountId);
            }

            if (!oldAccountIds.isEmpty()) {

                // cull targets to only those accounts that are Individuals
                List<Account> accountsToDelete = [select id
                                                         from Account
                                                         where RecordTypeId = :CommonServices.RecordTypeId('Account', AccountServices.ACCOUNT_INDIVIDUAL_TYPE)
                                                          and Id in:oldAccountIds ];

                // delete allowing for partial failure and reporting if problem
                system.debug('** acts to delete' + accountsToDelete);
                Database.DeleteResult[] deleteResults = Database.delete(accountsToDelete, false);
                String errorMessage = '';
                for (integer index = 0; index < deleteResults.size(); index++) {
                    if (LogUtilityException.throwError('accountDelete') || !deleteResults[index].isSuccess() ) {
                        errorMessage = errorMessage + 'Record Id unable to be deleted:' + accountsToDelete[index].Id + ' ';
                        for (Database.Error err : deleteResults[index].getErrors()) {
                            errorMessage += err.getMessage();
                        }
                    }
                }
                // log error if any occured for post process cleanup by admin
                if (errorMessage != '') ExLog.add('ContactTrigger.onDelete',
                                                      'Account',
                                                      'ContactServices.cleanUpOrphanAccounts',
                                                      errorMessage);
            }
        }
    }
    */
    
    
    /**
     * @description Pulled the phone number field handling out of the updateField methods (part of EPCP-3184)
     **/
    Public class managePhoneFields extends TriggerAbstract {
        
        public override void execute() {
			Map<Id, Contact> oldContactMap = (Map<Id, Contact>)Trigger.oldMap;
            phoneServices.formatPhoneWrapper fpw;
			boolean mpChanged = false;
			boolean phChanged = false;
			boolean hpChanged = false;
			boolean opChanged = false;
			boolean apChanged = false;
			Contact oldCon;
            for (Contact con : (List<Contact>) Trigger.new) {

                // On Insert
                if(oldContactMap == null) {
                    mpChanged = (con.MobilePhone != null);
                    phChanged = (con.Phone != null);
                    hpChanged = (con.HomePhone != null);
                    opChanged = (con.OtherPhone != null);
                    apChanged = (con.AssistantPhone != null);
                } else {
					oldCon = oldContactMap.get(con.Id);
                    mpChanged = commonUtilities.fieldHasChanged('MobilePhone', con, oldCon); 
                    phChanged = commonUtilities.fieldHasChanged('Phone', con, oldCon); 
                    hpChanged = commonUtilities.fieldHasChanged('HomePhone', con, oldCon); 
                    opChanged = commonUtilities.fieldHasChanged('OtherPhone', con, oldCon);
                    apChanged = commonUtilities.fieldHasChanged('AssistantPhone', con, oldCon);                    
                }
                    
                if (mpChanged) {
                    // Format the mobile phone immediately. This means it will be saved in the formatted state and not rely on the roll-up.
                    // This will reduce multiple duplicate record sets being created - a potential against the unformatted number and a perfect for the formatted.
                    fpw = phoneServices.initiatePhoneFormat(con.MobilePhone);
                    if (fpw.formatted) {
                        con.MobilePhone = fpw.phonenumber;    
                    } else {
                        con.MobilePhone = phoneServices.tidyPhone(con.MobilePhone); 
                    }
                } 
                
                // Copy an alpha and punctuation stripped version of the mobile number field for matching/duplication rules
                con.MobilePhone_Dup__c = con.MobilePhone==null?Null:phoneServices.rawFormatPhone(con.MobilePhone);
                
                // This field should be NOT written directly to but often is - it creates an undefined phone record (i.e. not mobile or landline)
                // By formatting it, we can allow rolldown to identify a duplicate number if it is the same as the mobile.
                if (phChanged) {
                    fpw = phoneServices.initiatePhoneFormat(con.Phone);
                    if (fpw.formatted) {
                        con.phone = fpw.phonenumber;    
                    } else {
                        con.phone = phoneServices.tidyPhone(con.phone); 
                    }
                }
                
                if (hpChanged) {
                    con.HomePhone = phoneServices.tidyPhone(con.Homephone); 
                }
                
                if (opChanged) {
                    con.OtherPhone = phoneServices.tidyPhone(con.Otherphone); 
                }
                
                if (apChanged) {
                    con.AssistantPhone = phoneServices.tidyPhone(con.AssistantPhone); 
                }
                
                if (string.isBlank(con.HomePhone)) {con.HomePhone_Verification_Status__c=null;}
                if (string.isBlank(con.Phone)) {con.Phone_Verification_Status__c=null;}
                if (string.isBlank(con.OtherPhone)) {con.Other_Phone_Verification_Status__c=null;}
                if (string.isBlank(con.MobilePhone)) {con.Mobile_Verification_Status__c =null;}                
            }
        }
    }
    
    /**
     * @description Update Email field using Monash/Personal Email field
     * 10/10/2019 - Stefan Scheit - Changed logic to concatenate the Birthdate_Dup__c field
     * 05/30/19   - PV disabled on Roll Up / Down logic
     * 04/12/19   - update contact profile with Donor value
     * 02/02/2024 - Removed the phone field manipulations in to a separate class (part of EPCP-3184)
     */
    public class updateFields extends TriggerAbstract {

        public override void execute() {
            // Retrieve all contact's record type details
            Map<Id, Schema.RecordTypeInfo> contactRecordTypesMapById = Schema.SObjectType.Contact.getRecordTypeInfosById();
            Boolean isRollDownEnabled = Person360Muting__c.getInstance().Enable_Roll_Down__c;
            //If Rolldown is enabled disable this feature - cutover item
            Map<Id, Contact> oldContactMap = (Map<Id, Contact>)Trigger.oldMap;
            Contact oldCon;
            List<string> contactProfileStr = new List<string>();

            for (Contact con : (List<Contact>) Trigger.new) {
                if(oldContactMap != null) { // Update
                    oldCon = oldContactMap.get(con.Id);
                    
                    if(con.contact_profile__c !=null) {
                        contactProfileStr= con.contact_profile__c.split(';');
                    }
                    if(con.ucinn_ascendv2__Lifetime_Fundraising__c > 0 && !contactProfileStr.contains('Donor') && con.contact_profile__c !=null) {
                        con.contact_profile__c=  con.contact_profile__c+'; '+'Donor';
                    }
                    if(con.ucinn_ascendv2__Lifetime_Fundraising__c > 0 && con.contact_profile__c ==null) {
                        con.contact_profile__c='Donor';
                    }
                    if(con.Volunteer_Status__c =='Available' && oldCon.Volunteer_Status__c ==null ){
                        con.Volunteer_Last_Web_Signup_Date__c = system.today();
                    }

                    if(con.Other_Given_Name__c != oldCon.Other_Given_Name__c && con.MiddleName != con.Other_Given_Name__c){
                        con.MiddleName = con.Other_Given_Name__c;
                    }
                    // This would better align to two fields but hope OGN field can be removed completely. 
                    //if (con.MiddleName != con.Other_Given_Name__c) {
                    //    con.Other_Given_Name__c = con.MiddleName;
                    //}

                    // Stamp contact's record type if changed
                    if(con.RecordTypeId != oldCon.RecordTypeId && con.RecordTypeId != null){
                        if(contactRecordTypesMapById.containsKey(con.RecordTypeId)){
                            con.Record_Type_Developer_Name__c = contactRecordTypesMapById.get(con.RecordTypeId).getDeveloperName();
                        }
                    }else if(con.RecordTypeId != oldCon.RecordTypeId && con.RecordTypeId == null){
                        con.Record_Type_Developer_Name__c = '';
                    }else if(con.RecordTypeId != null && con.Record_Type_Developer_Name__c == null){
                        con.Record_Type_Developer_Name__c = contactRecordTypesMapById.get(con.RecordTypeId).getDeveloperName();
                    }
                    //Populate Monash Previous Id with the PersonId only when Previous_Monash_ID__c is null 
                    if (String.isBlank(oldCon.Person_ID_unique__c) && String.isNotBlank(con.Person_ID_unique__c)  && con.Previous_Monash_ID__c == null) {
                        con.Previous_Monash_ID__c = con.Person_ID_unique__c;
                        con.Previously_Studied_at_Monash__c = true;
                    }

                    if(CommonUtilities.fieldHasChanged('Previous_CRM_Ids__c', con, oldcon)) {
                        Environment_Settings__c customSetting = Environment_Settings__c.getInstance();

                        // Contact merging support
                        if (customSetting.Track_CRM_Ids__c) {
                            Set<String> crmid = new Set<String>();
                            if (String.isNotBlank(con.Previous_CRM_Ids__c)) {crmid.addAll(con.Previous_CRM_Ids__c.split(';'));}
                            if (String.isNotBlank(oldCon.Previous_CRM_Ids__c)) {crmid.addAll(oldCon.Previous_CRM_Ids__c.split(';'));}
                            if (!crmid.isEmpty()) {con.Previous_CRM_Ids__c = String.join(new list<String>(crmid), ';');}
                        }
                    }
                    
                    // Due to mapping deficiencies from MIX/SAP, we makes sure these fields are aligned
                    // This is safe to do as SAP is the owner/source and not updates to these records are done directly in UniCRM (EPCP-3373)
                    // Rolldown and rollup will align the fields as business rules dictate
                    if (con.source__c == 'SAP') {
                        // If SAP removes the middle name, the legal name must be aligned. A firstname change won't be detected
                        if (commonUtilities.fieldHasChanged('MiddleName', con, oldCon)) {
                            if (con.middleName == null) {
                                con.First_Name__c = con.FirstName;
                            }
                        }
                        if (commonUtilities.fieldHasChanged('FirstName', con, oldCon)) {
                            con.First_Name__c = con.FirstName; // if SAP gives us a first name change, make it legal
                            con.middlename = null; // Assumption is that SAP gives us the middlename in the first name field for us to extract. Not really required as rollup should handle it but can't hurt.
                        }
                        if (commonUtilities.fieldHasChanged('LastName', con, oldCon)) {
                            con.Last_Name__c = con.LastName; // if SAP gives us a surname change, make it legal
                        }
                    }                    

                } else { // insert
                    // A catch all check for the only mandatory field on Contact
                    if (con.LastName==null && con.Last_Name__c != null) {
                        con.LastName = con.Last_Name__c;
                	}

                    /*
                     * enable copy of info from enquiry onto new contact - allows contact to be saved via global action
                     * post insert, copy field level info over to contact IF Copy_from_Enquiry is checked. done via case trigger post attachment of these contact records
                     * 
                     * Martin Cadman - Logic moved from EnableCopyCaseInfoToContact trigger method
                     */
                    if (con.Copy_from_Enquiry__c && con.lastname == null) {
                        con.lastname = 'temp_lastname'; // this enables contact to be stored, for post-insert processing.
	                }

                    If(con.Volunteer_Status__c =='Available'){
                        con.Volunteer_Last_Web_Signup_Date__c = system.today();    
                    }

                    if(con.Other_Given_Name__c != null && con.MiddleName != con.Other_Given_Name__c){
                        con.MiddleName = con.Other_Given_Name__c;
                    }
                    
                    // Stamp contact's record type
                    if(con.RecordTypeId != null) {
                        if(contactRecordTypesMapById.containsKey(con.RecordTypeId)){
                            con.Record_Type_Developer_Name__c = contactRecordTypesMapById.get(con.RecordTypeId).getDeveloperName();
                        }
                    }
                }
                
                /* Joint Insert and Update Operations */
                
                // Reduce the noise we are sending to Callista/downstream. Only changes the data if it's in CAPITALS or lowercase. 
                con.firstname = toProperCase(con.firstname);
                con.lastname = toProperCase(con.lastname);
                con.middlename = toProperCase(con.middlename);
                con.first_name__c = toProperCase(con.first_name__c);
                con.last_name__c = toProperCase(con.last_name__c);
                con.preferred_name__c = toProperCase(con.preferred_name__c);
                
                // Legal first name added to support duplicate rule changes
                // Legal first & lastname are defaulted as a pair. After this, the value is generally supplied from Callista or my.app.
                // Additional logic to support mononymous names - if it appears that the PFN has been promoted, don't use it as a legal first name.
                if (String.isBlank(con.First_Name__c) && String.isNotBlank(con.FirstName)) {
                    if ((String.isBlank(con.Preferred_Name__c))
                    || (String.isNotBlank(con.Preferred_Name__c) && con.Preferred_Name__c != con.FirstName) // potential mononymous name with promoted PFN
                    || (String.isNotBlank(con.sap_staff_id__c))) { // staff records often have the same FN & PFN. At this stage mononymous staff with PFN aren't supported.
                        con.First_Name__c = con.FirstName;
                        if(String.isnotBlank(con.MiddleName)) {
                            con.First_Name__c += ' ' + con.MiddleName;
                        }
                        con.Last_Name__c = con.LastName;
                    }
                }

                if (String.isBlank(con.Last_Name__c)) {
                    con.Last_Name__c = con.LastName;
                }

                // Copy birthdate value to text field for matching/duplication rules
                if (con.Birthdate != null) {
                    Datetime birthDate = Datetime.newInstance(con.Birthdate.year(), con.Birthdate.month(), con.Birthdate.day());
                    con.Birthdate_Dup__c = birthDate.format('yyyyMMdd');
                } else {
                    con.Birthdate_Dup__c = null;
                }
                                
                if ((String.isBlank(con.Salutation_ERDA__c) && String.isNotBlank(con.Salutation)) || 
                    (con.source__c == 'SAP')) { // Both values should be the same for Staff (EPCP-3373)
                    con.Salutation_ERDA__c = con.Salutation;
                }
                
            }
        }
    }

    /**
     * @author                      Kristian Vegerano, Martin Cadman
     * @description                 Updates the Citizenship field translated from Citizenship code fed from Callista
     *                              Before Context
     *                              If either the Citizenship or Citizenship code fields change, the contact and user record alignment is checked
     */
    public class syncCitizenship extends TriggerAbstract {
        Map<String, String> citizenshipCodeMap = new Map<String, String>{'1'=>'Domestic','2'=>'Domestic','3'=>'Domestic','8'=>'Domestic','4'=>'International','5'=>'International'};
        Map<Id,Contact> srcContacts = new Map<Id, Contact>();
        
        // Insert not required
        /*
        public override void process(SObject rec) {
            Contact c = (Contact)rec;

            // A change to Citizenship_Code__c will override any direct changes to citizenship              
            if (c.Citizenship_Code__c != null || c.Citizenship__c != null) {
                if (citizenshipCodeMap.containsKey(c.Citizenship_Code__c)) {
                    c.Citizenship__c = citizenshipCodeMap.get(c.Citizenship_Code__c);
                } 
                srcContacts.put(c.id,c);
            }
        }
        */

        // Update
        public override void process(SObject rec, SObject oldRec) {
            Contact c = (Contact)rec;
            Contact oc = (Contact)oldRec;

            // A change to Citizenship_Code__c will override any direct changes to citizenship              
            if (c.Citizenship_Code__c != oc.Citizenship_Code__c || c.Citizenship__c != oc.Citizenship__c){
                if (citizenshipCodeMap.containsKey(c.Citizenship_Code__c)) {
                    c.Citizenship__c = citizenshipCodeMap.get(c.Citizenship_Code__c);
                } 
                srcContacts.put(c.id,c);
            }
        }
        
        // Process any contact where a citizenship change has been detected.
        public override void execute() {
            if (srcContacts.size() > 0) {
                try {
                    List<User> updateUserList = new List<User>();
                    
                    for (User loopUser : [SELECT Id, App_Citizenship__c, ContactId
                                          FROM User
                                          WHERE ContactId in :srcContacts.keySet() and ContactId != null ]) {
                                              // Align the citizenship field for the Contacts related user record 
                        if (loopUser.App_Citizenship__c != srcContacts.get(loopUser.Contactid).Citizenship__c) {
                                                  loopUser.App_Citizenship__c = srcContacts.get(loopUser.Contactid).Citizenship__c;
                                                  updateUserList.add(loopUser);
                        }
                    }
                    //Update related users
                    if (updateUserList.size() > 0) {
                        // call queueable class to avoid MIXED_DML_OPERATION by updating User and Contact in one transaction
                        Queueable queueItem = new UserServices.UpdateSobjectsQueueable(updateUserList);
                        ID jobID = System.enqueueJob(queueItem);
                    }
                } catch (Exception ex) {
					nebula.logger.error (json.serializePretty(srcContacts),ex);
                } finally {
                    nebula.logger.saveLog();
                }
            }                    
        }
    }

    /**
     * @author                      Kristian Vegerano
     * @description                 Identify users which are to be activated based on the 'Scheduled_Deactivation__c' property
     */
    public class itAccountDisabled extends TriggerAbstract {
        Set<String> authcateSet = new Set<String>();

        public override void process(SObject record, SObject oldRec) {
            Contact newContact = (Contact) record;
            Contact oldContact = (Contact) oldRec;
            //Define which contacts has its it account disabled
            //Check that the it account disabled has been changed from false to true
            if (newContact.IT_account_disabled__c && newContact.IT_account_disabled__c != oldContact.IT_account_disabled__c && newContact.Authcate__c != null) {
                authcateSet.add(newContact.Authcate__c);
            }
        }

        public override void execute() {
            Environment_Settings__c environmentSettings = Environment_Settings__c.getOrgDefaults();

            //Update matching related contacts
            if (authcateSet.size() > 0) {
                List<User> pendingDeactivateUserList = new List<User>();
                for (User loopUser : [SELECT Id
                                             FROM User
                                             WHERE FederationIdentifier IN :authcateSet AND UserType = 'Standard']) { // ignore portal users
                    loopUser.Pending_Deactivation__c = true;
                    loopUser.Scheduled_Deactivation__c = environmentSettings.Deactivate_User_Delay_Days__c != null ?
                                                         System.NOW().addDays((Integer)environmentSettings.Deactivate_User_Delay_Days__c) :
                                                         System.NOW().addHours(1);
                    pendingDeactivateUserList.add(loopUser);
                }
                //Queue user changes
                if (pendingDeactivateUserList.size() > 0) {
                    //Call queueable class to avoid MIXED_DML_OPERATION by updating User and Contact in one transaction
                    Queueable queueItem = new UserServices.UpdateSobjectsQueueable(pendingDeactivateUserList);
                    ID jobID = System.enqueueJob(queueItem);
                }
            }
        }
    }

    /**
     * @author      Stefan Scheit
     * @description Changes the user's attribute (federationId) based on the Contact's property (authcate__c)
     */
    public class mapMonashIdToUser extends TriggerAbstract {
        Set<Id> s_userUpdateSet = new Set<Id>();

        // map of contact id to user record
        private Map<Id, User> userMap {
            get {
                if (this.userMap != null) {
                    return this.userMap;
                } else {
                    // map ContactId to User record
                    this.userMap = new Map<Id, User>();
                    List<User> userList = [SELECT Id, ContactId, FederationIdentifier FROM User WHERE ContactId IN :Trigger.new];
                    for (User user : userList) {
                        this.userMap.put(user.ContactId, user);
                    }
                    return this.userMap;
                }
            }
            set;
        }

        public override void process(SObject record) {
            if (Trigger.isDelete) {
                return; // Not required to handle? Don't remove the user's federationIdentifier automatically when deleted...
            }

            // This contact is new
            Contact newContact = (Contact) record;
            if (userMap.containsKey(newContact.Id)) {
                s_userUpdateSet.add(newContact.Id);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Contact newContact = (Contact) record;
            Contact oldContact = (Contact) oldRec;
            Boolean hasNameChange = CommonUtilities.valueDiff(newContact.FirstName,oldContact.FirstName) || CommonUtilities.valueDiff(newContact.LastName,oldContact.LastName);
            Boolean hasAuthcateChange = CommonUtilities.valueDiff(newContact.Authcate__c,oldContact.Authcate__c);
            if (hasNameChange || hasAuthcateChange) {
                // This contact has a relavent field change
                if (userMap.containsKey(newContact.Id)) {
                    s_userUpdateSet.add(newContact.Id);
                }
            }
        }

        public override void execute(){
            if (s_userUpdateSet.size() > 0) {
                //Call Platform Event class to avoid MIXED_DML_OPERATION by updating User records in same transaction
                try{ 
                    List<Async_Process__e> eventsToPublish = new List<Async_Process__e>();
                    AsyncProcessPayload payload = new AsyncProcessPayload();
                    payload.put ('s_userUpdateSet', s_userUpdateSet);
                    Async_Process__e evt = new Async_Process__e (Process_Name__c = 'ContactServices.SyncContactDetailsToUser',Parameter__c = payload.serialize());
                    eventsToPublish.add(evt);
                    if(!eventsToPublish.isEmpty()) {
                        EventBus.publish(eventsToPublish);
                    }
                }catch(Exception ex){
					nebula.logger.error(JSON.serializePretty(s_userUpdateSet), ex);
                } finally {
                    nebula.logger.saveLog();
                }
            }
        }
    }
    
    /**
     * @author      Inderpal Dhanoa
     * @description Fire an Platform Event to capture changes the user's attribute (federationId, firtname, Lastname) based on the Contact's property (federationId, firtname, Lastname)
     */
    public class SyncContactDetailsToUser implements IPlatformEventInvocable {
     
        private Set<Id> s_updateContactIds = new Set<Id>();
        
        public void execute(List<AsyncProcessPayload> payload) {
            try {
                initialize(payload);
                run();
            } catch(Exception ex) {
                nebula.logger.error(ex.getMessage(),ex);
            } finally {
                nebula.logger.saveLog();
            }
        }

        private void initialize(List<AsyncProcessPayload> payloads) { 
            if(payloads != null) {
                for(AsyncProcessPayload payload : payloads) {
                    //first, cast the get return of List<Object> into List<Id>
                    List<Object> objList = (List<Object>) payload.get('s_userUpdateSet');
                    //then, instantiate a Set out of it
                    for(Object io : objList) {
                        //parse object to ID
                        s_updateContactIds.add(Id.valueof(String.valueOf(io)));
                    }
                }
            }
        }

        public void run() {
            Database.SaveResult sr;
            List<User> l_userList = [SELECT Id, FirstName, lastName, FederationIdentifier, Contact.Authcate__c, Contact.FirstName, Contact.LastName FROM User WHERE ContactId IN : this.s_updateContactIds];
            for(User usr : l_UserList){
                if(CommonUtilities.valueDiff(usr.Contact.Authcate__c,usr.FederationIdentifier)) { 
                    usr.FederationIdentifier = usr.Contact.Authcate__c; // new value (could be empty/null)
                }
                if(CommonUtilities.valueDiff(usr.Contact.FirstName,usr.FirstName) || CommonUtilities.valueDiff(usr.Contact.lastName,usr.lastName)) {
                    usr.FirstName = usr.Contact.FirstName;
                    usr.LastName = usr.Contact.LastName;
                }
            }
            List<Database.SaveResult> srList = Database.update(l_UserList, false); // allOrNothing=false
            for(Integer i=0; i<srList.size(); i++) {
                sr = srList[i];
                if (!sr.isSuccess()) {
                    nebula.logger.error('Unable to sync Contact details to User',sr);
                }
            }
        }
    }
    
    
   /*
    * @author       Martin Cadman
    * @date         22/06/2021
    * @description  Clear the lastModifiedapi fields on a contact that has survived a merge operation.
    *               To avoid a "SELF_REFERENCE_FROM_TRIGGER, Object is currently in a merge operation" error, the Contact update is queued. 
    * 
    *               The need to delete the lastmodifieddate_api__c after a merge to is ensure that the next update received from Callista will be processed. Depending
    *               on the data conditions it was possible that the updated_on value in Callista was behind the field in the CRM, which effectively blocks updates.
    * 
    *               No check is done to determine is the surviving contact requires these fields to be cleared, so there could be a redundant update. However, merges are done in 
    *               small volumes, so no issues are predicted. A pre-query to determine contact record type and check that the lastmodifieddate_api__c is not null could be included
    *               to filter out records that do not need to be touched.
    * 
    *               Generic code has been added to maintain a list of CRM Ids for all contacts included in the merge.
    * 
    * @revision     1.0
    */
	public class ClearFieldsAfterMerge extends TriggerAbstract {

        // implement interface method
        public override void execute() {
            
            if (trigger.isDelete) {
                if (trigger.isAfter) {
                    String idList;
                    Environment_Settings__c customSetting = Environment_Settings__c.getInstance();

                    Map<Id, Contact> masterRecords = new Map<Id, Contact>();
                    // Loop through the deleted contacts
                    for (Contact record : (List<Contact>) trigger.old) {
                        if (record.MasterRecordId != null) { //this field is populated as part of the database.merge operation
                            if (customSetting.Track_CRM_Ids__c) {
                                if (String.isNotBlank(record.Previous_CRM_Ids__c)) {
                                    idList = record.crm_Id__c + ';' + record.Previous_CRM_Ids__c;
                                } else {
                                    idList = record.crm_Id__c;
                                }
                            } else {
                                idList = record.Previous_CRM_Ids__c; // leave it as-is if tracking is disabled
                            }
                            masterRecords.put(record.MasterRecordId
                                            , new Contact(Id=record.MasterRecordId
                                                        , Previous_CRM_Ids__c = idList
                                                        , lastmodifiedby_api__c = 'Merged at ' + System.Now().format()
                                                        , lastmodifieddate_api__c = DateTime.newInstance(1970, 1, 1, 12, 0, 0))
                                             );
                        }
                    }

                    if (masterRecords.size() > 0 ) {
                        // Update the above fields
                        Queueable queueItem = new UpdateSobjectsQueueable(masterRecords.values(), 0);
                        Id jobID = System.enqueueJob(queueItem);
                    }
                }
            }
        }
    }

   /*
    * @author       Martin Cadman
    * @date         10/07/2021
    * @description  Class supporting the logic to be queued (asynchronously) with retry counter
    * @revision     2.0
    */
    public class UpdateSobjectsQueueable implements Queueable {
        private List<SObject> sobjects;
        private Integer retryCount;

        private List<SObject> sErrors = new List<SObject>();

        public UpdateSobjectsQueueable(List<SObject> sobjects, Integer rt) {
            this.sobjects = sobjects;
            this.retryCount = rt;
        }

        // main method implementing the interface method
        public void execute(QueueableContext context) {
            try {
                Database.SaveResult[] updateResults =  Database.update(this.sobjects, false);

                Database.SaveResult aResult = null;
                for (Integer i=0; i<updateResults.size(); i++) {
                    aResult = updateResults[i];
                    if (!aResult.isSuccess()) {
                        for (Database.Error err : aResult.getErrors()) {
                            Switch on (err.getStatusCode()) {
                                when UNABLE_TO_LOCK_ROW {
                                    if (retryCount < 3) {
                                        sErrors.add(this.sobjects[i]);
                                    } else {
                                        nebula.logger.error(err.getMessage(),this.sobjects[i]);
                                    }
                                }
                                when else {
									nebula.logger.error(err.getMessage(),this.sobjects[i]);
                                }
                            }
                        } 
                    } 
                }

                if (sErrors.size() > 0) {
                    Queueable queueItem = new UpdateSobjectsQueueable(sErrors, retryCount++);
                    Id jobID = System.enqueueJob(queueItem);
                }

            } catch(Exception ex) {
                nebula.logger.error(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }    
    
    public class RecognitionNameUpdate implements Triggers.Handler {
        Set<Id> contactsToUpdateRecognitionName = new Set<Id>();

        public void run() {
            for (Contact contact : (List<Contact>) Trigger.new) {
                Contact oldContact = (Contact) Trigger.oldMap.get(contact.Id);

                if (contact.Ucinn_ascendv2__Is_Recognition_Name_Overridden__c == false &&
                        (contact.Ucinn_ascendv2__Salutation_Preference__c != oldContact.Ucinn_ascendv2__Salutation_Preference__c ||
                         contact.Ucinn_ascendv2__Is_Recognition_Name_Overridden__c != oldContact.Ucinn_ascendv2__Is_Recognition_Name_Overridden__c ||
                         contact.ucinn_ascendv2__Preferred_Spouse__c != oldContact.ucinn_ascendv2__Preferred_Spouse__c)) {

                    contactsToUpdateRecognitionName.add(contact.Id);
                }
            }

            if(!contactsToUpdateRecognitionName.isEmpty()){
                EngageSalutationHelper engageSalutationHelper = new EngageSalutationHelper();
                engageSalutationHelper.createOrUpdateSalutationRecords(contactsToUpdateRecognitionName);
            }
        }
    }


    /*
     * Person 360 Rolldown
     * 
     * July 2023 - Martin Cadman - Implemented the record type bypass, initially to stop Agency Contacts from rolling down 
     *
     */
    public class Person360RollDown extends TriggerAbstract {
		Person360RollDownUtility prdUtil = new Person360RollDownUtility();
        Person360Muting__c p360ctmd = Person360Muting__c.getInstance();
        Set<String> restrictedRT = new set<String>();
		
        public override void process(SObject record) {
			Contact nc = (Contact)record;
			Boolean isRollDownEnabled = p360ctmd.Enable_Roll_Down__c;

            if (isRollDownEnabled != null && isRollDownEnabled) {
                prdUtil.oldMap = null;
                if (String.isNotBlank(p360ctmd.Record_Type_Roll_Down_Bypass__c)) { restrictedRT.addAll(p360ctmd.Record_Type_Roll_Down_Bypass__c.toLowerCase().split(',')); }
                
                if (restrictedRT.isEmpty() || !restrictedRT.contains(nc?.Record_Type_Developer_Name__c?.toLowerCase())) {
                    records.add(nc);
                }
            }
        }

        public override void process(SObject record, SObject oldRec) {
			Contact oc = (Contact)oldRec;
			Contact nc = (Contact)record;
			Boolean isRollDownEnabled = p360ctmd.Enable_Roll_Down__c;
	        Set<String> restrictedRT = new set<String>();
                    
            if (isRollDownEnabled != null && isRollDownEnabled) {
                prdUtil.oldMap.put(oldRec.id, oc);
                if (String.isNotBlank(p360ctmd.Record_Type_Roll_Down_Bypass__c)) { restrictedRT.addAll(p360ctmd.Record_Type_Roll_Down_Bypass__c.toLowerCase().split(',')); }
                if (restrictedRT.isEmpty() || !restrictedRT.contains(nc?.Record_Type_Developer_Name__c?.toLowerCase())) {
                    records.add(nc);
                }
			}
        }
     
        public override void execute() {
            if (records.size() > 0 ){
                prdUtil.initialize360((List<Contact>)records);
                prdUtil.processRecords();
            }
        }
    }
   
    
    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Update contact's related applications when the contact's mailing country is changed
    *******************************************************************************/
    public class UpdateSubmissionLocationCountry extends TriggerAbstract {

        /**
         * Handle after update event checking and filtering
         */
        public override void process(SObject record, SObject oldRec) {
            //Start process
            Contact contextContact = (Contact)record;
            Contact contextOldContact = (Contact)oldRec;

            //Check mailing country change
            if(contextContact.MailingCountry != contextOldContact.MailingCountry) {
                records.add(record);
            }
        }

        /**
         * Run functionality logic
         */
        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()) {
                //Retrieve filtered contact ids
                Set<Id> contactIds = new Set<Id>();
                for(SObject loopRecord : records) {
                    Contact contextContact = (Contact)loopRecord;
                    contactIds.add(contextContact.Id);
                }

                //Retrieve related applications of the filtered contact ids
                //Map<Id, Application__c> childApplicationsMap = new Map<Id, Application__c>(new ApplicationsSelector().selectByApplicantId(contactIds));

                //  ApplicationHelper appHelper = new ApplicationHelper();
                //appHelper.executeUpdateSubmissionLocationCountry(childApplicationsMap);
            }
        }
    }

    /**
     * @author      K Liew
     * @description compose and decompose birthdate and deceased date fields into
     *              individual day / month / year fields based on project engage's requirements.
     *              bind to both before insert and before update
     */
    public class ComposeDecomposeBirthDeceasedDates extends TriggerAbstract {
        public override void process(SObject record) {
            Contact c = (Contact) record;

            try {
                if (c.Birthdate != null) {
                    c.Birth_Day__c = c.Birthdate.day().format().leftPad(2).replaceAll(' ', '0');
                    c.Birth_Month__c = c.Birthdate.month().format().leftPad(2).replaceAll(' ', '0');
                    c.Birth_Year__c = c.Birthdate.year().format().leftPad(4).replaceAll(',', '').replaceAll(' ', '0');
                }
                if (
                    c.Birthdate == null &&
                    c.Birth_Day__c != null &&
                    c.Birth_Month__c != null &&
                    c.Birth_Year__c != null
                ) {
                    c.Birthdate = date.newInstance(
                        integer.valueof(c.Birth_Year__c),
                        integer.valueof(c.Birth_Month__c),
                        integer.valueof(c.Birth_Day__c)
                    );
                }

                if (c.Deceased_Date__c != null) {
                    c.Deceased_Date_Day__c = c.Deceased_Date__c.day().format().leftPad(2).replaceAll(' ', '0');
                    c.Deceased_Date_Month__c = c.Deceased_Date__c.month().format().leftPad(2).replaceAll(' ', '0');
                    c.Deceased_Date_Year__c = c.Deceased_Date__c.year()
                        .format()
                        .leftPad(4)
                        .replaceAll(',', '')
                        .replaceAll(' ', '0');
                }
                if (
                    c.Deceased_Date__c == null &&
                    c.Deceased_Date_Day__c != null &&
                    c.Deceased_Date_Month__c != null &&
                    c.Deceased_Date_Year__c != null
                ) {
                    c.Deceased_Date__c = date.newInstance(
                        integer.valueof(c.Deceased_Date_Year__c),
                        integer.valueof(c.Deceased_Date_Month__c),
                        integer.valueof(c.Deceased_Date_Day__c)
                    );
                }

                // if (c.Deceased__c == true && c.Deceased_Date__c == null && c.Deceased_Date_Year__c ==null) {
                //     c.addError('if "Deceased" is checked, please provide "Deceased Date" or "Deceased Year".');
                // }

                // if ((c.Deceased_Date__c != null || c.Deceased_Date_Year__c !=null) && c.Deceased_Source__c == null) {
                //     c.addError('Please select Deceased source');
                // }

                if (c.Deceased_Source__c != null && c.Deceased__c == false) {
                    c.Deceased__c = true;
                }
            } catch (Exception ex) {
                nebula.logger.error(ex.getMessage(),ex);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Contact c = (Contact) record;
            Contact oc = (Contact) oldRec;

            try {
                if (oc.Birthdate != c.Birthdate && c.Birthdate != null) {
                    c.Birth_Day__c = c.Birthdate.day().format().leftPad(2).replaceAll(' ', '0');
                    c.Birth_Month__c = c.Birthdate.month().format().leftPad(2).replaceAll(' ', '0');
                    c.Birth_Year__c = c.Birthdate.year().format().leftPad(4).replaceAll(',', '').replaceAll(' ', '0');
                } else if (oc.Birthdate != c.Birthdate && c.Birthdate == null) {
                    c.Birth_Day__c = null;
                    c.Birth_Month__c = null;
                    c.Birth_Year__c = null;
                } else if (
                    (oc.Birth_Day__c != c.Birth_Day__c ||
                    oc.Birth_Month__c != c.Birth_Month__c ||
                    oc.Birth_Year__c != c.Birth_Year__c) &&
                    (c.Birth_Day__c != null &&
                    c.Birth_Month__c != null &&
                    c.Birth_Year__c != null)
                ) {
                    c.Birthdate = date.newInstance(
                        integer.valueof(c.Birth_Year__c),
                        integer.valueof(c.Birth_Month__c),
                        integer.valueof(c.Birth_Day__c)
                    );
                } else if (
                    (oc.Birth_Day__c != c.Birth_Day__c ||
                    oc.Birth_Month__c != c.Birth_Month__c ||
                    oc.Birth_Year__c != c.Birth_Year__c) &&
                    (c.Birth_Day__c == null ||
                    c.Birth_Month__c == null ||
                    c.Birth_Year__c == null)
                ) {
                    c.Birthdate = null;
                }

                if (c.Deceased_Date__c != null) {
                    c.Deceased_Date_Day__c = c.Deceased_Date__c.day().format().leftPad(2).replaceAll(' ', '0');
                    c.Deceased_Date_Month__c = c.Deceased_Date__c.month().format().leftPad(2).replaceAll(' ', '0');
                    c.Deceased_Date_Year__c = c.Deceased_Date__c.year()
                        .format()
                        .leftPad(4)
                        .replaceAll(',', '')
                        .replaceAll(' ', '0');
                } else if (
                    (oc.Deceased_Date__c != c.Deceased_Date__c && c.Deceased_Date__c == null) &&
                    c.Deceased_Date_Year__c == null
                ) {
                    c.Deceased_Date_Day__c = null;
                    c.Deceased_Date_Month__c = null;
                    c.Deceased_Date_Year__c = null;
                } else if (
                    c.Deceased_Date_Day__c != null &&
                    c.Deceased_Date_Month__c != null &&
                    c.Deceased_Date_Year__c != null
                ) {
                    c.Deceased_Date__c = date.newInstance(
                        integer.valueof(c.Deceased_Date_Year__c),
                        integer.valueof(c.Deceased_Date_Month__c),
                        integer.valueof(c.Deceased_Date_Day__c)
                    );
                } else if (
                    (oc.Deceased_Date_Day__c != c.Deceased_Date_Day__c ||
                    oc.Deceased_Date_Month__c != c.Deceased_Date_Month__c ||
                    oc.Deceased_Date_Year__c != c.Deceased_Date_Year__c) &&
                    (c.Deceased_Date_Day__c != null &&
                    c.Deceased_Date_Month__c != null &&
                    c.Deceased_Date_Year__c != null)
                ) {
                    c.Deceased_Date__c = date.newInstance(
                        integer.valueof(c.Deceased_Date_Year__c),
                        integer.valueof(c.Deceased_Date_Month__c),
                        integer.valueof(c.Deceased_Date_Day__c)
                    );
                } else if (
                    (oc.Deceased_Date_Day__c != c.Deceased_Date_Day__c ||
                    oc.Deceased_Date_Month__c != c.Deceased_Date_Month__c ||
                    oc.Deceased_Date_Year__c != c.Deceased_Date_Year__c) &&
                    (c.Deceased_Date_Day__c == null ||
                    c.Deceased_Date_Month__c == null ||
                    c.Deceased_Date_Year__c == null)
                ) {
                    c.Deceased_Date__c = null;
                }

                // if (c.Deceased__c == true && c.Deceased_Date__c == null && c.Deceased_Date_Year__c ==null) {
                //     c.addError('if "Deceased" is checked, please provide "Deceased Date" or "Deceased Year".');
                // }

                // if ((c.Deceased_Date__c != null || c.Deceased_Date_Year__c !=null) && c.Deceased_Source__c == null) {
                //     c.addError('Please select Deceased source');
                // }

                if (c.Deceased_Source__c != null && c.Deceased__c == false) {
                    c.Deceased__c = true;
                }
            } catch (Exception ex) {
                nebula.logger.error(ex.getMessage(),ex);
            }
        }
    }

    /**
     * @description Dispatch the generic Platform Event to re-evaluate the new
     *  primary email for each Contact record whenever the following
     *  fields got updated/populated (on insert):
     *      - IT_account_disabled__c
     *      - Monash_Email_Address__c
     *      - Personal_Email__c
     *      - Business_Email_Address__c
     *      - Email (only on update)
     * @revision
     *  FEB.13.2020     Nick Guia   - Updated bulkification type to 1 contact per event
     */
    public class UpdatePrimaryEmail extends TriggerAbstract {

        List<Contact_Point_Event__e> eventList = new List<Contact_Point_Event__e>();

        public override void execute() {
            if(Trigger.isInsert) {
                for(Contact newCon : (List<Contact>) Trigger.new) {
                    if(String.isNotBlank(newCon.Monash_Email_Address__c) ||
                       String.isNotBlank(newCon.Personal_Email__c) ||
                       String.isNotBlank(newCon.Business_Email_Address__c))
                    {
                        Contact_Point_Event__e contactPointEvent = createPayload(newCon.Id);
                        if(contactPointEvent != null) {
                            this.eventList.add(contactPointEvent);
                        }
                    }
                }
            }
            if(!eventList.isEmpty()) {
                EventBus.publish(this.eventList);
            }
        }

        private Contact_Point_Event__e createPayload(Id contactId) {
            Contact_Point_Event__e ap;

            if(contactId != null) {
                AsyncProcessPayload payload = new AsyncProcessPayload();
                payload.put ('contactIds', new Set<Id> {contactId});
                ap = new Contact_Point_Event__e (
                    Process_Name__c = 'EmailServices.CalculatePrimary',
                    Parameter__c = payload.serialize()
                    );
            }

            return ap;
        }
    }

    /**
     * @description     This function will call the defined recalculation of primary contact points
     *                  from Person360 logic
     * @param           Set<Id>
     * @return          Exception
     */
    public static void invokeReCalculateContactPrimaryContactPoints(Set<Id> pContactIds) {
        if (pContactIds == null || pContactIds.isEmpty()) {
            return;
        }
        pContactIds.remove(null);
        for (Id conId : pContactIds) {
            if (conId.getSobjectType() != Contact.sObjectType) {
                throw new ContactServicesException('Invalid Id ['+String.valueOf(conId)+'] provided. It does not refer to a Contact Id.');
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            // Email__c
            Triggers.bypass('RollUpLogic');
            Triggers.bypass('FindNewParentChannel');
            new EmailTriggerHandler.TogglePrimary(pContactIds).execute();
            Triggers.clearBypass('RollUpLogic');
            Triggers.clearBypass('FindNewParentChannel');
            // Invoke Email Primary re-calculation
            new EmailTriggerHandler.FindNewPrimary(pContactIds).execute();
            // Phone__c
            Triggers.bypass('RollUpLogic');
            Triggers.bypass('FindNewParentChannel');
            // Mark all records (currently primary) to not primary
            new PhoneTriggerHandler.TogglePrimary(pContactIds).execute();
            Triggers.clearBypass('RollUpLogic');
            Triggers.clearBypass('FindNewParentChannel');
            // Invoke Phone Primary re-calculation
            new PhoneTriggerHandler.FindNewPrimary(pContactIds).execute();
            // Address__c
            Triggers.bypass('RollUpLogic');
            Triggers.bypass('FindNewParentChannel');
            // Mark all records (currently primary) to not primary
            new AddressTriggerHandler.TogglePrimary(pContactIds).execute();
            Triggers.clearBypass('RollUpLogic');
            Triggers.clearBypass('FindNewParentChannel');
            // Invoke Address Primary re-calculation
            new AddressTriggerHandler.FindNewPrimary(pContactIds).execute();

            // Name__c
            new NameTriggerHandler.AllocatePrimaryRecord(pContactIds).execute();
            new NameTriggerHandler.RollUpLogic(pContactIds).execute();

        } catch (Exception ex) {
            Database.rollback(sp);
            throw new ContactServicesException('Error Message:' + ex.getMessage());
            
        }
    }

    /**
     * @description     This method will query all contact point records using contact ids
     *                  then will repopulate the Key_UID__c per contact point record
     *                  (Address__c, Name__c, Phone__c, Social__c, Email__c)
     * @param           Set<Id>
     * @return          List<Database.SaveResult>
     * @revision        Russell Cadapan @ 07/09/2021 - Added logic to use the latest greatest contact point as a surviving record when duplicates are found in the contact points to be re-hashed
     *                                               - Added bypass trigger logic to avoid roll up when performing re-hashing
     */
    public static ContactServices.RePopulateHashFoAllContactPointsWrapper rePopulateHashFoAllContactPoints(Set<Id> contactIds) {
        return rePopulateHashFoAllContactPoints(contactIds, false);
    }
    
    public static ContactServices.RePopulateHashFoAllContactPointsWrapper rePopulateHashFoAllContactPoints(Set<Id> contactIds, Boolean bypassDupValException) {
        List<SObject> recordsToUpdate = new List<SObject>();
        Map<String, SObject> latestGreatestContactPoint = new Map<String, SObject>();
        for ( Contact contactRec : [ SELECT Id,
                                            (SELECT Id, Is_Active__c, Key_UID__c, Contact__c, Street_Name__c, City__c, State__c, Country2__c, Post_Code__c, Start_Date__c, End_Date__c, Address__c FROM Addresses__r ORDER BY Is_Active__c ASC, Start_Date__c ASC, CreatedDate ASC, End_Date__c ASC NULLS LAST),
                                            (SELECT Id, Is_Active__c,  Key_UID__c, Contact__c, First_Name__c, Middle_Name__c, Last_Name__c, Prefix__c, Salutation__c, Suffix__c, Start_Date__c, End_Date__c, Full_Name__c, type__c FROM Names__r  ORDER BY Is_Active__c ASC, Start_Date__c ASC, CreatedDate ASC, End_Date__c ASC NULLS LAST),
                                            (SELECT Id, Is_Active__c,  Key_UID__c, Contact__c, Start_Date__c, End_Date__c, Name, Type__c FROM Phones__r ORDER BY Is_Active__c ASC, Start_Date__c ASC,  CreatedDate ASC, End_Date__c ASC NULLS LAST),
                                            (SELECT Id, Is_Active__c,  Key_UID__c, Contact__c, Start_Date__c, End_Date__c, Name FROM Social_Handles__r ORDER BY Is_Active__c ASC, Start_Date__c ASC,  CreatedDate ASC, End_Date__c ASC NULLS LAST),
                                            (SELECT Id, Is_Active__c,  Key_UID__c, Contact__c, Start_Date__c, End_Date__c, Name FROM Emails__r ORDER BY Is_Active__c ASC, Start_Date__c ASC,  CreatedDate ASC, End_Date__c ASC NULLS LAST)
                                    FROM Contact
                                    WHERE Id IN: contactIds]) {
            //  Map of the latest greatest contact points
            latestGreatestContactPoint = pushLatestGreatestContactPoints(latestGreatestContactPoint, contactRec);

            // Email__c
            for (Email__c emailRec : contactRec.Emails__r) {
                if(latestGreatestContactPoint.containsKey(emailRec.Name)){
                    sObject latestContactPointRec = latestGreatestContactPoint.get(emailRec.Name);
                    emailRec.Is_Active__c = (Boolean) latestContactPointRec.get('Is_Active__c');
                    emailRec.Start_Date__c = (Date) latestContactPointRec.get('Start_Date__c');
                    emailRec.End_Date__c = (Date) latestContactPointRec.get('End_Date__c');
                }
                new EmailTriggerHandler.PopulateHash().process(emailRec);
                recordsToUpdate.add(emailRec);
            }

            // Phone__c
            for (Phone__c phoneRec : contactRec.Phones__r) {
                if(latestGreatestContactPoint.containsKey(phoneRec.Name)){
                    sObject latestContactPointRec = latestGreatestContactPoint.get(phoneRec.Name);
                    phoneRec.Is_Active__c = (Boolean) latestContactPointRec.get('Is_Active__c');
                    phoneRec.Start_Date__c = (Date) latestContactPointRec.get('Start_Date__c');
                    phoneRec.End_Date__c = (Date) latestContactPointRec.get('End_Date__c');
                }
                new PhoneTriggerHandler.PopulateHash().process(phoneRec);
                recordsToUpdate.add(phoneRec);
            }

            // Address__c
            for (Address__c addressRec : contactRec.Addresses__r) {
                if(latestGreatestContactPoint.containsKey(addressRec.Address__c)){
                    sObject latestContactPointRec = latestGreatestContactPoint.get(addressRec.Address__c);
                    addressRec.Is_Active__c = (Boolean) latestContactPointRec.get('Is_Active__c');
                    addressRec.Start_Date__c = (Date) latestContactPointRec.get('Start_Date__c');
                    addressRec.End_Date__c = (Date) latestContactPointRec.get('End_Date__c');
                }
                new AddressTriggerHandler.PopulateHash().process(addressRec);
                recordsToUpdate.add(addressRec);
            }

            // Social__c
            for (Social__c socialRec : contactRec.Social_Handles__r) {
                if(latestGreatestContactPoint.containsKey(socialRec.Name)){
                    sObject latestContactPointRec = latestGreatestContactPoint.get(socialRec.Name);
                    socialRec.Is_Active__c = (Boolean) latestContactPointRec.get('Is_Active__c');
                    socialRec.Start_Date__c = (Date) latestContactPointRec.get('Start_Date__c');
                    socialRec.End_Date__c = (Date) latestContactPointRec.get('End_Date__c');
                }
                new SocialTriggerHandler.PopulateHash().process(socialRec);
                recordsToUpdate.add(socialRec);
            }

            // Name__c
            for (Name__c nameRec : contactRec.Names__r) {
                if(latestGreatestContactPoint.containsKey(nameRec.Full_Name__c)){
                    sObject latestContactPointRec = latestGreatestContactPoint.get(nameRec.Full_Name__c);
                    nameRec.Is_Active__c = (Boolean) latestContactPointRec.get('Is_Active__c');
                    nameRec.Start_Date__c = (Date) latestContactPointRec.get('Start_Date__c');
                    nameRec.End_Date__c =(Date)  latestContactPointRec.get('End_Date__c');
                    nameRec.Type__c =(String)  latestContactPointRec.get('Type__c');
                }
                new NameTriggerHandler.PopulateHash().process(nameRec);
                recordsToUpdate.add(nameRec);
            }
        }

        // bypass contact point rollup triggers - DISABLEMENT
        triggerCommon.disableTrigger('Contact');
        triggerCommon.disableTrigger('Name__c');
        triggerCommon.disableTrigger('Email__c');
        triggerCommon.disableTrigger('Address__c');
        triggerCommon.disableTrigger('Phone__c');
        triggerCommon.disableTrigger('Social__c');

        List<Database.SaveResult> srList = new List<Database.SaveResult>();
        if (!recordsToUpdate.isEmpty()) {
            srList = Database.update(recordsToUpdate, false);
        }

        // bypass contact rollup triggers - RE-ENABLEMENT
        triggerCommon.enableTrigger('Contact');
        triggerCommon.enableTrigger('Name__c');
        triggerCommon.enableTrigger('Email__c');
        triggerCommon.enableTrigger('Address__c');
        triggerCommon.enableTrigger('Phone__c');
        triggerCommon.enableTrigger('Social__c');

        if (srList != null && !srList.isEmpty()) {
            Database.SaveResult xSaveResult = null;
            for (Integer i = 0 ; i < srList.size() ; i++) {
                xSaveResult = srList[i];
                if (!xSaveResult.isSuccess()) {
                    for (Database.Error err : xSaveResult.getErrors()) {
                        //Added Bypass
                        if (bypassDupValException == false || (bypassDupValException == true && err.getStatusCode() != System.StatusCode.DUPLICATE_VALUE)) {
							nebula.logger.error(err.getStatusCode() + ' ' + err.getMessage(), recordsToUpdate[i]);
                        }
                    }
                }
            }
        }
        nebula.logger.saveLog();

        ContactServices.RePopulateHashFoAllContactPointsWrapper result = new ContactServices.RePopulateHashFoAllContactPointsWrapper();
        result.vsrList = srList;
        result.vrecordsToUpdate = recordsToUpdate;
        return result;
    }

    private static Map<String, SObject> pushLatestGreatestContactPoints(Map<String, sObject> mapContactPoint, Contact rec){
        for(Email__c email : rec.Emails__r){
            mapContactPoint.put(email.Name, email);
        }

        for(Phone__c phone : rec.Phones__r){
            mapContactPoint.put(phone.Name, phone);
        }

        for(Address__c address : rec.Addresses__r){
            mapContactPoint.put(address.Address__c, address);
        }

        for(Social__c social : rec.Social_Handles__r){
            mapContactPoint.put(social.Name, social);
        }

        for(Name__c name : rec.Names__r){
            mapContactPoint.put(name.Full_Name__c, name);
        }

        return mapContactPoint;
    }

    public class RePopulateHashFoAllContactPointsWrapper {
        public List<Database.SaveResult> vsrList {
            get; set;
        }
        public List<SObject> vrecordsToUpdate {
            get; set;
        }
    }

    public class ContactServicesException extends Exception {}

    /**
     * @description     Trigger (in asynchronous context) the recalculation of all primary contacts (Address, Email, Name, Phone) and rollup when "Is Student" indicator changes
     *                  Trigger (in asynchronous context) the recalculation of primary Address contact point and rollup when any of address fields in contact changes
     *                  - ("OtherStreet","OtherCity","OtherState","OtherPostalCode","OtherCountry","MailingStreet","MailingCity,"MailingState","MailingPostalCode","MailingCountry")
     *                  Trigger (in asynchronous context) the recalculation of primary Email contact point and rollup when any of email fields in contact changes
     *                  - ("Monash_Email_Address__c","Personal_Email__c","Business_Email_Address__c","Email")
     *                  Trigger (in asynchronous context) the recalculation of primary Name contact point and rollup when any of name fields in contact changes
     *                  - ("Salutation_ERDA__c","Suffix","FirstName","LastName","MiddleName")
     *                  Trigger (in asynchronous context) the recalculation of primary Phone contact point and rollup when any of phone fields in contact changes
     *                  - ("AssistantPhone","OtherPhone","Phone","MobilePhone","HomePhone","Fax")
     * 
     * @revision
     *                  20.JUL.2020 - J.Mapanao - Initial Created
     *                  28.JAN.2025 - Band aid fix. If rollup is not enabled for the executing user, do not execute this method - EPCP-4309
     *                                This check should probably be better supported in the P360 rollup code but there is some efficiencies in doing it here.
     */
    public class InvokeRollUpContactPointsAsync extends TriggerAbstract {

        public override void execute() {
            list<Contact_Point_Event__e> eventList = new List<Contact_Point_Event__e>();
			Boolean isRollUpEnabled = Person360Muting__c.getInstance().Enable_Roll_Up__c;
            
            if (isRollUpEnabled) {
                if (Trigger.isUpdate) {
                    //List<Contact_Point_Event__e> apList = new List<Contact_Point_Event__e>();
                    Map<Id, Contact> oldContactMap = (Map<Id, Contact>) Trigger.oldMap;
                    Map<Id, List<String>> contactIdWithTargetObjectsMap = new Map<Id, List<String>>();
                    
                    for(Contact newContact : (List<Contact>) Trigger.new) {
                        Contact oldCntact = oldContactMap.get(newContact.Id);
                        if (CommonUtilities.fieldHasChanged('Is_Student__c', newContact, oldCntact)) {
                            Contact_Point_Event__e ap = createPayloadItem(newContact.Id, new List<String>{'Address__c','Email__c','Name__c','Phone__c'}, 'ContactServices.ReCalculatePrimaryPointsAndRollUp');
                            if (ap != null) {
                                eventList.add(ap);
                            }
                            continue;
                        }
    
                        // Check if there's any change on Email fields, Address fields, Name fields, and Phone fields
                        // This will bypassed when Is_Student__c changed as it will perform all recalculation
                        // for all contact points and roll up
                        if (CommonUtilities.fieldHasChanged('Monash_Email_Address__c', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('Personal_Email__c', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('Business_Email_Address__c', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('Email', newContact, oldCntact)) {
                            if (!contactIdWithTargetObjectsMap.containsKey(newContact.Id)) {
                                contactIdWithTargetObjectsMap.put(newContact.Id, new List<String>{'Email__c'});
                            } else {
                                contactIdWithTargetObjectsMap.get(newContact.Id).add('Email__c');
                            }
                        }
                        if (CommonUtilities.fieldHasChanged('OtherStreet', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('OtherCity', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('OtherState', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('OtherPostalCode', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('OtherCountry', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('MailingStreet', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('MailingCity', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('MailingState', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('MailingPostalCode', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('MailingCountry', newContact, oldCntact)) {
                            if (!contactIdWithTargetObjectsMap.containsKey(newContact.Id)) {
                                contactIdWithTargetObjectsMap.put(newContact.Id, new List<String>{'Address__c'});
                            } else {
                                contactIdWithTargetObjectsMap.get(newContact.Id).add('Address__c');
                            }
                        }
                        if (CommonUtilities.fieldHasChanged('Salutation_ERDA__c', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('Suffix', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('First_Name__c', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('Last_Name__c', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('FirstName', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('LastName', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('MiddleName', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('Preferred_Name__c', newContact, oldCntact)) {
                            if (!contactIdWithTargetObjectsMap.containsKey(newContact.Id)) {
                                contactIdWithTargetObjectsMap.put(newContact.Id, new List<String>{'Name__c'});
                            } else {
                                contactIdWithTargetObjectsMap.get(newContact.Id).add('Name__c');
                            }
                        }
                        if (CommonUtilities.fieldHasChanged('AssistantPhone', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('OtherPhone', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('Phone', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('MobilePhone', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('HomePhone', newContact, oldCntact) ||
                                CommonUtilities.fieldHasChanged('Fax', newContact, oldCntact)) {
                            if (!contactIdWithTargetObjectsMap.containsKey(newContact.Id)) {
                                contactIdWithTargetObjectsMap.put(newContact.Id, new List<String>{'Phone__c'});
                            } else {
                                contactIdWithTargetObjectsMap.get(newContact.Id).add('Phone__c');
                            }
                        }
                    }
                    if (contactIdWithTargetObjectsMap != null && !contactIdWithTargetObjectsMap.isEmpty()) {
                        for (Id contactId : contactIdWithTargetObjectsMap.keySet()) {
                            Contact_Point_Event__e ap = createPayloadItem(contactId, contactIdWithTargetObjectsMap.get(contactId), 'ContactServices.ReCalculatePrimaryPointsAndRollUp');
                            if (ap != null) {
                                eventList.add(ap);
                            }
                        }
                    }
                } else if(Trigger.isInsert) {
                    //List<Contact_Point_Event__e> cpEvents = new List<Contact_Point_Event__e>();
                    for(Contact newContact : (List<Contact>) Trigger.new) {
                        Contact_Point_Event__e ap = createPayloadItem(newContact.Id, new List<String>{'Name__c','Email__c','Phone__c','Address__c'}, 'ContactServices.ReCalculatePrimaryPointsAndRollUp');
                        if (ap != null) {
                            eventList.add(ap);
                        }
                    }
                }
                
                if (!eventList.isEmpty()) {
                    EventBus.publish(eventList);
                }
            } else {
                nebula.logger.debug('Rollup disabled for this user',Trigger.new);
                nebula.logger.saveLog();
            }
        }

        public Contact_Point_Event__e createPayloadItem(Id contactId, List<String> targetObjects, String processName) {
            Contact_Point_Event__e ap;
            if (contactId != null && targetObjects != null && !targetObjects.isEmpty() && String.isNotBlank(processName)) {
                AsyncProcessPayload payload = new AsyncProcessPayload();
                payload.put('contactIds', new Set<Id> {contactId});
                payload.put('targetContactPointObjects', targetObjects);
                ap = new Contact_Point_Event__e(
                    Process_Name__c = processName,
                    Parameter__c = payload.serialize()
                    );
            }
            return ap;
        }
    }

    /**
     * @description     Logic to perform recalculation of Primary for all contact points
     *                  and perform rollup logic ReCalculatePrimaryPointsAndRollUp
     * 
     * @revision
     *                  20.JUL.2020 - J.Mapanao - Initial Created
     */
    public class ReCalculatePrimaryPointsAndRollUp implements IPlatformEventInvocable {

        private Set<Id> contactIds = new Set<Id>();
        private List<String> targetContactPointsAPIObjectsList = new List<String>();
        @TestVisible
        public String payloadKeyContactIds = 'contactIds';
        @TestVisible
        public final String payloadKeyTargetContactPoints = 'targetContactPointObjects';

        public void execute(List<AsyncProcessPayload> payload) {
            try {
                initialize(payload);
                run();
            } catch(Exception ex) {
                nebula.logger.error(ex.getMessage(), ex).setRecord(new list<Id>(this.contactIds));
            } finally {
                nebula.logger.saveLog();
            }
        }

        public void run() {
            ContactServices.invokeReCalculateContactPrimaryContactPoints(contactIds);
        }

        /**
         * @description initialize process by extracting the method
         *  parameters from the platform event payload
         */
        private void initialize(List<AsyncProcessPayload> payloads) {
            if (payloads != null) {
                for(AsyncProcessPayload payload : payloads) {
                    Map<String, Object> allArgs = payload.getArgs();
                    if (allArgs != null && !allArgs.isEmpty()
                            && allArgs.containsKey(payloadKeyContactIds) && allArgs.containsKey(payloadKeyTargetContactPoints)) {
                        // Get contact Id
                        //first, cast the get return of List<Object> into List<Id>
                        List<Object> objList1 = (List<Object>) payload.get('contactIds');
                        if (objList1 != null) {
                            //then, instantiate a Set out of it
                            for (Object io : objList1) {
                                //parse object to ID
                                this.contactIds.add(Id.valueOf(io.toString()));
                            }
                        }

                        // Get target object
                        //first, cast the get return of List<Object> into List<Id>
                        List<Object> objList2 = (List<Object>) payload.get(payloadKeyTargetContactPoints);
                        if (objList2 != null) {
                            //then, instantiate a List out of it
                            for (Object io : objList2) {
                                //parse object to String
                                this.targetContactPointsAPIObjectsList.add(String.valueOf(io.toString()));
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * @author      Vinothraja
     * @date        05.Apr.2021
     * @description Update the Associated Portal user's with the Contact's new details -- ONLY IF PARTNER
     * Revision:
     * 24/05/2022 - Vinothraja - Changed to new Trigger Framework
     */
    public class SyncPartnerUser extends TriggerAbstract {
        @TestVisible
        private Map<id, Contact> mapContact = new Map<Id, Contact> ();
    
        /*
        * Check if the contact's details have any changes -- ONLY IF PARTNER
        */
        public override void process(SObject record, SObject oldRec) {
            Id partnerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            // Check if its a Partner and if it's Contact details have changed
            if(((Contact) record).RecordTypeId == partnerRecordTypeId 
                && (CommonUtilities.fieldHasChanged('FirstName', record, oldRec)
                    || CommonUtilities.fieldHasChanged('MiddleName', record, oldRec)
                    || CommonUtilities.fieldHasChanged('LastName', record, oldRec)
                    || CommonUtilities.fieldHasChanged('Suffix', record, oldRec)
                    || CommonUtilities.fieldHasChanged('Title', record, oldRec)
                    || CommonUtilities.fieldHasChanged('Email', record, oldRec)
                    || CommonUtilities.fieldHasChanged('Company__c', record, oldRec)
                    || CommonUtilities.fieldHasChanged('Phone', record, oldRec)
                    || CommonUtilities.fieldHasChanged('MobilePhone', record, oldRec)
                    || CommonUtilities.fieldHasChanged('mailingStreet', record, oldRec)
                    || CommonUtilities.fieldHasChanged('mailingState', record, oldRec)
                    || CommonUtilities.fieldHasChanged('mailingCity', record, oldRec)
                    || CommonUtilities.fieldHasChanged('mailingPostalcode', record, oldRec)
                    || CommonUtilities.fieldHasChanged('mailingCountry', record, oldRec))) {
                mapContact.put(record.id, (Contact) record);
            }
        }
        /**
        * Update the Associated Portal user's details with the Contact's new details 
        */
        public override void execute() {
            if (mapContact.size() > 0) {
                List<User> lstSyncableUsers = new List<User> ();
                //Update the Associated Portal User's Profile details
                for (User usr : [SELECT id, FirstName, MiddleName, LastName, Suffix, Email, Title, CompanyName, Phone, Mobilephone,
                                        Street, State, City, Postalcode, Country, Contactid
                                        FROM User
                                        WHERE contactid IN :mapContact.keySet()
                                            AND id in (SELECT AssigneeId FROM PermissionSetAssignment 
                                                WHERE PermissionSet.Name = :Constants.PARTNER_PERMISSION_SET)]) {
                    Contact con = mapContact.get(usr.Contactid);
                    usr.FirstName = con.FirstName;
                    usr.MiddleName = con.MiddleName;
                    usr.LastName = con.LastName;
                    usr.Suffix = con.Suffix;
                    if (!String.isBlank(con.Email)){ //To avoid Email IDs being blanked out while syncing
                        usr.Email = con.Email;
                    }
                    usr.Title = con.Title;
                    usr.CompanyName = con.Company__c;
                    usr.Phone = con.Phone;
                    usr.Mobilephone = con.Mobilephone;
                    usr.Street = con.mailingStreet;
                    usr.State = con.mailingState;
                    usr.City = con.mailingCity;
                    usr.Postalcode = con.mailingPostalcode;
                    usr.Country = con.mailingCountry;
                    lstSyncableUsers.add(usr);
                }
                if (!lstSyncableUsers.isEmpty()) {
                    update lstSyncableUsers;
                }
            }
        }
    }

    /**
     * @author      Russell Cadapan
     * @date        25.Jul.2022
     * @description Flush Address Verification Source field after Person360 RollDown
     * Revision:
     * 25/07/2022 - Russell Cadapan - Created.
     */
    public class ResetContactPointSource extends TriggerAbstract {

        private List<Contact> contactRecords = new List<Contact>();

        public override void process(SObject record) {
            Contact con = (Contact) record;
            if(con.Mailing_Address_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN || con.Other_Address_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN || con.Phone_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN || con.Email_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN || con.Mobile_Phone_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN){
                contactRecords.add(con);
            }

        }
        public override void process(SObject record, SObject oldRec) {
            Contact con = (Contact) record;
            if(con.Mailing_Address_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN
                    || con.Other_Address_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN
                    || con.Phone_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN
                    || con.Email_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN
                    || con.Mobile_Phone_Verification_Source__c == Constants.CONTACT_POINT_SOURCE_EXPERIAN){
                contactRecords.add(con);
            }
        }

        public override void execute(){
            List<Contact> contactsToBeReset = new List<Contact>();
            for(Contact c: contactRecords){
                contactsToBeReset.add(new Contact(Id = c.Id, Mailing_Address_Verification_Source__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED,
                        Phone_Verification_Source__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED,
                        Email_Verification_Source__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED,
                        Other_Address_Verification_Source__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED,
                        Mobile_Phone_Verification_Source__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED));
            }
            TriggerCommon.disableTrigger('Contact');
                update contactsToBeReset;
            TriggerCommon.enableTrigger('Contact');
        }
    }
    /**
     * @author      Russell Cadapan
     * @date        25.Jul.2022
     * @description Flush DPID and Verification Status if the Mailing Address is update through unverified source
     * Revision:
     * 25/07/2022 - Russell Cadapan - Created.
     */
    public class CheckAddressSource extends TriggerAbstract{

        private List<Contact> newContacts = new List<Contact>();
        private List<Contact> newOtherContacts = new List<Contact>();

        public override void process(SObject record, SObject oldRec) {
            Contact newCon = (Contact) record;
            Contact oldCon = (Contact) oldRec;
            // if mailing address is not null and any of the fields has changed
            if(
                (String.isNotBlank(newCon.MailingStreet) && CommonUtilities.fieldHasChanged('MailingStreet', newCon, oldCon)) ||
                (String.isNotBlank(newCon.MailingCity) && CommonUtilities.fieldHasChanged('MailingCity', newCon, oldCon)) ||
                (String.isNotBlank(newCon.MailingState) && CommonUtilities.fieldHasChanged('MailingState', newCon, oldCon)) ||
                (String.isNotBlank(newCon.MailingPostalCode) && CommonUtilities.fieldHasChanged('MailingPostalCode', newCon, oldCon)) ||
                (String.isNotBlank(newCon.MailingCountry) && CommonUtilities.fieldHasChanged('MailingCountry', newCon, oldCon))
            ){
                newContacts.add(newCon);
            }

            //if other address is not null and any of the fields has changed
            if(
                (String.isNotBlank(newCon.OtherStreet) && CommonUtilities.fieldHasChanged('OtherStreet', newCon, oldCon)) ||
                (String.isNotBlank(newCon.OtherCity) && CommonUtilities.fieldHasChanged('OtherCity', newCon, oldCon)) ||
                (String.isNotBlank(newCon.OtherState) && CommonUtilities.fieldHasChanged('OtherState', newCon, oldCon)) ||
                (String.isNotBlank(newCon.OtherPostalCode) && CommonUtilities.fieldHasChanged('OtherPostalCode', newCon, oldCon)) ||
                (String.isNotBlank(newCon.OtherCountry) && CommonUtilities.fieldHasChanged('OtherCountry', newCon, oldCon))
            ){
                newOtherContacts.add(newCon);
            }
        }
        /**
        * Run functionality logic
        */
        public override void execute() {

            for(Contact newCon: newContacts){
                if(newCon.Mailing_Address_Verification_Source__c != Constants.CONTACT_POINT_SOURCE_EXPERIAN){
                    // reset the verification status fields on Contact
                    newCon.Mailing_Address_DPID__c = null;
                    newCon.Mailing_Address_Verification_Status__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                }
            }

            for(Contact newCon: newOtherContacts){
                if(newCon.Other_Address_Verification_Source__c != Constants.CONTACT_POINT_SOURCE_EXPERIAN){
                    // reset the verification status fields on Contact
                    newCon.Other_Address_DPID__c = null;
                    newCon.Other_Address_Verification_Status__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                }
            }

        }
    }

    /**
     * @author      Russell Cadapan
     * @date        14.AUG.2022
     * @description Flush Verification Status when any phone field is updated through unverified source
     * Revision:
     * 25/07/2022 - Russell Cadapan - Created.
     */
    public class CheckPhoneSource extends TriggerAbstract{

        private List<Contact> newContacts = new List<Contact>();

        private Set<Id> contactIdsWherePhoneChanged = new Set<Id>();
        private Set<Id> contactIdsWhereHomePhoneChanged = new Set<Id>();
        private Set<Id> contactIdsWhereMobileChanged = new Set<Id>();
        private Set<Id> contactIdsWhereOtherChanged = new Set<Id>();

        public override void process(SObject record, SObject oldRec) {
            Contact newCon = (Contact) record;
            Contact oldCon = (Contact) oldRec;

            Boolean isPhoneChanged = false;
            Boolean isMobileChanged = false;
            Boolean isHomePhoneChanged = false;
            Boolean isOtherPhoneChanged = false;

            if(String.isNotBlank(newCon.OtherPhone) && CommonUtilities.fieldHasChanged('OtherPhone', newCon, oldCon)) isOtherPhoneChanged = true;
            if(String.isNotBlank(newCon.Phone) && CommonUtilities.fieldHasChanged('Phone', newCon, oldCon)) isPhoneChanged = true;
            if(String.isNotBlank(newCon.MobilePhone) && CommonUtilities.fieldHasChanged('MobilePhone', newCon, oldCon)) isMobileChanged = true;
            if(String.isNotBlank(newCon.HomePhone) && CommonUtilities.fieldHasChanged('HomePhone', newCon, oldCon)) isHomePhoneChanged = true;

            if(isPhoneChanged) contactIdsWherePhoneChanged.add(newCon.Id);
            if(isMobileChanged) contactIdsWhereMobileChanged.add(newCon.Id);
            if(isHomePhoneChanged) contactIdsWhereHomePhoneChanged.add(newCon.Id);
            if(isOtherPhoneChanged) contactIdsWhereOtherChanged.add(newCon.Id);

            if(isPhoneChanged || isMobileChanged || isHomePhoneChanged || isOtherPhoneChanged) newContacts.add(newCon);

        }
        /**
        * Run functionality logic
        */
        public override void execute() {
            for(Contact newCon: newContacts){
                // if the new phone update is not verified from Experian, flush the verification status of which phone number was changed
                if(newCon.Phone_Verification_Source__c != Constants.CONTACT_POINT_SOURCE_EXPERIAN){
                    // if the global phone is updated from unverified source, flush the Phone_Verification_Status__c field
                    if(contactIdsWherePhoneChanged.contains(newCon.Id)) newCon.Phone_Verification_Status__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                    // if the home phone is updated from unverified source, flush the HomePhone_Verification_Status__c field
                    if(contactIdsWhereHomePhoneChanged.contains(newCon.Id)) newCon.HomePhone_Verification_Status__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                    // if the other phone is updated from unverified source, flush the Other_Phone_Verification_Status__c field
                    if(contactIdsWhereOtherChanged.contains(newCon.Id)) newCon.Other_Phone_Verification_Status__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                }
                if(newCon.Mobile_Phone_Verification_Source__c != Constants.CONTACT_POINT_SOURCE_EXPERIAN){
                    // if the mobile phone is updated from unverified source, flush the Mobile_Verification_Status__c field
                    if(contactIdsWhereMobileChanged.contains(newCon.Id)) newCon.Mobile_Verification_Status__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                }
            }
        }
    }

    /**
     * @author      Russell Cadapan
     * @date        07.SEP.2022
     * @description Flush Verification Status when any email field is updated through unverified source
     * Revision:
     * 08/09/2022 - Russell Cadapan - Created.
     */
    public class CheckEmailSource extends TriggerAbstract{

        private List<Contact> newContacts = new List<Contact>();

        private Set<Id> contactIdsWhereEmailChanged = new Set<Id>();
        private Set<Id> contactIdsWherePersonalChanged = new Set<Id>();
        private Set<Id> contactIdsWhereMonashChanged = new Set<Id>();
        private Set<Id> contactIdsWhereBusinessChanged = new Set<Id>();

        public override void process(SObject record, SObject oldRec) {
            Contact newCon = (Contact) record;
            Contact oldCon = (Contact) oldRec;

            Boolean isEmailChanged = false;
            Boolean isPersonalChanged = false;
            Boolean isBusinessChanged = false;
            Boolean isMonashChanged = false;

            if(String.isNotBlank(newCon.Email) && CommonUtilities.fieldHasChanged('Email', newCon, oldCon)) isEmailChanged = true;
            if(String.isNotBlank(newCon.Personal_Email__c) && CommonUtilities.fieldHasChanged('Personal_Email__c', newCon, oldCon)) isPersonalChanged = true;
            if(String.isNotBlank(newCon.Business_Email_Address__c) && CommonUtilities.fieldHasChanged('Business_Email_Address__c', newCon, oldCon)) isBusinessChanged = true;
            if(String.isNotBlank(newCon.Monash_Email_Address__c) && CommonUtilities.fieldHasChanged('Monash_Email_Address__c', newCon, oldCon)) isMonashChanged = true;

            if(isEmailChanged) contactIdsWhereEmailChanged.add(newCon.Id);
            if(isPersonalChanged) contactIdsWherePersonalChanged.add(newCon.Id);
            if(isBusinessChanged) contactIdsWhereBusinessChanged.add(newCon.Id);
            if(isMonashChanged) contactIdsWhereMonashChanged.add(newCon.Id);

            if(isEmailChanged || isPersonalChanged || isBusinessChanged || isMonashChanged) newContacts.add(newCon);

        }
        /**
        * Run functionality logic
        */
        public override void execute() {

            for(Contact newCon: newContacts){
                // if the new email update is not verified from Experian, flush the verification status of which email number was changed
                if(newCon.Email_Verification_Source__c != Constants.CONTACT_POINT_SOURCE_EXPERIAN){
                    // if the global email is updated from unverified source, flush the Email_Verification_Status__c field
                    if(contactIdsWhereEmailChanged.contains(newCon.Id)) newCon.Email_Verification_Status__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                    // if the personal email is updated from unverified source, flush the Personal_Email_Verification_Status__c field
                    if(contactIdsWherePersonalChanged.contains(newCon.Id)) newCon.Personal_Email_Verification_Status__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                    // if the business email is updated from unverified source, flush the Business_Email_Verification_Status__c field
                    if(contactIdsWhereBusinessChanged.contains(newCon.Id)) newCon.Business_Email_Verification_Status__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                    // if the monash email is updated from unverified source, flush the Monash_Email_Verification_Status__c field
                    if(contactIdsWhereMonashChanged.contains(newCon.Id)) newCon.Monash_Email_Verification_Status__c = Constants.CONTACT_POINT_SOURCE_UNDEFINED;
                }
            }
        }
    }

    /**
     * @author      Peter Sewell
     * @date        13.MAR.2023
     * @description Recreate Affiliation-related Apex Managed ContactShares after contact owner is changed
     *              This is needed as apex managed shares are (auto) deleted by the platform when the 
     *              owner of a shared record is changed, and therefore need to be recreated
     * Revision:
     * 13/03/2023 - Peter Sewell - Created.
     */
    public class RecreateAffiliationContactShares extends TriggerAbstract {
        
        // Filter for UPDATED records where contact owner has changed
        public override void process(SObject newRecord, SObject oldRecord) {
            Contact ctcOld = (Contact) oldRecord;
            Contact ctcNew = (Contact) newRecord;
            if (ctcOld.OwnerId != ctcNew.OwnerId) {
                records.add(ctcNew);
            }
        }

        /**
        * Now recreate ContactShare records for sharing-significant affiliations 
        */
        public override void execute() {
            // Make a list of the updated contact ids
            List<String> contactIds = new List<String>();
            for(Contact c : (List<Contact>) records) {
                contactIds.add(c.Id); 
            }  

            // Leave now if there is no work to do
            if (contactIds.isEmpty()) {
                return;
            }
            
            // Find Affiliations where the ContactShare need to be re-created, then re-create 'em 
            List<Affiliation__c> affils = AffiliationTriggerHandler.getAffiliationsOfSharingSignificance(contactIds);
            if (!affils.isEmpty()) {
                AffiliationTriggerHandler.reestablishSharing(affils); 
            }
        }
    }
    /**
    * @author      Seeva Singh
    * @date        28/04/2023
    * @description To Update account record type name on a backend field of contact insertion and update. This will be 
                    be used in duplicate and matching rule to flag only household contacts. For any contacts other than 
                    of Account RT Household the field's value will be kept blank.
    * Revision:
    * 28/04/2023 - Seeva Singh - Created.
    */
    public class UpdateAccountRecordType extends TriggerAbstract {
        private Set<Id> accountIds = new Set<Id>();

        public override void process(SObject record) {
            Contact newCon = (Contact) record;
            if (newCon.AccountId != null) {
                records.add(newCon);
                accountIds.add(newCon.AccountId);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Contact newCon = (Contact) record;
            if (newCon.AccountId != null) {
                records.add(newCon);
                accountIds.add(newCon.AccountId);
            }
        }
        /**
        * Run functionality logic
        */
        public override void execute() {
            if(!accountIds.isEmpty()){
                Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Account WHERE Id IN :accountIds]);
                for (Contact newCon : (List<Contact>) records) {
                    if (!AccountHandler.RecordtypeUpdatedByAccountTrigger && newCon.AccountId != null && accountsMap.containsKey(newCon.AccountId)) {
                        newCon.Account_Record_Type_Name__c = accountsMap.get(newCon.AccountId).RecordType.DeveloperName;
                    }
                }
            }
        }
    }

  /**
     * @author      Shalini Mendu
     * @date        03.MAY.2023
     * @description Restrict assigning Branch Manager/Principal Agent roles if 
     * the Account has already such roles assigned to users
     * Revision:
     * 03/05/2023 - Shalini Mendu - Created.
     */ 
    public class RestrictDuplicateAgencyRolesPerAgency extends TriggerAbstract {
        Id agentRecType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Agency_Contact').getRecordTypeId(); 
	    List<Contact> processContacts = new List<Contact>();
         //handle insert
         public override void process(SObject record) {
               Contact newCon = (Contact) record;
               if(newCon.RecordTypeId == agentRecType)
               {
                   processContacts.add(newCon);
               }
         }
         //handle updates
         public override void process(SObject record, SObject oldRec) {
               Contact newCon = (Contact) record;
               Contact oldCon = (Contact) oldRec;
               if(newCon.RecordTypeId == agentRecType && newCon.Agency_contact_roles__c!=oldCon.Agency_contact_roles__c)
               {
                  processContacts.add(newCon);
               }
         }
    
   	     public override void execute() {
          //Run further only if there are elements in the collection
            if(processContacts.size()>0)
            {
                processRole(processContacts, AgentPortalConstants.BRANCH_MANAGER_ROLE);
                processRole(processContacts, AgentPortalConstants.PRINCIPAL_AGENT_ROLE);
            }
        }
    }
    
    /**
     * @author      Shalini Mendu
     * @date        03.MAY.2023
     * @description Helper method to check for previouBranch Manager/Principal Agent roles and displays
     * a message to the user
     * Revision:
     * 03/05/2023 - Shalini Mendu - Created.
     */
    private static void processRole(List<Contact> contactList,  String role)
    {
        List<Id> contactIds = new List<Id>();
        List<Id> accIds = new List<Id>();
        Map<String, String> roleMap = new Map<String, String>();
     
         Integer cnt = 0;
        //Iterate over contacts and collect the contact id's if they contain BM/PA roles
        for(Contact c :  contactList) {
            if(String.isNotBlank(c.agency_contact_roles__c) && c.agency_contact_roles__c.contains(role))
            {
                contactIds.add(c.Id); 
                accIds.add(c.AccountId);
            }
        }
        // Leave now if there is no work to do
        if (contactIds.isEmpty()) {
            return ;
        }
        //Run a query to fetch all the Contacts under the Account and don't include the trigger context contacts 
        for(Contact con: [select AccountId, Name,Agency_contact_Roles__c from Contact where accountid =:accIds  
                           and id Not in :contactIds and Agency_contact_Roles__c!=null order by AccountId])
        {   
            //if the existing contacts have the PA/BM role?
            if(con.Agency_contact_Roles__c.contains(role))
            {
                //store in a map
                roleMap.put(con.AccountId, con.Name);
            }
        }
        //iterate over contacts in the trigger 
        for(Contact con :contactList)
        {
            //rolemap found key
            if(roleMap.get(con.AccountId)!=null)
            {
                con.addError('Please first demote '+roleMap.get(con.AccountId) + ' with '+role +' role and  then retry ');
            }
        }
            
    }
    
      /**
     * @author      Shalini Mendu
     * @date        05.MAY.2023
     * @description Reassigning Branch Manager/Principal Agent roles aligning with the Contact Agency_Contact_roles__c update
     * Revision:
     * 03/05/2023 - Shalini Mendu - Created
     * 24/01/2024 - Jitender Padda - Bulkified getUserRole function
     */
    public class ReAssignUserRole extends TriggerAbstract {
        Id agentRecType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('Agency_Contact')
            .getRecordTypeId();
         List<Contact> processContacts = new List<Contact>();

		  //handle updates
        public override void process(SObject record, SObject oldRec) {
               Contact newCon = (Contact) record;
               Contact oldCon = (Contact) oldRec;
            if (
                newCon.RecordTypeId == agentRecType &&
                newCon.Agency_contact_roles__c != oldCon.Agency_contact_roles__c
            ) {
                  processContacts.add(newCon);
               }
         }
        
         public override void execute() {
            if(processContacts.size() > 0){
             List<User> uList = new List<User>();

                // Get User Role for Contact
                Map<Id, UserRole> conIdToPortalUserRoleMap = ExperienceAuthenticationServices.getUserRole(processContacts);

              	//Find the User linked to the Contact
                for (User u : [SELECT id, ContactId, UserRole.Id FROM User WHERE ContactId IN :processContacts]) {
                    u.UserRoleId = conIdToPortalUserRoleMap.get(u.ContactId).Id;
                    uList.add(u);
                }

                if (uList.size() > 0) {
                    // call queueable class to avoid MIXED_DML_OPERATION by updating User and Contact in one transaction
                    Queueable queueItem = new UserServices.UpdateSobjectsQueueable(uList);
                    System.enqueueJob(queueItem);
                }
            }
         }
    }
    
    /**
	* Public method to format names to proper case.
	*/
    public Static String toProperCase(String value) {
        // return empty string if input is blank
        if (String.isBlank(value)) {
            return '';
        }

    	// return as-is if the value is not all uppercase/lowercase 
        if (!value.equals(value.toUppercase()) && !value.equals(value.toLowercase())) {
		    return value;
        }
        
        // change to proper case by changing any character following a 'divider' symbol to uppercase
        final List<String> dividers = new List<String>{' ', '-', '\''};
            
        // Change input to lowercase (as input from Callista is all uppercase) and split into characters
        String[] characters = value.toLowerCase().split('');
        
        // loop over every character, and capitalise after a devider
        boolean capitaliseNextCharacter = true;
        for(Integer i=0; i<characters.size(); i++) {
            if (capitaliseNextCharacter) {
                characters[i] = characters[i].capitalize();
            }
            capitaliseNextCharacter = (dividers.contains(characters[i])) ? true : false;
        }
        
        // join characters back together
        value = String.join(characters, '');
        return value;
    }
    
}