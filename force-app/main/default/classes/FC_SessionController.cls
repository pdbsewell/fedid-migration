/**
 * @description       : Class containing the logic for Session Extension
 * @author            : Inderpal Dhanoa/Seeva Singh
 * @group             : Monash Connect
 * @last modified on  : 2023-04-12
 * @last modified by  : Inderpal Dhanoa/Seeva Singh
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   2021-05-05 - Inderpal Dhanoa/Seeva Singh - Initial Creation
**/
public with sharing class FC_SessionController {
    /*******************************************************************************
	* @author Inderpal Dhanoa/Seeva Singh
	* @date 2023-04-12
	* @description  retrieves SessionStatus.
	* @revision 2023-04-12 - Created
	* @return SessionStatus - SessionStatus Wrapper
	*******************************************************************************/
    @AuraEnabled
    public static Boolean getUserStatus() {
        List<PermissionSetAssignment> l_permAssignmnts = [SELECT Id 
														  FROM PermissionSetAssignment
                                                          WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = :Label.Extend_Session];
        if(!l_permAssignmnts.isEmpty()){
            return true;
        }else{
            return false;
        }
    }
    /*******************************************************************************
	* @author Inderpal Dhanoa/Seeva Singh
	* @date 2023-04-12
	* @description  retrieves SessionStatus.
	* @revision 2023-04-12 - Created
	* @return SessionStatus - SessionStatus Wrapper
	*******************************************************************************/
    @AuraEnabled
    public static SessionStatus getSessionStatus() {
        try{
            SessionStatus status = new SessionStatus();
            // Currently set to 610 seconds/10 mins 
            if (getSessionSecondsRemaining() < Integer.ValueOf(Label.Session_Pending_Interval) && isBusinessHours()) { 
                status.inactiveForOneHour = true;
            } else {
                status.inactiveForOneHour = false;
            }      
            return status;
        }catch(Exception ex){
            LogUtilityException.logException(ex);throw ex;
        }
        
    }
    
    /*******************************************************************************
	* @author Inderpal Dhanoa/Seeva Singh
	* @date 2023-04-12
	* @description  retrieves Business Hours.
	* @revision 2023-04-12 - Created
	* @return Boolean - Flag to check Hours
	*******************************************************************************/
    public static Boolean isBusinessHours() {
        // Check if it's currently business hours
        
        // Get the current time in the user's timezone
        Datetime currentTime   = datetime.newInstance(Date.today(), Datetime.now().time());
        
        // Get the business hours for the organization
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
        
        // Check if the current time is within business hours
        Boolean isWithinBusinessHours = BusinessHours.isWithin(bh.id, currentTime);
		return isWithinBusinessHours;
    }

    /*******************************************************************************
	* @author Inderpal Dhanoa/Seeva Singh
	* @date 2023-04-12
	* @description  get Session Seconds Remaining.
	* @revision 2023-04-12 - Created
	* @return remainingTime - Variable to return remainng time
	*******************************************************************************/
    public static Long getSessionSecondsRemaining() {
        // Check how many seconds remaining
		if(test.isRunningTest()) return 200;
        AuthSession authSession = [SELECT NumSecondsValid, LastModifieddate , Sessiontype, CreatedDate FROM Authsession WHERE UsersId = :UserInfo.getUserId() AND IsCurrent = true AND sessiontype='Aura' ORDER BY LastModifieddate DESC LIMIT 1];
		// Calculate the remaining time in seconds
		Long remainingTime = authSession.NumSecondsValid - (Datetime.now().getTime() - authSession.CreatedDate.getTime()) / 1000;
        return remainingTime;
    }
    
    /*******************************************************************************
	* @author Inderpal Dhanoa/Seeva Singh
	* @date 2023-04-12
	* @description  retrieves session Status.
	* @revision 2023-04-12- Created
	* @return sessionStatus - Wrapper class
	*******************************************************************************/
    public class sessionStatus{
        @AuraEnabled 
        public Boolean inactiveForOneHour;
    }
}