/*******************************************************************************
* @author:      Suman Gunaganti
* @date:        13.September.2019
* @description: trigger by outcome status flow. 
*
* @revision:
*               13.September.2019 SG > Initial class creation.
*               15.OCT.2019 - J.Mapanao - Changed all "Citizenship_Country__r" to "Submission_Location_Country__r"
*               07.Nov.2019 - SG - updated the GTE logic to include all contact qualifications under the applicant
*******************************************************************************/
global class assessmentsDSSandGTECheck {
    @InvocableMethod
    global static List<DSSandGTECheckResponse> DSSandGTECheck(List<Id> acpIds) {
        List<DSSandGTECheckResponse> results = new List<DSSandGTECheckResponse>();
        Map<Id, String> cqMap = new Map<Id,String>();
        List<Id> applicantIds = new List<Id>();
        Map<Id,Application_Course_Preference__c> acpRecordMap = new Map<Id,Application_Course_Preference__c>([SELECT application__r.HasDisabilities__c, 
                                                                                                                     application__r.Existing_Aus_disability_support__c, 
                                                                                                                     application__r.Submission_Location_Country__r.GTE_Risk_Rating__c,
                                                                                                                     application__r.Citizenship_Classification__c, 
                                                                                                                     application__r.Campus_Location__c, 
                                                                                                                     application__r.Submission_Location_Country__r.Country__c, 
                                                                                                                     Course__r.Course_Level__c,
                                                                                                                     Applicant__c
                                                                                                              From Application_Course_Preference__c 
                                                                                                              WHERE ID IN :acpIds]);
        for(Application_Course_Preference__c acp: acpRecordMap.values()){
            applicantIds.add(acp.Applicant__c);
        }

        for (Contact_Qualification__c cq : [SELECT Id, Qualification_Country__r.Name, Contact__c  
                                            From Contact_Qualification__c 
                                            WHERE Qualification_Country__r.GTE_Risk_Rating__c = '3' AND
                                            Contact__c IN: applicantIds]) {
            cqMap.put(cq.Contact__c, cq.Qualification_Country__r.Name);
                                
        }
        for(Application_Course_Preference__c acp: acpRecordMap.values()){
            results.add(doDSSandGTECheck(acp,  cqMap.get(acp.Applicant__c)));
        }
        return results;
    }
    public static DSSandGTECheckResponse doDSSandGTECheck(Application_Course_Preference__c acpRecord, String GTEQualCountry){
        DSSandGTECheckResponse res = new DSSandGTECheckResponse();
        String Country;
        if(acpRecord.application__r.HasDisabilities__c == 'Yes' && 
           acpRecord.application__r.Existing_Aus_disability_support__c != 'Yes' &&
           acpRecord.application__r.Citizenship_Classification__c =='International' && 
           acpRecord.application__r.Campus_Location__c == 'Australia'){
               res.isDSSCheckRequired = 'Required';
           }
        else {
            res.isDSSCheckRequired = 'Not Required';
        }
        if(GTEQualCountry <> Null){
            country = GTEQualCountry;
            res.GTEQual = True;
        }
        if((acpRecord.application__r.Submission_Location_Country__r.GTE_Risk_Rating__c == '2'|| 
            acpRecord.application__r.Submission_Location_Country__r.GTE_Risk_Rating__c == '3') 
            /*&& acpRecord.application__r.Submission_Location_Country__r.Country__c != 'India'*/){
                
               country  = acpRecord.application__r.Submission_Location_Country__r.Country__c;
               res.GTEcountry = True;
           }
        // SFTLG-507 GTE Exemption removed for Indian UG applicants
        /*if(acpRecord.Course__r.Course_Level__c == 'PG' &&
            acpRecord.application__r.Submission_Location_Country__r.Country__c == 'India'){

            country  = acpRecord.application__r.Submission_Location_Country__r.Country__c;
            res.GTEcountry = True;
        }*/
        if(country <> Null){
            res.isGTECheckRequired = 'Required';
            switch on country {
                when 'Pakistan' {
                    res.GTEReviewGroup = 'Pakistan';
                }
                when 'India', 'Nepal' {
                    res.GTEReviewGroup = 'India and Nepal';
                }
                when else {
                    res.GTEReviewGroup = 'World';
                }
            }
        }
        else {
            res.isGTECheckRequired = 'Not Required';
        }
        return res;
    }
    @InvocableVariable
    global Id acpIds;
    
    global class DSSandGTECheckResponse{
        @InvocableVariable
        global String isGTECheckRequired; 
        
        @InvocableVariable
        global String isDSSCheckRequired;
        
        @InvocableVariable
        global String GTEReviewGroup;
        
        global Boolean GTEQual = False;

        global Boolean GTEcountry = False;
    }
}