/*******************************************************************************
* @author       trentdelaney
* @date         17/9/18
* @description  Fetch all the application related data 
* @revision
* 20.Jun.2024 - Vishal Gupta - MGROI-267 review page refactor, 
                adding 1 additional field to refer on LWC
* 9.Sep.2024  -  Vishal Gupta - review page for graduate research, 
                 to show file names on the review page        
*******************************************************************************/
public with sharing class ApplicationReviewController {

    /**
     * @author      trentdelaney
     * @description Fetch all the application related data
     */
    public class FullApplication {

        Id ApplicantId { get; set; }
        Contact Applicant { get; set; }
        Application__c Application { get; set; }
        Map<String, List<Contact_Qualification__c>> Qualifications { get; set; }
        List<Application_Course_Preference__c> Preferences { get; set; }
        List<Work_Experience__c> Experience { get; set; }
        List<Unit_Preference__c> UnitPreferenceList {get;set;}
        String Residency_Value {get;set;}
        Integer minimumUnits {get;set;}
        Integer maximumUnits {get;set;}
        List<DocumentChecklistData> docData {get; set;}

        FullApplication() {
            InitialiseQualificationMap();
            InitialisePreferences();
            InitialiseWorkExperience();
        }

        //Dynamically define where to map objects based on Record Type
        private void InitialiseQualificationMap() {
            Qualifications = new Map<String, List<Contact_Qualification__c>>();

            Schema.DescribeSObjectResult R = Contact_Qualification__c.SObjectType.getDescribe();
            List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();

            for (RecordTypeInfo rec : RT) {
                Qualifications.put(rec.name, new List<Contact_Qualification__c>());
            }
        }

        private void InitialisePreferences() {
            Preferences = new List<Application_Course_Preference__c>();
        }

        private void InitialiseWorkExperience() {
            Experience = new List<Work_Experience__c>();
        }
    }

    class DocumentChecklistData {
        Document_Checklist__c docChecklist {get; set;}
        String fileName {get; set;}    
    }

    /**
    * @description Get Record Type Name By Id and Object Name
    * @param objectName 
    * @param recordTypeId
    * @return String
    */
    public static String GetRecordTypeNameById(String objectName, Id recordTypeId)
    {
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById().get(recordTypeId).getName();
    }

    /**
    * @description get the application data
    * @param appId
    * @return String
    */
    @AuraEnabled
    public static String GetFullApplication(String appId) {
        //Create our wrapper
        FullApplication app = new FullApplication();

        //Get the application first
        List<Application__c> applications = [
                SELECT Id, Applicant__c, Type_of_Study__c,AgentName__c,Name, Guardian_Email_Address__c, Guardian_Relationship__c, Existing_Aus_disability_support__c, Proxy_Email_Address__c, Sponsor_Email_Address__c,
                        Guardian_Phone_Number__c, Guardian_Full_Name__c, Applicant__r.Salutation, Applicant__r.LastName, Applicant__r.Last_Name__c, toLabel(Applicant__r.Gender__c), Applicant__r.FirstName, Applicant__r.First_Name__c, Applicant__r.Pronouns_V2__c,Applicant__r.Other_Given_Name__c, Applicant__r.Preferred_Name__c, Applicant__r.Birthdate,
                        Applicant__r.Phone, Applicant__r.Email, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingCountry, Applicant__r.MailingPostalCode,
                        Applicant__r.Citizenship__c,  Applicant__r.Previous_Surname__c, toLabel(Residency_Status__c), HasDisabilities__c, Applicant__r.Aboriginal_or_Torres_Strait_Islander__c,
                        Sponsorship_Type__c, Sponsor_Name__c, Sponsor_Scholarship_organisation__c, Applicant__r.Previous_Monash_ID__c, Applicant__r.Previously_Studied_at_Monash__c, Applicant__r.MobilePhone,
                        Source_System__c, Duration_Of_Study__c, Campus_Location__c, Partner_Name__c, Graduate_Research_Application_Type__c, Status__c
                FROM Application__c
                WHERE Id = :appId
        ];

        //Check that we have an application
        if (applications.size() > 0) {
            //Double query for residency and label
            List<Application__c> apps = [SELECT Id,Residency_Status__c FROM Application__c WHERE Id = :applications[0].Id];

            Application__c reviewApp = applications[0];

            //Set the wrapper application
            app.ApplicantId = reviewApp.Applicant__c;
            app.Application = reviewApp;
            app.Residency_Value = apps[0].Residency_Status__c;



            List<Application_Qualification_Provided__c> quals = [
                    SELECT Id, Contact_Qualification__c
                    FROM Application_Qualification_Provided__c
                    WHERE Application__c = :appId
            ];



            //Getting the right Contact Qualifications for this application
            List<Id> contactQualificationIds = new List<Id>();
            for (Application_Qualification_Provided__c aqp : quals) {
                contactQualificationIds.add(aqp.Contact_Qualification__c);
            }
            List<Contact_Qualification__c> contactQuals = [
                    SELECT Id, RecordTypeId, Institution__r.Name,Expected_date_of_completion__c, Qualification__r.Qualification_Name__c,
                            Year_of_Completion__c, Date_Achieved__c, isTestCompleted__c, Qualification__c,
                            Other_Qualification__c, Institution_Name__c, Qualification_Country__r.Name, Status__c, Score__c, Other_Institution__c, First_Year_Enrolled__c,
                            toLabel(Evidence_Type__c), Name_of_Publisher_Journal_Org__c, Title_of_Publication_Work_Chapter_Paper__c, Relevant_Institution_Name__c,
                            Position__c, Referee_Name__c, Location_Venue__c, toLabel(English_Proficiency__c)
                    FROM Contact_Qualification__c
                    WHERE Id IN :contactQualificationIds
            ];

            if (contactQuals.size() > 0) {
                for (Contact_Qualification__c qual : contactQuals) {
                    String recordTypeName = GetRecordTypeNameById('Contact_Qualification__c', qual.RecordTypeId);
                    if (app.Qualifications.containsKey(recordTypeName)){
                        app.Qualifications.get(recordTypeName).add(qual);
                    }
                }
            }

            List<Application_Course_Preference__c> prefs = [
                    SELECT Id, Outcome_Status__c, Course_Code__c, Course_Offering__r.Admission_Calendar_Description__c, Attendance_Mode__c, Location_Code__c, Attendance_Type_Description__c,
                            Offer_Response_Status__c, Preference_Number__c, Course_Title__c, Course_Offering__r.Attendance_Mode_Description__c,
                            Course_Offering__r.Location_Description__c, Course_Offering__r.Commencement_Period__c, Application_Date__c,
                            Application__c, Application__r.Submitted_Date__c, Unit_Set_Description__c, Course_Offering__r.Type_of_Place_Description__c,
                            Course_Offering__r.Attendance_Type_Description__c, Course_Offering__r.Attendance_Mode__c, Course_Offering__r.Start_Date__c, Calendar_Code__r.Type__c, Calendar_Code__r.Year__c,
                            Location_Description__c, Proposed_Commencement_Date__c, Managing_Faculty__c, Research_Title__c, Research_Supervisors__c, External_Supervisor__c,
                            External_Funding__c, External_Funding_Type__c, External_Funding_Name__c, External_Fund_Duration_Value__c, Applied_for_External_Scholarship__c,
                            Applied_for_External_Scholarship_Name__c, Employment_During_Research__c, Employer_and_Position__c, Employment_Load__c, Research_Days__c
                    FROM Application_Course_Preference__c
                    WHERE Application__c = :appId
                    ORDER BY Preference_Number__c ASC
            ];

            app.Preferences = prefs;

            List<Application_Work_Experience_Provided__c> appWorkExperience = [
                    SELECT Id, Work_Experience__c
                    FROM Application_Work_Experience_Provided__c
                    WHERE Application__c = :appId
            ];

            List<Id> contactWorkExperienceId = new List<Id>();
            for (Application_Work_Experience_Provided__c awep : appWorkExperience) {
                contactWorkExperienceId.add(awep.Work_Experience__c);
            }

            List<Work_Experience__c> contactWorkExperience = [
                    SELECT Id, Employer_Name__c, Start_Date__c, End_Date__c, Position__c
                    FROM Work_Experience__c
                    WHERE Id IN :contactWorkExperienceId
            ];

            app.Experience = contactWorkExperience;
            if(reviewApp.Type_of_Study__c=='Study Abroad' || reviewApp.Type_of_Study__c=='Exchange' )
            {
                Map<String,Object> fetchUP =  StudyPreferenceService.fetchUnitPreferences(appId);
                app.UnitPreferenceList = (List<Unit_Preference__c>)fetchUP.get('UPList');
                app.minimumUnits = Integer.valueOf(fetchUP.get('minimumUnits'));
                app.maximumUnits = Integer.valueOf(fetchUP.get('maximumUnits'));
            }

            if(applications[0].Type_of_Study__c == 'Graduate Research') {
                List<DocumentChecklistData> documentDataList = new List<DocumentChecklistData>();
                for(Document_Checklist__c dc : [SELECT Id, Checklist_Requirement__c, Contact_Qualification__c, Application__c, 
                                                (SELECT Filename__c FROM Contact_Documents__r LIMIT 1) 
                                                FROM Document_Checklist__c WHERE Application__c = :appId AND Status__c IN ('Submitted', 'Requested')]) {
                    DocumentChecklistData documentData = new DocumentChecklistData();                   
                    documentData.docChecklist = dc;                               
                    if(!dc.Contact_Documents__r.isEmpty()) {
                        documentData.fileName = dc.Contact_Documents__r[0].Filename__c;
                    }
                    documentDataList.add(documentData);
                }
                app.docData = documentDataList;
            }
        }
        return JSON.serializePretty(app);
    }

}