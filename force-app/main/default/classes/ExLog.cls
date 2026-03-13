/**
 * @description: Class to log system exceptions.
 *               Invoke using ExLog.add(<Trigger || Class>, Object name, Function Name, exception object) 
 *               in the catch block of functions
 *               For example: ExLog.add('Trigger', 'Account', 'SomeFunction', e);
 * @revision
 *  MAR.1.2018  Nick Guia   - overloaded writeExlog to cater for Exception parameter
 *  AUG.14.2018 K Liew   	- added new method 'addIntegrationLog'
 */ 

public class ExLog {

    /**
     * @description No record ID required | directly INSERTS record
	 * @param functionName  :   Name of integration point, per configuration in custom metadata
     *        reqTS       	:   Timestamp of integration request, just before send
     *        req       	:   HTTP Request object itself
     *        headerParms   :   HTTP header parameters
     *        respTS       	:   Timestamp of integration response, just after send
     *        resp       	:   HTTP Response object itself
     *        ctx       	:   Queueable Context for Async REST
     */
    public static void addIntegrationLog(String functionName, 
                                         Datetime reqTS, 
                                         HttpRequest req, 
                                         String headerParms, 
                                         Datetime respTS, 
                                         HttpResponse resp,
                                         QueueableContext ctx) {
        try {

            Exception_Log__c exLog = new Exception_Log__c();
            String respHeader = '';

			// 2018-08-14 kliew: prefer to use getRecordTypeInfosByDeveloperName(), but seems to have a bug.
            exLog.RecordTypeId = Schema.SObjectType.Exception_Log__c.getRecordTypeInfosByName().get('Integration Log').getRecordTypeId();

            exLog.Function_Name__c = functionName;
            exLog.Request_Timestamp__c = reqTS;
            exLog.Request_Header__c = headerParms;
            exLog.Message__c = req.getBody();
            exLog.Response_Timestamp__c = respTS; 
            for (String headerKey : resp.getHeaderKeys()) {
                if (headerKey <> null) {
                    respHeader = respHeader + 'Key: ' + headerKey + ', Value: ' + resp.getHeader(headerKey) + ';';
                }
            }
            exLog.Response_Header_Parameters__c = respHeader;
            exLog.Response_Body__c = resp.getBody();
            exLog.Response_Status_Code__c = resp.getStatusCode();
            exLog.RecordId__c = ctx.getJobId();

            insert exLog;

        } catch(Exception ex) {

            throw(ex);      //ouch

        }
                                             
    }
    
    /**
     * @description No record ID required | directly INSERTS record
     * @param sourceType    :   nature of error
     *        objName       :   object name
     *        funcName      :   method name
     *        e             :   Exception object
     */
    public static void add(String sourceType, String objName, String funcName, Exception e) {
        try {
            write(sourceType, objName, funcName, e, '');
        } catch(Exception ex) {
            write('Class', 'ExLog', objName + '.' + funcName, ex, '');
        }
    }
    
    /**
     * @description This one accepts a record ID | directly INSERTS record
     * @param sourceType    :   nature of error
     *        objName       :   object name
     *        funcName      :   method name
     *        e             :   Exception object
     *        recordID      :   ID of record
     */
    public static void add(String sourceType, String objName, String funcName, Exception e, string recordID) {
        try {
            write(sourceType, objName, funcName, e, recordID);
        } catch(Exception ex) {
            write('Class', 'ExLog', objName + '.' + funcName, ex, recordID);    
        }
    }

    /**
     * @description This one accepts an error message | directly INSERTS record
     * @param sourceType    :   nature of error
     *        objName       :   object name
     *        funcName      :   method name
     *        e             :   Exception object
     *        errorMsg      :   error message in String format
     */
    public static void add(String sourceType, String objName, String funcName, String errorMsg) {
        try {
            write(sourceType, objName, funcName, errorMsg);
        } catch(Exception ex) {
            write('Class', 'ExLog', objName + '.' + funcName, errorMsg);    
        }
    }

    /**
     * @description Write the exception, accepting input from method overloading above
     * @param sourceType    :   nature of error
     *        objName       :   object name
     *        funcName      :   method name
     *        e             :   Exception object
     *        errorMsg      :   error message in String format
     */
    public static void write(String sourceType, String objName, String funcName, Exception e, string recordID) {
        try {
            Exception_Log__c exLog = new Exception_Log__c();

            exLog.Source_Type__c = sourceType;
            exLog.Object_Name__c = objName;
            exLog.Function_Name__c = funcName;
            exLog.RecordId__c = recordID;
            exLog.Exception_Type__c = e.getTypeName();
            exLog.Message__c = e.getMessage();
            exLog.Stack_Trace__c = e.getStackTraceString();
          
            insert exLog;
      
        } catch(Exception ex) {
                throw(ex);      //ouch
        }    
    }
    
    //Takes in a Database.SaveResult object.
    public static void write(String sourceType, String objName, String funcName, Database.Error e) {
        try {
            Exception_Log__c exLog = new Exception_Log__c();
          
            exLog.Source_Type__c = sourceType;
            exLog.Object_Name__c = objName;
            exLog.Function_Name__c = funcName;
            exLog.Exception_Type__c = 'DML Database Error';
            exLog.Message__c = 'Status Code: ' + e.getStatusCode() + '\nError Message: ' + e.getMessage();
            exLog.Stack_Trace__c = 'Status Code: ' + e.getStatusCode() + '\nError Message: ' + e.getMessage();
          
            insert exLog;
      
        } catch(Exception ex) {
                throw(ex);      
        }    
    }

    //Takes in a message.
    public static void write(String sourceType, String objName, String funcName, String errorMsg) {
        try {
            Exception_Log__c exLog = new Exception_Log__c();
          
            exLog.Source_Type__c = sourceType;
            exLog.Object_Name__c = objName;
            exLog.Function_Name__c = funcName;
            exLog.Exception_Type__c = 'Exception';
            exLog.Message__c = errorMsg;
            exLog.Stack_Trace__c = 'Exception';
          
            insert exLog;
      
        } catch(Exception ex) {
                throw(ex);      
        }    
    }

    /** NON-VOID METHODS | FOR BULK INSERT **/

    public static Exception_Log__c writeExlog(String sourceType, 
                                              String objName, 
                                              String funcName, 
                                              Database.Error e) 
    {
        try {
            Exception_Log__c exLog = new Exception_Log__c();
          
            exLog.Source_Type__c = sourceType;
            exLog.Object_Name__c = objName;
            exLog.Function_Name__c = funcName;
            exLog.Exception_Type__c = 'DML Database Error';
            exLog.Message__c = 'Status Code: ' + e.getStatusCode() + '\nError Message: ' + e.getMessage();
            exLog.Stack_Trace__c = 'Status Code: ' + e.getStatusCode() + '\nError Message: ' + e.getMessage();
          
            return exLog;
      
        } catch(Exception ex) {
                throw(ex);      
        }    
    }

    /**
     * @author Nick Guia
     * @description Takes in Exception object with record ID
     * @param sourceType    :   nature of error
     *        objName       :   object name
     *        funcName      :   method name
     *        recordID      :   Record ID where the exception occurred
     *        e             :   Exception object
     */
    public static Exception_Log__c writeExlog(String sourceType, 
                                              String objName, 
                                              String funcName, 
                                              String recordID,
                                              Exception e) 
    {
        try {
            Exception_Log__c exLog = createExLog(sourceType, objName, funcName, recordID);
            exLog.Exception_Type__c = e.getTypeName();
            exLog.Message__c = e.getMessage();
            exLog.Stack_Trace__c = e.getStackTraceString();
            return exLog;
      
        } catch(Exception ex) {
            throw(ex);      //ouch
        }    
    }

    /**
     * @author Nick Guia
     * @description Takes in Database.error object with record ID
     * @param sourceType    :   nature of error
     *        objName       :   object name
     *        funcName      :   method name
     *        recordID      :   Record ID where the exception occurred
     *        e             :   Exception object
     */
    public static Exception_Log__c writeExlog(String sourceType, 
                                              String objName, 
                                              String funcName, 
                                              String recordID, 
                                              Database.Error e) 
    {
        try {
            Exception_Log__c exLog = createExLog(sourceType, objName, funcName, recordID);
            exLog.Exception_Type__c = 'DML Database Error';
            exLog.Message__c = 'Status Code: ' + e.getStatusCode() + '\nError Message: ' + e.getMessage();
            exLog.Stack_Trace__c = 'Status Code: ' + e.getStatusCode() + '\nError Message: ' + e.getMessage();
            return exLog;

        } catch(Exception ex) {
            throw(ex);      //ouch
        }    
    }

    /**
     * @author Nick Guia
     * @description Takes in String error message with record ID
     * @param sourceType    :   nature of error
     *        objName       :   object name
     *        funcName      :   method name
     *        recordID      :   Record ID where the exception occurred
     *        errorMsg      :   String error message
     */
    public static Exception_Log__c writeExlog(String sourceType, 
                                              String objName, 
                                              String funcName, 
                                              String recordID,
                                              String errorMsg)
    {
        try {
            Exception_Log__c exLog = createExLog(sourceType, objName, funcName, recordID);
            exLog.Exception_Type__c = 'Custom validation';
            exLog.Message__c = errorMsg;
            return exLog;

        } catch(Exception ex) {
            throw(ex);      //ouch
        }    
    }

    private static Exception_Log__c createExLog(String sourceType, 
                                                String objName, 
                                                String funcName, 
                                                String recordID) 
    {
        return new Exception_Log__c(
                    Source_Type__c = sourceType,
                    Object_Name__c = objName,
                    Function_Name__c = funcName,
                    RecordId__c = recordID
            );
    }
}