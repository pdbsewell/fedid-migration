/*******************************************************************************
* @author		Vishal Gupta
* @date         01/10/2024   
* @description  map the GRApplicationJSON to send to callista 
* @revision     
*******************************************************************************/
public with sharing class GRApplicationJSONMapper {    

    private static final String RECORDTYPE_ENGLISH = 'English Test';
    private static final String RECORDTYPE_TERTIARY = 'Tertiary Education';
    private static final String RECORDTYPE_EMPLOYMENT = 'Employment and Research Experience';
    private static final String RECORDTYPE_REFEREE = 'Referees';
    private static final String RECORDTYPE_OTHER = 'Other Qualification';
    private static final String RECORDTYPE_AWARDS = 'Awards, Prizes and Scholarships';
    private static final String RECORDTYPE_THEATRE = 'Theatre Performance';
    private static final String RECORDTYPE_PUBLICATIONS = 'Publications';
    private static final String RECORDTYPE_MUSIC = 'Music';
    private static final String RECORDTYPE_EXHIBITION = 'Exhibitions';
    private static final String RECORDTYPE_CREATIVE = 'Creative Works';
    private static final String QUAL_STATUS_ACCEPTED = 'ACCEPTED';
    private static final String QUAL_STATUS_INPRESS = 'IN-PRESS';
    private static final String QUAL_STATUS_PUBLISHED = 'PUBLISHED';
    private static final String STUDY_LOCATION_CHINA = 'China';

    //enum for switch case constants
    private enum JSONConstants {RECORDTYPE_ENGLISH, RECORDTYPE_TERTIARY, RECORDTYPE_EMPLOYMENT, 
                                RECORDTYPE_REFEREE, RECORDTYPE_OTHER, RECORDTYPE_AWARDS, RECORDTYPE_THEATRE,
                                RECORDTYPE_PUBLICATIONS, RECORDTYPE_MUSIC, RECORDTYPE_EXHIBITION, RECORDTYPE_CREATIVE,
                                QUAL_STATUS_ACCEPTED, QUAL_STATUS_INPRESS, QUAL_STATUS_PUBLISHED}

    //map for constants used for switch case statements
    private static Map<String, JSONConstants> constantsMap = new Map<String, JSONConstants> {
        RECORDTYPE_ENGLISH => JSONConstants.RECORDTYPE_ENGLISH,
        RECORDTYPE_TERTIARY => JSONConstants.RECORDTYPE_TERTIARY,
        RECORDTYPE_EMPLOYMENT => JSONConstants.RECORDTYPE_EMPLOYMENT,
        RECORDTYPE_REFEREE => JSONConstants.RECORDTYPE_REFEREE,
        RECORDTYPE_OTHER => JSONConstants.RECORDTYPE_OTHER,
        RECORDTYPE_THEATRE => JSONConstants.RECORDTYPE_THEATRE,
        RECORDTYPE_AWARDS => JSONConstants.RECORDTYPE_AWARDS,
        RECORDTYPE_PUBLICATIONS => JSONConstants.RECORDTYPE_PUBLICATIONS,
        RECORDTYPE_MUSIC => JSONConstants.RECORDTYPE_MUSIC,
        RECORDTYPE_EXHIBITION => JSONConstants.RECORDTYPE_EXHIBITION,
        RECORDTYPE_CREATIVE => JSONConstants.RECORDTYPE_CREATIVE,
        QUAL_STATUS_ACCEPTED => JSONConstants.QUAL_STATUS_ACCEPTED,
        QUAL_STATUS_INPRESS => JSONConstants.QUAL_STATUS_INPRESS,
        QUAL_STATUS_PUBLISHED => JSONConstants.QUAL_STATUS_PUBLISHED
    };

    /**
     * @author      Vishal Gupta
     * @description get the visa details for grad research applicant
     * @param applicationInfo
     * @return Visa
    */
    public static GRApplicationJSON.Visa getVisaInfo(Application__c applicationInfo) {
        GRApplicationJSON.Visa visaDetails = new GRApplicationJSON.Visa();  
        List<GRApplicationJSON.AdditionalDetails> additionalVisaDetails = new List<GRApplicationJSON.AdditionalDetails>();
        additionalVisaDetails.add(getAdditionalDetails('prApplicationDate', String.valueOf(applicationInfo.PR_Application_Date__c), null));
        additionalVisaDetails.add(getAdditionalDetails('hasAppliedForPR', true, null));
        visaDetails.additionalDetails = additionalVisaDetails;
        return visaDetails;
    }
    /**
     * @author      Vishal Gupta
     * @description get the additional details for grad research applicant
     * @param contactInfo
     * @return List<AdditionalDetails>
    */
    public static List<GRApplicationJSON.AdditionalDetails> getApplicantAdditionalDetails(Contact contactInfo) {
        List<GRApplicationJSON.AdditionalDetails> additionalDetails = new List<GRApplicationJSON.AdditionalDetails>();
        if(contactInfo.Previous_Surname__c != null) {
            additionalDetails.add(getAdditionalDetails('hasNameChanged', true, null));
        }
        if(contactInfo.Monash_Staff_ID__c != null) {
            additionalDetails.add(getAdditionalDetails('monashStaffId', contactInfo.Monash_Staff_ID__c, null));
        }
        return additionalDetails;
    }

    /**
     * @author      Vishal Gupta
     * @description get the Qualifications for grad research applicant
     * @param qualifications
     * @return List<Qualifications>
    */
    public static List<GRApplicationJSON.Qualifications> getApplicantQualificationDetails(List<Contact_Qualification__c> qualifications) {
        List<GRApplicationJSON.Qualifications> quals = new List<GRApplicationJSON.Qualifications>();
        Map<String, List<Contact_Qualification__c>> mapQualNameList = groupContactQualifications(qualifications);
        for(String qualType : mapQualNameList.keyset()){
            quals.addAll(getQualification(mapQualNameList.get(qualType), qualType));
        }
        return quals;
    }

    /**
     * @author      Vishal Gupta
     * @description get the application info for grad research applicant
     * @param qualifications
     * @return List<Qualifications>
    */
    public static GRApplicationJSON.HdrApplicationDetails getHDRApplicationDetails(Application__c applicationInfo, Application_Course_Preference__c acp) {
        GRApplicationJSON.HdrApplicationDetails applicationDetails = new GRApplicationJSON.HdrApplicationDetails();
        applicationDetails.supportingDocuments = getApplicationSupportingDocs(applicationInfo);
        applicationDetails.agentDetail = new GRApplicationJSON.AgentDetail(new GRApplicationJSON.Cls_Contact(applicationInfo.Agent_Staff_Email__c, applicationInfo.Agent_Staff_Details__c));
        if(applicationInfo.Agent__c != null && applicationInfo.Applicant_Agent__c == 'Yes') {
            applicationDetails.agency = new GRApplicationJSON.Agency(applicationInfo.Agent__r.Callista_Org_Unit_Code__c, applicationInfo.Agent__r.Name);
        }
        applicationDetails.hdrApplicationType = getHDRApplicationType(applicationInfo.Graduate_Research_Application_Type__c);
        applicationDetails.countryOfStudy = getHDRCampusLocation(applicationInfo.Campus_Location__c);
        applicationDetails.commencementDate = acp.Proposed_Commencement_Date__c != null ? string.valueOf(acp.Proposed_Commencement_Date__c) : null;
        applicationDetails.submissionDate = applicationInfo.Submitted_Date_Time__c != null ? applicationInfo.Submitted_Date_Time__c.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : null;
        applicationDetails.externalModeContactPlans = acp.Justify_External_Attendance__c;
        applicationDetails.mumNRICPassportNumber = applicationInfo.Malaysian_NRIC_Passport__c;
        applicationDetails.mumResidenceFlag = applicationInfo.Currently_residing_in_Malaysia__c;
        applicationDetails.mumPassType = applicationInfo.Malaysia_pass_type__c;
        applicationDetails.mumPassExpiryDate = applicationInfo.Malaysia_pass_expiry__c != null ? string.valueOf(applicationInfo.Malaysia_pass_expiry__c) : null;
        if(acp.Academic_Org_Unit__c != null) {
            String effectiveDate = acp.Academic_Org_Unit__r.Monash_AM_Start_Date__c != null ? string.valueOf(acp.Academic_Org_Unit__r.Monash_AM_Start_Date__c) : null;
            applicationDetails.academicOrgUnit = new GRApplicationJSON.AcademicOrgUnit(effectiveDate, acp.Academic_Org_Unit__r.Callista_Org_Unit_Code__c);
        }
        applicationDetails.researchProposal = getResearchProposal(acp);
        applicationDetails.scholarship = getScholarshipDetails(acp);
        applicationDetails.declarationText = applicationInfo.Declaration_Text__c;
        applicationDetails.addedAgentFlag = getAddedAgentFlag(applicationInfo);
        return applicationDetails;
    }

    /**
     * @author      Vishal Gupta
     * @description get the Course details for grad research applicant
     * @param qualifications
     * @return List<Qualifications>
    */
    public static List<GRApplicationJSON.CourseDetail> getCourseDetails(Application__c applicationInfo, Application_Course_Preference__c acp) {
        List<GRApplicationJSON.CourseDetail> lstCourseDetails = new List<GRApplicationJSON.CourseDetail>();
        GRApplicationJSON.CourseDetail courseDetails = new GRApplicationJSON.CourseDetail();
        GRApplicationJSON.Course course = new GRApplicationJSON.Course();
        course.title = acp.Course_Title__c;
        course.code = acp.Course_Code__c;
        course.versionNumber = acp.Course_Version_Number__c != null ? Integer.valueOf(acp.Course_Version_Number__c) : null;
        course.faculty = acp.Course__r.Faculty__r.Monash_AM_Start_Date__c != null ? new GRApplicationJSON.Faculty(String.valueof(acp.Course__r.Faculty__r.Monash_AM_Start_Date__c), acp.Course__r.Faculty_Code__c) : null;
        course.courseOffering = getCourseOffering(acp);
        courseDetails.course = course;

        lstCourseDetails.add(courseDetails);
        return lstCourseDetails;
    }

    /**
     * @author      Vishal Gupta
     * @description group the qualifications based on record types
     * @param contactQuals
     * @return Map<String, List<Contact_Qualification__c>>
    */
    private static Map<String, List<Contact_Qualification__c>> groupContactQualifications(List<Contact_Qualification__c> contactQuals) {
        Map<String, List<Contact_Qualification__c>> mapQualNameList = new Map<String, List<Contact_Qualification__c>>();
        for(Contact_Qualification__c cq : contactQuals) {
            if(mapQualNameList.containsKey(cq.Qualification_Type__c)) {
                mapQualNameList.get(cq.Qualification_Type__c).add(cq);
            } else {
                mapQualNameList.put(cq.Qualification_Type__c, new List<Contact_Qualification__c>{cq});
            }            
        }
        return mapQualNameList;
    }
    /**
     * @author      Vishal Gupta
     * @description get the Qualifications section JSON
     * @param cqList
     * @param qualType
     * @return List<GRApplicationJSON.Qualifications> 
    */
    private static List<GRApplicationJSON.Qualifications> getQualification(List<Contact_Qualification__c> cqList, String qualType) {
        List<GRApplicationJSON.Qualifications> qualJsonList = new List<GRApplicationJSON.Qualifications>();
        if(qualType == RECORDTYPE_ENGLISH) {
            if(!cqList.isEmpty())
                qualJsonList.add(formEnglishJSON(cqList[0]));
        }else {
            for(Contact_Qualification__c cq : cqList) {
                GRApplicationJSON.Qualifications qualJSON = new GRApplicationJSON.Qualifications();
                JSONConstants constants = constantsMap.get(qualType);
                switch on constants {
                    when RECORDTYPE_TERTIARY {
                        qualJSON = formTeritaryEducationJSON(cq);
                    }
                    when RECORDTYPE_EMPLOYMENT {
                        qualJSON = formEmploymentJSON(cq);
                    }
                    when RECORDTYPE_AWARDS {
                        qualJSON = formAwardsJSON(cq);
                    }
                    when RECORDTYPE_REFEREE {
                        qualJSON = formRefereeJSON(cq);
                    }
                    when RECORDTYPE_OTHER {
                        qualJSON = formMiscQualJSON(cq);
                    }
                    when else {	
                        qualJSON = formPublicationBookChapterJSON(cq, qualType);
                    }
                }
                qualJsonList.add(qualJSON);
            }
        }
        
        return qualJsonList;
    }
    /**
     * @author      Vishal Gupta
     * @description get the english education section JSON in qualifications
     * @param cq
     * @return GRApplicationJSON.Qualifications
    */
    private static GRApplicationJSON.Qualifications formEnglishJSON(Contact_Qualification__c cq){
        GRApplicationJSON.Qualifications englishJSON = new GRApplicationJSON.Qualifications();
        String qualName = String.isNotBlank(cq.Relevant_Qualification_Name__c) ? getEnglishQualificationCode(cq) : null;
        englishJSON.type = getCQType(qualName, RECORDTYPE_ENGLISH);
        englishJSON.conferredDate = cq.Date_Achieved__c != null ? string.valueOf(cq.Date_Achieved__c) : null;
        englishJSON.expectedDateOfCompletion = cq.Expected_date_of_completion__c != null ? String.valueOf(cq.Expected_date_of_completion__c) : null;

        List<GRApplicationJSON.AdditionalDetails> additionalDetails = new List<GRApplicationJSON.AdditionalDetails>();
        additionalDetails.add(getAdditionalDetails('englishProficiency', cq.English_Proficiency__c, null));
        additionalDetails.add(getAdditionalDetails('smsDocumentId', getCallistaDocId(cq), null));
        englishJSON.additionalDetails = additionalDetails;
        return englishJSON;
    }
    /**
     * @author      Vishal Gupta
     * @description get the Teritary education section JSON in qualifications
     * @param cq
     * @return GRApplicationJSON.Qualifications
    */
    private static GRApplicationJSON.Qualifications formTeritaryEducationJSON(Contact_Qualification__c cq){
        GRApplicationJSON.Qualifications teJSON = new GRApplicationJSON.Qualifications();
        teJSON.type = getCQType(null, RECORDTYPE_TERTIARY);
        teJSON.name = cq.Relevant_Qualification_Name__c;
        teJSON.countryObtained = getCQCountry(cq.Qualification_Country__r.Callista_Code__c, null);
        String instCode = String.isNotBlank(cq.Institution_Code__c) ? cq.Institution_Code__c : '9004';
        teJSON.institution = getCQInstitution(instCode, cq.Relevant_Institution_Name__c);
        teJSON.status = new GRApplicationJSON.Status(cq.Qualification_Status__c);
        teJSON.conferredDate = cq.Completion_Withdrawal_Date__c != null ? string.valueOf(cq.Completion_Withdrawal_Date__c) : null;
        teJSON.startDate = cq.Commencement_Date__c != null ? string.valueOf(cq.Commencement_Date__c) : null;

        List<GRApplicationJSON.AdditionalDetails> additionalDetails = new List<GRApplicationJSON.AdditionalDetails>();
        additionalDetails.add(getAdditionalDetails('sequenceNumber', getSequenceNumber(cq), null));
        additionalDetails.add(getAdditionalDetails('evidenceType', cq.Other_Evidence_Type__c, cq.Evidence_Type__c));
        additionalDetails.add(getAdditionalDetails('courseLength', cq.Course_Length__c, null));
        additionalDetails.add(getAdditionalDetails('researchDescription', cq.Description__c, null));
        if(cq.Former_Supervisor_Details__c != null) {
            additionalDetails.add(getAdditionalDetails('supervisorDetails', cq.Former_Supervisor_Details__c, null));
        }            
        if(cq.Former_Thesis_Topic__c != null) {
            additionalDetails.add(getAdditionalDetails('researchTopic', cq.Former_Thesis_Topic__c, null));
        }            
        if(cq.Reasons_for_transfer__c != null) {
            additionalDetails.add(getAdditionalDetails('transferReason', cq.Reasons_for_transfer__c, null));
        }            
        if(cq.Transfer_Description__c != null) {
            additionalDetails.add(getAdditionalDetails('fieldOfStudySimilarities', cq.Transfer_Description__c, null));
        }            
        additionalDetails.add(getAdditionalDetails('smsDocumentId', getCallistaDocId(cq), null));

        teJSON.additionalDetails = additionalDetails;
        return teJSON;
    }
    /**
     * @author      Vishal Gupta
     * @description get the Employment and Research section JSON in qualifications
     * @param cq
     * @return GRApplicationJSON.Qualifications
    */
    private static GRApplicationJSON.Qualifications formEmploymentJSON(Contact_Qualification__c cq) {
        GRApplicationJSON.Qualifications employmentJSON = new GRApplicationJSON.Qualifications();
        employmentJSON.type = getCQType(null, 'Employment and Research');
        employmentJSON.institution = getCQInstitution('', cq.Relevant_Institution_Name__c);
        employmentJSON.countryObtained = getCQCountry(null, cq.Qualification_Country__r.Name);
        employmentJSON.startDate = cq.Commencement_Date__c != null ? string.valueOf(cq.Commencement_Date__c) : null;
        employmentJSON.endDate = cq.Date_Achieved__c != null ? string.valueOf(cq.Date_Achieved__c) : null;
        List<GRApplicationJSON.AdditionalDetails> additionalDetails = new List<GRApplicationJSON.AdditionalDetails>();
        additionalDetails.add(getAdditionalDetails('sequenceNumber', getSequenceNumber(cq), null));
        additionalDetails.add(getAdditionalDetails('smsDocumentId', getCallistaDocId(cq), null));
        additionalDetails.add(getAdditionalDetails('position', cq.Position__c, null));
        additionalDetails.add(getAdditionalDetails('tenure', cq.Tenure__c, null));
        additionalDetails.add(getAdditionalDetails('description', cq.Description__c, null));
        employmentJSON.additionalDetails = additionalDetails;
        return employmentJSON;
    }
    /**
     * @author      Vishal Gupta
     * @description get the Awards section JSON in qualifications
     * @param cq
     * @return GRApplicationJSON.Qualifications
    */
    private static GRApplicationJSON.Qualifications formAwardsJSON(Contact_Qualification__c cq) {
        GRApplicationJSON.Qualifications awardsJSON = new GRApplicationJSON.Qualifications();
        awardsJSON.type = getCQType(null, 'Awards');
        awardsJSON.institution = getCQInstitution('', cq.Relevant_Institution_Name__c);
        awardsJSON.name = cq.Other_Qualification__c;
        awardsJSON.conferredDate = cq.Date_Achieved__c != null ? string.valueOf(cq.Date_Achieved__c) : null;
        
        List<GRApplicationJSON.AdditionalDetails> additionalDetails = new List<GRApplicationJSON.AdditionalDetails>();
        additionalDetails.add(getAdditionalDetails('sequenceNumber', getSequenceNumber(cq), null));
        additionalDetails.add(getAdditionalDetails('smsDocumentId', getCallistaDocId(cq), null));
        additionalDetails.add(getAdditionalDetails('evidenceType', null, cq.Evidence_Type__c));
        additionalDetails.add(getAdditionalDetails('awardPrestige', cq.Standing_of_Award__c, null));
        additionalDetails.add(getAdditionalDetails('description', cq.Description__c, null));
        awardsJSON.additionalDetails = additionalDetails;
        return awardsJSON;
    }
    /**
     * @author      Vishal Gupta
     * @description get the referee section JSON in qualifications
     * @param cq
     * @return GRApplicationJSON.Qualifications
    */
    private static GRApplicationJSON.Qualifications formRefereeJSON(Contact_Qualification__c cq) {
        GRApplicationJSON.Qualifications refereeJSON = new GRApplicationJSON.Qualifications();
        refereeJSON.type = getCQType(null, 'Referee');
        refereeJSON.institution = getCQInstitution('', cq.Relevant_Institution_Name__c);
        refereeJSON.countryObtained = getCQCountry(null, cq.Qualification_Country__r.Name);
        
        List<GRApplicationJSON.AdditionalDetails> additionalDetails = new List<GRApplicationJSON.AdditionalDetails>();
        additionalDetails.add(getAdditionalDetails('sequenceNumber', getSequenceNumber(cq), null));
        additionalDetails.add(getAdditionalDetails('smsDocumentId', getCallistaDocId(cq), null));
        additionalDetails.add(getAdditionalDetails('position', cq.Position__c, null));
        additionalDetails.add(getAdditionalDetails('refereeName', cq.Referee_Name__c, null));
        additionalDetails.add(getAdditionalDetails('refereeEmail', cq.Email__c, null));
        additionalDetails.add(getAdditionalDetails('refereeRelationship', cq.Relationship__c, null));
        refereeJSON.additionalDetails = additionalDetails;
        return refereeJSON;
    }
    /**
     * @author      Vishal Gupta
     * @description get the JSON for qualifications such as Publication, Music, Creative Writing, Exhibition,Theatre Performance
     * @param cq
     * @param type
     * @return GRApplicationJSON.Qualifications
    */
    private static GRApplicationJSON.Qualifications formPublicationBookChapterJSON(Contact_Qualification__c cq, String type) {
        GRApplicationJSON.Qualifications publicationJSON = new GRApplicationJSON.Qualifications();
        JSONConstants typeConstants = constantsMap.get(type);
        switch on typeConstants {
            when RECORDTYPE_PUBLICATIONS {
                publicationJSON.type = getCQType(null, 'Publication Details');
            }
            when RECORDTYPE_MUSIC {
                publicationJSON.type = getCQType(null, 'Music');
            }
            when RECORDTYPE_CREATIVE {
                publicationJSON.type = getCQType(null, 'Creative Writing');
            }
            when RECORDTYPE_EXHIBITION {
                publicationJSON.name = cq.Other_Qualification__c;
                publicationJSON.type = getCQType(null, 'Exhibition');
            }
            when RECORDTYPE_THEATRE {
                publicationJSON.type = getCQType(null, 'Theatre Performance');
            }
        }
        if(type == RECORDTYPE_PUBLICATIONS || type == RECORDTYPE_CREATIVE || type == RECORDTYPE_EXHIBITION) {
            publicationJSON.isEnglishInstruction = cq.Is_in_English__c;
        }
        if(type != RECORDTYPE_EXHIBITION && type != RECORDTYPE_CREATIVE) {
            publicationJSON.status = new GRApplicationJSON.Status(cq.Qualification_Status__c);
        }

        if(type == RECORDTYPE_CREATIVE) {
            String status;
            JSONConstants qualStatusConstants = constantsMap.get(cq.Qualification_Status__c);
            switch on qualStatusConstants {
                when QUAL_STATUS_ACCEPTED {
                    status = 'CR-ACCEPTD';
                }
                when QUAL_STATUS_INPRESS {
                    status = 'CR-INPRESS';
                }
                when QUAL_STATUS_PUBLISHED {
                    status = 'CR-PUBLSHD';
                }
                when else {
                    status = cq.Qualification_Status__c;
                }
            }

            publicationJSON.status = new GRApplicationJSON.Status(status);
        }
            
        List<GRApplicationJSON.AdditionalDetails> additionalDetails = new List<GRApplicationJSON.AdditionalDetails>();
        additionalDetails.add(getAdditionalDetails('sequenceNumber', getSequenceNumber(cq), null));
        additionalDetails.add(getAdditionalDetails('smsDocumentId', getCallistaDocId(cq), null));
        if(!String.isBlank(cq.Evidence_Type__c)) {
            additionalDetails.add(getAdditionalDetails('evidenceType', null, cq.Evidence_Type__c));
        }
        if(!String.isBlank(cq.Name_of_Publisher_Journal_Org__c)) {
            String publicationTypeName = cq.Evidence_Type__c == 'CHAPTER' ? 'bookTitle' : 'publisherName';
            additionalDetails.add(getAdditionalDetails(publicationTypeName, cq.Name_of_Publisher_Journal_Org__c, null));
        }
        if(!String.isBlank(cq.Title_of_Publication_Work_Chapter_Paper__c)) {
            additionalDetails.add(getAdditionalDetails('title', cq.Title_of_Publication_Work_Chapter_Paper__c, null));
        }
        if(!String.isBlank(cq.Type_of_publisher__c)) {
            if(type == RECORDTYPE_CREATIVE) {
                additionalDetails.add(getAdditionalDetails('publisherType', null, cq.Type_of_publisher__c));
            }else {
                additionalDetails.add(getAdditionalDetails('publisherType', cq.Type_of_publisher__c, null));
            }
        }
        if(cq.Word_Length__c != null) {
            additionalDetails.add(getAdditionalDetails('wordCount', String.valueOf(cq.Word_Length__c), null));
        }
        if(cq.Number_of_Author_Performer__c != null) {
            additionalDetails.add(getAdditionalDetails('contributorCount', cq.Number_of_Author_Performer__c, null));
        } 
        if(cq.Contribution_Percentage__c != null) {
            additionalDetails.add(getAdditionalDetails('contributionPercentage', cq.Contribution_Percentage__c, null));
        }
        if(!String.isBlank(cq.Language__c)) {
            additionalDetails.add(getAdditionalDetails('languageCode', cq.Language__c, null));
        }
        if(cq.Publication_Date__c != null) {
            additionalDetails.add(getAdditionalDetails('publicationYear', String.valueOf(cq.Publication_Date__c?.year()), null));
        }
        if(cq.Page_Count__c != null) {
            additionalDetails.add(getAdditionalDetails('pageCount', cq.Page_Count__c, null));
        }        
        if(cq.Position_of_author__c != null) {
            additionalDetails.add(getAdditionalDetails('contributorPosition', cq.Position_of_author__c, null));
        }
        if(!String.isBlank(cq.Duration__c)) {
            additionalDetails.add(getAdditionalDetails('duration', cq.Duration__c, null));
        }
        if(!String.isBlank(cq.Location_Venue__c)) {
            additionalDetails.add(getAdditionalDetails('location', cq.Location_Venue__c, null));
        }
        if(!String.isBlank(cq.Solo_or_Group_Exhibition__c)) {
            additionalDetails.add(getAdditionalDetails('soloOrGroup', cq.Solo_or_Group_Exhibition__c, null));
        }
        if(!String.isBlank(cq.Funding_source__c)) {
            additionalDetails.add(getAdditionalDetails('fundingSource', cq.Funding_source__c, null));
        }
        if(!String.isBlank(cq.Primary_Role__c)) {
            additionalDetails.add(getAdditionalDetails('primaryRole', cq.Primary_Role__c, null));
        }
        additionalDetails.add(getAdditionalDetails('quality', cq.Quality_of_work__c, null));
        additionalDetails.add(getAdditionalDetails('description', cq.Description__c, null));
        publicationJSON.additionalDetails = additionalDetails;
        return publicationJSON;
    }
    /**
     * @author      Vishal Gupta
     * @description get the Misc Qualification section
     * @param cq
     * @return GRApplicationJSON.Qualifications
    */
    private static GRApplicationJSON.Qualifications formMiscQualJSON(Contact_Qualification__c cq) {
        GRApplicationJSON.Qualifications miscJSON = new GRApplicationJSON.Qualifications();
        miscJSON.type = getCQType(null, 'Miscellaneous Documents');
        miscJSON.name = cq.Other_Qualification__c;        
        List<GRApplicationJSON.AdditionalDetails> additionalDetails = new List<GRApplicationJSON.AdditionalDetails>();
        additionalDetails.add(getAdditionalDetails('sequenceNumber', getSequenceNumber(cq), null));
        additionalDetails.add(getAdditionalDetails('smsDocumentId', getCallistaDocId(cq), null));
        additionalDetails.add(getAdditionalDetails('title', cq.Title_of_Publication_Work_Chapter_Paper__c, null));
        additionalDetails.add(getAdditionalDetails('quality', cq.Quality_of_work__c, null));
        additionalDetails.add(getAdditionalDetails('description', cq.Description__c, null));
        miscJSON.additionalDetails = additionalDetails;
        return miscJSON;
    }
    /**
     * @author      Vishal Gupta
     * @description get the application supporting docs
     * @param app
     * @return List<GRApplicationJSON.SupportingDocuments> 
    */
    private static List<GRApplicationJSON.SupportingDocuments> getApplicationSupportingDocs(Application__c app) {
        List<GRApplicationJSON.SupportingDocuments> lstSD = new List<GRApplicationJSON.SupportingDocuments>();
        if(app.Contact_Documents__r != null && !app.Contact_Documents__r.isEmpty()) {
            for(Contact_Document__c cd : app.Contact_Documents__r) {
                GRApplicationJSON.SupportingDocuments sd = new GRApplicationJSON.SupportingDocuments();
                if(cd.Contact_Qualification__c == null) {
                    sd.type = cd.Document_Checklist__r.Document_Request_Type__c;
                    List<GRApplicationJSON.AdditionalDetails> additionalDetails = new List<GRApplicationJSON.AdditionalDetails>();
                    additionalDetails.add(getAdditionalDetails('smsDocumentId', cd.Callista_Document_Id__c, null));
                    sd.additionalDetails = additionalDetails; 
                    lstSD.add(sd);
                }
            }
        }
        return lstSD;
    }
    
    /**
     * @author      Vishal Gupta
     * @description get the HDR Application Tupe
     * @param applicationType
     * @return String
    */
    private static String getHDRApplicationType(String applicationType) {
        if(applicationType == 'Admission application only') {
            return 'CAND-ONLY';
        } else if(applicationType == 'Admission and Scholarship') {
            return 'CAND+SS';
        } else if(applicationType == 'Scholarship application only') {
            return 'SS-ONLY';
        }
        return null;
    }
    /**
     * @author      Vishal Gupta
     * @description get the HDR campus location
     * @param location
     * @return String
    */
    private static String getHDRCampusLocation(String location) {
        if(!String.isBlank(location) && location != STUDY_LOCATION_CHINA) {
            return location.toUpperCase();
        } else if(location == STUDY_LOCATION_CHINA) {
            return 'SUZHOU';
        }
        return null;
    }
    /**
     * @author      Vishal Gupta
     * @description get the English qualification name code
     * @param qualName
     * @return String
    */
    private static String getEnglishQualificationCode(Contact_Qualification__c cq) {
        List<String> validQualcodes = new List<String>{'IELTS','PTOEFL','ITOEFL'};
        if(!String.isBlank(cq.Qualification__c) && !String.isBlank(cq.Qualification__r.Callista_Code__c) && validQualcodes.contains(cq.Qualification__r.Callista_Code__c)){
            return cq.Qualification__r.Callista_Code__c;
        }
        return 'ZZ-HDR-OTH';
    }
    /**
     * @author      Vishal Gupta
     * @description get the research proposal for acp
     * @param acp
     * @return GRApplicationJSON.ResearchProposal
    */
    private static GRApplicationJSON.ResearchProposal getResearchProposal(Application_Course_Preference__c acp) {
        GRApplicationJSON.ResearchProposal proposal = new GRApplicationJSON.ResearchProposal();
        proposal.title = acp.Research_Title__c;
        proposal.summary = acp.Research_Summary__c;
        proposal.supervisorName = acp.Research_Supervisors__c;
        proposal.externalSupervisorFlag = acp.External_Supervisor__c;
        proposal.externalFundingFlag = acp.External_Funding__c;
        proposal.externalFundingType = getFundingType(acp.External_Funding_Type__c);
        proposal.externalFundingName = acp.External_Funding_Name__c;
        proposal.externalFundingDurationAndValue = acp.External_Fund_Duration_Value__c;
        proposal.externalFundingSurrenderInd = (acp.Surrender_External_Fund__c != null && acp.Surrender_External_Fund__c.startsWith('Yes')) ? 'Y' : 'N';
        proposal.externalScholarshipApplicationFlag = acp.Applied_for_External_Scholarship__c;
        proposal.externalScholarshipName = acp.Applied_for_External_Scholarship_Name__c;
        proposal.employmentFlag = String.isNotBlank(acp.Employment_Load__c)? true : false;
        proposal.employerNameAndPostion = acp.Employer_and_Position__c;
        proposal.employmentLoadCode = getEmploymentLoad(acp.Employment_Load__c);
        proposal.employmentSchedule = getEmploymentSchedule(acp);
        proposal.researchSchedule = acp.Research_Days__c;
        return proposal;
    }
    /**
     * @author      Vishal Gupta
     * @description get the funding type 
     * @param type
     * @return String
    */
    private static String getFundingType(String type) {
        if(type == 'Stipend / Living Allowance') {
            return 'STIPEND';
        } else if(type == 'Tuition / Fee Paying') {
            return 'TUITION';
        } else if(type == 'Both') {
            return 'BOTH-EFT';
        }
        return null;
    }
    /**
     * @author      Vishal Gupta
     * @description get the EmploymentLoad value for employment type
     * @param type
     * @return String
    */
    private static String getEmploymentLoad(String type) {
        if(type == 'Full-Time') {
            return 'FULL-TIME';
        } else if(type == 'Part-Time/Casual') {
            return 'PTTM+CSUL';
        }
        return null;
    }
    /**
     * @author      Vishal Gupta
     * @description get the employment schedule for Application_Course_Preference__c
     * @param acp
     * @return String
    */
    private static String getEmploymentSchedule(Application_Course_Preference__c acp) {

        Map<String, String> daysMap = new Map<String, String>{'Mon' => 'N', 'Tue' => 'N', 'Wed' => 'N', 'Thu' => 'N', 'Fri' => 'N', 'Sat' => 'N', 'Sun' => 'N'};
        if(String.isNotBlank(acp.Employment_Days__c) && acp.Employment_Hours__c != null) {
            for(String day : acp.Employment_Days__c.split(';')) {
                if(daysMap.containsKey(day)) {
                    daysMap.put(day, 'Y');
                }
            }
            return String.join(daysMap.values(), '|') + '|' +String.valueOf(acp.Employment_Hours__c);
        }
        return null;
    }
    /**
     * @author      Vishal Gupta
     * @description get the sholarship details for course
     * @param acp
     * @return GRApplicationJSON.Scholarship
    */
    private static GRApplicationJSON.Scholarship getScholarshipDetails(Application_Course_Preference__c acp) {
        GRApplicationJSON.Scholarship scholarship = new GRApplicationJSON.Scholarship();
        scholarship.mastersUpgradeFlag = acp.Graduate_Research_Application_Type__c == 'Scholarship' && acp.Master_Upgrade_Flag__c ? true : false;//MGROI-789
        scholarship.previousApplicationYear = acp.Previous_GRT_Application_Date__c != null ? String.valueOf(acp.Previous_GRT_Application_Date__c?.year()) : null;
        scholarship.equityScholarshipFlag = acp.Apply_for_Equity_Scholarship__c;
        scholarship.indigenousScholarshipFlag = acp.Apply_for_Indigenous_Scholarship__c;
        scholarship.changeToFullTimeFlag = acp.Graduate_Research_Application_Type__c == 'Scholarship' && acp.Change_to_Fulltime_Flag__c ? true : false; //MGROI-789
        scholarship.changeToInternalFlag = acp.Graduate_Research_Application_Type__c == 'Scholarship' && acp.Change_to_Internal_Flag__c ? true : false; //MGROI-789
        scholarship.scholarshipRoundCalendarDetail = getScholarshipCalendarDetails(acp);
        return scholarship;
    }
    /**
     * @author      Vishal Gupta
     * @description get the course offering details for course
     * @param acp
     * @return GRApplicationJSON.CourseOffering
    */
    private static GRApplicationJSON.CourseOffering getCourseOffering(Application_Course_Preference__c acp) {
        GRApplicationJSON.CourseOffering courseOffering = new GRApplicationJSON.CourseOffering();
        courseOffering.attendanceType = acp.Attendance_Type__c;
        courseOffering.attendanceMode = acp.Attendance_Mode__c;
        courseOffering.location = new GRApplicationJSON.Location(acp.Location_Code__c);
        courseOffering.calendarDetail = getCalendarDetails(acp);

        return courseOffering;
    }
    /**
     * @author      Vishal Gupta
     * @description get the calendar details for course
     * @param acp
     * @return List<GRApplicationJSON.CalendarDetail>
    */
    private static List<GRApplicationJSON.CalendarDetail> getCalendarDetails(Application_Course_Preference__c acp) {
        List<GRApplicationJSON.CalendarDetail> lstCalendarDetails = new List<GRApplicationJSON.CalendarDetail>();
        String sequenceNumberYear, sequenceNumber;
        if(acp.Course_Offering__r.Calendar__r.Sequence_Number_Year__c != null) {
            sequenceNumberYear = String.valueOf(acp.Course_Offering__r.Calendar__r.Sequence_Number_Year__c);
        }
        if(acp.Course_Offering__r.Calendar__r.Sequence_Number__c != null) {
            sequenceNumber = String.valueOf(acp.Course_Offering__r.Calendar__r.Sequence_Number__c);
        }
        GRApplicationJSON.CalendarDetail calendarDetails1 = new GRApplicationJSON.CalendarDetail(sequenceNumberYear,'ACAD-YR','Academic');
        GRApplicationJSON.CalendarDetail calendarDetails2 = new GRApplicationJSON.CalendarDetail(sequenceNumber,acp.Course_Offering__r.Calendar__r.Type__c,'Admission');
        
        lstCalendarDetails.add(calendarDetails1);
        lstCalendarDetails.add(calendarDetails2);
        return lstCalendarDetails;
    }
    /**
     * @author      Vishal Gupta
     * @description get the scholarship calendar details for course
     * @param acp
     * @return List<GRApplicationJSON.CalendarDetail>
    */
    private static List<GRApplicationJSON.CalendarDetail> getScholarshipCalendarDetails(Application_Course_Preference__c acp) {
        List<GRApplicationJSON.CalendarDetail> lstCalendarDetails = new List<GRApplicationJSON.CalendarDetail>();
        String sequenceNumberYear, sequenceNumber;
        if(acp.Scholarship_Calendar__r.Sequence_Number_Year__c != null) {
            sequenceNumberYear = String.valueOf(acp.Scholarship_Calendar__r.Sequence_Number_Year__c);
        }
        if(acp.Scholarship_Calendar__r.Sequence_Number__c != null) {
            sequenceNumber = String.valueOf(acp.Scholarship_Calendar__r.Sequence_Number__c);
        }
        GRApplicationJSON.CalendarDetail calendarDetails1 = new GRApplicationJSON.CalendarDetail(sequenceNumberYear,'ACAD-YR','Academic');
        GRApplicationJSON.CalendarDetail calendarDetails2 = new GRApplicationJSON.CalendarDetail(sequenceNumber,acp.Scholarship_Calendar__r.Type__c,'Admission');
        
        lstCalendarDetails.add(calendarDetails1);
        lstCalendarDetails.add(calendarDetails2);
        return lstCalendarDetails;
    }
    /**
     * @author      Vishal Gupta
     * @description form the additional details object
     * @param name
     * @param value
     * @param code
     * @return GRApplicationJSON.AdditionalDetails
    */
    private static GRApplicationJSON.AdditionalDetails getAdditionalDetails(String name, Object value, String code) {
        GRApplicationJSON.AdditionalDetails objAdditionalDetails = new GRApplicationJSON.AdditionalDetails(name, value, code);
        return objAdditionalDetails;
    }
    /**
     * @author      Vishal Gupta
     * @description form the contact qualification type object
     * @param name
     * @param type
     * @return GRApplicationJSON.Type
    */
    private static GRApplicationJSON.Type getCQType(String name, String type) {
        GRApplicationJSON.Type typeJSON = new GRApplicationJSON.Type(name, type);
        return typeJSON;
    }
    /**
     * @author      Vishal Gupta
     * @description form the CountryObtained object
     * @param code
     * @param name
     * @return GRApplicationJSON.CountryObtained
    */
    private static GRApplicationJSON.CountryObtained getCQCountry(String code, String name) {
        GRApplicationJSON.CountryObtained countryJSON = new GRApplicationJSON.CountryObtained(code, name);
        return countryJSON;
    }
    /**
     * @author      Vishal Gupta
     * @description form the Institution object
     * @param code
     * @param name
     * @return GRApplicationJSON.Institution
    */
    private static GRApplicationJSON.Institution getCQInstitution(String code, String name) {
        GRApplicationJSON.Institution institutionJSON = new GRApplicationJSON.Institution(code, name);
        return institutionJSON;
    }
    /**
     * @author      Vishal Gupta
     * @description get the sequence numner of Application Qualification
     * @param cq
     * @return Integer
    */
    private static Integer getSequenceNumber(Contact_Qualification__c cq) {
        if(!cq.Application_Qualifications__r.isEmpty() && cq.Application_Qualifications__r[0].Sequence_Number__c != null) {
            return Integer.valueOf(cq.Application_Qualifications__r[0].Sequence_Number__c);
        }
        return null;
    }
    /**
     * @author      Vishal Gupta
     * @description get the callista document id
     * @param cq
     * @return String
    */
    private static String getCallistaDocId(Contact_Qualification__c cq) {
        if(!cq.Contact_Documents__r.isEmpty()) {
            return cq.Contact_Documents__r[0].Callista_Document_Id__c;
        }
        return null;
    }

    /**
     * @author      Arnie Ug
     * @description get the addedagentflag
     * @param applicationInfo
     * @return object
    */
    public static Boolean getAddedAgentFlag(Application__c applicationInfo) {
        if(applicationInfo.Citizenship_Classification__c != 'Domestic'){
            if(applicationInfo.Agent__c != null && applicationInfo.Applicant_Agent__c == 'Yes'){
                return true;
            }
            return null;
        }
        return null;
    }
}