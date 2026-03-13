/*******************************************************************************
* @author       Trent Delaney?
* @date         2018-08-13       
* @description  
* @revision     Trent De Laney - 18/03/2019 - Updated International mapping and formatting
*******************************************************************************/
public with sharing class Under18Controller {

    /**
    * @author Trent De Laney
    * @description Gets the application information for the component
    * @date 18 Mar 2019 at 10:39:48 am
    * @param String appId
    * @return Application__c appObject
    */
    @AuraEnabled
    public static Map<String, Object> getApplicationFields(String appId) {

        Map<String, Object> data = new Map<String, Object>();

        List<Application__c> apps =[
                SELECT a.Id, a.Guardian_Full_Name__c, a.Guardian_Relationship__c, a.Guardian_Phone_Number__c, a.Guardian_Email_Address__c, a.Applicant__r.Birthdate, a.Campus_Location__c
                FROM Application__c a
                WHERE a.Id = :appId
        ];

        if(apps.size() > 0 ){
            data.put('Application', apps[0]);
            data.put('Under18', under18(apps[0]));
            data.put('International', internationalStudent(apps[0]));
        }

        return data;
    }

    /**
    * @author Trent De Laney
    * @description Check's to see if the user is under 18 years of age.
    * @date 18 Mar 2019 at 10:40:17 am
    * @param String appId
    * @return Boolean
    */
    private static Boolean under18(Application__c app) {
        if (Math.floor(app.Applicant__r.Birthdate.daysBetween(Date.today()) / 365.2425) < 18) {
            return true;
        }
        return false;
    }

    /**
    * @author Trent De Laney
    * @description Check to see if the Student is International or not
    * @date 18 Mar 2019 at 10:42:56 am
    * @param Application__c app
    * @return Boolean
    */
    private static Boolean internationalStudent(Application__c app) {
        String type = MyApplicationUtilities.getApplicationCitizenshipType(app.Id);
        if(app.Campus_Location__c == 'Australia'){
            if (type == 'INTERNATIONAL') {
                return true;
            }else{
                return false;
            }
        }
        else if(app.Campus_Location__c == 'Malaysia'){
            return true;
        }

        return false;
    }

    /**
    * @author Trent De Laney
    * @description Saves the application back to the database
    * @date 18 Mar 2019 at 10:43:47 am
    * @param Application__c app
    */
    @AuraEnabled
    public static Application__c saveApplication(Application__c app) {
        if (app != null) {
            update app;
        }
        return app;
    }
}