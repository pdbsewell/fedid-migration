/**
@author Cartick Sub
@date 18 August 2020
@group Student Letters
@description Makes callouts to Student Letters API or Salesforce to retrieve student letter entitlements, 
Student Letter Logs, generate letters and so on
@revision Initial version 18 August 2020
          Cartick Sub - 1 October 2020 - Add method to retrieve Student Letter Logs from Salesforce
**/

public class StudentLettersHelper {

    /**
    @description Retrieves from the Student Letters API the letter entitlements for a student
    @param studentNumber The student number as stored in the Person Id field on the student Contact record
    @return the HTTP response String, if the request was successful; otherwise, undefined
    **/
    @AuraEnabled
    public static String getEntitlementsFromAPI(String studentNumber) {
        
        HTTP http = new HTTP();
        HTTPRequest request = new HTTPRequest();
        request.setEndpoint('callout:Student_Letters/' + studentNumber + '/letters/entitlements');
        request.setTimeout(1000 * 30);
        request.setMethod('GET');

        String strResponse = 'undefined';
        try {
            HTTPResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                strResponse = response.getBody();
            }
            return strResponse;
        } catch(Exception e) {
            LogUtilityException.logException(e);
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('An error has occurred. Please contact your administrator for assistance.');
        }
    }

    /**
    @description Retrieves from the Salesforce database the Student Letter Logs for a student
    @param contactId The Salesforce Id of the student's Salesforce Contact record
    @return a list of the Student Letter Logs found
    **/
    @AuraEnabled(cacheable=true)
    public static List<Student_Letter_Log__c> getStudentLetterLogsFromSF(String contactId) {
        List<Student_Letter_Log__c> listResults = new List<Student_Letter_Log__c>();
        listResults = [SELECT
            Id,
            Name,
            CreatedDate,
            Channel__c,
            toLabel(Letter_Description__c),
            Course_Title__c,
            Message__c,
            Payment_Method__c,
            Letter_Status__c
            FROM Student_Letter_Log__c
            WHERE Contact__c = :contactId
            ORDER BY CreatedDate DESC
        ];
        return listResults;
    }
}