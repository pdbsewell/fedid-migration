/*
 * @author PwC
 * @description: Utility class that provides test data creation methods
 * @revision
 *  2018-10-16 - Stefan Scheit 	- added accountid to SOQL of retrieveContactRecords() method
 *  2018-06-27 - Nick Guia   	- removed createSubscriptionMember and createSubscriptionList
 *                                (for deleting Subscripton_Member__c and Subscripton_List__c objects)
 *  2018-11-29 - Nick Guia      - added createCourseAttempts(), createUnitAttempts(), createInboundUnitAttempts()
 *  2018-12-13 - Nick Guia      - createACP()
 *  2020-01-13 - APRivera       - Added @isTest Annotation
 *  2021-06-09 - Aref Samad     - Modified createEventCampaigns and createBlackthornEvents for Test Cover of EPBBS-1970 added new field in Event object Internal_Name__c
 **/

@isTest
public with sharing class TestHelper {

    /**
    * apply named permission sets to user supplied, names concatenated with ;
    * @param names names of permission sets, concatenated using semi-colon
    * @param usr the id of the user to apply the permissions to
    * @return void
    */
    public static void applyPermissionSets(String names, user usr){
        Set<string> psNames = new Set<string>();
        for(string nm : names.split(';')) psNames.add(nm);
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        for(PermissionSet ps : [select id from PermissionSet where name in:psNames]){
            psaList.add(new PermissionSetAssignment(PermissionSetId = ps.id, AssigneeId = usr.id));
        }
        insert psaList;
    }

    /**
     * generate a list of emailmessage records
     * @param EmailMessage number of email messages to create
     * @param parentId the id of object to parent the messages
     * @param fromName the string containing 'from' for the email message
     * @param fromAddress the string containing from email address for the message
     * @param ToAddress the address that the email message is to be sent to
     * @return list of emailmessage records
     */
    public static list<EmailMessage> createEmailMessages(integer EmailMessage, id parentId, String fromName, String fromAddress, String ToAddress){
        list<EmailMessage> emails = new list<EmailMessage>();
        for(integer index=0; index < EmailMessage; index++) {
            emails.add(new EmailMessage( subject = 'test email',
                                        parentId = parentId,
                                        textBody = 'test email body',
                                        htmlBody = '<p>test email body</p>',
                                        fromName = fromName,
                                        fromAddress = fromAddress,
                                        toAddress = ToAddress,
                                        MessageDate = Date.today().addDays(-10 * index)
                                        ));
        }
        return emails;
    }

    /**
    * generate a list of task records
    * @param numberOfTasks the number of task records to create
    * @param whoId the id of the contact to link the tasks to
    * @param whatId the id of another object to link the tasks to
    * @return list of task records
    */
    public static list<task> createTasks(integer numberOfTasks, id whoId, id whatId){
        list<task> tasks = new list<task>();
        for(integer index=0; index < numberOfTasks; index++){
            tasks.add(new Task( subject = 'test task',
                                activitydate = Date.today().addDays(-60).addDays(index),
                                description = 'test description',
                                whoId = whoId,
                                whatId = whatId,
                                Status = 'Completed',
                               Type = 'Other'));
        }
        return tasks;
    }

    /**
    * generate a list of attachments
    * @param numberOfAttachments the number of attachment records to create
    * @param parentId the id of the parent object for the attachments
    * @return list of attachment records
    */
    public static list<attachment> createAttachments(integer numberOfAttachments, id parentId){
        list<attachment> attachments = new list<attachment>();
        for(integer index=0; index<numberOfAttachments; index++){
            attachments.add(new attachment(name = 'att_'+String.valueOf(index),
                                           parentId = parentId,
                                           body = Blob.valueOf('testAttachment')));
        }
        return attachments;
    }

    /**
    * generate a list of course records
    * @param numberOfCourses the number of course__c records to setup
    * @return a list of course__c records
    */
    public static list<Course__c> createCourses(integer numberOfCourses){
        list<course__c> courses = new list<course__c>();
        for(integer index=0; index<numberOfCourses; index++){
            courses.add(new course__c(name = String.valueOf(index),
                                      course_description__c = 'test course',
                                      specialisation__c = String.valueOf(index)+'specialty'));
        }
        return courses;
    }

    /**
     * @description generates a list of courses with a specific type
     * @param num : number of courses to be generated
     *        courseType : type of course - 'Academic_Course' || 'Short_Course' || 'Course-All' ||  'Unit Set'
     */
    public static List<Course__c> createCoursesWithType(Integer num, String courseType){
        List<Course__c> courseList = new List<Course__c>();

        for(integer i = 0; i < num; i++) {
            Course__c iCourse = new Course__c();
            iCourse.Name = 'Code-' + i;
            iCourse.Course_Description__c = 'test course ' + i;
            iCourse.Version__c = '1';
            iCourse.Type__c = courseType;
            courseList.add(iCourse);
        }
        return courseList;
    }


    /**
    * generate test contact records that have no parent account record, so automation
    * will create the account records for them.
    * @param numberOfContacts the number of contact records to setup
    * @return list of contact records with no account id
    */
    public static list<Contact> createOrphanContactRecords(integer numberOfContacts){
        return createStudentContacts(numberOfContacts,null);
    }

    /**
    * ? redundant logic to generate PAs
    * <p>Can likely be factored out of logic layer altogether, once solution stable
    * @param numberOfStudents the number of student records to setup
    * @return list of account records that ? represent person accounts
    */
    public static list<Account> createStudent(integer numberOfStudents){

        list<Account>  accounts = new  list<Account>();
        Schema.DescribeSObjectResult descSobject =Account.SObjectType.getDescribe();

        Map<String,Schema.RecordTypeInfo> recordTypeInfoByName = descSobject.getRecordTypeInfosByName();


        //Id recTypeID = recordTypeInfoByName.get('Individual').getRecordTypeId();
        Id recTypeID = CommonServices.recordTypeId('Account', AccountServices.ACCOUNT_INDIVIDUAL_TYPE);
        // ? need an assert in here to confirm we get the record type, given its hardcoded ?
        // need to refactor hardcoded string values over to helper/service classes

        for(integer studentNumber = 0; studentNumber < numberOfStudents; studentNumber++){
            Account newAccount= new Account(
                Name='Account'+studentNumber,
                recordtypeid=recTypeID
            );
            accounts.add(newAccount);
        }
        return accounts;
    }
    
    /**
    * builds a list of staff contact records
    * @param numberOfContacts the number of records to setup
    * @return list of contact records
    */
    public static list<Contact> createStaffContacts(Integer numberOfContacts){

        list<Contact> newContacts = new  list<Contact>();
        for(Integer i = 0; i < numberOfContacts; i++){
            Contact newContact = new contact(
                FirstName='Sample' + generateRandomNumber(),
                LastName='Monash',
                Personnel_Area_Code__c='MU01',
                SAP_Staff_Id__c = generateRandomNumber(),
                Authcate__c = 'jmon' + generateRandomNumber()
            );

            newContacts.add(newContact);
        }
        return newContacts;
    }


    /**
    * retrieve the test contact records
    * @return the contact records that have been inserted during test setup
    */
    public static list<Contact> retrieveContactRecords() {

        return new List<Contact>([SELECT Id, firstName, lastName, Email, Monash_Email_Address__c, Applicant_Email_Address__c, AccountId
                                  FROM Contact LIMIT 500]);
    }

    /**
    * builds a list of student contact records - ? redundant logic from the original UniCRM v1.
    * @param numberOfContacts the number of records to setup
    * @param accounts a list of accounts that student records are to be setup for on a 1:1 basis
    * @return list of contact records each having a parent account id prior to insert
    */
    public static list<Contact> createStudentContacts(integer numberOfContacts, List<Account> accounts){

        list<Contact> newContacts = new  list<Contact>();
        for(integer contactNumber =0; contactNumber < numberOfContacts; contactNumber++){
            Id accountId = (accounts == null) ? null : accounts[contactNumber].Id;
            Contact newContact= new contact(
                FirstName='Sample'+ generateRandomNumber(),
                LastName='John',
                AccountId= accountId,
                MonTrack_Opt_Out__c=false,
                Email = generateRandomNumber() + 'test@mutesting.edu',
                citizenship_code__c = String.valueOf(math.mod(contactNumber,4) + 1),
                Monash_Email_Address__c = generateRandomNumber() + 'test@monash.edu',
                Applicant_Email_Address__c = generateRandomNumber() + 'test@mutesting.edu',
                Aboriginal_or_Torres_Strait_Islander__c = 'No'
            );

            newContacts.add(newContact);
        }
        return newContacts;
    }

    /**
    * creates a specific type of user (SSA) for Montrack testing purposes
    * @return a user record that has the SSA custom field set to true
    */
    public static User ssaUser(){

        User ssaUser = createTestUsers('System Administrator',1)[0];
        ssaUser.SSA__c = true;
        update ssaUser;

        return ssaUser;

    }

    /**
    * create a list of campaign records for testing
    * @param numberOfCampaigns the number of campaign records to setup
    * @return a list of campaign records
    */
    public static list<Campaign> createCampaign(integer numberOfCampaigns){
        list<Campaign> newCampaigns = new list<Campaign>();
        for(integer campaignNumber = 0; campaignNumber < numberOfCampaigns; campaignNumber++){
            Campaign newCampaign = new Campaign(Name='My Campaign ' + campaignNumber);
            newCampaigns.add(newCampaign);
        }
        return newCampaigns;

    }

    /**
    * creates a list of cohort records for testing
    * @param numberOfCohorts the number of cohort records to setup
    * @return a list of cohort records
    */
    public static list<Cohort__c> createCohort(integer numberOfCohorts){
        list<Cohort__c> newCohorts = new list<Cohort__c>();
        for(integer cohortNumber = 0; cohortNumber < numberOfCohorts; cohortNumber++){
            Cohort__c newCohort = new Cohort__c(Name='2014-1' + cohortNumber);
            newCohorts.add(newCohort);
        }
        return newCohorts;
    }

    /**
    *   creates campaign member records that map to a specific cohort and ssa for testing
    * @param ssaID the Id of an existing SSA user
    * @param cohortID the Id of an existing cohort record
    * @param CampaignID the Id of an existing campaign record
    * @param contactIds a set of contact ids of existing records that need to be linked to cohort etc for testing
    * @return a list of campaign member records setup to support MonTrack testing
    */
    public static list<CampaignMember> createCampaignMember(Id ssaID, Id cohortID, Id CampaignID, Set<Id> contactIds) {
        list<CampaignMember> newCampaignMembers = new list<CampaignMember>();
        for(Id contactId:contactIds) {
            CampaignMember newCampaignMember = new CampaignMember(Cohort__c=cohortID, SSA__c=ssaID, CampaignID=CampaignID, ContactID=contactId);
            newCampaignMembers.add(newCampaignMember);
        }
        return newCampaignMembers;
    }

    /**
    *   create a list of round records for testing MonTrack functionality
    * @param cohortId the id of an existing cohort to link the round to
    * @param CampaignID the id of an existing campaign to link the round to
    * @param ctr the number of rounds to setup
    * @return a list of round records all linked to cohort,campaign etc as required
    */
    public static list<Round__c> createRounds(Id cohortID, Id CampaignID, Integer ctr){
        List<Round__c> newRounds = new list<Round__c>();
        for(Integer i=0;i<ctr;i++){
            Round__c newRound= new Round__c(Campaign__c=CampaignID, Cohort__c=cohortID, Round_Number__c=String.valueof(i+1) );
            newRounds.add(newRound);
        }
        return newRounds;
    }

    /**
    *  create topics records for testing purposes
    *  @param roundId the id of an existing round record to link to
    *  @param SSAId the id of an existing SSA user to link to
    *  @param contactId the id of a Montrack test contact record
    *  @param numberOfTopics the number of topic records to return
    *  @return a list of topic records all linked as required for Montrack testing
    */
    public static list<Topic__c> createTopics(ID roundID, ID SSAID, ID contactID, Integer numberOfTopics){
        list<Topic__c> topics = new List<Topic__c>();
        for(Integer topicNumber =0; topicNumber < numberOfTopics; topicNumber++) {
            Topic__c newTopic= new Topic__c(Round__c=roundID, SSA_Identified__c=SSAID, Type__c='General', Description__c='Other', Student__c=contactID);
            topics.add(newTopic);
        }
        return topics;
    }

    /**
    * insert a custom setting record used to mute a trigger
    * @param username the name of user to insert trigger mute setting for
    * @param triggerString a string of triggers to be muted, concatenated via ','
    */
    public static void createTriggerMutingCustomSetting(String username, String triggersString){
        TriggerMuteRequest__c request = new TriggerMuteRequest__c(Name = username, TriggersList__c = triggersString);
        insert request;
    }

    /**
     * setup Test user data
     * @param profileName a string containing the profile to use for the new users
     * @param numberOfusers the number of user records to setup
     * @return a list of user records that have been inserted, so have ids ready for use
     */
    public static List<User> createTestUsers( String profileName , integer numberOfUsers){
        return createTestUsers(profileName, numberOfUsers, true);
    }

    /**
     * setup Test user data
     * @param profileName a string containing the profile to use for the new users
     * @param numberOfusers the number of user records to setup
     * @param performDML option to skip dml
     * @return a list of user records that have been inserted, so have ids ready for use
     */
        public static List<User> createTestUsers( String profileName , integer numberOfUsers, Boolean performDML){
            Id profileId = [select id from Profile where name =:profileName limit 1].Id;
            system.assertNotEquals(null,profileId,'No user profile found for user setup');

            List<User> users = new List<User>();

            for(Integer userCount = 0; userCount < numberOfUsers; userCount++){
                Integer rnd = Integer.valueOf(Math.random()*9999);
                users.add(new User(Alias = String.valueOf(rnd)+ 'usr',
                                Email= String.valueOf(rnd) +'testuser@mutesting.edu',
                                EmailEncodingKey='UTF-8',
                                LastName='TestingUser',
                                LanguageLocaleKey='en_US',
                                LocaleSidKey='en_GB',
                                ProfileId = profileId,
                                TimeZoneSidKey='Australia/Sydney',
                                UserName= String.valueOf(rnd) +'testuser@mutesting.edu'));
            }
            if(performDML){
                insert users;
            }
           
            return users;
        }


    /**
    * static map of simulated errors to throw during testing
    * <p>if dev wants to simulate errors in testing, then can incorporate this logic into codebase.
    * @return a set of custom error types described as strings.
    */
        private static Set<string> errorsToThrow {
            get{
                if(errorsToThrow == null) errorsToThrow = new Set<string>();
                return errorsToThrow;
            }
            private set;
        }

    /**
    * store an error simulation request
    * @param errorType the name of the error that dev wants to test
    * @ return void
    */
        public static void setupError(String errorType){
            errorsToThrow.add(errorType);
        }

    /**
    * confirm if error simulation should go ahead or not
    * @param errorType string value for dev custom error that is to be checked for
    * @return boolean of true if error is to be thrown, otherwise false
    */
        public static Boolean throwError(String errorType){
            if(Test.isRunningTest() && errorsToThrow.contains(errorType)){
                errorsToThrow.remove(errorType); // only permit error to fire once per time it is set
                return true;
            } else {
                return false;
            }
        }

    /**
    * create a list of simple web to case forms
    * @param numberOfForms the number of web form cases to setup
    * @return a list of case records
    */
    public static List<Case> webToCaseForms(Integer numberOfForms){
        List<Case> cases = new List<Case>();
        for(integer formNumber = 0; formNumber < numberOfForms ; formNumber++){
            cases.add(new Case( SuppliedName = 'testName',
                               SuppliedPhone = '0400000000',
                               SuppliedEmail = String.valueOf(formNumber) + 'testformEmail@mutesting.edu',
                               Type = 'Web',
                               Case_type__c = '',
                               ContactId = null,
                               AccountId = null,
                               Course_code__c = '0'));
        }
        return cases;
    }

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         23/02/2017
    * @description  method for setting Calabrio details
    * @revision
    *******************************************************************************/
    public static void calabrioSetUp(){
        //set up custom settings
        CalabrioIntegration__c calabrioSetting = new CalabrioIntegration__c();
        calabrioSetting.Name = 'Credentials';
        calabrioSetting.AllowCallout__c = false;
        calabrioSetting.AllowedStaff__c = '';
        calabrioSetting.CalabrioURL__c = 'http://calabrio.ocio.monash.edu/cwfo/apps/Recordings.html?loadContact=';
        calabrioSetting.Client_ID__c = 'e4300af3f0ca487b855031659cac6caa';
        calabrioSetting.Client_Secret__c = '1414625753724c45830316ADDAE08C7C';
        calabrioSetting.AllowedStaff__c = 'Monash Connect Officer';
        insert calabrioSetting;
    }

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         31.AUG.2017
    * @description  method for creating channel record
    * @revision
    *******************************************************************************/
    public static Channel__c createChannel(Contact contactRecord) {
        Channel__c channel = new Channel__c();
        channel.Contact__c = contactRecord.Id;
        channel.Country__c = 'Australia';
        channel.Email__c = 'primary.email@mutesting.edu';
        channel.City__c = 'test city';
        channel.Type__c = 'MAILING';
        return channel;
    }

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         31.AUG.2017
    * @description  method for creating Role record
    * @revision
    *******************************************************************************/
    public static Roles__c createRole(Contact contactRecord, Channel__c channelRecord) {
        Roles__c role = new Roles__c();
        role.Contact__c = contactRecord.Id;
        //LeadN :: role.Channel__c = channelRecord.Id;
        role.Role__c = 'Music Coordinator';
        role.Status__c = 'Current';
        return role;
    }

    /**
     * @author Nick Guia
     * @date MAY.15.2018
     * @description Creates test Contact records of record type 'Prospective Student'
     */
    public static List<Contact> createProspectiveStudentContact(Integer num) {
        List<Contact> returnVal = new List<Contact>();

        for(Integer i = 0; i < num; i++) {
            //create a test Contact record
            Contact con = new Contact(
                FirstName = 'Test' + i,
                LastName = 'Prospective',
                Email = 'test.prospective' + i + '@test.com',
                Monash_Email_Address__c = 'test.prospective' + i + '@test.com',
                RecordTypeId = StagedProspectiveStudentUtil.CONTACT_RECTYPE_PROPECTIVESTUDENT,
                Account_Record_Type_Name__c = 'Household_Account'
            );
            returnVal.add(con);
        }
        return returnVal;
    }

    /**
     * @author Nick Guia
     * @date 30/08/2017
     * @description helper method for generating test Leads
     * @param number of Leads to be created
     */
    public static List<Lead> createLeads(Integer num) {
        List<Lead> returnVal = new List<Lead>();
        for(Integer i = 0; i < num; i++) {
            returnVal.add(
                new Lead (FirstName = 'TestFirst' + i,
                          LastName = 'TestLast' + i,
                          Company = 'Test Company ' + i,
                          Country_of_Residence__c = 'AUSTRALIA',
                          Commencement_Year__c = '2017',
                          Current_Studies__c = 'Current student at Monash University',
                          Seeking_information_for__c = 'Myself',
                          Student_type__c = 'Domestic',
                          Study_Level__c = 'Diploma',
                          Status = 'Open',
                          Email = 'Test'+i+'@test.org'
                )
            );
        }
        return returnVal;
    }

    /**
     * @author Nick Guia
     * @date 30/08/2017
     * @description helper method for generating test Leads
     * @param parentIds : Set of IDs to be associated with campaign member. Could be either contact or lead
     *        campaignId : parent campaign ID of campaign member
     */
    public static List<CampaignMember> createCampaignMembersWithParent(Set<Id> parentIds,
                                                                       Id campaignId)
    {
        String contactPrefix = Schema.SObjectType.Contact.getKeyPrefix();
        List<CampaignMember> returnVal = new List<CampaignMember>();
        for(Id parentId : parentIds) {
            CampaignMember cm = new CampaignMember();
            cm.CampaignId = campaignId;
              //check if id is for contact
            if ((String.valueOf(parentId)).startsWith(contactPrefix)) {
                //assign contact as parent
                cm.ContactId = parentId;
            } else {
                //assign lead as parent
                cm.LeadId = parentId;
            }
            returnVal.add(cm);
        }
        return returnVal;
    }


    /**
     * @author Nick Guia
     * @date FEB.14.2018
     * @description helper method for generating test Contact Qualifications
     * @param num : number of records that will be created
     *        conId : Id of parent Contact
     */
    public static List<Contact_Qualification__c> createContactQualifications(Integer num, Id conId) {
        List<Contact_Qualification__c> cqList = new List<Contact_Qualification__c>();
        for(Integer i = 0; i < num; i++) {
            Contact_Qualification__c cq = new Contact_Qualification__c();
            cq.Contact__c = conId;
            cq.Other_Qualification__c = 'Test' + i;
            cq.Institution_Name__c = 'Test' + i;

            cqList.add(cq);
        }
        return cqList;
    }

    /**
     * @author Nick Guia
     * @date FEB.14.2018
     * @description helper method for generating Staged Prospective Student Records
     * @param num : number of records that will be created
     */
    public static List<Staged_Prospective_Student__c> createSPS(Integer num) {
        List<Staged_Prospective_Student__c> spsList = new List<Staged_Prospective_Student__c>();
        for(Integer i = 0; i < num; i++) {
            Staged_Prospective_Student__c sps = new Staged_Prospective_Student__c();
            //Setup status
            sps.Status__c = 'New';
            //Contact Fields
            sps.Salutation__c = 'Mr';
            sps.First_Name__c = 'Test' + i;
            sps.Last_Name__c = 'PVT';
            sps.Email__c = 'test.prospective1@test.com';
            sps.Mobile__c = '0411734787';
            sps.Phone__c = '0411111111';
            sps.Birthdate__c = date.newinstance(1990, 2, 1);
            sps.Birth_year__c = '1980';
            sps.Gender__c = 'M';
            sps.Country_of_Residence__c = 'AUSTRALIA';
            sps.Nationality__c = 'ADELIE LAND (FRANCE)';
            //Channel Fields
            sps.Mailing_Street__c = 'Test' + i;
            sps.Mailing_City__c = 'Test' + i;
            sps.Mailing_State__c = 'Test' + i;
            sps.Mailing_Postcode__c = '3000';
            sps.Mailing_Country__c = 'Barbados';
            //Lead Fields
            sps.Lead_Source__c = 'Web';
            sps.Broad_area_s_of_interest__c = 'Art, Design and Architecture';
            sps.Study_Funded_By__c = 'My parents are funding my studies';
            sps.Considering_Asian_universities_Text__c = 'true';
            sps.Desired_Start_Year__c = '2020';
            sps.Desired_Start_Period__c = 'Trimester 1';
            sps.Student_type__c = 'International';
            sps.Study_Level__c = 'Foundation Year';
            sps.Current_Studies__c = 'Not currently studying';
            sps.Seeking_information_for__c = 'Child';
            sps.Specific_Study_Area__c = 'Test Area';
            sps.English_Proficiency_Level__c = 'Certificate in Advanced English';
            sps.Complete_Secondary_School__c = '2018';
            sps.Secondary_School__c = 'Some High School';
            sps.Interested_in_Monash_College_Text__c = 'true';
            sps.Parent_Guardian_First_Name__c = 'Test Parent First Name';
            sps.Parent_Guardian_Last_Name__c = 'Test Parent Last Name';
            sps.Parent_Guardian_Email__c = 'testparent@monash.edu';
            sps.Parent_Guardian_Mobile__c = '0411 734 787';
            //Campaign Member Fields
            sps.Web_Lead_Source__c = 'GoogleSourceCode';
            sps.Number_of_Attendees__c = 1;
            sps.Dietary_Requirements__c = 'Vegetarian';
            sps.Session__c = 'Morning';
            //Contact Qualification Fields
            sps.Contact_Qualification_JSON__c = '[{' +
                                                    '"attributes":{'+
                                                        '"type":"Contact_Qualification__c"' +
                                                    '},' +
                                                    '"Other_Qualification__c":"Bachelor\'s",' +
                                                    '"Institution_Name__c":"GRIFFITH UNIVERSITY (FROM 1992 TO CURRENT)"' +
                                                '},{' +
                                                    '"attributes":{' +
                                                        '"type":"Contact_Qualification__c"' +
                                                    '},' +
                                                    '"Other_Qualification__c":"bachelor of social science (youth work)",' +
                                                    '"Institution_Name__c":"RMIT UNIVERSITY"' +
                                                '}]';

            spsList.add(sps);
        }
        return spsList;
    }

    /**
     * @author Nick Guia
     * @date MAR.20.2018
     * @description helper method for generating Lead Course Association (LCA)
     * @param   courseMasterId : Id of parent course
     *          leadId : Id of associated Lead
     *          num : number of records that will be created
     */
    public static List<Lead_Course_Association__c> createLCA(Id courseMasterId, Id leadId, Integer num) {
        List<Lead_Course_Association__c> lcaList = new List<Lead_Course_Association__c>();

        //note: set Last_Associated_Rank__c after return to test properly
        for(Integer i = 0; i < num; i++) {
            Lead_Course_Association__c lca = new Lead_Course_Association__c();
            lca.Course_Master__c = courseMasterId;
            lca.Lead__c = leadId;
            lca.Associated_Date__c = Date.today();

            lcaList.add(lca);
        }
        return lcaList;
    }

    /**
     * @author Nick Guia
     * @description helper method for generating Course_Attempt__c records.
     *              ideally, each contact should only have 1 'Enrolled' Course Attempt
     *              at a time. Test records generated need to be adjusted accordingly
     *              from the client Test Class to produce a more accurate test scenario
     * @param   num : number of records to be created
     *          TODO
     */
    public static List<Course_Attempt__c> createCourseAttempts(Integer num, Id contactId, Id courseId) {
        List<Course_Attempt__c> caList = new List<Course_Attempt__c>();

        for(Integer i = 0; i < num; i++) {
            Course_Attempt__c ca = new Course_Attempt__c();
            ca.Attendance_Mode__c = 'IN';
            ca.Attendance_Type__c = 'FT';
            ca.Callista_External_Id__c = '12345678_A0001';
            ca.Callista_Admission_Application_Id__c = '12345678';
            ca.Commencement_Date__c = Date.today();
            ca.Contact__c = contactId;
            ca.Course__c = courseId;
            ca.Course_Attempt_Status__c = 'Enrolled';
            ca.Course_Requirements_Completed__c = true;
            ca.Course_Requirements_Completion_Date__c = Date.today();
            ca.Fee_Category_Code__c = 'XYZ';
            ca.Fee_Payment_Option__c = 'Fee-Help';
            ca.Fee_Payment_Option_Description__c = 'Test Fee_Payment_Option_Description__c';
            ca.Fee_Payment_Option_Start_Date__c = Date.today();
            ca.Fee_Payment_Option_End_Date__c = Date.today();
            ca.GPA__c = 1;
            ca.Location__c = 'Test Location';
            ca.Nominated_Completion_Period__c = 'Test Nominated_Completion_Period__c';
            ca.Nominated_Completion_Year__c = 2018;
            ca.Portal_Application_Id__c = 'Test Portal_Application_Id__c';
            ca.Student_Confirmed__c = true;
            ca.WAM__c = 80;
            ca.WAM_GPA_Last_Refresh_Date__c = Date.today();
            caList.add(ca);
        }

        return caList;
    }

    /**
     * @author Nick Guia
     * @description helper method for generating Unit_Attempt__c records.
     *              A student should ideally only have 1 'Enrolled' Unit Attempt
     *              of the same Unit Code. Test records generated need to be adjusted accordingly
     *              from the client Test Class to produce a more accurate test scenario
     * @param num : number of records to be created
     * @param courseAttemptId : Id of parent Course Attempt
     * @param contactId : ID of related student (Contact)
     * @revision
     *  APR.02.2019     Nick Guia   - Added CI_Sequence_Number__c data;
     */
    public static List<Unit_Attempt__c> createUnitAttempts(Integer num, Id courseAttemptId, Id contactId) {
        List<Unit_Attempt__c> uaList = new List<Unit_Attempt__c>();
        String unitCode = 'AAA000';

        for(Integer i = 0; i < num; i++) {
            //TODO: add more fields once finalised
            Unit_Attempt__c ua = new Unit_Attempt__c();
            ua.Academic_Year__c = '2018';
            ua.Calendar_Type__c = 'ACAD-YR';
            ua.Course_Attempt__c = courseAttemptId;
            ua.Enrolment_Date__c = Date.today();
            ua.Status__c = 'Enrolled';
            ua.Student__c = contactId;
            ua.Unit_Code__c = unitCode + i;
            ua.CI_Sequence_Number__c = '0001';
            uaList.add(ua);
        }

        return uaList;
    }


        /**
     * @author Nick Guia
     * @description helper method for generating IbdUnitAttempt__e records
     * @param num : number of records to be created
     * @param eventType : 'insert' || 'delete'
     * @revision
     *  APR.02.2019     Nick Guia   - Added CI_Sequence_Number__c data;
     *  AUG.23.2019 	MJC	Removed fields for SF-2872
     */
    public static List<IbdUnitAttempt__e> createIbdUnitAttempts(Integer num, String eventType) {
        List<IbdUnitAttempt__e> iuaList = new List<IbdUnitAttempt__e>();
        String personId = '12345678';
        String unitCode = 'AAA000';
        String courseCode = 'A000';

        for(Integer i = 0; i < num; i++) {
            IbdUnitAttempt__e iua = new IbdUnitAttempt__e();
            iua.Event_Type__c = eventType;
            iua.Academic_Year__c = '2018';
            iua.Calendar_Type__c = 'ACAD-YR';
            iua.Course_Code__c = courseCode + i;
            iua.Enrolment_Date__c = Date.today();
            iua.Short_Title__c = 'Unit Short Title';
            iua.Person_ID__c = personId + i;
            iua.Status__c = 'Enrolled';
            iua.Unit_Code__c = unitCode + i;
            iua.Unit_Class__c = 'Day';
            iua.Unit_Mode__c = 'ON';
            iua.Unit_Level__c = '1';
            iua.Discontinued_Date__c = Date.today();
            iua.Enrolment_Date__c = Date.today();
            iua.Grade__c = '100';
            iua.Location__c = 'TESTLOC';
            iua.Mark__c = 100;
            iua.Outcome_Date__c = Date.today();
            iua.Override_Credit_Points_Reason__c = 'Test credit points reason';
            iua.Rule_Waived_Comments__c = 'Test rule waived comments';
            iua.Rule_Waived_Date__c = Date.today();
            iua.Unit_Version__c = 1;
            iua.CI_Sequence_Number__c = '0001';

            iuaList.add(iua);
        }
        return iuaList;
    }

    /**
     * @author Nick Guia
     * @description helper method for generating Application_Course_Preference__c records
     * @param   num : number of records to be created
     *          contactId : applicant associated to the ACP
     */
    public static List<Application_Course_Preference__c> createACP(Integer num, Id contactId) {
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();

        for(Integer i = 0; i < num; i++) {
            Application_Course_Preference__c acp = new Application_Course_Preference__c();
            acp.Applicant__c = contactId;
            acp.Callista_Unique_Key_AP__c = '123456-1';
            acp.Callista_Unique_Key_ADM__c = '123456789';
            acp.Unique_External_Id__c = 'generictest56801savcg';
            acpList.add(acp);
        }
        return acpList;
    }

     /**
     * @description helper method for generating Application_Course_Preference__c records for flow
     * @param   num : number of records to be created
     * contactId : applicant associated to the ACP
     * applicationId : Application ID
     * CourseId : CourseId
     */
    public static List<Application_Course_Preference__c> createACPFlow(Integer num, Id contactId, Id applicationId, Id CourseId) {
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        for(Integer i = 0; i < num; i++) {
            Application_Course_Preference__c acp = new Application_Course_Preference__c();
            acp.Applicant__c = contactId;
            acp.Course__c = CourseId;
            acp.Application__c = applicationId;
            acp.Location_Code__c = 'Calyton';
            acpList.add(acp);
        }
        insert acpList;
        return acpList;
    }

    /**
     * @description helper method for generating Application record
     * contactId : applicant associated to the ACP
     */
    public static Application__c createApplication(Id contactId) {
    	Application__c app = new Application__c();
        app.Applicant__c = contactId;
        insert app;
        return app;
    }

    /**
     * @description helper method for generating Account record
     */
    public static Account createAccount() {
    	Account acc = new Account();
        acc.name = 'Testuser';
        insert acc;
        return acc;
    }

    /**
     * @description helper method for generating Opportunity record
     * accountId : Account Id for the opportunity
     * PBookId : Pricebook ID
     */
    public static Opportunity createOpportunity(Id accountId, Id PBookId) {
    	Opportunity opp = new Opportunity();
        opp.name = 'Bachelor In Salesforce 27 September 2019';
        opp.AccountId = accountId;
        opp.CloseDate = System.today();
        opp.StageName = 'Prospecting';
        opp.Pricebook2Id = PBookId;
        insert opp;
        return opp;
    }

     /**
     * @description helper method for generating Opportunity Line Item
     * @param   num : number of records to be created
     * productId : Id of the product
     * oppId : Opportunity ID
     * pbe : Pricebook entry Id
     */
    public static List<OpportunityLineItem> createOpportunityLineItem(Integer num, Id productId, Id oppId, Id pbe) {
    	List<OpportunityLineItem> lstOli = new List<OpportunityLineItem>();
        for(Integer i = 0; i < num; i++)
        {
        	OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId=oppId;
            oli.Quantity = 1;
            oli.Product2Id = productId;
            oli.PriceBookEntryId=pbe;
            lstOli.add(oli);
        }
	    return lstOli;
   }

    /**
     * @description helper method for generating Product record
     * PBookId : Pricebook ID
     */
    public static Product2 createProduct(Id PBookId) {
    	Product2 prod = new Product2();
        prod.name = 'MONASH INTERNATIONAL MERIT SCHOLARSHIP';
        prod.isActive = true;
        insert prod;

        Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true);
		insert standardPrice;

		PricebookEntry interPrice = new PricebookEntry(Pricebook2Id = PBookId, Product2Id = prod.Id, UnitPrice = 12000, IsActive = true);
		insert interPrice;

        return prod;
    }

     /**
     * @description helper method for generating Pricebook
     */
    public static Pricebook2 createPricebook() {
		Pricebook2 interPB = new Pricebook2(Name='International', isActive=true);
		insert interPB;
        return interPB;
    }

     /**
     * @description helper method for generating Course record
     * productId : Passing Product Id
     */
     public static Course__c createCourse(Id productId) {
     	Course__c cou = new Course__c();
        cou.name = 'APEX101';
        cou.Version__c = '1';
        cou.course_code__c = 'APEX101_1';
        cou.Product2__c = productId;
        insert cou;
        return cou;
    }

    /**
     * @author Nick Guia
     * @description helper method for generating test Event Campaigns records
     * @param num : number of records to be created
     * @param btEventList : list of Blackthorn Event records to be linked to the Campaign
     */
    public static List<Campaign> createEventCampaigns(Integer num, List<conference360__Event__c> btEventList) {
        List<Campaign> recList = new List<Campaign>();
        for(Integer i = 0; i < num; i++) {
            Campaign rec = new Campaign();
            if ((i+1)<=btEventList.size())
            {
                rec.Name = btEventList[i].Internal_Name__c;
                rec.Public_Display_Name__c = btEventList[i].Name;
            }
            else {
                rec.Name = 'Test Event ' + i;
                rec.Public_Display_Name__c = 'Test Event ' + i;
            }

            rec.RecordTypeId = CampaignServices.EVENT_RECTYPE;
            rec.IsActive = true;

            //check if there's sufficient event records to be linked
            if(i < btEventList.size()) {
                rec.conference360__Event__c = btEventList[i].Id;
            }
            recList.add(rec);
        }
        return recList;
    }
    
     /**
     * @author Ibrahim Rumi
     * @description helper method for generating Event Settings
     * @param num : number of records to be created
     */
	public static List<conference360__Event_Settings__c> createEventSettings(Integer num) {
    	List<conference360__Event_Settings__c> recList = new List<conference360__Event_Settings__c>();
        for(Integer i = 0; i < num; i++) {
        	conference360__Event_Settings__c rec = new conference360__Event_Settings__c();
            rec.Name = 'Test Event Setting' + i;
            //TODO: ADD MORE FIELDS HERE
            recList.add(rec);
        }
        return recList;
    }
    
    /**
     * @author Nick Guia
     * @description helper method for generating test Blackthorn Event Campaigns records
     * @param   num : number of records to be created
     */
    public static List<conference360__Event__c> createBlackthornEvents(Integer num) {
        List<conference360__Event__c> recList = new List<conference360__Event__c>();
        for(Integer i = 0; i < num; i++) {
            conference360__Event__c rec = new conference360__Event__c();
            rec.Name = 'Test Event ' + i;
            rec.Internal_Name__c = 'Test Event internal ' + i;
            //TODO: ADD MORE FIELDS HERE
            recList.add(rec);
        }
        return recList;
    }

    /**
     * @author Nick Guia
     * @description helper method for generating test Blackthorn Event Attendee records
     * @param   num : number of records to be created
     */
    public static List<conference360__Attendee__c> createBlackthornAttendee(Id eventId, Integer num) {
        List<conference360__Attendee__c> recList = new List<conference360__Attendee__c>();
        for(Integer i = 0; i < num; i++) {
            conference360__Attendee__c rec = new conference360__Attendee__c();
            rec.conference360__Event__c = eventId;
            rec.conference360__First_Name2__c = 'Test';
            rec.conference360__Last_Name2__c = 'Attendee' + i;
            rec.conference360__Email2__c = rec.conference360__First_Name2__c + '.' + rec.conference360__Last_Name2__c + '@test.org';
            //TODO: ADD MORE FIELDS HERE
            recList.add(rec);
        }
        return recList;
    }
    
    
    /**
     * @author Ibrahim Rumi
     * @description helper method for generating test Blackthorn Event Attendee records with matching contacts
     * @param   num : number of records to be created
     */
    
    public static List<conference360__Attendee__c> createBlackthornAttendeeWithMatchingContacts(Id eventId, Integer num) {
        List<conference360__Attendee__c> recList = createBlackthornAttendee(eventId,num);
        for(conference360__Attendee__c att: recList) {
            Contact con = createContactWithMatchingAttendeeDetails(att);
            att.conference360__Contact__c = con.Id;
        }
        return recList;
    }
    
    /**
    * @Author Ibrahim Rumi
    * @description ensures attendee details matches the contact
    *  so they can be linked together via matching rules
    */
    public static Contact createContactWithMatchingAttendeeDetails(conference360__Attendee__c att) {
        Contact con = new Contact();
        //make sure details match against contact record, so they can be linked
        con.FirstName = att.conference360__First_Name2__c;
        con.LastName = att.conference360__Last_Name2__c;
        con.Email = att.conference360__Email2__c;
        insert con;
        return con;
    }
    
    /**
     * @author Mairaj Haider
     * @description helper method for generating Attendees with  multiple events
     * @param   num : number of records to be created
     */
    public static List<conference360__Attendee__c> createBlackthornAttendeeWithMultipleEvents(Integer num) {
        List<conference360__Attendee__c> recList = new List<conference360__Attendee__c>();
        List<Contact> con = createStudentContacts(1, null);
        insert con;
        List<conference360__Event__c> event =  createBlackthornEvents(num);
    	insert event;        
        for(Integer i = 0; i < num; i++) {
            conference360__Attendee__c rec = new conference360__Attendee__c();
            rec.conference360__Event__c = event[i].Id;
            rec.conference360__Contact__c = con[0].Id;
            recList.add(rec);
        }
        return recList;
    }
    

    public static List<conference360__Form_Submission__c> createBTFormSubmission(Integer num, Id contactId, Id eventId, Id attendeeId, Boolean withFormElement) {
        List<conference360__Form_Submission__c> recList = new List<conference360__Form_Submission__c>();
        for(Integer i = 0; i < num; i++) {
            conference360__Form_Submission__c rec = new conference360__Form_Submission__c();
            rec.conference360__Contact__c = contactId;
            rec.conference360__Event__c = eventId;
            rec.conference360__Attendee__c = attendeeId;
            rec.conference360__Key__c = 'rdgffhmfndmfgddfgndf';
            rec.conference360__Processed__c = false;
            rec.conference360__Status__c = BTFormSubmissionTriggerHandler.STATUS_IN_PROGRESS;
            rec.conference360__Payload__c = createBTFormSubmissionPayload(withFormElement);
            recList.add(rec);
        }
        return recList;
    }

    /**
     * @description create a test payload for form submissions
     */
    private static String createBTFormSubmissionPayload(Boolean withFormElement) {
        //build base open ended payload
        String payload = '{' +
            '"sessionId" : null,' +
            '"sessionAttendeeId" : null,' +
            '"relatedId" : null,' +
            '"key" : null,' +
            '"formSubmissionId" : null,' +
            '"formId" : null,' +
            '"eventId" : "aBY4Y00000017KPWAY",' +
            '"attendeeKey" : "0yDYtqmw4K",' +
            '"attendeeId" : "aBG4Y0000000EHfWAM"';

        //add form elements attribute if required
        if(withFormElement) {
            payload += ',"formElements" : [ {' +
            '"formElementId" : "aBf4Y00000000rqSAA",' +
            '"answer" : "Art, Design and Architecture;Arts, Humanities and Social Sciences"' +
            '} ]';
        }

        //close the JSON
        payload += '}';
        return payload;
    }

    /**
     * @author Nick Guia
     * @description helper method for generating test Blackthorn Event Attendee records
     * @param   num : number of records to be created
     */
    public static bt_stripe__Relationship_Settings__c createBTRelationshipSetting() {
        return new bt_stripe__Relationship_Settings__c(
            Name = 'Default Relationship Setting',
            bt_stripe__Default__c = true,
            bt_stripe__Create_Rule__c = 'Contact',
            bt_stripe__Relationship_Rule__c = 'No Matching Or Record Creation',
            bt_stripe__Match_Records__c = 'Contact',
            bt_stripe__Set_All_Email_Fields__c = true,
            bt_stripe__Contact_Account_Rule__c = 'Create Account'
        );
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         16/Mar/2018
    * @description  generates a random number
    *******************************************************************************/
    public static String generateRandomNumber () {
        return String.valueOf((Math.random()*98765).intValue());
    }

    /**
    * generate a list of files
    * @author Arnie Ug
    * @param numberOfFiles the number of condentDocumentLink records to create
    * @param parentId the id of the parent object for the condentDocumentLink
    * @return list of condentDocumentLink records
    */
    public static List<ContentDocumentLink> createdFiles(integer numberOfFiles, id parentId){
        //Create a ContentVersion (simulating the file content)
        List<ContentVersion> cvToInsert = new List<ContentVersion>();
        for(integer index=0; index<numberOfFiles; index++){
            String fileContent = 'This is the content of the test file ' + index;
            Blob fileBlob = Blob.valueOf(fileContent);

            cvToInsert.add(
                new ContentVersion(
                    Title = 'Test File ' + index,
                    PathOnClient = 'testfile ' + index + '.txt', 
                    VersionData = fileBlob, 
                    IsMajorVersion = true
                )
            );
        }

        //Insert the ContentVersion record
        insert cvToInsert;

        Set<Id> cvInsertedIds = new Set<Id>();
        for(ContentVersion cv : cvToInsert){
            cvInsertedIds.add(cv.Id);
        }
 

        //Retrieve the ContentDocument ID linked to the ContentVersion
        List<ContentDocument> cdList = [SELECT Id, Title FROM ContentDocument WHERE Id IN 
                                            (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvInsertedIds)];
 
        //Create a ContentDocumentLink to link the ContentDocument to the parent record
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for(ContentDocument cd : cdList){
            cdlList.add(
                new ContentDocumentLink(
                    ContentDocumentId = cd.Id, 
                    LinkedEntityId = parentId,  
                    ShareType = 'V',  // 'V' for Viewer, 'C' for Collaborator, 'I' for Inferred
                    Visibility = 'AllUsers'
                )
            );
        }
        
        //Return List
        return cdlList;
    }
}