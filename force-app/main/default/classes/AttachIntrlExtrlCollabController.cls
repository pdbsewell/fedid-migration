/**
*  @author idha0002
*  @date (13-07-2021)
*  @group Enterprise Engage
*  @description Used to validate Record Access
*  Modifications Log
*  Ver   Date         Author          Modification
*  1.0   2021-07-13 - Inderpal Dhanoa - Initial Creation
**/
public with sharing class AttachIntrlExtrlCollabController {
    /*
    * Method Name: validateAccess
     * @param  opptyId opportunity id 
     * Description: Validate Edit access
    */
    @AuraEnabled
    public static Boolean validateAccess(String opptyId) {
        Boolean editAccess = false;
        List<UserRecordAccess> l_userAccess = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId = :opptyId];
        if(!l_userAccess.isEmpty()){
            if(l_userAccess[0].HasEditAccess){
                editAccess = true;
            }
        }
        return editAccess; 
    }
}