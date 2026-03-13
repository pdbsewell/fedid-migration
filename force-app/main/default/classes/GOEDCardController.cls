/****************************************************************************
@Name: GOEDCardController
@Author: Kevin Evasco (GrowthOps)
********************************************************************************/
public without sharing class GOEDCardController {
    @AuraEnabled
    public static String getEDInfo(String params)
    {
        System.debug('getEDInfo invoked...');
        System.debug('params=' + params);
        Map<String, String> paramMap = (Map<String, String>)JSON.deserialize(params,   Map<String, String>.class);
        GOEDResponse resp = new GOEDResponse();
        
        try
        {
            String recId = paramMap.get('recId');
            String outcomeField = paramMap.get('outcomeField');
            
            // get the object name
            String objectName = ID.valueOf(recId).getSObjectType().getDescribe().getName();
            
            String queryStr = 'SELECT Id,' + String.escapeSingleQuotes(outcomeField);
            if (paramMap.get('explanationField') != null) {
                queryStr += ', ' + String.escapeSingleQuotes(paramMap.get('explanationField'));
            }
            if (paramMap.get('recommendationField') != null) {
                queryStr += ', ' + String.escapeSingleQuotes(paramMap.get('recommendationField'));
            }
            queryStr += ' FROM ' + String.escapeSingleQuotes(objectName) + ' WHERE Id=\'' + String.escapeSingleQuotes(recId) + '\''; 
            
            SObject obj = Database.query(queryStr);
            
            Map<String, Object>respMap = new Map<String, Object>();
            respMap.put('outcomeField', obj.get(outcomeField));
            if (paramMap.get('explanationField') != null) {
                respMap.put('explanationField', obj.get(paramMap.get('explanationField')));
            }
            if (paramMap.get('recommendationField') != null) {
                respMap.put('recommendationField', obj.get(paramMap.get('recommendationField')));        
            }
            resp.data = respMap;
        }
        catch (exception e)
        {
            resp.status = GOEDResponse.ERROR;
            resp.msg = e.getMessage();
        }
        
        return  JSON.serialize(resp);
    }
}