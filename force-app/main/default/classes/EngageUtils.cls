/**
 * Utility class providing general util methods to the rest of the ERDA codebase.
 * 
 * @author Mark Johnson UC Innovation
 * 
 */
public class EngageUtils {

    public static Boolean ReviewTransactionHandlerIsRunning = true;		//For handling when review transaction handler is running
    public static Boolean HardSoftTriggerIsRunning = false;				//For handling when HSC trigger is running
    public static Boolean Payment_CreateMatchingGift_WantRun = true;	//For handling if matching gift trigger should run

	/*******************************************************************************
	* @description  UTIL function to get record type ID by developername
	* @param        sObj - sObj that contains record types.
	*               developerName - Developer Name of record type to get ID
	*******************************************************************************/
	public static Id getRecordTypeIDByDeveloperName(SObject sObj, String developerName) {

		Map<String, Schema.RecordTypeInfo> recordTypeMap = sObj.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName();

		Schema.RecordTypeInfo recordTypeInfo = recordTypeMap.get(developerName);

		if (recordTypeInfo == null) {
			return null;
		}

		return recordTypeInfo.getRecordTypeId();
	}
}