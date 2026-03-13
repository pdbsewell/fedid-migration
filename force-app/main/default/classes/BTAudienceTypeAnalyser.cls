/**
 * @author Nick Guia
 * @date 16-10-2020
 * @group Event Management
 * @description Service class for conference360__Event__c object (Blackthorn)
 **/
public with sharing class BTAudienceTypeAnalyser {

    @TestVisible
    private List<String> audienceTypes;
    @TestVisible
    private String winningAffiliation;

    //todo: move this to custom metadata
    public static final String EVENT_AUDIENCE_PROSPECTIVE_STUDENT = 'Prospective Student';
    public static final String EVENT_AUDIENCE_APPLICANT = 'Applicant';
    public static final String EVENT_AUDIENCE_STUDENT = 'Student';
    public static final String EVENT_AUDIENCE_ALUMNI = 'Alumni';
    public static final String EVENT_AUDIENCE_DONOR = 'Donor';
    public static final String EVENT_AUDIENCE_EMPLOYEE = 'Employee';
    public static final String EVENT_AUDIENCE_INDUSTRY = 'Industry';
    public static final String EVENT_AUDIENCE_RESEARCHER = 'Researcher';

    public static final String AFFILIATION_PROSPECTIVE_STUDENT = 'Prospective_Student';
    public static final String AFFILIATION_APPLICANT = 'Applicant';
    public static final String AFFILIATION_STUDENT = 'Student';
    public static final String AFFILIATION_ALUMNI = 'Alumni';
    public static final String AFFILIATION_DONOR = 'Donor';
    public static final String AFFILIATION_EMPLOYEE = 'Employee';
    public static final String AFFILIATION_INDUSTRY = 'Industry_Contact';
    public static final String AFFILIATION_RESEARCHER = 'Researcher';

    public static final Map<String, String> AFFILIATION_AUDIENCETYPE_MAPPING = new Map<String, String>{
        EVENT_AUDIENCE_PROSPECTIVE_STUDENT => AFFILIATION_PROSPECTIVE_STUDENT,
        EVENT_AUDIENCE_APPLICANT => AFFILIATION_APPLICANT,
        EVENT_AUDIENCE_STUDENT => AFFILIATION_STUDENT,
        EVENT_AUDIENCE_ALUMNI => AFFILIATION_ALUMNI,
        EVENT_AUDIENCE_DONOR => AFFILIATION_DONOR,
        EVENT_AUDIENCE_EMPLOYEE => AFFILIATION_EMPLOYEE,
        EVENT_AUDIENCE_INDUSTRY => AFFILIATION_INDUSTRY,
        EVENT_AUDIENCE_RESEARCHER => AFFILIATION_RESEARCHER
    };
    
    
    public BTAudienceTypeAnalyser(String eventAudType) {
        if(String.isNotBlank(eventAudType)) {
            audienceTypes = eventAudType.split(';');
        }
    }

    /**
     * @description run logic for analysing the "winning affiliation" based 
     * on (potentially) multiple audience types set on the Event
     */
    public BTAudienceTypeAnalyser runAnalyser() {
        if(this.audienceTypes != null && !this.audienceTypes.isEmpty()) {
            if(this.audienceTypes.size() == 1) {
                /**
                 * if only one audience type was set, we only care about
                 * Prospective Student and industry type
                 */
                String at = this.audienceTypes[0];
                if(at.equalsIgnoreCase(EVENT_AUDIENCE_PROSPECTIVE_STUDENT) ||
                   at.equalsIgnoreCase(EVENT_AUDIENCE_INDUSTRY)) 
                {
                    this.winningAffiliation = at;
                }
            } else if(this.audienceTypes.size() == 2) {
                /**
                 * if more than one audience type was set, check if it contains
                 * Prospective Student ir industry type
                 */
                if(this.audienceTypes.contains(EVENT_AUDIENCE_PROSPECTIVE_STUDENT)) {
                    //PS wins over industry
                    this.winningAffiliation = EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
                } else if(this.audienceTypes.contains(EVENT_AUDIENCE_INDUSTRY)) {
                    //else - industry
                    this.winningAffiliation = EVENT_AUDIENCE_INDUSTRY;
                }
            } else {
                System.debug(LoggingLevel.INFO , 'More than two audience types found. Affiliation is undefined');
            }
        }
        return this;
    }

    /**
     * @description return the "winning" Affiliation based on
     * analyser rules
     */
    public String getAffiliationString() {
        return this.winningAffiliation;
    }
}