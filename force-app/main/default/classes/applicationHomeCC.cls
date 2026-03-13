/*******************************************************************************
* @author       Ryan Wilson
* @date         31.Mar.2017         
* @description  controller class for communities application home page
* @revision     Stefan Scheit (2018-09-15): Changed class to with sharing
*******************************************************************************/
public with sharing class applicationHomeCC {
    public Contact contactRecord { get; set; }
    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         31.Mar.2017         
    * @description  initialise values
    * @revision     
    *******************************************************************************/
    public applicationHomeCC() {
        User currentUser = [SELECT ContactId
                            FROM User
                            WHERE Id = :userInfo.getUserId()];
        if (currentUser.ContactId != null) {
            contactRecord = [SELECT Id, Birthdate
                             FROM Contact
                             WHERE Id = :currentUser.ContactId];
        }
    }

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         31.Mar.2017         
    * @description  determine whether to put the user on the update details page or to
						the application home
    * @revision     
    *******************************************************************************/
    public PageReference redirectToCorrectPage() {
        PageReference redirect = new PageReference('/s/');

        if (contactRecord.Birthdate == null) {
            redirect = new PageReference('/s/my-details');
        }
        return redirect;
    }
}