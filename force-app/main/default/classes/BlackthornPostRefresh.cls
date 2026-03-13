/**
 * @author Nick Guia
 * @date 17.05.2021
 * @group Commons
 * @description For automating sandbox post-refresh steps for Blackthorn
 * @revision
 *  24.05.2021  Nick G.     - Moved commits to BaseClass; Added Public Group Membership
 *  30.06.2021  Nick G.     - removed runAll, created runSetupObjects and runNonSetupObjects to avoid Mixed DML error
 */
global without sharing class BlackthornPostRefresh {
   
    // TODO - POPULATE THIS WITH MARKETING USERS
    // MAP OF FED ID => MONASH EMAIL
    public static Map<String, String> MARKETING_USERS = new Map<String, String>();
    // TODO - POPULATE WITH PASSWORD
    public static String MARKETING_USER_PW;
    public static String INTEG_USER_PW;
   
    // private List<User> mUsers;
    public static List<User> mUsers {
        get {
            if(mUsers == null) {
                mUsers = selectMarketingUsers();
            }
            return mUsers;
        } set;
    }
   
    public static List<PermissionSet> MARKETING_PERMISSION_SETS {
        get {
            if(MARKETING_PERMISSION_SETS == null) {
                MARKETING_PERMISSION_SETS = selectMarketingPermissionSets();
            }
            return MARKETING_PERMISSION_SETS;
        } set;
    }
   
    public static List<PermissionSetGroup> MARKETING_PERMISSION_SET_GROUPS {
        get {
            if(MARKETING_PERMISSION_SET_GROUPS == null) {
                MARKETING_PERMISSION_SET_GROUPS = selectMarketingPermissionSetGroups();
            }
            return MARKETING_PERMISSION_SET_GROUPS;
        } set;
    }
   
    public static Profile BASE_POFILE {
        get {
            if(BASE_POFILE == null) {
                BASE_POFILE = [SELECT Id FROM Profile WHERE Name = 'Base Profile' LIMIT 1];
            }
            return BASE_POFILE;
        } set;
    }
   
    public static final Set<String> MARKETING_USER_PERMISSION_SETS = new Set<String> {
        'Enable_Lightning_With_Classic_Switcher'
    };
   
    public static final Set<String> MARKETING_USER_PERMISSION_SET_GROUPS = new Set<String> {
        'Blackthorn_Events_Admin_Group'
    };
   
    public static final Set<String> MARKETING_USER_PUBLIC_GROUPS = new Set<String> {
        'SMC_Users',
        'Contacts_Non_Student_RW',
        'Contacts_Student_RO'
    };
   
    private FormConfig CONFIG;
    private final String COMPANY_INFO_EMAIL = 'webmaster@monash.edu';
    private final String COMPANY_INFO_GTM_ID = 'GTM-W2GCHBS';
    private final String SANDBOX_NAME = UserInfo.getUserName().substringAfterLast('.');
    private BaseClass bc;
   
    public BlackthornPostRefresh() {
        init();
    }
 
    private void init() {
        this.CONFIG = new FormConfig();
        bc = new BaseClass(
            new List<Schema.sObjectType> {
            User.SObjectType,
            PermissionSetAssignment.SObjectType,
            GroupMember.SObjectType,
            Account.SObjectType,
            Global_Monash_Account__c.SObjectType,
            Campaign.SObjectType,
            Marketing_Subscription_List__c.SObjectType,
            Mutex__c.SObjectType,
            bt_stripe__Relationship_Settings__c.SObjectType,
            conference360__Event_Settings__c.SObjectType,
            conference360__Form__c.SObjectType,
            conference360__Form_Element__c.SObjectType,
            bt_stripe__Company__c.SObjectType
        }
            );
    }
 
    public void runSetupObjects() {
        activateMarketingUsers().assignBlackthornPermissions(BlackthornPostRefresh.mUsers)
        .createAutomationUsers().resetBtIntegUser().commitRecords();
        //flush
        init();
    }
 
    public void runNonSetupObjects() {
        createSubscriptionList().createGlobalMonashAccount().createExLeadsMutex()
        .createEventDefaults().createBaseRegForm().createCompanyInfo().commitRecords();
        //flush
        init();
    }
   
    /**
     * @description Create campaign subscription lists and update custom setting
     */
    public BlackthornPostRefresh createSubscriptionList() {
        Campaign mie = generateSubscriptionListCampaign('Monash Info and Events for Prospective Students');
        bc.push(mie);
        Campaign mr = generateSubscriptionListCampaign('Market research participation for Prospective Students');
        bc.push(mr);
   
        Marketing_Subscription_List__c setting = Marketing_Subscription_List__c.getOrgDefaults();
        bc.relate(setting, Marketing_Subscription_List__c.MIE__c, mie);
        bc.relate(setting, Marketing_Subscription_List__c.MR__c, mr);
        bc.push(setting);
        return this;
    }
   
    /**
     * @description create global monash account and update custom setting
     */
    public BlackthornPostRefresh createGlobalMonashAccount() {
        //create account
        Account gma = generateMonashAccount();
        bc.push(gma);
   
        //update custom setting
        Global_Monash_Account__c globalAcc = Global_Monash_Account__c.getOrgDefaults();
        bc.relate(globalAcc, Global_Monash_Account__c.Id__c, gma);
        bc.push(globalAcc);
   
        return this;
    }
   
    /**
     * @description Create mutex record for exploding leads
     */
    public BlackthornPostRefresh createExLeadsMutex() {
        Mutex__c exLeadsMutex = generateMutex('Exploding_Leads');
        bc.push(exLeadsMutex);
        return this;
    }
   
    /**
     * @description create default event setting and relationship setting
     */
    public BlackthornPostRefresh createEventDefaults() {
        //create Relationship Settings
        bt_stripe__Relationship_Settings__c relSetting = generateDefaultRelationshipSetting();
        bc.push(relSetting);
   
        //create event settings
        conference360__Event_Settings__c setting = generateDefaultEventSetting();
        bc.push(setting, conference360__Event_Settings__c.conference360__Relationship_Settings__c, relSetting);
   
        return this;
    }
   
    /**
     * @description create Base Registration Form
     */
    public BlackthornPostRefresh createBaseRegForm() {
        conference360__Form__c form = new conference360__Form__c(Name = 'Base Registration Form');
        bc.push(form);
        form = generateProspectiveStudentForm(form);
        return this;
    }
   
    /**
     * @description create company info
     */
    public BlackthornPostRefresh createCompanyInfo() {
        bt_stripe__Company__c com = generateCompanyInfo();
        bc.push(com);
        return this;
    }
   
    /**
     * @description activate marketing users
     */
    public BlackthornPostRefresh activateMarketingUsers() {
        for(User iUser : BlackthornPostRefresh.mUsers) {
            iUser.Email = BlackthornPostRefresh.MARKETING_USERS.get(iUser.FederationIdentifier);
            iUser.isActive = TRUE;
            iUser.UserPermissionsMarketingUser = TRUE;
            System.setPassword(iUser.Id, BlackthornPostRefresh.MARKETING_USER_PW);
            bc.push(iUser);
        }
        return this;
    }
   
    /**
     * @description assign permissions and permission set groups
     */
    public BlackthornPostRefresh assignBlackthornPermissions(List<User> userList) {
        for(User iUser : userList) {
            //assign permission sets
            for(PermissionSet ps : BlackthornPostRefresh.MARKETING_PERMISSION_SETS) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                bc.relate(psa, PermissionSetAssignment.AssigneeId, iUser);
                bc.relate(psa, PermissionSetAssignment.PermissionSetId, ps);
                bc.push(psa);
            }
            //assign permission set groups
            for(PermissionSetGroup psg : BlackthornPostRefresh.MARKETING_PERMISSION_SET_GROUPS) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                bc.relate(psa, PermissionSetAssignment.AssigneeId, iUser);
                bc.relate(psa, PermissionSetAssignment.PermissionSetGroupId, psg);
                bc.push(psa);
            }
        }
        return this;
    }
   
   
    /**
     * @description only create blackthorn test user (for now)
     */
    public BlackthornPostRefresh createAutomationUsers() {
        User btUser = createBlackthornTestUser();
        bc.push(btUser);
        List<User> autUserList = new List<User> {btUser};
        assignBlackthornPermissions(autUserList);
        assignMarketingPublicGroups(autUserList);
        return this;
    }
   
    /**
     * @description assign (default) public group for marketing user
     */
    public BlackthornPostRefresh assignMarketingPublicGroups(List<User> userList) {
        for(Group iGroup : [SELECT Id, DeveloperName
                            FROM Group
                            WHERE DeveloperName IN :BlackthornPostRefresh.MARKETING_USER_PUBLIC_GROUPS
                            AND Type = 'Regular'])
        {
            for(User iUser : userList) {
                GroupMember gm = new GroupMember();
                bc.relate(gm, GroupMember.GroupId, iGroup);
                bc.relate(gm, GroupMember.UserOrGroupId, iUser);
                bc.push(gm);
            }
        }
        return this;
    }
   
    /**
     * @description reset Blackthorn Integration User
     */
    public BlackthornPostRefresh resetBtIntegUser() {
        try {
            User btInteg = [SELECT Id FROM User WHERE FederationIdentifier = 'blackprd' LIMIT 1];
            System.setPassword(btInteg.Id, BlackthornPostRefresh.INTEG_USER_PW);
        } catch(Exception e) {
            LogUtilityException.logException(e);
            System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
        }
        return this;
    }
   
    /**
     * @description partial commit and log any exception
     */
    public BlackthornPostRefresh commitRecords() {
        BaseClass.ResultSet rs = bc.commitRecordsPartial();
        LogUtilityException.logCommitRecords(rs);
        return this;
    }
   
    @TestVisible
    private User createBlackthornTestUser() {
        return new User (
            FirstName = 'Blackthorn',
            LastName ='User',
            Alias = 'buser',
            Email = 'manjunath.batti@monash.edu',
            UserPermissionsMarketingUser = TRUE,
            isActive = TRUE,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_AU',
            ProfileId = BASE_POFILE.Id,
            TimeZoneSidKey='Australia/Sydney',
            UserName = 'blackthorn.testuser@monash.edu.'+SANDBOX_NAME
            );
    }
   
    @TestVisible
    private Campaign generateSubscriptionListCampaign(String campaignName) {
        return new Campaign(
            Name = campaignName,
            RecordTypeId = CampaignServices.SUB_LIST_RECTYPE,
            Channel_Type__c = 'Email',
            CampaignMemberRecordTypeId = CampaignMemberServices.RECORDTYPE_EVENT_ATTENDEE
            );
    }
   
    @TestVisible
    private Account generateMonashAccount() {
        Id recTypeId = Schema.SObjectType.Account
                       .getRecordTypeInfosByDeveloperName()
                       .get('Monash_Organisation')
                       .getRecordTypeId();
   
        return new Account(
            Name='Monash University Global Account',
            RecordTypeId = recTypeId
            );
    }
   
    @TestVisible
    private Mutex__c generateMutex(String appName) {
        return new Mutex__c(
            Name = appName,
            is_Locked__c = false
            );
    }
   
    @TestVisible
    private bt_stripe__Relationship_Settings__c generateDefaultRelationshipSetting() {
        return new bt_stripe__Relationship_Settings__c(
            Name = 'Default Relationship Setting',
            bt_stripe__Relationship_Rule__c = 'No Matching Or Record Creation',
            bt_stripe__Match_Records__c = 'Contact',
            bt_stripe__Set_All_Email_Fields__c = TRUE,
            bt_stripe__Default__c = TRUE,
            bt_stripe__Create_Rule__c = 'Contact'
            );
    }
   
    @TestVisible
    private conference360__Event_Settings__c generateDefaultEventSetting() {
        return new conference360__Event_Settings__c(
            Name = 'Default Setting',
            conference360__Default__c = TRUE,
            conference360__Enable_Forms_v2__c = TRUE,
            conference360__Enable_Cancel_Registration__c = 'Yes',
            conference360__Campaign_Member_Attended_Status__c = 'Attended',
            conference360__Campaign_Member_Declined_Status__c = 'Declined',
            conference360__Campaign_Member_Registered_Status__c = 'Registered'
            );
    }
   
    @TestVisible
    private conference360__Form__c generateProspectiveStudentForm(conference360__Form__c form) {
        Integer sortOrder = 1;
        //Seeking_Information_For__c
        conference360__Form_Element__c seeking = new FormElementBuilder()
                                                 .withType('Picklist')
                                                 .setPicklistValues(CONFIG.SEEKING_INFORMATION_FOR)
                                                 .withMapsToField('Seeking_Information_For__c')
                                                 .withQuestion('Who are you seeking information for?')
                                                 .withSortOrder(sortOrder)
                                                 .build();
        bc.push(seeking, conference360__Form_Element__c.conference360__Form__c, form);
        sortOrder++;
   
        // Student_Type__c
        conference360__Form_Element__c studentType = new FormElementBuilder()
                                                     .withType('Picklist')
                                                     .setPicklistValues(CONFIG.STUDENT_TYPE)
                                                     .withMapsToField('Student_Type__c')
                                                     .withQuestion('Are you a domestic or international student?')
                                                     .withRichTextQuestion('<p>You are a domestic student if you are an:</p><ul><li>Australian citizen (including dual citizens), or</li><li>New Zealand citizen (including dual citizens), or</li><li>Australian Permanent Resident, or</li><li>Australian Permanent Humanitarian Visa holder.</li></ul>')
                                                     .withSortOrder(sortOrder)
                                                     .build();
        bc.push(studentType, conference360__Form_Element__c.conference360__Form__c, form);
        sortOrder++;
   
        // Study_level__c
        conference360__Form_Element__c studyLevel = new FormElementBuilder()
                                                    .withType('Picklist')
                                                    .setPicklistValues(CONFIG.STUDY_LEVEL)
                                                    .withMapsToField('Study_level__c')
                                                    .withQuestion('Study level')
                                                    .withRichTextQuestion('<p>You are a domestic student if you are an:</p><ul><li>Australian citizen (including dual citizens), or</li><li>New Zealand citizen (including dual citizens), or</li><li>Australian Permanent Resident, or</li><li>Australian Permanent Humanitarian Visa holder.</li></ul>')
                                                    .withSortOrder(sortOrder)
                                                    .build();
        bc.push(studyLevel, conference360__Form_Element__c.conference360__Form__c, form);
        sortOrder++;
   
        // Broad_area_s_of_interest__c
        conference360__Form_Element__c baoi = new FormElementBuilder()
                                              .withType('Multi-Select Picklist')
                                              .setPicklistValues(CONFIG.BAOI)
                                              .withMapsToField('Broad_area_s_of_interest__c')
                                              .withQuestion('Broad area(s) of interest')
                                              .withSortOrder(sortOrder)
                                              .build();
        bc.push(baoi, conference360__Form_Element__c.conference360__Form__c, form);
        sortOrder++;
   
        // Specific_Study_Area__c
        conference360__Form_Element__c studyArea = new FormElementBuilder()
                                                   .withType('Text (30,000)')
                                                   .withMapsToField('Specific_Study_Area__c')
                                                   .withQuestion('Specific Study Area')
                                                   .withSortOrder(sortOrder)
                                                   .build();
        bc.push(studyArea, conference360__Form_Element__c.conference360__Form__c, form);
        sortOrder++;
   
        // Current_Studies__c
        conference360__Form_Element__c currentStudies = new FormElementBuilder()
                                                        .withType('Picklist')
                                                        .setPicklistValues(CONFIG.CURRENT_STUDIES)
                                                        .withMapsToField('Current_Studies__c')
                                                        .withQuestion('Current Studies')
                                                        .withSortOrder(sortOrder)
                                                        .build();
        bc.push(currentStudies, conference360__Form_Element__c.conference360__Form__c, form);
        sortOrder++;
   
        // Marketing_Subscription_Opt_In__c
        conference360__Form_Element__c sub = new FormElementBuilder()
                                             .withType('Checkbox')
                                             .withMapsToField('Marketing_Subscription_Opt_In__c')
                                             .withQuestion('I agree to receive marketing communications from Monash University.')
                                             .withRichTextQuestion('<p><br></p><p>By registering, you agree to receive communications about this event from Monash University. Monash University values the privacy of every individual\'s personal information and is committed to the protection of that information from unauthorized use and disclosure except where permitted by law. For information about the handling of your personal information please see the <a href="https://www.monash.edu/__data/assets/pdf_file/0003/1595271/Visitors-and-Enquirers-Data-Protection-and-Privacy-Collection-Statement.pdf" target="_blank">Visitors and Enquirers Data Protection and Privacy Collection Statement (PDF)</a>. For more information about Data Protection and Privacy at Monash University please see our <a href="https://www.monash.edu/__data/assets/pdf_file/0003/790086/Privacy.pdf" target="_blank">Data Protection and Privacy Procedure (PDF)</a>.</p><p><br></p><p>If you have any questions about how Monash University is collecting and handling your personal information, please contact our Data Protection and Privacy Office at <a href="mailto:dataprotectionofficer@monash.edu" target="_blank">dataprotectionofficer@monash.edu</a>.</p>')
                                             .withSortOrder(sortOrder)
                                             .build();
        bc.push(sub, conference360__Form_Element__c.conference360__Form__c, form);
        sortOrder++;
   
        // Web_Lead_Source__c
        conference360__Form_Element__c source = new FormElementBuilder()
                                                .withType('Parameter')
                                                .withMapsToField('Web_Lead_Source__c')
                                                .withQuestion('Web Lead Source')
                                                .withSortOrder(sortOrder)
                                                .build();
        bc.push(source, conference360__Form_Element__c.conference360__Form__c, form);
        sortOrder++;
   
        return form;
    }
   
    @TestVisible
    private bt_stripe__Company__c generateCompanyInfo() {
        return new bt_stripe__Company__c(
            Name = 'Monash University',
            bt_stripe__Email__c = COMPANY_INFO_EMAIL,
            conference360__Google_Tag_Manager_Id__c = COMPANY_INFO_GTM_ID
            );
    }
   
    @TestVisible
    private static List<User> selectMarketingUsers() {
        System.debug('!@#$ MARKETING_USERS : ' + BlackthornPostRefresh.MARKETING_USERS);
        return [SELECT Id, Email, Alias, isActive, FederationIdentifier, UserPermissionsMarketingUser FROM User WHERE FederationIdentifier IN :BlackthornPostRefresh.MARKETING_USERS.keySet()];
    }
   
    @TestVisible
    private static List<PermissionSet> selectMarketingPermissionSets() {
        return [SELECT Id FROM PermissionSet WHERE Name IN :BlackthornPostRefresh.MARKETING_USER_PERMISSION_SETS];
    }
   
    @TestVisible
    private static List<PermissionSetGroup> selectMarketingPermissionSetGroups() {
        return [SELECT Id FROM PermissionSetGroup WHERE DeveloperName IN :BlackthornPostRefresh.MARKETING_USER_PERMISSION_SET_GROUPS];
    }
   
    public class FormElementBuilder {
        private conference360__Form_Element__c elem;
        private Set<String> picklistValues;
   
        public FormElementBuilder() {
            this.elem = new conference360__Form_Element__c();
            //default
            this.elem.conference360__Maps_To_Object__c = 'Attendee__c';
            this.picklistValues = new Set<String>();
        }
   
        public FormElementBuilder withType(String sType) {
            this.elem.conference360__Type__c = sType;
            return this;
        }
   
        public FormElementBuilder withMapsToField(String sField) {
            this.elem.conference360__Maps_To_Field__c = sField;
            return this;
        }
   
        public FormElementBuilder withRichTextQuestion(String rtQuestion) {
            this.elem.conference360__Question_RT__c = rtQuestion;
            return this;
        }
   
        public FormElementBuilder withQuestion(String question) {
            this.elem.conference360__Question__c = question;
            return this;
        }
   
        public FormElementBuilder setPicklistValues(Set<String> val) {
            if(validPicklistType()) {
                this.picklistValues = val;
            }
            return this;
        }
   
        public FormElementBuilder withSortOrder(Integer sortNum) {
            this.elem.conference360__Sort_Order__c = sortNum;
            return this;
        }
   
        public conference360__Form_Element__c build() {
            //if field is a picklist, assign picklist values and join by next line
            if(validPicklistType()) {
                this.elem.conference360__Picklist_Values__c = String.join(new List<String>(this.picklistValues), '\n');
            }
            return this.elem;
        }
   
        private Boolean validPicklistType() {
            return String.isNotBlank(this.elem.conference360__Type__c) && this.elem.conference360__Type__c == 'Picklist';
        }
    }
   
    // static configs
    public class FormConfig {
        public final Set<String> SEEKING_INFORMATION_FOR = new Set<String> {
            'Myself',
            'My child'
        };
   
        public final Set<String> STUDENT_TYPE = new Set<String> {
            'Domestic',
            'International'
        };
   
        public final Set<String> STUDY_LEVEL = new Set<String> {
            'Postgraduate',
            'Diploma',
            'Foundation Year',
            'Graduate Coursework',
            'Graduate research',
            'Undergraduate education'
        };
   
        public final Set<String> BAOI = new Set<String> {
            'Art, Design and Architecture',
            'Arts, Humanities and Social Sciences',
            'Business',
            'Education',
            'Engineering',
            'Information Technology',
            'Law',
            'Medicine, Nursing and Health Sciences',
            'Pharmacy and Pharmaceutical Sciences',
            'Science',
            'None'
        };
   
        public final Set<String> CURRENT_STUDIES = new Set<String> {
            'Secondary School',
            'TAFE or RTO',
            'Current student at Monash University',
            'Another University',
            'Not currently studying',
            'Other'
        };
    }
}