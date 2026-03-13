/**
 * @author Majid Reisi Dehkordi
 * @date 02/08/2018
 * @description this classes is used for citizenship section of the my.app
 * @revision     Stefan Scheit (2018-09-15): Changed class to with sharing
 */
public with sharing class CitizenshipController {
    private static final User currentUser = [   SELECT  contactId
                                                FROM    User
                                                WHERE   Id =: userInfo.getUserId()];
    
    /**
    * Get the type of the citizenship
    * @author Majid Reisi Dehkordi
    * @date 02/08/2018
    * @return age(String)
    */
    @AuraEnabled
    public static String retrieveApplicantCitizenship() {
        return MyApplicationUtilities.getCitizenshipTypeCodeByContactId(currentUser.contactId);
    }
}