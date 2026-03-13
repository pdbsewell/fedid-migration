/**
 * @File Name          : OfferDeferalService.cls
 * @Description        : Deferral service class
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 6/5/2020, 1:17:01 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/27/2020   jasmin.rudio@monash.edu     Initial Version
**/
public with sharing class OfferDeferalService {

    /**
     * Get a list of acp and new offering group by signed offer. 
     * @param  contactId   contact id of the applicant
     * @return             String json of the response, list of OfferWrapper
     */
    @AuraEnabled
    public static String getOffersForDeferral(String contactId){
        Set<String> statuses = new Set<String>{
            'Review Offer',
            'Publish',
            'Signed'
        };
        return new OfferCourseOfferingMatcher(contactId, statuses).execute();
    }
    public class OfferCourseOfferingMatcher{
        String contactId;
        Set<String> opptyStatus;
        
        @TestVisible OpportunitiesSelector opptySelector;
        @TestVisible CourseOfferingSelector coSelector;
        public OfferCourseOfferingMatcher(String contactId, Set<String> opptyStatus){
            this.contactId = contactId;
            this.opptyStatus = opptyStatus;
            this.opptySelector = new OpportunitiesSelector();
            this.coSelector = new CourseOfferingSelector();
        }
        public String execute(){
            List<OfferWrapper> wrapperMap = new List<OfferWrapper>();
            List<Opportunity> opportunities = this.opptySelector.selectLatesByContactIdWithOpportunityLines(new Set<String>{contactId}, opptyStatus);

            if(opportunities.isEmpty()){
                return '';
            }
            
            Map<String, Set<String>> queryFields = new Map<String, Set<String>>();
            for (String key : new String[]{'CourseCodes', 'LocationCodes', 'AttendanceTypes', 'AttendanceModes','AdmissionCategory', 'UnitSetCodes', 'CitizenshipTypes'}) {
                queryFields.put(key, new Set<String>());
            }
            for(Opportunity opp: opportunities){
                OfferWrapper wrapper = new OfferWrapper(opp); 
                for(OpportunityLineItem lineItem: opp.OpportunityLineItems){
                    //check for course offering link
                    if (lineItem.Application_Course_Preference__c != null &&  lineItem.Application_Course_Preference__r.Course_Offering__r!=null && lineItem.ProductCode != 'ADMFEE'){ 
                        Application_Course_Preference__c acp = lineItem.Application_Course_Preference__r;
                        ACPWrapper acpWrapper = new ACPWrapper(acp);
                        wrapper.acps.add(acpWrapper);
                        queryFields.get('CourseCodes').add(acp.Course_Code__c);
                        queryFields.get('LocationCodes').add(acp.Course_Offering__r.Location_Code__c);
                        queryFields.get('AttendanceTypes').add(acp.Course_Offering__r.Attendance_Type__c);
                        queryFields.get('AttendanceModes').add(acp.Course_Offering__r.Attendance_Mode__c);
                        queryFields.get('AdmissionCategory').add(acp.Course_Offering__r.Admission_Category__c);
                        queryFields.get('CitizenshipTypes').add(acp.Course_Offering__r.Citizenship_Type__c);
                        queryFields.get('UnitSetCodes').add((String.isNotBlank(acp.Unit_Set_Code__c) ? acp.Unit_Set_Code__c : null));
                    }
                }
                System.debug('** wrapper: ' + wrapper);
                wrapperMap.add(wrapper);
            }
            System.debug('-- queryFields: ' + JSON.serialize(queryFields));
            Map<String, Course_Offering__c[]> courseOfferings = new Map<String, Course_Offering__c[]>();
            List<Course_Offering__c> coList = this.coSelector.selectCourseOfferingByAcp(queryFields);
            for(Course_Offering__c offering : coList){
                    String key = offering.Course_Code__c +
                                offering.Location_Code__c + 
                                offering.Attendance_Type__c + 
                                offering.Attendance_Mode__c + 
                                offering.Admission_Category__c + 
                                offering.Citizenship_Type__c + 
                                (offering.Unit_Set_Code__c != null ? offering.Unit_Set_Code__c : '');
                    if (courseOfferings.get(key) == null){
                        courseOfferings.put(key, new Course_Offering__c[0]);
                    }
                    courseOfferings.get(key).add(offering);
            }
            if(wrapperMap.size() > 0){
                ACPWrapper[] lastOfferAcps = wrapperMap.get(0).acps;
                for (ACPWrapper acps : lastOfferAcps){
                        String key = acps.acp.Course_Code__c +
                                    acps.acp.Course_Offering__r.Location_Code__c + 
                                    acps.acp.Course_Offering__r.Attendance_Type__c + 
                                    acps.acp.Course_Offering__r.Attendance_Mode__c + 
                                    acps.acp.Course_Offering__r.Admission_Category__c + 
                                    acps.acp.Course_Offering__r.Citizenship_Type__c + 
                                    (acps.acp.Unit_Set_Code__c != null ? acps.acp.Unit_Set_Code__c : '');
                        if (courseOfferings.get(key) != null){
                            for (Course_Offering__c co : courseOfferings.get(key)){
                                if (acps.acp.Course_Offering__c != co.Id) acps.availableOffering.add(co);
                            }                                        
                        }
                }
                wrapperMap.get(0).acps = lastOfferAcps;
            }
            System.debug('** wrapperMap' + JSON.serialize(wrapperMap));
            return JSON.serialize(wrapperMap);

        }
    }

    public class OfferWrapper{
        public Opportunity oppty;
        public ACPWrapper[] acps;
        public Map<String, Application_Course_Preference__c> updateACPs;
        public OfferWrapper(Opportunity oppty){
            this.oppty = oppty;
            this.acps = new ACPWrapper[0];
            this.updateACPs = new Map<String, Application_Course_Preference__c>();
        }
    }

    public class ACPWrapper{
        public Application_Course_Preference__c acp;
        public Course_Offering__c[] availableOffering;
        public ACPWrapper(Application_Course_Preference__c acp){
            this.acp = acp;
            availableOffering = new Course_Offering__c[0];
        }
    }
}