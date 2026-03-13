/**
* @description Controller class to check 'Outcome Controls - Outstanding Tasks' used in 'SCR-Application Course Preference-Outcome Assistant' Flow
* @author      Sravani Naramsetti
* @date        05/02/2025
* @group       Admissions
*/
global class OutstandingTasksOutcomeController {
	/**
* @description Method which checks if any Outstanding Tasks of specific type exists on ACP used in 'SCR-Application Course Preference-Outcome Assistant' Flow
* @param  List<Id> acpIds 
*/
    @InvocableMethod
    global static List<ValidationResponse> outstandingTasksOutcomeCheck(List<Id> acpIds) {
        List<ValidationResponse> results = new List<ValidationResponse>();
        try{
            ValidationResponse result = new ValidationResponse();
            List<String> taskTypes = new List<String>{'Genuine Student','Disability Support Service','Credit Check','Cognate Discipline','Work Experience','Additional Assessment','Non-guideline assessment'};
                List<String> taskStatuses = new List<String>{'Completed'};
                Map<String,List<Task>> taskMap = new Map<String,List<Task>>();
            Application_Course_Preference__c acpRecord = [SELECT Applicant__c, Citizenship_Classification__c From Application_Course_Preference__c WHERE ID IN :acpIds LIMIT 1];
            RecordType taskrecType=[Select id from RecordType where SObjectType='Task' AND DeveloperName = 'Admissions'];
            for(Task tsk : [SELECT Id, WhatId, Type, Owner.Name  
                                      From Task 
                                      WHERE WhatId IN: acpIds AND Type IN :taskTypes AND Status NOT IN : taskStatuses AND RecordTypeId=:taskrecType.id]){
                                          if(tsk.Type == 'Genuine Student'){
                                              taskMap = getTaskMap('Genuine Student',tsk,taskMap);
                                          }else if(tsk.Type == 'Disability Support Service' && acpRecord.Citizenship_Classification__c == 'International'){
                                              taskMap = getTaskMap('Disability Support Service',tsk,taskMap);
                                          }else if(tsk.Type == 'Non-guideline assessment'){
                                              taskMap = getTaskMap('Non-guideline assessment',tsk,taskMap);
                                          }else{
                                              taskMap = getTaskMap(tsk.Type,tsk,taskMap);
                                          }
                                      }
            String resultMsg='';
            String taskList='';
            Boolean otherTask = false;
            if(!taskMap.isEmpty()){
                if(taskMap.size() > 1 && (taskMap.containsKey('Genuine Student') || taskMap.containsKey('Disability Support Service') || taskMap.containsKey('Non-guideline assessment'))){
                    resultMsg+='<i>The following tasks must be completed prior to proceeding: </i>\n'; 
                }       
                for(String taskType:taskMap.keySet()){
                    if(taskType == 'Genuine Student'){
                        result.hasOutstandingTask = true;
                        result.isBlocked = true;
                        if(taskMap.size() >1){
                            resultMsg+= '<i>Genuine Student</i>\n';
                        }else{
                            resultMsg+= '<i>There is an outstanding task for genuine student check.\n This task must be completed before proceeding.</i> \n';
                        }
                    }else if(taskType == 'Disability Support Service'){
                        result.hasOutstandingTask = true;
                        result.isBlocked = true;
                        if(taskMap.size() >1){
                            resultMsg+= '<i>Disability Support Service</i>\n';
                        }else{
                            resultMsg+= '<i>There is an outstanding task for DSS. \n This task must be completed before proceeding.</i> \n';
                        }
                    }else if(taskType == 'Non-guideline assessment'){
                        result.hasOutstandingTask = true;
                        result.isBlocked = true;
                        if(taskMap.size() >1){
                            resultMsg+= '<i>Non-guideline qualification assessment</i>\n';
                        }else{
                            resultMsg+= '<i>There is an outstanding task for Non-guideline Qualification Assessment. \n This task must be completed before proceeding.</i> \n';
                        }
                    }else{
                        otherTask = true;
                        result.hasOutstandingTask = true;
                        Integer i=0;
                        String taskListStr = '<li>';
                        for(Task tsk:taskMap.get(taskType)){
                            taskListStr+=taskType;
                            taskListStr+=', ';
                            taskListStr+=tsk.Owner.Name;
                            if(taskMap.get(taskType).size() != i+1){
                                taskListStr+='</li><li>';
                                i++;
                            }else{
                                taskListStr+='</li>';
                            }
                        }
                        taskList+=taskListStr;
                    }
                }
                if(otherTask){
                	resultMsg+= '<i><ul>The following task(s) have not been completed:'+taskList+' </ul></i> \n';
                }
            }
            result.resultMessage = resultMsg;
            results.add(result);
            
        }catch(Exception ex){
            Nebula.Logger.error('OutstandingTasksOutcomeController.outstandingTasksOutcomeCheck', ex);
            Nebula.Logger.saveLog();
        }      
        return results;
    }
    
    global static Map<String,List<Task>> getTaskMap(String str, Task tsk, Map<String,List<Task>> mapTsk){
        if(mapTsk.containsKey(str)){
            List<Task> tskList = new List<Task>();
            tskList=mapTsk.get(str);
            tskList.add(tsk);
            mapTsk.put(str,tskList);
        }else{
            mapTsk.put(str,new List<Task>{tsk});
        }
        return mapTsk;
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
        global Boolean hasOutstandingTask = false;
    }
}