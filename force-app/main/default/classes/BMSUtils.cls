/**
* @author           Nick Guia
* @date             07/08/2017
* @description      - Singleton mainly used for Bulk Messaging System (BMS).
*					  Class contains all configurable variables.
* @revision
*
**/
public with sharing class BMSUtils {

	public static final String BMS_EMAIL_REVIEW_ROW_LIMIT = '200';
    public static final String BMS_NEW_EMAIL_SEARCH_LIMIT = '100';
    public static final String NONE_STR = 'NONE';
	public static final Set<String> adminProfiles = new Set<String> {
														'System Administrator',
														Label.BMS_Admin_Profile
													};
    public static final Map<String, String> soqlOperators = new Map<String, String> {
                                                                'equals' => '=',
                                                                'not equal to' => '!=',
                                                                'contains (separate by comma or space)' => 'IN',
                                                                'less than or equal' => '<=',
                                                                'greater than or equal' => '>=',
                                                                'includes' => 'IN',
                                                                'does not include' => 'NOT IN'
                                                            };
    public static final Set<String> listTypeOperators = new Set<String> {
                                                                'IN', 'NOT IN'
                                                            };
    public static final Id bmsRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName()
                                                             .get(Label.Campaign_Record_Type_BMS)
                                                             .getRecordTypeId();
    /**
    * @description campaign statuses that are visible in BMSEmailReviewV2
    *              Update this and BMSEmailReviewCCV2.buildQueryString().filter
    *              if we want to put additional statuses
    **/
    public static List<String> campaignStatusList {
        get {
            if(campaignStatusList == null) {
                campaignStatusList = new List<String>{
                    Label.Campaign_Status_On_Hold,
                    Label.Campaign_Status_Approved,
                    Label.Campaign_Status_Cancelled
                };
            }
            return campaignStatusList;
        }
        set;
    }

    /**
    * @description campaign type list visible in BMSEmailReviewCCV2
    **/
    public static List<String> campaignTypeList {
        get {
            if(campaignTypeList == null) {
                campaignTypeList = new List<String>{
                    Label.Campaign_Type_Email,
                    Label.Campaign_Type_SMS
                };
            }
            return campaignTypeList;
        }
        set;
    }
    
    //for caching values
    private static Boolean isAdmin;
    private static String profileName;
    private static SelectOptionWrapper filterFieldOptions;
    private static SelectOptionWrapper allStaffOptions;
    private static SelectOptionWrapper unitOfferingOptions;
    private static List<SelectOption> cohortOptions;
    private static List<SelectOption> emailOptions;
    private static Map<Id, EmailTemplate> emailTemplatesById;

    /** PUBLIC CLASSES **/

    /**
	* @description Fields available for filtering recipients in BMSNewEmailPageV2CC.
	*			   Fields are based on the configured 'Bulk_Messaging_Filter' fieldset in contact
	**/
    public static SelectOptionWrapper getFilterFieldOptionWrapper() {
        //check if value has not been cached
        if(filterFieldOptions == null) {
            //cache value
            filterFieldOptions = generateSelectOptionWrapperFromFieldSet(SObjectType.Contact.FieldSets.Bulk_Messaging_Filter, true);
        }
        return filterFieldOptions;
    }

    /**
    * @description Fields available for filtering recipients in BMSNewEmailPageV2CC.
    *              Fields are based on the configured 'Bulk_Messaging_Filter' fieldset in contact
    **/
    public static SelectOptionWrapper getAllStaffOptionWrapper() {
        //check if value has not been cached
        if(allStaffOptions == null) {
            //cache value
            allStaffOptions = generateSelectOptionWrapperFromFieldSet(SObjectType.Contact.FieldSets.Staff_Bulk_Messaging_Filter, true);
        }
        return allStaffOptions;
    }

    /**
    * @description Fields available for filtering recipients in BMSNewEmailPageV2CC.
    *              Fields are based on the configured 'Bulk_Messaging_Filter' fieldset in Unit Offering
    **/
    public static SelectOptionWrapper getUOfferingOptionWrapper() {
        //check if value has not been cached
        if(unitOfferingOptions == null) {
            //cache value
            unitOfferingOptions = generateSelectOptionWrapperFromFieldSet(SObjectType.Unit_Attempt__c.FieldSets.Bulk_Messaging_Filter, true);
        }
        return unitOfferingOptions;
    }

    /**
    * @description For retrieving available email templates
    **/
    public static List<SelectOption> getEmailOptions() {
        //check if value has been cached
        if(emailOptions == null) {
            emailOptions = new List<SelectOption>();
            try {
                Folder bmsFolder = [SELECT DeveloperName, Id, Name, Type 
                                    FROM Folder 
                                    WHERE Name = :Label.BMS_Email_Templates 
                                    LIMIT 1];
                if(bmsFolder != null) {
                    if(emailTemplatesById == null) {
                        //get email tempaltes
                        emailTemplatesById = new Map<Id, EmailTemplate>(
                                            [SELECT Id, HtmlValue, Name, FolderId, IsActive 
                                            FROM EmailTemplate 
                                            WHERE FolderId = :bmsFolder.Id 
                                            AND IsActive = true]);

                    }

                    for(EmailTemplate tempLoop : emailTemplatesById.values()) {
                        //only add staff communication of current user is an admin
                        if (!checkIfAdmin(UserInfo.getProfileId()) && 
                            tempLoop.Name == Label.Email_Template_Staff_Communication) 
                        {
                            continue;
                        }
                        emailOptions.add(new SelectOption(tempLoop.Id, tempLoop.Name));
                    }

                } else {
                    System.debug('ERROR: Unable to retrieve email template folder with name : ' + Label.BMS_Email_Templates);
                }
            } catch (Exception e) {
                //TO DO: INSERT EXCEPTION LOG
                System.debug('ERROR ON : BMSUtils.getEmailOptions() while trying to retrieve email templates : ' + e);
            }
        }

        return emailOptions;
    }

    /**
	* @description Business-define Cohort Options. Used by BMSNewEmailPageV2CC
	**/
    public static List<SelectOption> getCohortOptions() {
        //check if value has not been cached
        if(cohortOptions == null) {
            //cache value
            cohortOptions = new List<SelectOption>{
                new SelectOption('ALLSTUDENTS', 'All Students'),
                new SelectOption('HDR', 'All HDR Students'),
                new SelectOption('ALLEXCEPTHDR', 'All Students except HDR'),
                new SelectOption('POSTGRAD', 'All Postgraduate Students'),
                new SelectOption('UNDERGRAD', 'All Undergraduate Students'),
                new SelectOption('UNITOFFERING', 'Unit Offerings')
            };
            //if current user's profile is a BMS admin, add All Staff option
            if (checkIfAdmin(UserInfo.getProfileId())) {
                cohortOptions.add(new SelectOption('ALLSTAFF', 'All Staff'));
            }
        }
        return cohortOptions;
    }

    /**
    * @description for dynamically pulling pick list values based on
    *              sobject name and field api
    **/
    public static List<String> getPickListValues(SObjectType token, String fieldName) {
        List<String> returnVal = new List<String>();
        Schema.DescribeSObjectResult describe = token.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> picklist = fieldMap.get(fieldName).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        for (Schema.PicklistEntry a : picklist) { //for all values in the picklist list
            returnVal.add(a.getLabel());
        }
        return returnVal; //return the List
    }

    /**
	* @description method for retrieving profile name, and checking if it is an admin.
	*			   values will be cached in a public variable
	**/
    public static String getProfileName(Id profileId) {
        //check if value has not been cached
        if(profileName == null) {
            //retrieve value
            try {
                isAdmin = false;
                profileName = [SELECT Id, Name 
                            FROM Profile 
                            WHERE Id = :profileId].Name;
                //check if profile is Admin
                if (adminProfiles.contains(profileName)) {
                    //cache value
                    isAdmin = true;
                }
            } catch(Exception e) {
                //TO DO: INSERT EXCEPTION LOG
                System.debug('ERROR ON : BMSUtils.getProfileName() while trying to retrieve profile name : ' + e);
            }
        }

        return profileName;
    }

    /**
    * @description method for checking if current user profile is a BMS admin.
    *              this is based on the indicated 'adminProfiles'
    **/
    public static Boolean checkIfAdmin(Id profileId) {
        //check if value has been cached
        if(isAdmin == null) {
            //call get profile name method which also caches value of isAdmin
            String profileName = getProfileName(profileId);
        }
        return isAdmin;
    }

    /** PRIVATE CLASSES **/

    /**
    * @description  method for building list of select option wrapper.
    * @param    fieldSet : determines the fields to be added in the select option
    *           isAddNone : determines whether to add 'None' value in the select option
    **/
    private static SelectOptionWrapper generateSelectOptionWrapperFromFieldSet(Schema.FieldSet fieldSet, Boolean isAddNone) {
        SelectOptionWrapper options = new SelectOptionWrapper();
        for(Schema.FieldSetMember fieldSetRecord : fieldSet.getFields()) {
            options.parent.put(
                fieldSetRecord.getLabel(),
                new SelectOptionWrapper(fieldSetRecord)
            );
        }
        //default value NONE - always put this last in order to set it as default in page
        if(isAddNone) { 
            options.parent.put(
                '-- NONE --',
                new SelectOptionWrapper(NONE_STR)
            );
        }
        return options;
    }

    /** WRAPPER CLASSES **/

    /**
    * @author       Nick Guia
    * @date         02/08/2017
    * @description  Wrapper class for BMSEmailReview table's data. Constructor
    *               automatically parses campaign details as required.
    *               (i.e. date fields, number fields that can be null)
    **/
    public class TableDataWrapper {
        public String cmpId {get; set;}
        public String subject {get; set;}
        public String sendType {get; set;}
        public Decimal totalRecipients {get; set;}
        public String submittedBy {get; set;}
        public String submittedDate {get; set;}
        public String status {get; set;}
        public Boolean isBatchFinished {get; set;}

        public TableDataWrapper(Campaign cmp) {
            this.cmpId = String.valueOf(cmp.Id);
            this.subject = cmp.Name;
            this.sendType = cmp.Type;
            this.submittedBy = cmp.Owner_Name__c;
            this.status = cmp.Status;
            this.isBatchFinished = cmp.Batch_Finished__c;
            //check if total members is not null, otherwise assign 0
            this.totalRecipients = (cmp.Total_Members__c != null) ? cmp.Total_Members__c : 0;
            //formate date to String
            this.submittedDate = cmp.CreatedDate.day() + 
                            '/' + cmp.CreatedDate.month() + 
                            '/' + cmp.CreatedDate.year();
        }
    }

    /**
    * @author       Nick Guia
    * @date         02/08/2017
    * @description  Wrapper class for Select Options. This is because apex
    *               doesn't support serialization of Select Option data type
    **/
    public class SelectOptionWrapper {
        public Map<String, SelectOptionWrapper> parent {get; set;}
        public String value {get; set;}
        public String fieldType {get; set;}

        public SelectOptionWrapper(Schema.FieldSetMember field) {
            this.value = field.getFieldPath();
            this.fieldType = String.valueOf(field.getType());
        }

        //overload constructor
        public SelectOptionWrapper(String val) {
            this.value = val;
            this.fieldType = '';
        }

        //overload constructor
        public SelectOptionWrapper() {
            this.parent = new Map<String, SelectOptionWrapper>();
            this.value = '';
            this.fieldType = '';
        }
    }

    //Wrapper class for filters
    public class FilterWrapper {
        public String cohort {get; set;}
        public Boolean isIncludeInactive {get; set;}
        public List<FilterRowWrapper> filters {get; set;}
        public String filterLogic {get; set;}
    }

    public class FilterRowWrapper {
        public String field {get; set;}
        public String criteria {get; set;}
        public String value {get; set;}
    }

    //for storing preview table data during Search
    public class PreviewTableWrapper {
        public List<SObject> tableData {get; set;}
        public Integer totalCount {get; set;}
        public String finalQueryString {get; set;}

        public PreviewTableWrapper(List<SObject> td, Integer count, String fQueryString) {
            this.tableData = td;
            this.totalCount = count;
            this.finalQueryString = fQueryString;
        }
    }

    //for storing soql string sequence
    public class QueryWrapper {
        public List<String> fields {get; set;}
        public String obj {get; set;}
        public String filter {get; set;}

        public QueryWrapper(List<String> fields, String obj, String filter) {
            this.fields = fields;
            this.obj = obj;
            this.filter = filter;
        }
    }

    //data received upon saving campaign
    public class NewEmailSaveWrapper {
        public String audienceType {get; set;} //either 'search' or 'upload'
        public Blob fileUpload {get; set;}
        public String fileName {get; set;}
        public String attachmentContent {get; set;} //Person ID or Email
        public String finalQueryString {get; set;}
        public Campaign massEmailRecord {get; set;}
    }

    public class BuildPreviewEmailWrapper {
        public String emailTemplate {get; set;}
        public String name {get; set;}
        public String messageHeader {get; set;}
        public String customMessage {get; set;}
        public Boolean isAddCricos {get; set;}
        public Boolean isAddBaseSignature {get; set;}
    }
}