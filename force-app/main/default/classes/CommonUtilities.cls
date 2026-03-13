/**
 * @author       Ryan Wilson
 * @date         22.Nov.2016
 * @description  Common Utility class
 * @revision     FEB.28.2017    ACUSTODIO,  - requeried the parameter list to retrieve the merge fields
 *                                            used on sending emails to the email sender
 *               APR.11.2018    Nick Guia   - created getDateTimeDifference
 *                                          - moved fieldHasChanged in this class
 *                                          - moved mergeRecordList here from StagedProspectiveStudentUtil
 *               NOV.15.2018    K Liew      - added methods as part of refactoring of Contact Name logic,
 *                                            changing to Title Case and stripping of numbers.  Originally
 *                                            in class InbContactServices.
 *               DEC.07.2018    Nick Guia   - Added static 'Event' strings
 *               JAN.07.2020    Nick Guia   - added LastActivityDate into SYSTEM_FIELDS
 *               June.02.2021   Steffi      - added createNicknameForUser PENGAGE-1867
 *               Mar.10.2022    Rumi        - Modified getGlobalMonashAccountId() to set accountId after account is inserted
 *               June.27.2022   Inderpal    - added userSessionTermiation PENGAGE-2242
 *               SEPT.28.2022   Nick Guia   - Added isOverride mechanism when merging SObject records
 *               NOV.07.2022    Vinothraja  - Added method to fetch values from a Picklist
 * 				 JUL.19.2023    Inderpal D  - Added method to retrieve Month Names MCT-154
 *  			 MAR.15.2024    Inderpal D  - Added method to update Last Login date PENGAGE-2730
 *               JUN.05.2024    Martin C    - fieldHasChanged made case senstive
 *               OCT.09.2024    Martin C    - Overloaded fieldHasChanged 
 *               AUG.14.2025    Matt M      - PMD Cleanup
 */
/*******************************************************************************
   !!!!!! WARNING !!!!!!!!!
   LeadN has switched the relationship between Role and Channel.
   Some code has been commented out in this file to accomodate.
   Please search for "LeadN" to find the lines that has been commented out.
*******************************************************************************/

public class CommonUtilities {
    public static final String BMS_ADMIN = 'BMS Admin';
    public static final String SYSTEM_ADMIN = 'System Administrator';
    public static final String EVENT_INSERT = 'insert';
    public static final String EVENT_UPDATE = 'update';
    public static final String EVENT_UPSERT = 'upsert';
    public static final String EVENT_DELETE = 'delete';

    public static final Set<String> SYSTEM_FIELDS = new Set<String> {
        'Name',
        'Id',
        'IsDeleted',
        'CreatedById',
        'CreatedDate',
        'LastModifiedById',
        'LastModifiedDate',
        'SystemModstamp',
        'LastViewedDate',
        'LastReferencedDate',
        'LastTransferDate',
        'LastActivityDate',
        'PhotoUrl' // for Leads
    };

    public static Id GLOBAL_MONASH_ACCOUNT_ID {
        get {
            if(GLOBAL_MONASH_ACCOUNT_ID == null) {
                GLOBAL_MONASH_ACCOUNT_ID = getGlobalMonashAccountId();
            }
            return GLOBAL_MONASH_ACCOUNT_ID;
        } set;
    }

    public static Set<Id> MARKETING_SUB_LISTS {
        get {
            if(MARKETING_SUB_LISTS == null) {
                MARKETING_SUB_LISTS = getMarketingSubLists();
            }
            return MARKETING_SUB_LISTS;
        } set;
    }

    public CommonUtilities() {}

    /**
     * @author      Inderpal DHanoa
     * @description Method that updates login details
     * @revision    15/03/2024 - Inderpal DHanoa - Created
     */
    @future
    public static void updateLastPortalLoginDate(Id userId, String sPortalName){
        Network portalNetwork = [SELECT Id FROM Network Where Name = :sPortalName];
        List<LoginHistory> lastSuccessfulPortalLogin = new List<LoginHistory>();
        for(LoginHistory eachLogin : [SELECT LoginTime, Status
                                      FROM LoginHistory 
                                      WHERE NetworkId = :portalNetwork.Id 
                                      AND UserId = :userId
                                      ORDER BY LoginTime DESC LIMIT 10]){
            if(eachLogin.Status == 'Success'){
                lastSuccessfulPortalLogin.add(eachLogin);break;
            }
        }
        if(!lastSuccessfulPortalLogin.isEmpty()){
            List<User> linkedUserDetails = [SELECT Id, ContactId, Contact.Last_Ascend_Portal_Login__c FROM User WHERE Id = :UserId AND Last_2FA_Login__c != null];
            if(!linkedUserDetails.isEmpty()){
                Contact updateContTimeDetails = new Contact (Id = linkedUserDetails[0].ContactId, Last_Ascend_Portal_Login__c = lastSuccessfulPortalLogin[0].LoginTime);
                try{
                    update updateContTimeDetails;
                }catch(Exception ex){
                    Nebula.Logger.exception('CommitQueryRecords updateLastPortalLoginDate '+userId+ ' Portal Name ' + sPortalName + '. ' + ex.getMessage(), ex);
                }
            }
        }
    }
	
	 /**
     * @author      Inderpal Dhanoa
     * @date        30/06/2022
     * @description Terminate User session  
     * @revision    Initial
     */
	public static void terminateUserSession(Id userId){
        try{
            List<AuthSession> loggedUserSession = [SELECT Id FROM AuthSession WHERE UsersId = :userId AND IsCurrent = false];
            if(!loggedUserSession.isEmpty()){
                delete loggedUserSession;
            }
        }catch(Exception ex){
            LogUtilityException.LogException(ex);
        }
    }

    public static void sendBMSEmail(List<Campaign> massEmailList) {
        String admStudentEmail = System.label.StudentCommsEmail;

        //requery the mass email list to re-reference the fields being used in the class
        List<Campaign> requeriedMassEmailList = [  SELECT  Id,
                               Email_Template__c,
                               Reply_To__c,
                               Additional_Email__c,
                               Notify__c,
                               Name,
                               Message_Header__c,
                               Custom_Message__c,
                               Type,
                               SMS_Body__c
                               FROM Campaign
                               WHERE Id IN: massEmailList];


        OrgWideEmailAddress senderEmail = [SELECT Address,DisplayName,Id FROM OrgWideEmailAddress WHERE DisplayName = 'Monash Student Global'];
        Id studentGlobalId = senderEmail.Id;

        Map<String, EmailTemplate> mapTemplates = new Map<String, EmailTemplate>();

        Folder bmsFolder = [SELECT DeveloperName,Id,Name,Type FROM Folder WHERE Name = 'BMS Emails'];

        for(EmailTemplate template: [SELECT Id, HtmlValue, FolderId, Name FROM EmailTemplate WHERE FolderId =:bmsFolder.Id]) {
            mapTemplates.put(template.Name, template);
        }

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

        for(Campaign cme: requeriedMassEmailList) {
            Messaging.SingleEmailMessage additionalMail = new Messaging.SingleEmailMessage();
            additionalMail.setSaveAsActivity(false);
            if (cme.Type != 'SMS') {
                additionalMail.setTemplateId(mapTemplates.get(cme.Email_Template__c).Id);
            }
            additionalMail.setOrgWideEmailAddressId(studentGlobalId);

            if(cme.Reply_To__c != null) {
                additionalMail.setReplyTo(cme.Reply_To__c);
            }

            if(cme.Additional_Email__c != null) {
                String tempStr = cme.Additional_Email__c;
                String[] strAddEmails = tempStr.split(';');
                additionalMail.setToAddresses(strAddEmails);
            }

            List<String> strCCEmails = new List<String>();
            if(cme.Notify__c != null) {
                String tempCC = cme.Notify__c;
                strCCEmails = tempCC.split(';');
            }
            strCCEmails.add(admStudentEmail);
            additionalMail.setBccAddresses(strCCEmails);

            String htmlBody = '';
            if (cme.Type != 'SMS') {
                htmlBody = mapTemplates.get(cme.Email_Template__c).HtmlValue;
                if (cme.Name != null) {
                    htmlBody = htmlBody.replace('[SUBJECT]', cme.Name);
                }
                if (cme.Message_Header__c != null) {
                    htmlBody = htmlBody.replace('[MESSAGE_HEADER]', cme.Message_Header__c);
                }
                if (cme.Custom_Message__c != null) {
                    htmlBody = htmlBody.replace('[CAMPAIGN_MESSAGE]', cme.Custom_Message__c);
                } else {
                    htmlBody = htmlBody.replace('[CAMPAIGN_MESSAGE]', '');
                }

                if(mapTemplates.get(cme.Email_Template__c).Name.contains('Student')) {
                    htmlBody = htmlBody.replace('[CONTACT_NAME]', 'Student');
                } else if (mapTemplates.get(cme.Email_Template__c).Name.contains('Staff')) {
                    htmlBody = htmlBody.replace('[CONTACT_NAME]', 'Colleague');
                }

            } else if (cme.Type == 'SMS') {
                htmlBody = cme.SMS_Body__c;
            }
            additionalMail.setHtmlBody(htmlBody);
            additionalMail.setSubject(cme.Name);
            messages.add(additionalMail);
        }

        try {
            if(messages.size() >0) {
                Messaging.sendEmail(messages);
            }
        }
        catch(Exception ex) {
            Nebula.Logger.exception('CommonUtiltiies.sendBMSEmail - Error encountered while sending email: ' + ex.getMessage(), ex);
        }
    }
	
	/**
     * @description retrieve all the Month Long Names with Month Numbers
     */
    public static Map<Integer,String> getLongMonthNameWithMonthNumber () {
        Map<Integer,String> monthNumberMonthLongName = new Map<Integer,String>();
        monthNumberMonthLongName.put(1,'January');
        monthNumberMonthLongName.put(2,'February');
        monthNumberMonthLongName.put(3,'March');
        monthNumberMonthLongName.put(4,'April');
        monthNumberMonthLongName.put(5,'May');
        monthNumberMonthLongName.put(6,'June');
        monthNumberMonthLongName.put(7,'July');
        monthNumberMonthLongName.put(8,'August');
        monthNumberMonthLongName.put(9,'September');
        monthNumberMonthLongName.put(10,'October');
        monthNumberMonthLongName.put(11,'November');
        monthNumberMonthLongName.put(12,'December');
        return monthNumberMonthLongName;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         02.Mar.2017
    * @description  retrieves the send type (Email or SMS)
    * @revision
    *******************************************************************************/
    public static String retrieveSendType () {
        String sendType = 'email';
        if(Apexpages.currentpage().getparameters().containsKey('type')) {
            sendType = Apexpages.currentpage().getparameters().get('type').escapeHtml4();
            if (sendType != 'email' && sendType != 'sms') {
                //auto set to email when none specified
                sendType = 'email';
            }
        }
        return sendType;
    } 

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         17.Mar.2017
    * @description  retrieves profile name
    * @revision
    *******************************************************************************/
    public static String getProfileName () {
        String currentUserProfile = [SELECT Id, Name FROM Profile WHERE Id =: userinfo.getProfileId() ].Name;
        return currentUserProfile;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         17.Mar.2017
    * @description  validates the email address
    * @return       returns false if invalid and true if valid
    * @revision     14/03/2018 = Stefan Scheit - Changed regex
    *******************************************************************************/
    public static Boolean validateEmail(String email) {
        Boolean isValid = false;
        // regex pattern taken from: https://help.salesforce.com/articleView?id=000170904&language=en_US&type=1
        String emailRegex = '^([a-zA-Z0-9_%+\\-\\.\\*\\^/!#$&\'=?`{|}~])+@((([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})$';
        Pattern myPattern = Pattern.compile(emailRegex);
        Matcher myMatcher = myPattern.matcher(email);

        if (myMatcher.matches()) {
            isValid = true;
        }
        return isValid;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         17.Mar.2017
    * @description  inserting custom campaignMemberStatuses based on Campaign_Member_Status__mdt
    * @revision     22/03/2018 = APRIVERA - Refactor method for flexible addition of Campaign Member status via custom metadata
                    14/08/2025 = MMARAMOT - Removed System Debug
    NOTE: THIS METHOD TO BE REVIEWED FOR REMOVAL AS CAMPAIGN MEMBER STATUS IS AUTOMATICALLY CREATED 
          AS PART OF CampaignTriggerHandler.createCampaignMemberStatuses
    *******************************************************************************/
    public static void assignCampaignMemberStatus(Id campaignId) {
        List<CampaignMemberStatus> campMemStatus = new List<CampaignMemberStatus>();
        // 22/03/2018 = APRIVERA - BMS 2.0 - Added new status on Campaign - START
        List<Campaign_Member_Status__mdt> lstCmpMemberStatus = [Select Id, MasterLabel, Campaign_Record_Type__c
                       from Campaign_Member_Status__mdt where Campaign_Record_Type__c='BMS'];

        if(!lstCmpMemberStatus.isEmpty()) {
            for(Campaign_Member_Status__mdt cmpMemberStat : lstCmpMemberStatus) {
                campMemStatus.add(new CampaignMemberStatus(CampaignId=campaignId, Label=cmpMemberStat.MasterLabel));
            }
        }
        // 22/03/2018 = APRIVERA - BMS 2.0 - Added new status on Campaign - END

        try{
            insert campMemStatus;
        }
        catch(Exception ex){
            nebula.logger.exception('CommonUtiltiies.assignCampaignMemberStatus ' +ex.getMessage(), ex);
        }
    }

    // Retrieve inserted or updated Role record
    public static List<Roles__c> getRoles(Set<Id> roleIds) {
        String strQueryString = queryBuilder('Roles__c');
        String commaSepratedFields = getAllFields('Roles__c');
        String contactFields = ', Contact__r.CRM_Id__c, '
                               +'Contact__r.Person_ID__c, '
                               +'Contact__r.Title, '
                               +'Contact__r.Birthdate, '
                               +'Contact__r.First_Name__c, '
                               +'Contact__r.Last_Name__c, '
                               +'Contact__r.Gender__c, '
                               +'Contact__r.Preferred_Name__c ';
        //LeadN :: +'Channel__r.Name';

        String queryString = 'SELECT ' + commaSepratedFields + contactFields +' FROM Roles__c WHERE Id IN:roleIds';

        List<Roles__c> roleList = Database.Query(queryString);
        return roleList;
    }

    // Retrieve inserted or updated Channel record
    public static List<Channel__c> getChannels(Set<Id> channelIds) {
        String commaSepratedFields = getAllFields('Channel__c');
        String contactFields = ', Contact__r.CRM_Id__c, '
                               +'Contact__r.Person_ID__c, '
                               +'Contact__r.Title, '
                               +'Contact__r.Birthdate, '
                               +'Contact__r.First_Name__c, '
                               +'Contact__r.Last_Name__c, '
                               +'Contact__r.Gender__c, '
                               +'Contact__r.Preferred_Name__c';

        String queryString = 'SELECT ' + commaSepratedFields + contactFields +' FROM Channel__c WHERE Id IN:channelIds';

        List<Channel__c> roleList = Database.Query(queryString);
        return roleList;
    }

    // Get all fields for a specific object
    public static String getAllFields(String sobjName) {
        if(sobjName != null && sobjName != '') {
            String sobjectApiName = sobjName;
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sobjectApiName).getDescribe().fields.getMap();
            String commaSepratedFields = '';
            for(Schema.SObjectField val : fieldMap.values()) {
                if(val.getDescribe().isAccessible()) {
                    if(commaSepratedFields == null || commaSepratedFields == '') {
                        commaSepratedFields = val.getDescribe().getName();
                    } else {
                        commaSepratedFields = commaSepratedFields + ', ' + val.getDescribe().getName();
                    }
                }
            }

            return commaSepratedFields;
        }
        return null;
    }

    // Get Picklist values 
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPicklistValues(String sObjName, String sFieldName) {
        Map<String, String> options = new Map<String, String>();
        if(String.isNotBlank(sobjName) && String.isNotBlank(sFieldName)) {

            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sobjName).getDescribe().fields.getMap();

            Schema.DescribeFieldResult fieldResult = fieldMap.get(sFieldName).getDescribe();
            List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry p: pList) {
                //Put Picklist Value & Label in Map
                options.put(p.getValue(), p.getLabel());
            }
        }
        return options;
    }

    // Generic method that generates a query for all fields on any object
    public static String queryBuilder(String sobjName) {
        if(sobjName != null && sobjName != '') {
            String sobjectApiName = sobjName;
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sobjectApiName).getDescribe().fields.getMap();
            String commaSepratedFields = '';
            for(Schema.SObjectField val : fieldMap.values()) {
                if(val.getDescribe().isAccessible()) {
                    if(commaSepratedFields == null || commaSepratedFields == '') {
                        commaSepratedFields = val.getDescribe().getName();
                    } else {
                        commaSepratedFields = commaSepratedFields + ', ' + val.getDescribe().getName();
                    }
                }
            }

            String query = 'select ' + commaSepratedFields + ' from ' + sobjectApiName;
            return query;
        }
        return null;
    }

    /**
     * @author Nick Guia
     * @description - gets the time difference (in seconds) between two
     *                DateTime values. We are getting the difference regardless
     *                of which one is greater by getting absolute value
     * @return - Long value of time difference in seconds
     */
    public static Long getDateTimeDifference(DateTime dt1, DateTime dt2) {
        Long diff;
        if(dt1 != null && dt2 != null) {
            //get millisec value of date times
            Long dt1Time = dt1.getTime();
            Long dt2Time = dt2.getTime();

            //get difference, get absolute value, then convert to seconds
            diff = (Math.abs(dt1Time - dt2Time)) / 1000;
        }
        return diff;
    }

   /**
    * @description Utility to confirm if field has changed  - case sensitive
    * @param fieldname : the API name of the field to look at
    *        newObj : the new version of the sObject to be considered
    *        oldObj : the previous or older version of the sObject to be considered
    * @return boolean confirming if change has been observed or not
    */
    public static Boolean fieldHasChanged(String fieldName, SObject newObj, SObject oldObj) {
        try {

            if (fieldName == null || newObj == null || oldObj == null) { 
                return false;
            }

            // get the value of the field
            object oldf = oldObj.get(fieldName); 
            object newf = newObj.get(fieldName);
            if (oldf == null && newf == null) { 
                return false;
            } else {
	            return valueDiff(oldf, newf);
            }
        } catch (exception ex) {
			nebula.logger.exception(ex.getMessage(), ex);
            return false;
        }
    }

   /**
    * @description Utility to confirm if a value has changed - case sensitive
    * @param oldf : the old value as an object
    *        newf : the new value as an object
    * @return boolean confirming if change has been observed or not
    */
    public static Boolean valueDiff(Object oldf, Object newf) {
        try {
            if (oldf == null && newf == null) { 
                return false;
            } else {
                // the hashcode method will fail if value is null
                if (oldf == null) {oldf = 'oldvalue';}
                if (newf == null) {newf = 'newvalue';}
                return (!newf.hashCode().equals(oldf.hashCode())) ? true : false;
            }
        } catch (exception ex) {
			nebula.logger.exception(ex.getMessage(), ex);
            return false;
        }
    }
    
    /**
    * @description utility method to create a map of parent Id with value
    *              as List of it's child records
    * @param sobjList : list of child records
    *        key : String value field API name to serve as key of map
    * @return map of key String and list of common 'child' records
    * @revision
    *   01/28/2018  Nick Guia   - modified method to also handle String as keys, aside from just lookup fields
    *                           - renamed method from addListToMapByParentId to addListToMapByKey
    */
    public static Map<String, List<SObject>> addListToMapByKey(List<Sobject> sobjList, String key) {
        Map<String, List<SObject>> sobjMapByKey = new Map<String, List<sObject>>();

        for(SObject obj : sobjList) {
            if(obj.get(key) != null) {
                String sKey = String.valueOf(obj.get(key)); //parse object return type to String
                List<SObject> objList = sobjMapByKey.get(sKey);
                if(objList == null) objList = new List<SObject>();
                objList.add(obj);
                sobjMapByKey.put(sKey, objList);
            }
        }

        return sobjMapByKey;
    }

    /**
     * @description method for merging list of records : LATEST - GREATEST
     *              merge only if latest record's field is null or empty
     * @param objList : list of SObject records to be merged
     */
    public static SObject mergeRecordList(List<SObject> objList) {
        SObject oReturn;
        if(objList != null && !objList.isEmpty()) {
            if(objList.size() > 1) {
                //merge
                for(Integer i = 0; (i+1) < objList.size(); i++) {
                    oReturn = mergeRecords(objList[i], objList[i+1]);
                }
            } else {
                //get the only record in the list
                oReturn = objList[0];
            }
        }
        return oReturn;
    }

    /**
     * @description method for merging list of records : OLDEST - GREATEST
     *              merge only if oldest record's field is null or empty
     * @param objList : list of SObject records to be merged
     */
    public static SObject mergeRecordListOldestGreatest(List<SObject> objList) {
        SObject oReturn;
        if(objList != null && !objList.isEmpty()) {
            if(objList.size() > 1) {
                //merge
                for(Integer i = 0; (i+1) < objList.size(); i++) {
                    oReturn = mergeRecords(objList[i], objList[0]);
                }
            } else {
                //get the only record in the list
                oReturn = objList[0];
            }
        }
        return oReturn;
    }

    /**
     * @description get all populated fields in 2nd param and cast them to 1st param
     *        NOTE: getPopulatedFieldsAsMap() method behaves as follows:
     *              - The field has been queried by a SOQL statement
     *              - The field has been explicitly set before the call to the getPopulatedFieldsAsMap() method
     *          This means that the method could also pull null values if it was explicitly set.
     *          ref: https://releasenotes.docs.salesforce.com/en-us/summer16/release-notes/rn_apex_sobject_getmap.htm
     * @param origObj : record to be overwritten
     * @param newObj : record to overwrite
     * @param isOverrideAccessible : indicates if FLS should be checked before merging or not
     */
    public static SObject mergeRecords(SObject origObj, SObject newObj, Boolean isOverrideAccessible) {
        SObject returnObj;
        //if newObj is null - return origObj
        if(origObj != null && newObj == null) {
            returnObj = origObj;
            //if origObj is null - return newObj
        } else if(origObj == null && newObj != null) {
            returnObj = newObj;
            //otherwise, merge
        } else if(origObj != null & newObj != null) {
            //get global describe
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            //get field mapping of newObj (object to supersede)
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(newObj.getSObjectType().getDescribe().getName()).getDescribe().fields.getMap();
            //get all populated fields of newObj and put them to a map
            Map<String, Object> fieldsToValue = newObj.getPopulatedFieldsAsMap();
            //clone origObj (to be overwritten)
            returnObj = origObj.clone(false, true, true, true);

            //merge field if Accessible, non-formula field, and not a system field
            for(String fieldName : fieldsToValue.keySet()) {
                DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
                if((isOverrideAccessible || dfr.isAccessible()) && 
                    !dfr.isCalculated() && !dfr.isAutoNumber() &&
                    !SYSTEM_FIELDS.contains(fieldName))
                {
                    //make sure no null value is saved in memory
                    if(fieldsToValue.get(fieldName) != null) {
                        returnObj.put(fieldName, fieldsToValue.get(fieldName));
                    }
                }
            }
        }

        return returnObj;
    }

    /**
     * @description overload - defaults isOverrideAccessible to false (will check FLS)
     * @param origObj : record to be overwritten
     * @param newObj : record to overwrite
     */
    public static SObject mergeRecords(SObject origObj, SObject newObj) {
        return mergeRecords(origObj, newObj, false);
    }

    /*******************************************************************************
    * @author       K Liew
    * @date         15.Nov.2018
    * @description  Existing code 'refactored' from InbContactServices' 'correctName'
    *               and 'toProperCase' methods.  Method signature may change slightly
    *               but core logic remains the same.
    * @return
    * @revision
    *******************************************************************************/
    public static String correctName(String inName) {
        String outNname = toProperCase(inName);
        if(outNname.containsAny('1234567890')) {
            outNname = outNname.replaceAll('[0-9]', '');
        }
        return outNname;
    }

    public static String toProperCase(String value) {
        // Normalize - Convert to lowercase
        value = value.toLowerCase();
        // Hold each word
        List<String> pieces = new List<String>();
        // Split
        for(String s : value.split(' ')) {
            // Capitalize each piece
            s = s.capitalize();
            // Add to pieces
            pieces.add(s);
        }
        // Join
        return String.join(pieces, ' ');
    }

    /**
     * @description get Global Monash Account ID from custom setting.
     *  If running from test context and custom setting isn't setup yet,
     *  create a test record. This is to enable parallel test runs for multiple
     *  classes trying to get an instance of this setting
     */
    private static Id getGlobalMonashAccountId() {
        Id globalMonashaccountId;
        Global_Monash_Account__c idSetting = Global_Monash_Account__c.getOrgDefaults();
        if(idSetting.Id__c != null) {
            globalMonashaccountId = Id.valueOf(idSetting.Id__c);
        } else if(Test.isRunningTest()) {
            //for test classes, create a test Global Monash Account and use ID in custom setting
            Account acc = new Account(Name='Monash University Global Account');
            insert acc;
            globalMonashaccountId = acc.Id;

            Global_Monash_Account__c globalAcc = new Global_Monash_Account__c();
            globalAcc.Id__c = '' + acc.Id;
            insert globalAcc;
        }
        return globalMonashaccountId;
    }
      /*
     * Helper method to append value to multi-picklist if it is not present already.
     */
    public Static String appendToMultiPicklist(String currentValue, String newValue) {
        // something to be added
        if(String.isNotBlank(newValue)) {
            // avoid null
            if(String.isBlank(currentValue)) {
                currentValue = '';
            }
            // only append value, if not already present
            if (!currentValue.toLowerCase().contains(newValue.toLowerCase())) {
                // if there are existing values, append ';' prior to new value
                if (String.isNotEmpty(currentValue)) {
                    currentValue += ';';
                }
                currentValue += newValue;
            }
        }
        return currentValue;
    }
  /*
     * Helper method to return alias for User creation.
     */
    public Static String createAliasForUser(String firstName, String lastName) {
       
        String alias = '';
        if(String.isEmpty(firstName)) {
        	alias = lastName;	    
        }
        else{
            alias = firstName.charAt(0)+lastName;	
        }
        if(alias.length()>8){
            alias = alias.abbreviate(8);
        }
            
        return alias;
    }
    /*
     * Helper method to return Nickname for User creation.
     */
    public Static String createNicknameForUser(String firstName, String lastName, integer i) {
        
        String nickName = '';
        if(String.isEmpty(firstName)) {
        	nickName = i + lastName;	    
        }
        else{
            nickName = i + firstName.charAt(0)+lastName ;	
        }
        
        if(nickName.length()>8){
            nickName = i + nickName.abbreviate(8);
        }
            
        return nickName;
    }

    /**
     * @description get the Marketing Subscription List Campaigns from custom settings.
     *  If running from test context, create test records to do the heavy lifting
     *  for the getter.
     */
    private static Set<Id> getMarketingSubLists() {
        Set<Id> campaignIds = new Set<Id>();
        Marketing_Subscription_List__c listSetting = Marketing_Subscription_List__c.getOrgDefaults();
        //monash info and Events
        Id mie = (Id) listSetting.MIE__c;
        //Market Research participation
        Id mr = (Id) listSetting.MR__c;
        //add here....
        
        campaignIds.add(mie);
        campaignIds.add(mr);
        return campaignIds;
    }
    /**
     * @description limitStringLengthByDescribe Limits String Length By Describe Unicode Max length
     */ 
    public static SObject populateSObjectStrLengthByDescribe(String sValue, SObject record, Schema.sObjectField sfield){
        //
        if(record.get(sfield) != null){
            Integer lng = sfield.getDescribe().getLength();
            record.put(sfield, limitStringLength(sValue, lng));
        }
        return record;
    }
    /**
     * @description limitStringLength SubString Limit String length
     */ 
    public static String limitStringLength(String str, Integer lng){
        String nVal = str;
        if(String.isNotBlank(nVal)){
            if(nVal.length() > lng){
                return nVal.substring(0, lng);
            }
        }
        return nVal;
    }
    /*
     * Inline class to update the user record (without sharing context)
     */
    public without sharing class UserUpdateHandler {
        
        public void updateCommunityAccess(String Username, String CommunityName) { 
            try {
                List<User> userList = [SELECT Id, Community_Access__c FROM User WHERE Username = :Username LIMIT 1];
                if(!userList.isEmpty()) {
                    User updateUser = userList[0];
                    String strCommAccess = updateUser.Community_Access__c;
                    // if the field is null or does not contain the community name, add it
                    if(String.isBlank(strCommAccess) || !strCommAccess.containsIgnoreCase(CommunityName)) {
                        updateUser.Community_Access__c = CommonUtilities.appendToMultiPicklist(updateUser.Community_Access__c, CommunityName);
                        update updateUser;
                    }
                }       
            } catch(exception err) {
                LogUtilityException.logExceptionMSG('Error', 'User', err.getMessage());
            }
		}
    }
}