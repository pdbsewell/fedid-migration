/**************************************************************************************************
Apex Controller Name :  LightningCreateCaseController
Version              :  1.0
Created Date         :
Function             :  controller class to create case from community ask a question page.
*--------------------------------------------------------------------------------------------------
Developer                        Date                        Description
Veera G                       3.July.2017                        Created.
APRivera                      6.April.2020                       Added Logic to handle COVID-19 grants.
APRivera                      31.August.2020                     Added Logic to handle Support grants ($1000).
APRivera                      18.July.2022                       Added Logic to handle International Grant
Peter Sewell                  16.June.2023                       Added Captcha validation
Peter Sewell                  09.Sep.2024                        Rate Limit number of Attachments
***************************************************************************************************/
public without sharing class LightningCreateCaseController {

    // Constants
    private static final string ERROR_INVALID_CAPTCHA = 'An unexpected processing error occured.';
    private static final string ERROR_TOO_MANY_ATTACHMENTS = 'Number of attachments exceeded limit';


    public static final User currentUser = [SELECT Id, Profile.Name, Name, FederationIdentifier, Profile.UserLicense.Name,
                                                   ContactId, Contact.Person_ID_unique__c, Contact.Faculty__c, Contact.Campus__c,
                                                   FirstName, LastName, Email
                                                   FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017
    * @description  method will return the picklist values of Community_Status__c picklist values.
    * @InputParameter: string
    * @return type  list<sobject>
    * @revision
    *******************************************************************************/
    @AuraEnabled
    public static list<String> getReasonofEnquiry() {
        list<String> options = new list<String>();
        Schema.DescribeFieldResult fieldResult = Case.Community_Status__c.getDescribe();
        list<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        options.add('Please select an option');
        for (Schema.PicklistEntry f: values) {
            options.add(f.getLabel());
        }

        return options;
    }

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017
    * @description  method decides whether the logged in user is internal or guest.
    * @InputParameter: string
    * @return type  list<sobject>
    * @revision
    *******************************************************************************/
    @AuraEnabled
    public static string getUserType() {
        String currentUserProfileName = currentUser.Profile.Name;
        String usertype = '';
        if(currentUserProfileName == Label.Guest_User_Profile_Name) {
            usertype = 'Guest';
        } else {
            usertype = 'Internal';
        }
        return usertype;
    }



    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         06.April.2020
    * @description  Creates case for Covid Grants
    * @InputParameter: case
    * @return type  Id
    * @revision     APRivera - 06.April.2020 - Checks if current user has
    *                                           existing application for COVID Grant
    *******************************************************************************/
    @AuraEnabled
    public static Boolean checkExistingApplication() {
        Boolean bHasExistingApplication = false;
        if(currentUser.ContactId != null) {
            List<Case> lstCseRecords = [SELECT Id, CaseNumber FROM Case WHERE ContactId =: currentUser.ContactId
                                               AND Subject LIKE 'Emergency Student Grant application%' LIMIT 1];
            if(!lstCseRecords.isEmpty()) {
                bHasExistingApplication = true;
            }
        }
        return bHasExistingApplication;
    }

    /*******************************************************************************
    * @description  Counts hardship applications
    *******************************************************************************/
    @AuraEnabled
    public static Map<String, Integer> checkExistingHardshipApplication() {
        Map<String, Integer> existingApplications = new Map<String, Integer>();

        existingApplications.put('has5000', [SELECT count() FROM Case WHERE ContactId =: currentUser.ContactId AND Subject LIKE 'Early Travel Ban Student Grant application%' AND Amount__c != null]);
        existingApplications.put('has7000', [SELECT count() FROM Case WHERE ContactId =: currentUser.ContactId AND Subject LIKE 'Hardship Student Grant application%' AND Amount__c != null]);
        existingApplications.put('has1000', [SELECT count() FROM Case WHERE ContactId =: currentUser.ContactId AND Subject LIKE 'Support Student Grant application%' AND Amount__c != null]);

        return existingApplications;
    }

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         06.April.2020
    * @description  Creates case for Covid Grants
    * @InputParameter: case
    * @return type  Id
    * @revision     APRivera - 06.April.2020 - Added Logic for the COVID Grant Application
     *              APRivera - 31.August.2020 - Added Logic for the Support Grant Application
    *******************************************************************************/
    @AuraEnabled
    public static String createCaseCovid(Case casRec, String recTypeName, String strAmount) {
        try {
            List<Community_Case_Creation_Settings__c> caseCustomSetting =  new List<Community_Case_Creation_Settings__c>();
            Map<string,list<Community_Case_Creation_Settings__c>> enquiryCSMapByName = new Map<string,list<Community_Case_Creation_Settings__c>>();

            for(Community_Case_Creation_Settings__c customSetting: Community_Case_Creation_Settings__c.getAll().values()) {
                List<Community_Case_Creation_Settings__c> cccsettings = new List<Community_Case_Creation_Settings__c>();
                if(enquiryCSMapByName.containsKey(customSetting.Name)) {
                    cccsettings = enquiryCSMapByName.get(customSetting.Name);
                }
                cccsettings.add(customSetting);
                enquiryCSMapByName.put(customSetting.Name, cccsettings);
            }

            // check for correct recTypeName (to drive logic) and that the custtom setting is present
            if(recTypeName == 'COVIDGRANT' || recTypeName == 'SUPPORTGRANT' || recTypeName == 'INTERNATIONALGRANT' ) {
                if(recTypeName == 'COVIDGRANT' && enquiryCSMapByName.get('COVIDGRANT') != null) {
                    caseCustomSetting = enquiryCSMapByName.get('COVIDGRANT');
                } else if(recTypeName == 'SUPPORTGRANT' && enquiryCSMapByName.get('SUPPORTGRANT') != null){
                    caseCustomSetting = enquiryCSMapByName.get('SUPPORTGRANT');
                } else if(recTypeName == 'INTERNATIONALGRANT' && enquiryCSMapByName.get('INTERNATIONALGRANT') != null){
                    caseCustomSetting = enquiryCSMapByName.get('INTERNATIONALGRANT');
                }
                if(!caseCustomSetting.isEmpty()) {
                    Datetime d = Date.Today() ;
                    String dateStr =  d.format('dd/MM/yyyy');
                    casRec.Status = caseCustomSetting[0].Status__c;
                    casRec.Community_Enquiry_Type__c = caseCustomSetting[0].Case_Enquiry_Type__c;
                    casRec.Enquiry_Type__c = caseCustomSetting[0].enquiryType__c;
                    casRec.RecordTypeId = MonConCaseServices.SPECON_RECTYPEID;
                    casRec.Category_Level_1__c = caseCustomSetting[0].category__c;
                    casRec.Category_Level_2__c = caseCustomSetting[0].sub_category__c;
                    casRec.Origin = caseCustomSetting[0].Origin__c;
                    // map User & Contact properties
                    casRec.SuppliedEmail = UserInfo.getUserEmail(); // set to user's email as there isn't a field on the form
                    casRec.ContactId = currentUser.ContactId;
                    casRec.Faculty__c = currentUser.Contact.Faculty__c;
                    casRec.Managing_Faculty__c = currentUser.Contact.Faculty__c;
                    casRec.Campus__c = currentUser.Contact.Campus__c;
                    casRec.Description = casRec.Description + '\r\n' + '\r\nAmount Needed: ' + strAmount;
                    if(casRec.Subject != null) {
                        casRec.Subject += ' (' + currentUser.Contact.Person_ID_unique__c + ', ' + currentUser.Name + ', ' + dateStr + ')';
                    } else {
                        casRec.Subject = caseCustomSetting[0].reason_of_enquiry__c + ', ('
                                + currentUser.Contact.Person_ID_unique__c + ', ' + currentUser.Name + ', ' + dateStr + ')';
                    }
                }else{
                    throw new AuraHandledException('Could not find the settings for this enquiry.');
                }
            } else {
                throw new AuraHandledException('Could not create enquiry with the provided parameters.');
            }

            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = true;

            //Correct the emailmessage sent via auto-response to be sent out as Incoming=false
            dmlOpts.EmailHeader.triggerAutoResponseEmail = true;

            Database.SaveResult[] sr= Database.Insert(new List<Case> {casRec},dmlOpts);
            return casRec.Id;
        } catch (exception ex) {
            ExLog.add('create Enquiry','LightningCreateCaseController','createCaseCovid', ex);
            return null;
        }
    }

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017
    * @description  method will create case which takes input from CreateCaseComponent or CreateCaseForm.
    * @InputParameter: case
    * @return type  Id
    * @revision
    *               19.July.2023    Peter Sewell   Add reCaptcha validation
    *******************************************************************************/
    @AuraEnabled
    public static String createCase(Case casRec, String recTypeName, String captchaToken) {

        if(!passCaptcha(captchaToken)) {throw new AuraHandledException(ERROR_INVALID_CAPTCHA);}

        try {
            List<Community_Case_Creation_Settings__c> caseCustomSetting =  new List<Community_Case_Creation_Settings__c>();
            Map<string,list<Community_Case_Creation_Settings__c>> enquiryCSMap = new Map<string,list<Community_Case_Creation_Settings__c>>();

            for(Community_Case_Creation_Settings__c customSetting: Community_Case_Creation_Settings__c.getAll().values()) {
                List<Community_Case_Creation_Settings__c> cccsettings = new List<Community_Case_Creation_Settings__c>();
                if(enquiryCSMap.containsKey(customSetting.enquiryType__c)) {
                    cccsettings = enquiryCSMap.get(customSetting.enquiryType__c);
                }
                cccsettings.add(customSetting);
                enquiryCSMap.put(customSetting.enquiryType__c, cccsettings);
            }

            if(recTypeName == 'HR') {
                map<string,Community_Case_Creation_Settings__c> questionCaseMap = new map<string,Community_Case_Creation_Settings__c>();
                if(enquiryCSMap.get('HR') != NULL) {
                    caseCustomSetting = enquiryCSMap.get('HR');
                }

                for(Community_Case_Creation_Settings__c cs: caseCustomSetting) {
                    questionCaseMap.put(cs.reason_of_enquiry__c, cs);
                }
                if(!questionCaseMap.isEmpty()) {
                    if(questionCaseMap.get(casRec.Community_Status__c) != NULL && casRec.Community_Status__c != 'Please select an option') {
                        casRec.Channel__c = questionCaseMap.get(casRec.Community_Status__c).Channel__c;
                        casRec.Origin = questionCaseMap.get(casRec.Community_Status__c).Origin__c;
                        casRec.Tier_Level__c = questionCaseMap.get(casRec.Community_Status__c).Tier__c;
                        casRec.Category__c = questionCaseMap.get(casRec.Community_Status__c).category__c;
                        casRec.Subject = casRec.Community_Status__c;
                        casRec.Status = questionCaseMap.get(casRec.Community_Status__c).Status__c;
                        casRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(questionCaseMap.get(casRec.Community_Status__c).Record_Type_Name__c).getRecordTypeId();
                        casRec.Community_Enquiry_Type__c =  questionCaseMap.get(casRec.Community_Status__c).Case_Enquiry_Type__c;
                        casRec.sub_category__c = questionCaseMap.get(casRec.Community_Status__c).sub_category__c;
                    }
                }

            } else if (recTypeName == 'IT') {
                if(enquiryCSMap.get('IT') != NULL) {
                    caseCustomSetting = enquiryCSMap.get('IT');
                }

                if(!caseCustomSetting.isEmpty()) {
                    casRec.Origin = caseCustomSetting[0].Origin__c;
                    casRec.Status = caseCustomSetting[0].Status__c;
                    casRec.Community_Enquiry_Type__c = caseCustomSetting[0].Case_Enquiry_Type__c;
                }

                casRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(caseCustomSetting[0].Record_Type_Name__c).getRecordTypeId();
            } else {
                if(recTypeName == 'Student') {
                    if(enquiryCSMap.get('Student') != NULL) {
                        caseCustomSetting = enquiryCSMap.get('Student');
                    }

                    if(!caseCustomSetting.isEmpty()) {
                        casRec.Origin = caseCustomSetting[0].Origin__c;
                        casRec.Status = caseCustomSetting[0].Status__c;
                        casRec.Community_Enquiry_Type__c = caseCustomSetting[0].Case_Enquiry_Type__c;

                        if(currentUser.Profile.Name == Label.Guest_User_Profile_Name) {
                            casRec.User_Type__c = 'Guest';
                        } else if(currentUser.Profile.Name == Label.Community_Student_Profile_Name) {
                            casRec.User_Type__c = 'Student';
                        } else {
                            casRec.User_Type__c='Staff';
                        }
                    }
                    casRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(caseCustomSetting[0].Record_Type_Name__c).getRecordTypeId();
                }
            }
            
            if(casRec.Supplied_First_Name__c != '' && casRec.Supplied_Last_Name__c != '') {
                String tempSuppliedName = casRec.Supplied_First_Name__c+' '+casRec.Supplied_Last_Name__c;
                casRec.SuppliedName = tempSuppliedName.left(80); // limit of 80 for SuppliedName
            }

            if(casRec.contactId==null && currentUser.Profile.UserLicense.Name!='Customer Community Login') {
                String email=currentUser.Profile.Name== Label.Guest_User_Profile_Name?casRec.SuppliedEmail:userInfo.getUserEmail();
                List<contact> conList=[select id,Authcate__c,email,Monash_Email_Address__c from contact where (Authcate__c!=null and Authcate__c=:currentUser.FederationIdentifier) or (Authcate__c=null and (email=:email or Monash_Email_Address__c=:email))];
                if(conList.size()==0 && Schema.SObjectType.Contact.getRecordTypeInfosByName().containsKey(Label.Internal_User_Contact_Record_Type)) {
                    contact newContact=new Contact();
                    newContact.email=currentUser.Profile.Name == Label.Guest_User_Profile_Name?casRec.SuppliedEmail:userInfo.getUserEmail();
                    newContact.firstname=currentUser.Profile.Name== Label.Guest_User_Profile_Name?casRec.Supplied_First_Name__c:userInfo.getFirstName();
                    newContact.lastname=currentUser.Profile.Name== Label.Guest_User_Profile_Name?casRec.Supplied_Last_Name__c:userInfo.getLastName();
                    newContact.recordtypeId=Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Label.Internal_User_Contact_Record_Type).getRecordTypeId();
                    newContact.isAskMonashCreated__c=true;
                    if(Label.Guest_User_Profile_Name!=currentUser.Profile.Name) {
                        newContact.Authcate__c=currentUser.FederationIdentifier;
                    }
                    insert newContact;
                    conList.add(newContact);
                }
                if(conList.size()>0) {
                    for(contact c: conList) {
                        if(c.Authcate__c==currentUser.FederationIdentifier) {
                            casRec.contactId=c.Id;
                        }
                    }
                    List<contact> conToUpd=new List<Contact>();
                    if(casRec.contactId==null) {
                        for(contact c: conList) {
                            if(c.Authcate__c==null && (c.Email==email || c.Monash_Email_Address__c==email)) {
                                casRec.contactId=c.Id;
                                c.Authcate__c=currentUser.FederationIdentifier;
                                conToUpd.add(c);
                            }
                        }
                    }
                    if(conToUpd.size()>0) {
                        try {
                            update conToUpd;
                        }
                        catch(Exception e) {
                        }
                    }
                }
            }

            AssignmentRule rule = new AssignmentRule();
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = true;

            //Correct the emailmessage sent via auto-response to be sent out as Incoming=false
            dmlOpts.EmailHeader.triggerAutoResponseEmail = true;

            Database.SaveResult[] sr= Database.Insert(new List<case> {casRec},dmlOpts);

            // Create manual sharing for the case record if conditions are met
            String usrType = getUserType();
            if (casRec.Id != null && (recTypeName == 'HR' || recTypeName == 'Student') && (casRec.Origin == 'Web - ask.Monash' || casRec.Origin == 'ask.monash@monash.edu') && (usrType == 'Internal')) {
                createManualSharing(casRec);
            }

            // Cache the captcha token mapped to the case id - for checking on subsequent method calls from aura/lwc
            cacheTheToken(captchaToken, casRec.id);

            return casRec.id;

        } catch (exception ex) {
            ExLog.add('create Enquiry','LightningCreateCaseController','createCase', ex);
            return null;
        }

    }

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017
    * @description  method is used to insert attachment from CreateCaseComponent.
    * @InputParameter: string
    * @return type  list<sobject>
    * @revision
    *******************************************************************************/
    @AuraEnabled
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
        
        // Check max attachments not exceeded
        if (isMaxAttachments(parentId)) {
            Nebula.Logger.error('Maximum attachments reached on case: ' + parentId);
            throw new AuraHandledException(ERROR_TOO_MANY_ATTACHMENTS);
        }

        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

        Attachment a = new Attachment();
        a.parentId = parentId;

        a.Body = EncodingUtil.base64Decode(base64Data);
        a.Name = fileName;
        a.ContentType = contentType;

        insert a;

        return a.Id;
    }

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017
    * @description  method will decide whether the attachment has to be attached in chunks or can be attached as attachment directly based on attachment size.
    * @InputParameter: Id,string,string,string,string
    * @return type  Id
    * @revision
    *******************************************************************************/
    @AuraEnabled
    public static Id saveTheChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId, String captchaToken) {
        // Revalidate captcha token against case id
        if(!passCaptchaCached(captchaToken, parentId)){throw new AuraHandledException(ERROR_INVALID_CAPTCHA);}

        if (fileId == '' || fileId ==null) {
            fileId = saveTheFile(parentId, fileName, base64Data, contentType);
        } else {
            fileId = appendToFile(fileId, base64Data);
        }
        return Id.valueOf(fileId);
    }

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017
    * @description  method is used to update attachment body in chunks.
    * @InputParameter: Id, String
    * @return type
    * @revision
    *******************************************************************************/
    private static Id appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

        Attachment a = [
                           SELECT Id, Body
                           FROM Attachment
                           WHERE Id = :fileId
                       ];

        String existingBody = EncodingUtil.base64Encode(a.Body);
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data);

        update a;
        return a.Id;
    }

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017
    * @description  method to return User First Name
    * @Input Parameters:
    * @return type: string
    * @revision
    *******************************************************************************/
    @AuraEnabled
    public static string getUserFirstName() {

        string firstName = '';

        if(currentUser.Profile.Name != Label.Guest_User_Profile_Name) {
            firstName = ' '+currentUser.firstname;
        }

        return firstName;
    }
    /*******************************************************************************
    * @author       Vaibhav B, PwC
    * @date         9.Spetember.2017
    * @description  method to return allowed File Types
    * @Input Parameters:
    * @return type: List<string>
    * @revision
    *******************************************************************************/

    @AuraEnabled
    public static List<string> getAllowedFileTypes() {
        return Label.AllowedAttachmentTypes.replaceAll(' ','').split(',');
    }

    /*******************************************************************************
    * @author       Vaibhav B, PwC
    * @date         10.October.2017
    * @description  method to return emails considered as Monash Emails
    * @Input Parameters:
    * @return type: List<string>
    * @revision
    *******************************************************************************/

    @AuraEnabled
    public static List<string> getMonashEmails() {
        return Label.MonashEmails.replaceAll(' ','').split(',');
    }

    @AuraEnabled
    public static List<String> retrieveLocationOptions() {
        List<String> items = new List<String>();
        try {
            Schema.DescribeFieldResult fieldResult = Case.Supplied_Country_of_Residence__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple) {
                items.add(pickListVal.getLabel());
            }
        } catch (Exception e) {
            Nebula.Logger.error(e.getMessage());
        }
        return items;
    }
    // Does the user pass captcha validation
    //
    private static Boolean passCaptcha(String token) {
        // Skip validation?
        if (isSkipCaptcha()) {return true;}

        // Otherwise validate the token 
        if (String.isBlank(token)) {return false;}
        return ReCaptchaService.validateCaptchaToken(token);
    }

    // Is the captcha token cached and does it match value?
    //
    private static Boolean passCaptchaCached(String token, String value) {
        // Skip validation?
        if (isSkipCaptcha()) {return true;}

        return doPassCaptchaCached(token, value);
    }

    // Cache token and value in Org cache for later validation
    //
    private static void cacheTheToken(String token, String value) {
        if (isSkipCaptcha()) {return;}
        doCacheTheToken(token, value);
    }

    // Dont require Captcha for all uses and scenarios
    //
    private static Boolean isSkipCaptcha() {
        // Skip captcha check for the following scenarios
        if (!(UserInfo.getUserType() == 'Guest')) {
            return true;
        }
        if (Test.isRunningTest()) {
            return true;
        }
        // Otherwise no skip
        return false;
    }

    // Cache token and value in Org cache
    //
    @TestVisible
    private static void doCacheTheToken(String token, String value) {
        if (String.isBlank(token)) {return;}
        Cache.Org.put(convertTokenToKey(token), value, 300);
    }

    /// (re) validate that the token 'maps' to 'value' from org cache
    //
    @TestVisible
    private static Boolean doPassCaptchaCached(String token, String value) {

        String key = convertTokenToKey(token);
        if (String.isBlank(key)) {
            return false;
        }
        if (!Cache.Org.contains(key)) {
            return false;
        }
        String cachedValue = (String) Cache.Org.get(key);
        if (cachedValue != value) {
            return false;
        }
        // Validation passed
        return true;
    }

    // Convert Google captch token into string suitable for Org cache key
    //
    @TestVisible
    private static String convertTokenToKey(String token) {
        if (String.isBlank(token)) {return '';}
        String key = String.valueOf(token.hashCode());
        key = key.replace('-', '0'); // replace negative sign
        key = 'key' + key; // prefix with alpha chars
        return key;
    }

    // Method to create manual sharing for the case record if conditions are met
    private static void createManualSharing(Case casRec) {
        // Create manual sharing entry for the case creator
        CaseShare caseShare = new CaseShare();
        caseShare.CaseId = casRec.Id;
        caseShare.UserOrGroupId = UserInfo.getUserId();
        caseShare.CaseAccessLevel = 'Read'; // Adjust access level as needed
        caseShare.RowCause = 'Manual';
        // Insert manual sharing entry
        Database.SaveResult shareResult = Database.insert(caseShare, false);
        if (!shareResult.isSuccess()) {
            for (Database.Error error : shareResult.getErrors()) {
                Nebula.Logger.error(error.getMessage());
            }
        }
    }

    // Check if number of attachments is at maximum
    private static boolean isMaxAttachments(Id parentId) {
        List<Attachment> atts = new List<Attachment>();
        
        atts = [SELECT Id FROM Attachment WHERE parentId = :parentId];

        // No attachments
        if (atts == null) {return false;}
        
        // Less than 3 attachments
        if (atts.size() < 3 ) {return false;}

        return true;
    }
}