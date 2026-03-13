//@revision     Suman Gunaganti(2019-07-05): (SF-2781) Removed Application Document provided object reference
//@Revision     24/01/2020 -Shalini Mendu - SFTN-677 - Accessing Custom settings with getInstance() as query builder isAccessible()
//                           was failing for Custom settings was returning false in Spring '20
//@revision     21/07/2022 - Vinothraja - SFTG-2797 - Used DynamicSoqlBuilder for query generation
public class StudFirst_SubmitApplicationHelper {

    private static final String AUSTRALIA_COUNTRY_CODE = BDPConstants.AUSTRALIA_CALLISTA_CODE;

    //variables FOR Sub Score Type - R.Wilson 14/07/2017
    private static final String LISTENING = 'Listening';
    private static final String READING = 'Reading';
    private static final String SPEAKING = 'Speaking';
    private static final String WRITING = 'Writing';
    private static final String TEST_OF_WRITTEN_ENGLISH = 'Test of Written English';
    private static final String ESSAY_RATING = 'Essay Rating';

    // Retrieve application by application Id
    public static Application__c getApplicationById(String applicationId) {
        Set<String> queryFields = new Set<String> ();
        queryFields.addAll(getAllFields('Application__c').split(','));
        System.debug(LoggingLevel.DEBUG, 'queryFields = ' + queryFields);
        
        String appId = String.escapeSingleQuotes(applicationId);
        String strWHERE = ' Id = :appId';

        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(true)
                .querySObject('Application__c')
                .queryFields(queryFields)
                .getQuery(strWHERE);
        System.debug(LoggingLevel.DEBUG, 'dynamicSOQL = ' + dynamicSOQL);
        List<Application__c> applications = Database.Query(dynamicSOQL);
        return applications.get(0);
    }

    // Retrieve applications by application Ids
    public static Map<String,Application__c> getApplicationsByIds(List<String> applicationIds) {
        List<Application__c> applications = [SELECT Id, Status__c FROM Application__c WHERE Id IN : applicationIds];
        Map<String, Application__c> applicationMap = new Map<String, Application__c>();
        for(Application__c application : applications) {
            applicationMap.put(application.Id, application);
        }
        
        return applicationMap;
    }

    // Retrieve contact by applicant Id
    public static Contact getApplicantById(String applicantId) {
        String strApplicantId = String.escapeSingleQuotes(applicantId);

        String strWHERE = ' Id = :strApplicantId';
        Set<String> queryFields = new Set<String> ();
        queryFields.addAll(getAllFields('Contact').split(','));

        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(true)
                .querySObject('Contact')
                .queryFields(queryFields)
                .getQuery(strWHERE);
        List<Contact> applicants = Database.Query(dynamicSOQL);
        return applicants.get(0);
    } 

    // Retrieve contact qualifications by applicant Id
    public static List<Contact_Qualification__c> getContactQualifications(String applicantId) {
        String strApplicantId = String.escapeSingleQuotes(applicantId);

        String strWHERE = ' Contact__c = :strApplicantId';
        Set<String> queryFields = new Set<String> ();
        queryFields.addAll(getAllFields('Contact_Qualification__c').split(','));
        queryFields.addAll('Qualification_Country__r.Callista_Code__c,Qualification__r.Qualification_Name__c,Qualification__r.Callista_Code__c,Qualification__r.Sub_score_Type__c'.split(','));
        
        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(true)
                .querySObject('Contact_Qualification__c')
                .queryFields(queryFields)
                .getQuery(strWHERE);

        List<Contact_Qualification__c> contactQualifications = Database.Query(dynamicSOQL);
        return contactQualifications;    
    }

    // Retrieve work expereince by applicant Id
    public static List<Work_Experience__c> getWorkExperience(String applicantId) {
        String strApplicantId = String.escapeSingleQuotes(applicantId);

        String strWHERE = ' Contact__c = :strApplicantId';
        Set<String> queryFields = new Set<String> ();
        queryFields.addAll(getAllFields('Work_Experience__c').split(','));
        
        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(true)
                .querySObject('Work_Experience__c')
                .queryFields(queryFields)
                .getQuery(strWHERE);

        List<Work_Experience__c> workExperience = Database.Query(dynamicSOQL);
        return workExperience;
    }

    // Retrieve Attachments by parentId
    public static Map<String, Attachment> getAttachments(List<String> parentIds) {
        List<Attachment> attachments = [SELECT ParentId, Description, ContentType, Body FROM Attachment where ParentId IN : parentIds];
        Map<String, Attachment> attachmentMap = new Map<String, Attachment>();
        for(Attachment attachment : attachments) {
            attachmentMap.put(attachment.ParentId, attachment);
        }
        
        return attachmentMap;
    }

    // Retrieve application course preferences
    public static List<Application_Course_Preference__c> getCoursePreferences(String applicationId) {
        Set<String> queryFields = new Set<String> ();
        queryFields.addAll(getAllFields('Application_Course_Preference__c').split(','));
        String status = 'Closed';
        String appId = String.escapeSingleQuotes(applicationId);
        String dynamicWHEREClause = ' Application__c = :appId AND status__c != :status';

        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(true)
                .querySObject('Application_Course_Preference__c')
                .queryFields(queryFields)
                .getQuery(dynamicWHEREClause);

        List<Application_Course_Preference__c> coursePreferences = Database.Query(dynamicSOQL);
        return coursePreferences;
    }

    // Retrieve Contact Document
    public static Contact_Document__c getContactDocument(String cdId) {
        String queryString = queryBuilder('Contact_Document__c');
        queryString = queryString + ' where Id = \'' + cdId + '\'';
        List<Contact_Document__c> contactDocuments = Database.Query(queryString);
        return contactDocuments.get(0);
    }

    // Retrieve documents requested for application
    public static Map<String, Document_Requested__c> getDocumentsRequested(List<String> applicationIds) {
        Map<String, Document_Requested__c> drMap = new Map<String, Document_Requested__c>();
        List<Document_Requested__c> documentsRequested = [SELECT Id, Application__c, CreatedById, Documents_Requested__c, DR__c FROM Document_Requested__c where Application__c IN : applicationIds];
        for(Document_Requested__c dr : documentsRequested) {
            drMap.put(dr.Application__c, dr);
        }

        return drMap;
    }

    // Retrieve User
    public static User getUser(String userId) {
        String queryString = queryBuilder('User');
        queryString = queryString + ' where Id = \'' + userId + '\'';
        List<User> users = Database.Query(queryString);
        return users.get(0);
    }

    // Retrieve country code by name
    public static String getCountryCode(String countryName) {
        if(String.isNotBlank(countryName)) {
            countryName = countryName.replaceAll('\'', '');    
        }
        String queryString = queryBuilder('Callista_Country_Code__c');
        queryString = queryString + ' where Country__c = \'' + countryName + '\'';
        List<Callista_Country_Code__c> countryCodes = Database.Query(queryString);
        String countryCode = '';
        if(countryCodes.size()>0){
            countryCode = countryCodes.get(0).Code__c;
        }
        return countryCode;    
    }

    // Retrieve SubScore Type code by SubScore description - R.WIlson 14/07/2017
	// Retrieve Subscore Type using getInstance() on Custom setting
    public static String getSubScoreCode(String subscoreName) {
        String subScoreCode = '';

        if(String.isNotBlank(subscoreName))
            subScoreCode = Callista_Sub_Score_Type__c.getInstance(subscoreName).Code__c;
        return subScoreCode;
    }

    // Generic method that generates a query for all fields on any object
    public static String queryBuilder(String sobjName) {
        if(sobjName != null && sobjName != ''){
            String SobjectApiName = sobjName;
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
            String commaSepratedFields = '';
            for(Schema.SObjectField val : fieldMap.values()){
                if(val.getDescribe().isAccessible()){                    
                    if(commaSepratedFields == null || commaSepratedFields == ''){
                        commaSepratedFields = val.getDescribe().getName();
                    }else{
                        commaSepratedFields = commaSepratedFields + ', ' + val.getDescribe().getName();
                    }
                }                
            }
            
            String query = 'select ' + commaSepratedFields + ' from ' + SobjectApiName;
            return query;
        }        
        return null;
    }

    // Get all fields for a specific object
    public static String getAllFields(String sobjName) {
        if(sobjName != null && sobjName != ''){
            String SobjectApiName = sobjName;
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
            String commaSepratedFields = '';
            for(Schema.SObjectField val : fieldMap.values()){
                if(val.getDescribe().isAccessible()){                    
                    if(commaSepratedFields == null || commaSepratedFields == ''){
                        commaSepratedFields = val.getDescribe().getName();
                    }else{
                        commaSepratedFields = commaSepratedFields + ',' + val.getDescribe().getName();
                    }
                }                
            }
            
            return commaSepratedFields;
        }        
        return null;
    }

    // Add Secondary
    public static ObdAdmissionApplicationRequest.Secondary addSecondary(Contact_Qualification__c cq) {
        ObdAdmissionApplicationRequest.Secondary sec= new ObdAdmissionApplicationRequest.Secondary();
        sec.countryCode = cq.Qualification_Country__r.Callista_Code__c;
        sec.stateCode = cq.State__c;
        sec.assessmentQualificationType = cq.Qualification__r.Callista_Code__c;
        sec.otherAssessmentQualification = cq.Other_Qualification__c;
        sec.englishInstructionIndicator = cq.Instruction_in_English__c;
        sec.schoolCode = cq.Institution_Code__c;
        sec.otherSchool = cq.Other_Institution__c;
        sec.completionYear = cq.Year_of_Completion__c;

        // extract the year from the expected date
        if(cq.Expected_date_of_completion__c != null)
        {
            String expectedYear = String.valueOf(cq.Expected_date_of_completion__c.year());
            sec.completionYear = expectedYear;
        }

        if(String.isNotBlank(sec.countryCode) && sec.countryCode.equalsIgnoreCase(AUSTRALIA_COUNTRY_CODE)) {
            sec.score = cq.Score__c;
        }
        else {
            sec.result = cq.Score__c;    
        }
        
        return sec;
    }

    // Add Tertiary
    public static ObdAdmissionApplicationRequest.Tertiary addTertiary(Contact_Qualification__c cq) {
        ObdAdmissionApplicationRequest.Tertiary ter = new ObdAdmissionApplicationRequest.Tertiary();
        ter.countryCode = cq.Qualification_Country__r.Callista_Code__c;
        //ter.countryCode = getCountryCode(cq.Country__c);
        ter.qualificationName = '';
        if(cq.Qualification__r != null && String.isNotBlank(cq.Qualification__r.Qualification_Name__c)) {
            ter.qualificationName = cq.Qualification__r.Qualification_Name__c;
        } else {
            ter.qualificationName = cq.Other_Qualification__c;
        }
        ter.englishInstructionIndicator = cq.Instruction_in_English__c;
        ter.institutionCode = cq.Institution_Code__c;
        ter.otherInstitution = cq.Other_Institution__c;
        ter.firstYearEnrolled = cq.First_Year_Enrolled__c;
        ter.lastYearEnrolled = cq.Last_Year_Enrolled__c;
        ter.levelOfCompletion = getLevelOfCompletion(cq.Status__c);
        return ter;
    }

    // Add Other
    public static ObdAdmissionApplicationRequest.OtherQualification addOther(Contact_Qualification__c cq) {
        ObdAdmissionApplicationRequest.OtherQualification oq = new ObdAdmissionApplicationRequest.OtherQualification();

        oq.otherQualification = '';
        if(cq.Qualification__r != null && String.isNotBlank(cq.Qualification__r.Qualification_Name__c)) {
            oq.otherQualification = cq.Qualification__r.Qualification_Name__c;
        } else {
            oq.otherQualification = cq.Other_Qualification__c;
        } 
        
        //oq.qualificationType = 'OTHERQUAL';      

        if(!cq.isTestCompleted__c){
            oq.achievedDate = convertDate(cq.Expected_date_of_completion__c);
        }else{
            oq.achievedDate = convertDate(cq.Date_Achieved__c);
        }
        oq.comments = cq.Other_Qualification_Comments__c;
        return oq;
    }

    // Add Admission Test
    public static ObdAdmissionApplicationRequest.AdmissionTest addAdmissionTest(Contact_Qualification__c cq) {
        ObdAdmissionApplicationRequest.AdmissionTest at = new ObdAdmissionApplicationRequest.AdmissionTest();
        at.admissionTestType = cq.Qualification__r.Callista_Code__c;
        at.resultType = cq.Status__c;
        at.score = cq.Score__c;
        at.grade = '';

        if(cq.isTestCompleted__c) {
            at.achievedDate = convertDate(cq.Date_Achieved__c);

            //build Admission Test Subscore - R.Wilson 17/07/2017
            List<ObdAdmissionApplicationRequest.AdmissionTestSubscore> tempSubScore = new List<ObdAdmissionApplicationRequest.AdmissionTestSubscore>();

            Map<String, String> fieldsToShowMap = new Map<String, String>();
            List<Schema.FieldSetMember> fieldSetMemberList = SObjectType.Contact_Qualification__c.FieldSets.Sub_Score_Field_Set.getFields();

            String multiSelectField = cq.Qualification__r.Sub_score_Type__c;
            Set<String> multiSelectSet = new Set<String>();

            if(multiSelectField != null){
                if (multiSelectField != null && multiSelectField != '') {
                    multiSelectSet.addAll(multiSelectField.split(';'));
                }
                System.debug('***SUBSCORE: '+multiSelectSet);

                for (Schema.FieldSetMember fsmRec : fieldSetMemberList) {
                    if (multiSelectSet.contains(fsmRec.getLabel())) {
                        fieldsToShowMap.put(fsmRec.getLabel(), fsmRec.getFieldPath());
                    }
                }
                System.debug('***FINAL FIELDS: '+fieldsToShowMap);

                for(String subScoreType: fieldsToShowMap.keySet()){
                    String subScoreValue = (String)cq.get(fieldsToShowMap.get(subScoreType));
                    if(subScoreValue != null){
                        //at.admissionTestSubscore.add(addSubScore(subScoreValue, subScoreType));
                        tempSubScore.add(addSubScore(subScoreValue, subScoreType));
                    }
                }

                if(tempSubScore.size() >0){
                    at.admissionTestSubscore = new List<ObdAdmissionApplicationRequest.AdmissionTestSubscore>();
                    at.admissionTestSubscore.addAll(tempSubScore);
                }
            }

        }
        else {
            at.plannedDate = convertDate(cq.Expected_date_of_completion__c);
        }

        
        return at;
    }

    /*******************************************************************************
     * @author:      Shalini Mendu
     * @date:        25.Jan.2022
     * Integrate English Language proficiency field with Callista
     * @param englishLanguageProficiency  Application.English_Language_Proficiency__c value 
    *******************************************************************************/
    public static ObdAdmissionApplicationRequest.AdmissionTest addEnglishLanguageProficiency(String englishLanguageProficiency) {
        ObdAdmissionApplicationRequest.AdmissionTest at = new ObdAdmissionApplicationRequest.AdmissionTest();
        at.admissionTestType = 'ENG-SC-U19';
        at.grade = englishLanguageProficiency.equalsIgnoreCase('Yes')?'YES':'NO';
        at.achievedDate = convertDate(System.today());
        return at;
    }

    
    //Add subscore 
    public static ObdAdmissionApplicationRequest.AdmissionTestSubscore addSubScore(String strValue, String subScoreType){
        ObdAdmissionApplicationRequest.AdmissionTestSubscore ats = new ObdAdmissionApplicationRequest.AdmissionTestSubscore();
        ats.referenceCode = getSubScoreCode(subScoreType);
        ats.subscore = strValue;
        return ats;
    }

    // Add Work Experience
    public static ObdAdmissionApplicationRequest.WorkExperience addWorkExperience(Work_Experience__c wrkExp) {
        ObdAdmissionApplicationRequest.WorkExperience we = new ObdAdmissionApplicationRequest.WorkExperience();
        we.position = wrkExp.Position__c;
        we.employer = wrkExp.Employer_Name__c;
        we.startDate = convertDate(wrkExp.Start_Date__c);
        we.endDate = convertDate(wrkExp.End_Date__c);
        
        String personName = '';
        if(String.isNotBlank(wrkExp.Contact_Person_First_Name__c))
            personName = personName + wrkExp.Contact_Person_First_Name__c + ' ';
        if(String.isNotBlank(wrkExp.Contact_Person_Last_Name__c))
            personName = personName + wrkExp.Contact_Person_Last_Name__c;
        we.contactPersonName = personName;

        String address = '';
        if(String.isNotBlank(wrkExp.Contact_Person_Street__c))
            address = address + wrkExp.Contact_Person_Street__c + ' ';
        if(String.isNotBlank(wrkExp.Contact_Person_City__c))
            address = address +wrkExp.Contact_Person_City__c + ' ';
        if(String.isNotBlank(wrkExp.Contact_Person_State__c))
            address = address + wrkExp.Contact_Person_State__c + ' ';
        if(String.isNotBlank(wrkExp.Contact_Person_PostalCode__c))
            address = address +wrkExp.Contact_Person_PostalCode__c + ' ';
        if(String.isNotBlank(wrkExp.Contact_Person_Phone__c))
            address = address + wrkExp.Contact_Person_Phone__c + ' ';
        if(String.isNotBlank(wrkExp.Contact_Person_Email__c))
            address = address +wrkExp.Contact_Person_Email__c + ' ';
        
        we.contactAddress = address;

        return we;
    }

    // Add Course Data
    public static ObdAdmissionApplicationRequest.CourseData addCourseData(Application_Course_Preference__c acp) {
        ObdAdmissionApplicationRequest.CourseData cd = new ObdAdmissionApplicationRequest.CourseData();
        cd.courseCode = acp.Course_Code__c;
        cd.courseVersionNumber = String.valueOf(acp.Course_Version_Number__c);
        cd.locationCode = acp.Location_Code__c;
        cd.attendanceMode = acp.Attendance_Mode__c;
        if(String.isNotBlank(acp.Attendance_Type__c)){
            if(acp.Attendance_Type__c.equalsIgnoreCase('FULL TIME')) {
                cd.attendanceType = 'FT';    
            }
            else if(acp.Attendance_Type__c.equalsIgnoreCase('PART TIME')) {
                cd.attendanceType = 'PT';    
            }
            else {
                cd.attendanceType = acp.Attendance_Type__c;
            }
        }        
        cd.preferenceNumber = acp.Preference_Number__c;
        cd.academicCalendarType = acp.Academic_Calendar_Type__c;
        cd.academicCiSequenceNumber = String.valueOf(acp.Academic_CI_Sequence_Number__c);
        cd.admissionCalendarType = acp.Admission_Calendar_Type__c;
        cd.admissionCiSequenceNumber = String.valueOf(acp.Admission_CI_Sequence_Number__c);
        cd.typeOfPlaceCode = acp.Type_of_Place_Code__c;
        cd.unitDetails = acp.Unit_Set_Description__c;
        cd.unitSet = new ObdAdmissionApplicationRequest.UnitSet();
        cd.unitSet.unitSetCode = acp.Unit_Set_Code__c;
        if(acp.Unit_Set_Version__c != null) {
            cd.unitSet.usVersionNumber = String.valueOf(acp.Unit_Set_Version__c);
        }

        return cd;
    }

    // Date formatter
    public static String convertDate(Date d) {
        String dt = '';
        
        if(d != null)
            dt = d.day()+'/'+d.month()+'/'+d.year();

        return dt;
    }

    // Insitution Codes - HARDCODED FOR LATER REMOVAL - TECHNICAL DEBT CAPTURED
    public static String getInstitutionCode(String name) {

        if(String.isNotBlank(name)) {
            String institution1 = 'Caulfield/Chisholm Institute of Technology (before 1990)';
            String institution2 = 'Gippsland Institute of Advanced Education(before 1991)';
            String institution3 = 'Monash University';
            String institution4 = 'Victorian College of Pharmacy (before 1992)'; 

            if(institution1.containsIgnoreCase(name)) {
                return '2160';
            } 
            if(institution2.containsIgnoreCase(name)) {
                return '2165';
            }
            if(institution3.containsIgnoreCase(name)) {
                return '3035';
            }
            if(institution4.containsIgnoreCase(name)) {
                return '2181';
            }    
        }
        
        return '';
    }

    // Level of Completion - HARDCODED FOR LATER REMOVAL - TECHNICAL DEBT CAPTURED
    public static String getLevelOfCompletion(String name) {
        if(String.isNotBlank(name)) {
            String loc1 = 'ATTEMPTED BUT WAS NOT COMPLETED';
            String loc2 = 'CURRENTLY STUDYING';
            String loc3 = 'DISCONTINUED';
            String loc4 = 'SUCCESSFULLY COMPLETED AND OBTAINED'; 

            if(loc1.containsIgnoreCase(name)) {
                return 'ATTEMPTED';
            } 
            if(loc2.containsIgnoreCase(name)) {
                return 'CURRENT';
            }
            if(loc3.containsIgnoreCase(name)) {
                return 'DISCONT';
            }
            if(loc4.containsIgnoreCase(name)) {
                return 'SUCCESSFUL';
            }    
        }
        
        return '';
    }

    // Transaction thread sleep
    public static void sleep(Long milliSeconds) {
        Long timeDiff = 0;
        DateTime firstTime = System.now();
        
        do {
            timeDiff = System.now().getTime() - firstTime.getTime();
        }
        while(timeDiff <= milliSeconds);
    }

    /**
     * @description Return applicantId after parsing CallistaApplicantId
     * from Application and bulkApplicantIds from Contact
     * @author smen0015 
     * @Revision 29/1/2024 - Created
     * @param  appCallistaAppId     Application__r.Callista_Applicant_Id__c passed
     * @param  bulkApplicantId      Applicant__r.bulkapi_Applicant_Ids__c passed
     * @return Return either Application__r.Callista_Applicant_Id__c if not null
     * or the largest Applicant__r.bulkapi_Applicant_Ids__c value 
     */    
    public static String parseApplicantId(String appCallistaAppId , String bulkApplicantId) {
        //appCallistaAppId is not null, it is the Application__r.Callista_Applicant_Id__c
        //return it
        if(appCallistaAppId!=null)
        {
            return appCallistaAppId;
        }
        
        List<String> bulkApplicantIds = new List<String>();

        //if Application__r.Callista_Applicant_Id__c = null
        if(appCallistaAppId ==null)
        {
            //check pplicant__r.bulkapi_Applicant_Ids__c parse it by ;
            if(bulkApplicantId!=null)
            {
                bulkApplicantIds = bulkApplicantId.split(';');
                
                //return the value if there is only one value
                if(bulkApplicantIds.size()==1)
                {
                    return bulkApplicantIds[0];
                }
                else 
                {   //Convert String array to Integer array to find the largest number
                    List<Integer> bulkIntegerApplicantIds = new List<Integer>();
                    //Convert all Strings to Integer and push it to Integer list
                    for(String appId:bulkApplicantIds)
                    {
                        bulkIntegerApplicantIds.add(Integer.valueOf(appId));
                    }
                    //return largest value if there are more than one ; separated values
                    bulkIntegerApplicantIds.sort();
                    return String.valueOf(bulkIntegerApplicantIds[bulkIntegerApplicantIds.size()-1]);
                }
            }
        }
        //return null if it doesnt match any criteria
        return null;
    }

}