/**
* @description Service class for running Full Offer Validations for ACP when Outcome Status is OFFER, OFFER-PROV
* @author      Sravani Naramsetti
* @date        06/01/2025
* @group       Admissions
*/
global class ACPValidationFullOfferService {
    /**
     * @description Method which gets validation messages for Full Offer Check in 'SCR - ACP - Outcome Assistant : Full Offer / Conditional Offer' Flow
     * @param  List<Id> acpIds 
     */
    @InvocableMethod
    global static List<ValidationResponse> FullOfferValidationCheck(List<Id> acpIds) {
        List<ValidationResponse> results = new List<ValidationResponse>();
        try{
            ValidationResponse result = new ValidationResponse();
            List<Id> applicantIds = new List<Id>();
            List<Course_Preference_Qualification__c> educationCpqList;
            List<Course_Preference_Qualification__c> englishCpqList;
            Boolean educationFound=false;
            Boolean englishFound=false;
            Map<Id,Application_Course_Preference__c> acpRecordMap = new Map<Id,Application_Course_Preference__c>([SELECT Applicant__c
                                                                                                                  From Application_Course_Preference__c 
                                                                                                                  WHERE ID IN :acpIds]);
            for(Application_Course_Preference__c acp: acpRecordMap.values()){
                applicantIds.add(acp.Applicant__c);
            }
            
            
            List<Course_Preference_Qualification__c > cpqRecords = new List<Course_Preference_Qualification__c >();
            cpqRecords= [SELECT Id, Application_Course_Preference_Parent__c, Contact__c, Result__c, Qualification_Type__c, Contact_Qualification__c, Contact_Qualification__r.Score__c    
                         From Course_Preference_Qualification__c 
                         WHERE Contact__c IN: applicantIds AND Application_Course_Preference_Parent__c IN: acpIds];
            
            if(!cpqRecords.isEmpty()){
                educationCpqList = new List<Course_Preference_Qualification__c>();
                englishCpqList = new List<Course_Preference_Qualification__c>();
                for(Course_Preference_Qualification__c cpq:cpqRecords){
                    if(cpq.Qualification_Type__c == 'Education'){
                        educationCpqList.add(cpq);
                    }else if(cpq.Qualification_Type__c == 'English'){
                        englishCpqList.add(cpq);
                    }
                }
                
                if(!educationCpqList.isEmpty()){
                    for(Course_Preference_Qualification__c cpq1:educationCpqList){
                        if(!String.isBlank(cpq1.Contact_Qualification__r.Score__c)){
                            educationFound = true;
                            break;
                        }
                    }
                    if(!educationFound){
                        result.resultEducationMessage = 'No Score Education';
                    }
                }else{
                    result.resultEducationMessage = 'No Education';
                }
                
                if(!englishCpqList.isEmpty()){
                    for(Course_Preference_Qualification__c cpq2:englishCpqList){
                        if(cpq2.Result__c == 'Satisfactory'){
                            englishFound = true;
                            break;
                        }
                    }
                    if(!englishFound){
                        result.resultEnglishMessage = 'No Satisfactory English';
                    }
                }else{
                    result.resultEnglishMessage = 'No English';
                }
            }else{
                result.resultEnglishMessage = 'Full failed';
                result.resultEducationMessage = 'Full failed';
            }
            
            if(educationFound && englishFound){
                result.isValid = true;
            }
            results.add(result);
        }catch(Exception ex){
             Nebula.Logger.error('ACPValidationFullOfferService.FullOfferValidationCheck', ex);
             Nebula.Logger.saveLog();
        }
        return results;
    }
    
    @InvocableVariable
    global Id acpIds;
    
    //Wrapper to store return data to flow
    global class ValidationResponse{
        @InvocableVariable
        global String resultEducationMessage; 
        
        @InvocableVariable
        global String resultEnglishMessage;
        
        @InvocableVariable
        global Boolean isValid = false;
    }
}