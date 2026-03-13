/*******************************************************************************
 * @author          Inderpal
 * @description     This class contains lookup and search logic for the Lookup Component LWC
 * @group           Enterprise
 * @revision
 * 1.1            		15/08/2022 - Inderpal D		   - Added method fix SOQL vulnerabilities (ENGAGEIE-1452)
 * 1.0					08/04/2021 - Inderpal D        - Initial version
*******************************************************************************/
public with sharing class LookupComponentController {
    /*
    * Method Name: lookUp
    * @param  searchTerm            searchTerm description
    * @param  objectName            objectName description
    * @param  filters               filters description
    * @param recordId               recordId of the 
    * @param fields                 fields 
    * @return                       return List of SObjects
    * Description: method to query and generate List of SObjects
    */
    @AuraEnabled(cacheable=true)
    public static List<sObject> lookUp(String searchTerm, String objectName, String filters, String recordId, String fields) {

        Integer limitNum = 20;
        String soql = '';
        Set<String> s_fields = new Set<String>();
        for(String field : fields.split(',')){
            s_fields.add(field.trim());
        }
        String whereClause = '';
        if(String.isBlank(recordId)){
            if(String.isNotBlank(searchTerm)){
                whereClause += ' Name Like  \'%' + searchTerm + '%\' ';
            }
            
            if(String.isNotBlank(filters)){
                whereClause += String.isNotBlank(searchTerm) ? ' AND ' : ' ';
                whereClause += filters;
            }
        }else{
            whereClause += ' Id =  \'' + recordId + '\'';
        }  
        soql = DynamicSoqlBuilder.getInstance()
                        .showSOQLStatement(true)
                        .setEnforced(false)
                        .setLimit(20)  
                        .querySObject(objectName)
                        .queryFields(s_fields)
                        .getQuery(whereClause); 
        System.debug('Final Query::::' + soql);
        List<sObject> lookUpList = database.query(soql);
        return lookUpList;  
    }
}