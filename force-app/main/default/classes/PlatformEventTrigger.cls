/**
 * @description       : Platform Event Trigger (framework) class.
 * @author            : Paul Victoriano
 * @group             : Common
 * @last modified on  : 2020-10-15
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.1   2020-10-15   Stefan Scheit   Corrected processing logic flaws and reduced describe() calls
 * 1.0   2020-10-15   Paul Victoriano Initial Version
**/
public class PlatformEventTrigger {
    @TestVisible // Flag whether a custom batch size should be used
    private Boolean applyBatchSize = true;
    @TestVisible // Maximum batch size of the events to be processed in one transaction (platform default is 2,000)
    private Decimal maxBatchSize {
        get {
            if (maxBatchSize != null && maxBatchSize > 0) {
                return maxBatchSize;
            } else {
                // Object needs to be a platform event
                if(strSobjectName.endsWith('__e')) {
                    // Query for batch size
                    PlatformEventControl__c eventControlSetting = PlatformEventControl__c.getInstance();
                    // Dynamic replace of Platform Event object API name (__e) to field name in custom setting (__c)
                    String strSobjectFieldName = strSobjectName.replace('__e', '__c');
                    try {
                        // Fails if field does not exist...
                        Object settingValue = eventControlSetting.get(strSobjectFieldName);
                        if(settingValue != null) {
                            maxBatchSize = (Decimal)settingValue;
                        } else {
                    		throw new PlatformEventTriggerException('Unable to read the max batch size for ' + PlatformEventControl__c.sobjectType + ' from expected field '+strSobjectFieldName);
                        }
                    } catch (Exception e) {
                        maxBatchSize = eventControlSetting.Default__c;
						logUtilityException.logException('PlatformEventTrigger', e.getStackTraceString(), new TRACELOG_Exception(e.getMessage()), 'Defaulting maximum batch size to ' + maxBatchSize, 'INFO');
                    }
                    
                } else {
                    throw new PlatformEventTriggerException('Type is not a allowed. PlatformEventTrigger can only be used with Platform Event Objects.');
                }
                return maxBatchSize;
            }
        }
        set;
    }
    @TestVisible // Event records to be processed (from trigger context)
    private List<SObject> records;
    @TestVisible // Map of trigger handlers
    private List<HandlerExtended> eventHandlerMap;
    // Name of the SobjectType of the event
    public String strSobjectName {
        get {
            if(strSobjectName==null || String.isBlank(strSobjectName)) {
                strSobjectName = records.getSObjectType().getDescribe().getName();
            }
            return strSobjectName;
        }
        set;
    } 
    /**
     * PlatformEventTrigger Private Constructor
     */
    public PlatformEventTrigger() {
        eventHandlerMap = new List<HandlerExtended>();
        // Populate records based on Trigger context (only)
        if (Trigger.isExecuting) {
            records = Trigger.new;
        }
    }
    /**
     * enablePlatformEventControl Enable Controls
     */
    public PlatformEventTrigger enablePlatformEventControl() {
        applyBatchSize = true;
        return this;
    }
    /**
     * disablePlatformEventControl Disable Control
     */
    public PlatformEventTrigger disablePlatformEventControl() {
        applyBatchSize = false;
        return this;
    }
    /**
     * Registers Handler class (by name) implementing PlatformEventTrigger.HandlerExtended
     * @param strClassName Name of the class
     * TODO: remove to return this (it should be a void method...)
     */
    public PlatformEventTrigger registerHandler(String strClassName) {
        LogUtilityException.debug('TriggerCommon - register with class name: '+strClassName);
        if(String.isNotBlank(strClassName)) {
            try {
                Type customType = Type.forName(strClassName);
                registerHandler(customType);
            } catch(Exception e) {
                LogUtilityException.logException(e, 'PlatformEventTrigger');
            }
        }
        return this;
    }
    /**
     * Registers Handler class (by type/class to avoid reflection at run-time) implementing PlatformEventTrigger.HandlerExtended
     * @param classType Type of the class
     * TODO: remove to return this (it should be a void method...)
     */
    public PlatformEventTrigger registerHandler(Type classType) {
        LogUtilityException.debug('TriggerCommon - register with type: '+classType.getName());
        if(null != classType) {
            try {
                HandlerExtended handlerInstance = (HandlerExtended)classType.newInstance();
                if(handlerInstance != null) {
                    eventHandlerMap.add(handlerInstance);
                }
            } catch(Exception e) {
                LogUtilityException.logException(e, 'PlatformEventTrigger');
            }
        }
        return this;
    }

    /**
     * Executes the processing of (event) records with the max batch size.
     * There is no re-try and errors are to be handled in the specific event handler by e.g. re-queuing events if required.
     */
    public void run() {
        // check if the trigger handler should execute
        if (TriggerCommon.doNotRunTrigger(strSobjectName)) {
            return;
        }
        // run trigger handlers
        if(records != null && !records.isEmpty()) {
            if(eventHandlerMap != null && !eventHandlerMap.isEmpty()) {
                // Counter tracking events against batch size
                Integer recordCounter = 0;
                // Latest event's replayId
                String strReplayId;
                // Process all records
                for (SObject record : records) {
                    // Stop processing events when the desired batch size is reached, if that's enabled
                    recordCounter++;
                    if(recordCounter > maxBatchSize && applyBatchSize == true) {
                        break;
                    }
                    // Invoke handlers' process() method, try/catch to identify faulty handlers from others
                    for(HandlerExtended handler : eventHandlerMap) {
                        try {
                            handler.process(record);
                        } catch (Exception e) {
                            LogUtilityException.logException(e, 'PlatformEventTrigger invoking process() method of handler: '+String.valueOf(handler));
                            throw e;
                        }
                    }
                    // Set the resume point (mark current event as processed)
                    strReplayId = (String)record.get('replayId');
                    EventBus.TriggerContext.currentContext().setResumeCheckpoint(strReplayId);
                }
                // Invoke handlers' execute() method, try/catch to identify faulty handlers from others
                for(HandlerExtended handler : eventHandlerMap) {
                    try {
                        handler.execute();
                    } catch (Exception e) {
                        LogUtilityException.logException(e, 'PlatformEventTrigger invoking exectue() method of handler: '+String.valueOf(handler));
                        throw e;
                    }
                }
            }
        }
    }
    /**
     * Interface for Extended Handler
     */
    public interface HandlerExtended {
        void process(SObject rec);
        void execute();
    }
    /**
     * Custom Exception
     */
    public class PlatformEventTriggerException extends Exception {}

    public class TRACELOG_Exception extends Exception {
        public override string getStackTraceString(){
            return '';
        }
    }  
}