/**
* @description Controller class to check 'Outcome Controls - Encumbrance' used in 'SCR-Application Course Preference-Outcome Assistant' Flow
* @author      Sravani Naramsetti
* @date        29/01/2025
* @group       Admissions
*/
global class EncumbranceOutcomeController {
    /**
* @description Method which checks if any Encumbrances exists on Contact used in 'SCR-Application Course Preference-Outcome Assistant' Flow
* @param  List<Id> acpIds 
*/
    @InvocableMethod
    global static List<ValidationResponse> encumbrancesOutcomeCheck(List<Id> acpIds) {
        List<ValidationResponse> results = new List<ValidationResponse>();
        try{
            ValidationResponse result = new ValidationResponse();
            List<Id> applicantIds = new List<Id>();
            List<String> effTypes = new List<String>{'EXC_COURSE','EXC_CRS_GP','RVK_SRVC','SUS_SRVC'};
                Map<String,List<Encumbrance__c>> encumbranceMap = new Map<String,List<Encumbrance__c>>();
            Application_Course_Preference__c acpRecord = new Application_Course_Preference__c();
            Map<Id,Application_Course_Preference__c> acpRecordMap = new Map<Id,Application_Course_Preference__c>([SELECT Applicant__c, Course_Code__c
                                                                                                                  From Application_Course_Preference__c 
                                                                                                                  WHERE ID IN :acpIds]);
            for(Application_Course_Preference__c acp: acpRecordMap.values()){
                applicantIds.add(acp.Applicant__c);
                acpRecord = acpRecordMap.values()[0];
            }
            
            for(Encumbrance__c enc : [SELECT Id, IsActive__c, eff_type__c, enc_course_code__c, enc_course_group__c, enc_course_group__r.Name   
                                      From Encumbrance__c 
                                      WHERE Contact__c IN: applicantIds AND eff_type__c IN :effTypes AND IsActive__c=true]){
                                          if(enc.eff_type__c == 'RVK_SRVC' && enc.IsActive__c==true){
                                              encumbranceMap = getEncumbranceMap('RVK_SRVC',enc,encumbranceMap);
                                          }else if(enc.eff_type__c == 'SUS_SRVC' && enc.IsActive__c==true){
                                              encumbranceMap = getEncumbranceMap('SUS_SRVC',enc,encumbranceMap);
                                          }else if(enc.eff_type__c == 'EXC_COURSE' && enc.IsActive__c==true && enc.enc_course_code__c==acpRecord.Course_Code__c){
                                              encumbranceMap = getEncumbranceMap('EXC_COURSE',enc,encumbranceMap);
                                          }else if(enc.eff_type__c == 'EXC_CRS_GP' && enc.IsActive__c==true && enc.enc_course_code__c==acpRecord.Course_Code__c){
                                              encumbranceMap = getEncumbranceMap('EXC_CRS_GP',enc,encumbranceMap);
                                          }
                                      }
            String resultMsg='';
            if(!encumbranceMap.isEmpty()){
                if(encumbranceMap.size() >1){
                    resultMsg+='<i>The applicant has multiple encumbrances and an offer cannot be made until all encumbrances have been removed: </i>\n'; 
                }                
                if(encumbranceMap.containsKey('RVK_SRVC')){
                    result.hasEncumbrance = true;
                    result.isBlocked = true;
                    if(encumbranceMap.size() >1){
                        resultMsg+= '<i>All services have been revoked.</i>\n';
                    }else{
                        resultMsg+= '<i>The applicant currently has all services revoked, an offer cannot be made at this stage until encumbrance(s) have been removed.</i> \n';
                    }
                }
                if(encumbranceMap.containsKey('SUS_SRVC')){
                    result.hasEncumbrance = true;
                    result.isBlocked = true;
                    if(encumbranceMap.size() >1){
                        resultMsg+= '<i>All services have been withdrawn.</i>\n';
                    }else{
                    	resultMsg+= '<i>The applicant currently has all services withdrawn, an offer cannot be made at this stage until encumbrance(s) have been removed.</i> \n';   
                    }
                }
                if(encumbranceMap.containsKey('EXC_COURSE')){
                    Integer i=0;
                    String courseCodeList='';
                    for(Encumbrance__c enc:encumbranceMap.get('EXC_COURSE')){
                        courseCodeList+=enc.enc_course_code__c;
                        if(encumbranceMap.get('EXC_COURSE').size() != i+1){
                            courseCodeList+='</li><li>';
                            i++;
                        }else{
                            courseCodeList+='</li>';
                        }
                    }
                    result.hasEncumbrance = true;
                    if(encumbranceMap.size() >1){
                        resultMsg += '<i>The applicant has been excluded from admission and enrolment from: <li>'+courseCodeList+'</ul></i>';
                    }else{
                    	resultMsg += '<i><ul>The applicant has been excluded from admission and enrolment for the  following course codes:<li>'+courseCodeList+'</ul></i>';
                    }
                }
                if(encumbranceMap.containsKey('EXC_CRS_GP')){
                    Integer j=0;
                    String courseCodeGrpList='';
                    for(Encumbrance__c encum:encumbranceMap.get('EXC_CRS_GP')){
                        courseCodeGrpList+=encum.enc_course_group__r.Name;
                        if(encumbranceMap.get('EXC_CRS_GP').size() != j+1){
                            courseCodeGrpList+='</li><li>';
                            j++;
                        }else{
                            courseCodeGrpList+='</li>';
                        }
                    }
                    result.hasEncumbrance = true;
                    if(encumbranceMap.size() >1){
                        resultMsg += '<i>The applicant has been excluded from admission and enrolment from: <li>'+courseCodeGrpList+'</ul></i>';
                    }else{
                    	resultMsg += '<i><ul>The applicant has been excluded from admission and enrolment from the following course groups: <li>'+courseCodeGrpList+'</ul>This course  is part of the course group.</i>';
                    }
                }
            }
            result.resultMessage = resultMsg;
            results.add(result);
            
        }catch(Exception ex){
            Nebula.Logger.error('EncumbranceOutcomeController.encumbrancesOutcomeCheck', ex);
            Nebula.Logger.saveLog();
        }      
        return results;
    }
    
    global static Map<String,List<Encumbrance__c>> getEncumbranceMap(String str, Encumbrance__c enc, Map<String,List<Encumbrance__c>> mapEnc){
        if(mapEnc.containsKey(str)){
            List<Encumbrance__c> encList = new List<Encumbrance__c>();
            encList=mapEnc.get(str);
            encList.add(enc);
            mapEnc.put(str,encList);
        }else{
            mapEnc.put(str,new List<Encumbrance__c>{enc});
        }
        return mapEnc;
    }
    
    @InvocableVariable
    global Id acpIds;
    
    //Wrapper to store return data to flow
    global class ValidationResponse{
        @InvocableVariable
        global String resultMessage='';
        
        @InvocableVariable
        global Boolean isBlocked = false;
        
        @InvocableVariable
        global Boolean hasEncumbrance = false;
    }
}