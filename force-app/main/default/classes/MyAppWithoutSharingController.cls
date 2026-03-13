/**
 * @author      Vishal Gupta
 * @description controller for My.App for the records we want 
 *              to access without applying the sharing rules.
 *              As some object's sharing settings cant be applied on my.app guest user, 
 *              so we have created this class to access the records.
 * @created on  10/09/2024
 */
public without sharing class MyAppWithoutSharingController {
    private static Integer MAX_RESULTS_LIMIT = 500;
    /**
     * @description Construct the query string
     * @param fieldsToReturn
     * @param objectAPIName
     * @param whereFields
     * @param whereValues
     * @param optionalWhereFields
     * @param searchFields
     * @param searchText
     * @return List<Object>
     */
    @AuraEnabled
    public static List<Object> getSearchResults(List<String> fieldsToReturn,
            String objectAPIName,
            List<String> whereFields,
            List<String> whereValues,
            List<String> optionalWhereFields,
            List<String> searchFields,
            String searchText)
    {

        String sQuery = getQueryString(fieldsToReturn,
                objectAPIName,
                whereFields,
                whereValues,
                optionalWhereFields,
                searchFields,
                searchText);

        List<object> listResults;
        listResults = Database.query(sQuery);

        return listResults;
    }

    /**
     * @description Construct the query string, useful for debugging any errors when implemented
     * @param fieldsToReturn
     * @param objectAPIName
     * @param whereFields
     * @param whereValues
     * @param optionalWhereFields
     * @param searchFields
     * @param searchText
     * @return String
     */
    public static String getQueryString(List<String> fieldsToReturn,
            String objectAPIName,
            List<String> whereFields,
            List<String> whereValues,
            List<String> optionalWhereFields,
            List<String> searchFields,
            String searchText)
    {
        Set<String> setFieldsToReturn = new Set<String> ();

        // fields to return
        for(String strField : fieldsToReturn)
        {
            setFieldsToReturn.add(String.escapeSingleQuotes(strField));
        }

        // where conditions
        String sWhere = '';
        Integer iWhereFields = whereFields.size();
        for(Integer iWhere = 0; iWhere < iWhereFields; ++iWhere)
        {
            if(iWhere != 0)
                sWhere += ' AND ';

            // do not do not add quotes for integer and booleans
            String sValue = whereValues[iWhere];
            String sDelim = '\'';
            if(sValue.isNumeric() || sValue=='true' || sValue =='false')
            {
                sDelim = '';
            }

            // if it's an optional field, need to add an or clause
            String sField = whereFields[iWhere];
            if(optionalWhereFields.indexOf(sField) >= 0)
            {
                sWhere += '(' + String.escapeSingleQuotes(sField) + '=NULL OR ';
                sWhere +=  String.escapeSingleQuotes(sField) + '=' + sDelim + String.escapeSingleQuotes(sValue) + sDelim;
                sWhere += ')';
            }
            else
            {
                // SFTG-2480 Included to handle NOT logic & LIKE comparison scenarios; 
                // Prefix where Fields names in the component with ! (for NOT) and % (for LIKE) in this order
                // example: whereFields="['Overseas__c','RecordType.Name', '!%Qualification_Name__c']"
                Boolean isLikeComparison = false;
                Boolean isNOTLogic = false;
                if (sField.startsWith('!')) { 
                    isNOTLogic = true;
                    sField = sField.removeStart('!');
                } 
                if (sField.startsWith('%')) { 
                    isLikeComparison = true;
                    sField = sField.removeStart('%');
                }
                if (isLikeComparison) {
                    if (isNOTLogic){
                        sWhere +=  '( NOT ' + String.escapeSingleQuotes(sField) + ' LIKE \'%' + String.escapeSingleQuotes(sValue) + '%\')';
                    } else {
                        sWhere +=  '(' + String.escapeSingleQuotes(sField) + ' LIKE \'%' + String.escapeSingleQuotes(sValue) + '%\')';
                    }
                } else {
                    if (isNOTLogic){
                        sWhere +=  String.escapeSingleQuotes(sField) + '!=' + sDelim + String.escapeSingleQuotes(sValue) + sDelim;
                    } else {
                        sWhere +=  String.escapeSingleQuotes(sField) + '=' + sDelim + String.escapeSingleQuotes(sValue) + sDelim;
                    }
                }
            }
        }

        // like clause
        String sSearch = '';
        Integer iSearchFields = searchFields.size();
        for(Integer iSearch = 0; iSearch < iSearchFields; ++iSearch)
        {
            if(iSearch != 0)
                sSearch += ' OR ';
            sSearch += String.escapeSingleQuotes(searchFields[iSearch]) + ' LIKE \'%' + String.escapeSingleQuotes(searchText) + '%\'';
        }
        String orderByClause = '';
        if(sSearch != '') {
            sWhere += ' AND (' + sSearch + ')';

            // order by the first search field
            orderByClause = ' ORDER BY ' + String.escapeSingleQuotes(searchFields[0]);
        }

        String dynamicSOQL = DynamicSoqlBuilder.getInstance()   
                    .showSOQLStatement(true)
                    .setEnforced(true)
                    .querySObject(String.escapeSingleQuotes(objectAPIName))
                    .queryFields(setFieldsToReturn)
                    .getQuery(sWhere);
        // limit results
        String limitClause = ' LIMIT ' + MAX_RESULTS_LIMIT;

        // final query
        String strQuery = dynamicSOQL.remove('\\') + orderByClause + limitClause;

        return strQuery;
    }

    /**
     * @description update the objects without sharing settings
     * @param objData
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> updateApplication(Application__C objData){
        Map<String,Object> objResults = new Map<String,Object>();
        try {
            //authentication for the applicant
            Application__c app = [SELECT Applicant__c FROM Application__c WHERE Id=:objData.Id AND Status__c = 'Draft'];
            if(!isRecordOwnedByTheUser(app)) {
                throw new MyAppWithoutSharingControllerException('Invalid application');
            }
            
            Database.update(objData);
            
            objResults.put('success', 'successfully update');
            Nebula.Logger.info('updateApplication msg: updated the record successfully').addTag('updateApplication');
        } catch(exception ex) {
            objResults.put('error', ex.getMessage());
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
        return objResults;
    }

    /**
     * @description function to delete the Contact Qualifications and return the steps for particular course
     *
     * @param applicationId
     * @return  List<String>
     */
    @AuraEnabled
    public static List<String> getGradResearchStepsAndDeleteContactQualification(Id applicationId) {
        String sMessage;
        String courseCode;
        List<String> stepsToReturn = new List<String>();
        List<String> cqRecordTypes = new List<String>{'Publications','Music','Creative Works','Theatre Performance', 'Exhibitions'};
        try {            
            List<Application_Course_Preference__c> acps = [SELECT Course_Code__c FROM Application_Course_Preference__c WHERE Application__c = :applicationId];
            if(!acps.isEmpty()) {
                courseCode = acps[0].Course_Code__c;
            }
            
            if(courseCode != null) {
                List<Course_Master__c> courseMaster = [SELECT Id, GradRes_Application_Requirement__c
                                                           FROM Course_Master__c
                                                           WHERE Course_Code__c =: courseCode
                                                           AND GradRes_Application_Requirement__c <> NULL];
                if(courseMaster.size() > 0) {
                    stepsToReturn = courseMaster[0].GradRes_Application_Requirement__c.split(';');
                    Set<Id> cqIdsToDelete = new Set<Id>();
                    for(Application_Qualification_Provided__c aqp : [SELECT Contact_Qualification__c, Contact_Qualification__r.RecordType.Name FROM Application_Qualification_Provided__c
                                                                    WHERE Application__c = :applicationId AND Contact_Qualification__r.RecordType.Name IN :cqRecordTypes]) {
                        if(!stepsToReturn.contains(aqp.Contact_Qualification__r.RecordType.Name)) {
                            cqIdsToDelete.add(aqp.Contact_Qualification__c);
                        }
                    }
                    if(!cqIdsToDelete.isEmpty()) {
                        delete [SELECT Id FROM Contact_Qualification__c WHERE Id IN :cqIdsToDelete];
                    }                
                }
            }

            Application__c app = [SELECT Applicant__c, Residency_Status__c, Applicant_Agent__c, Agent__c, Agent_Staff_Email__c, Agent_Staff_Details__c, Campus_Location__c FROM Application__c WHERE Id = :applicationId];
            //authentication for the applicant
            if(!isRecordOwnedByTheUser(app)) {
                throw new MyAppWithoutSharingControllerException('Invalid application');
            }            
            if(!String.isBlank(app.Residency_Status__c) && 
                    ((app.Residency_Status__c == 'INTRNTNL') || 
                    (app.Campus_Location__c == 'Malaysia' && app.Residency_Status__c != 'DOM-SUN') || 
                    (app.Campus_Location__c == 'Indonesia' && (app.Residency_Status__c != 'DOM-IDN' && app.Residency_Status__c != 'DOM-IDN-PR')) ||
                    (app.Campus_Location__c == 'Australia' && (app.Residency_Status__c == 'INTRNTNL' || app.Residency_Status__c == 'DOM-IDN' || app.Residency_Status__c == 'DOM-IDN-PR' || app.Residency_Status__c == 'DOM-SUN'))
                    )
                ){//exclude agent for malaysian and indonesian domestic application
                stepsToReturn.add('Agent');
            }
            else if(app.Applicant_Agent__c == 'Yes') {
                app.Applicant_Agent__c = '';
                app.Agent__c = null;
                app.Agent_Staff_Email__c = '';
                app.Agent_Staff_Details__c = '';
                update app;
            }
            Nebula.Logger.info('getGradResearchStepsAndDeleteContactQualification msg: returned the grad research steps successfully'+ string.join(stepsToReturn,', ')).addTag('getGradResearchStepsAndDeleteContactQualification');
        }
        catch(Exception e) {
            sMessage = 'ERROR:' + e.getMessage();
            stepsToReturn.add(sMessage);
            Nebula.Logger.error(e.getMessage(), e);
        }
        Nebula.Logger.saveLog();

        return stepsToReturn;
    }

    /**
     * @author      Vishal Gupta
     * @description method to check if the application is related to the logged in user
     * @revision    28/3/2025 - Initial Version
    */
    private static boolean isRecordOwnedByTheUser(Application__c app){
        MyAppApplicationAuthenticator checker = new MyAppApplicationAuthenticator(app);
        if (checker.isRecordRelatedToCurrentUser()) {
            return true;
        } else {
            return false;
        }
    }

    public class MyAppWithoutSharingControllerException extends Exception {}
}