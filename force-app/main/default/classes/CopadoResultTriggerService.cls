/**
* @description: Service Class for CopadoResultTrigger
**/
public class CopadoResultTriggerService {
    @testvisible
    public static final String JOB_STEP_NAME = Label.Job_Step_Name_CheckMarx;
     public static Map<Id,Id> checkMarxsResultIdByUserStoryIdMap = new Map<Id,Id>();
    private static List<String> resultStatus = new List<String>{'Success','Failed'};
        public static void beforeUpdate(List<copado__Result__c> newList, Map<Id,copado__Result__c> oldMap){
            processCheckMarxResult(newList,oldMap);
        }   
    
    private static void processCheckMarxResult(List<copado__Result__c> newList, Map<Id,copado__Result__c> oldMap){
        Map<Id,copado__Result__c> filteredResultByIdMap = new Map<Id,copado__Result__c>();
        Map<Id,ContentVersion> versionDataByDocumentIdMap = new Map<Id,ContentVersion>();
        Map<Id,Set<Id>> documentIdByResultIdMap = new Map<Id,Set<Id>>(); 
        Set<Id> contentDocumentIdsSet = new Set<Id>();
        List<copado__Static_Code_Analysis_Result__c> insertSCAResultList = new List<copado__Static_Code_Analysis_Result__c>();
        Map<Id,List<copado__Static_Code_Analysis_Violation__c>> insertSCAViolationByResultIdMap = new Map<Id,List<copado__Static_Code_Analysis_Violation__c>>();
        // filter the result records, pick only the Success or Failed result records
        for(copado__Result__c result: newList){
            if(resultStatus.contains(result.copado__Status__c) 
               && (result.copado__JobStep__c != null || result.copado__Result_Data__c != null) 
               && (!resultStatus.contains(oldMap.get(result.Id).copado__Status__c)
                   || result.copado__Result_Data__c != oldMap.get(result.Id).copado__Result_Data__c)){
                       system.debug('result&&&'+result);
                       system.debug('oldMap.get(result.Id)&&&'+oldMap.get(result.Id));
                       filteredResultByIdMap.put(result.Id,result);
               }
        }
        // filter the result records, pick only relevant to Checkmarx result, this is filtered based on the JobStep name
        if(!filteredResultByIdMap.isEmpty()){
        filterResultRecordForCheckMarxResult(filteredResultByIdMap);
        }
        // Query ContentDocumentLink to fetch the ContentDocumentId
        if(!checkMarxsResultIdByUserStoryIdMap.isEmpty()){
            for(ContentDocumentLink documentLink: [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink
                                                   WHERE LinkedEntityId IN :checkMarxsResultIdByUserStoryIdMap.keySet()]){
                                                       contentDocumentIdsSet.add(documentLink.ContentDocumentId);
                                                       if(documentIdByResultIdMap.containsKey(documentLink.LinkedEntityId)){
                                                           documentIdByResultIdMap.get(documentLink.LinkedEntityId).add(documentLink.ContentDocumentId);
                                                       } else {
                                                           documentIdByResultIdMap.put(documentLink.LinkedEntityId,new Set<Id>{documentLink.ContentDocumentId});
                                                       }
                                                   }
        }
        // Query ContentVersion to fetch the File VersionData
        if(!documentIdByResultIdMap.isEmpty()){
            for(ContentVersion version: [SELECT VersionData, FileType , ContentDocumentId FROM ContentVersion 
                                         WHERE ContentDocumentId IN :contentDocumentIdsSet AND FileType = 'XML' AND IsLatest = true]){
                                             versionDataByDocumentIdMap.put(version.ContentDocumentId,version);
                                         }
        }
        if(!versionDataByDocumentIdMap.isEmpty()){
            for(Id resultId: checkMarxsResultIdByUserStoryIdMap.keySet()){
                CxXMLResults cxXMLResultsObj = new CxXMLResults();
                if(documentIdByResultIdMap.containsKey(resultId) && documentIdByResultIdMap.get(resultId) != null){
                    for(Id contentDocumentId : documentIdByResultIdMap.get(resultId)){
                        if(versionDataByDocumentIdMap.containsKey(contentDocumentId) && versionDataByDocumentIdMap.get(contentDocumentId) != null){
                            cxXMLResultsObj  = parseCheckMarxLogFile(versionDataByDocumentIdMap.get(contentDocumentId));
                        } 
                    }
                    if(cxXMLResultsObj.deepLink != null || cxXMLResultsObj.deepLink != ''){
                        copado__Result__c result = filteredResultByIdMap.get(resultId);
                        result.copado__Link__c = cxXMLResultsObj.deepLink;
                    }
                    if(cxXMLResultsObj.querys.size() > 0){
                        // create SCA and voilation records
                        if(checkMarxsResultIdByUserStoryIdMap.get(resultId) != null){
                            copado__Static_Code_Analysis_Result__c scaResultObj = new copado__Static_Code_Analysis_Result__c();
                            scaResultObj.copado__User_Story__c = checkMarxsResultIdByUserStoryIdMap.get(resultId);
                            insertSCAResultList.add(scaResultObj);
                            for(Query queryObj: cxXMLResultsObj.querys){
                                String name = queryObj.name;
                                String categories = queryObj.categories;
                                for(Result resultObj: queryObj.result){
                                    Decimal severityIndex =  resultObj.severityIndex != null ? Decimal.valueOf(resultObj.severityIndex) : null;
                                    for(PathNode pathNodeObj: resultObj.pathNodes){
                                        copado__Static_Code_Analysis_Violation__c violationObj = new copado__Static_Code_Analysis_Violation__c(
                                            copado__File__c = pathNodeObj.fileName,
                                            copado__Line__c =    pathNodeObj.line != null ? Decimal.valueOf(pathNodeObj.line) : null,
                                            copado__Rule__c = name,
                                            copado__Priority__c = severityIndex + 1,
                                            copado__Message__c = categories,
                                            copado__Info_URL__c = resultObj.resultDeepLink
                                        );
                                        if(insertSCAViolationByResultIdMap.containsKey(resultId)){
                                            insertSCAViolationByResultIdMap.get(resultId).add(violationObj);
                                        } else{
                                            insertSCAViolationByResultIdMap.put(resultId, new List<copado__Static_Code_Analysis_Violation__c>{violationObj});
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(insertSCAResultList.size() > 0){
                Set<Id> scaREsultInserSet = new Set<Id>();
                Database.SaveResult[] srList = Database.insert(insertSCAResultList, false);
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        scaREsultInserSet.add(sr.getId());
                    }
                } 
                Map<Id,Id> userStoryIdBySCAResultIdMap = new Map<Id,Id>();
                List<copado__Static_Code_Analysis_Violation__c> scaViolationRecordsForInsertList = new List<copado__Static_Code_Analysis_Violation__c>();
                for(copado__Static_Code_Analysis_Result__c scaResult: [SELECT Id,copado__User_Story__c FROM copado__Static_Code_Analysis_Result__c
                                                                       WHERE Id IN: scaREsultInserSet ]){
                                                                           userStoryIdBySCAResultIdMap.put(scaResult.copado__User_Story__c,scaResult.Id);  
                                                                       }
                if(!insertSCAViolationByResultIdMap.isEmpty() && !userStoryIdBySCAResultIdMap.isEmpty()){
                    for(Id resultId: insertSCAViolationByResultIdMap.keySet()){
                        for(copado__Static_Code_Analysis_Violation__c violationObj: insertSCAViolationByResultIdMap.get(resultId)){
                            Id userStoryId = checkMarxsResultIdByUserStoryIdMap.get(resultId);
                            violationObj.copado__Static_Code_Analysis_Result__c = userStoryIdBySCAResultIdMap.get(userStoryId);
                            scaViolationRecordsForInsertList.add(violationObj);
                        }
                    }
                }
                if(scaViolationRecordsForInsertList.size() > 0){
                    Database.SaveResult[] srViolationList = Database.insert(scaViolationRecordsForInsertList, false);
                }
            }
        }
    }
    
    private static void filterResultRecordForCheckMarxResult(Map<Id,copado__Result__c> filteredResultIdMap){
        for(copado__Result__c result: [SELECT Id, copado__JobStep__c, copado__JobStep__r.Name,copado__Result_Data__c ,
                                       copado__JobStep__r.copado__JobExecution__r.copado__UserStoryCommit__r.copado__User_Story__c
                                       FROM copado__Result__c
                                       WHERE Id IN :filteredResultIdMap.keySet()]){
                                           system.debug('result**'+result);
                                           system.debug('result.copado__Result_Data__c**'+result.copado__Result_Data__c);
                                           if(result.copado__JobStep__r.Name == JOB_STEP_NAME){
                                               checkMarxsResultIdByUserStoryIdMap.put(result.Id,result.copado__JobStep__r.copado__JobExecution__r.copado__UserStoryCommit__r.copado__User_Story__c);             
                                           } else if(result.copado__Result_Data__c != null || filteredResultIdMap.get(result.Id)?.copado__Result_Data__c != null){
                                               String copadoResultData = result.copado__Result_Data__c == null ? filteredResultIdMap.get(result.Id)?.copado__Result_Data__c : result.copado__Result_Data__c ;
                                               try{
                                                   Map<String,Object>  resultData = (Map<String,Object>)  JSON.deserializeUntyped(copadoResultData);
                                                   if(!resultData.isEmpty() && resultData.containsKey('userstoryid') && resultData.get('userstoryid') != null){
                                                       checkMarxsResultIdByUserStoryIdMap.put(result.Id,(Id) resultData.get('userstoryid')); 
                                                   }
                                               } catch (Exception exp){
                                                   system.debug('Exception Thrown during Result Data deserialize'+ exp.getMessage());
                                               }
                                           }
                                       }
    }
    
    private static CxXMLResults parseCheckMarxLogFile(ContentVersion version){
        DOM.Document doc = new DOM.Document();
        String deepLink = null;
        CxXMLResults cxXMLResults = new CxXMLResults();
        try{
            doc.load(version.VersionData.toString());
            Dom.XMLNode cxXMLResult = doc.getRootElement();
            cxXMLResults.deepLink = cxXMLResult.getAttribute('DeepLink', null);
            cxXMLResults.querys = new List<Query>();
            for(Dom.XMLNode query: cxXMLResult.getChildElements()){
                Query queryObj = new Query();
                queryObj.name = query.getAttribute('name',null);
                String categories = query.getAttribute('categories',null);
                queryObj.categories = categories?.length() > 255 ? categories.substring(0, 255): categories;
                for(Dom.XMLNode result: query.getChildElements()){
                    Result resultObj = new Result();
                    resultObj.severityIndex = result.getAttribute('SeverityIndex',null);
                    resultObj.resultDeepLink = result.getAttribute('DeepLink',null);
                    Dom.XmlNode[] path = result.getChildren();
                    
                    for(Dom.XMLNode pathNode : path[1].getChildElements()){
                        PathNode pathNodeObj = new PathNode();
                        String fileName = pathNode.getChildElement('FileName',null)?.getText();
                        pathNodeObj.fileName = fileName?.substringAfterLast('/');
                        pathNodeObj.line = pathNode.getChildElement('Line',null)?.getText();
                        resultObj.pathNodes.add(pathNodeObj);
                    }
                    queryObj.result.add(resultObj);
                }
                cxXMLResults.querys.add(queryObj);
            }
        } catch (Exception exp){
            System.debug('Exception in method parseCheckMarxLogFile with '+ exp.getMessage());
        }
        return cxXMLResults;
    }
    
    private class CxXMLResults{
        String deepLink; // DeepLink, fetch from <CxXMLResults> attributes
        List<Query> querys = new List<Query>();
    }
    
    private class Query{
        String name;
        String categories;
        List<Result> result = new List<Result>();
    }
    
    private class Result{
        String severityIndex;
        String resultDeepLink;
        List<PathNode> pathNodes = new List<PathNode>();
    }
    
    private class PathNode{
        String fileName;
        String line;
    }
}