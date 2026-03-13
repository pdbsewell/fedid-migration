/**
 * @author Nadula Karunaratna
 * @date 07-08-2018
 * @group Professional Development
 * @description Controller class for the visualforce components FacultyCustomData*
 * @revision: Nadula Karunaratna | 14-01-2020 | Added class header comments
*/

global class FacultyCustomDataController {
    
	public String facultyName {get;set;}
	public Faculty_Custom_Data__mdt facultyCustomData {get;set;}

	public Faculty_Custom_Data__mdt getFacultyData()
	{
	    System.debug('FacultyCustomDataController:facultyName ==='+facultyName);

	    if(facultyName != null){
	    facultyCustomData = [SELECT Faculty_Email__c,Faculty_Website_Label__c,Faculty_Website_URL__c,Managing_Faculty__c,Faculty_Phone__c,Faculty_Phone_Label__c,Terms_and_Conditions_URL__c  FROM Faculty_Custom_Data__mdt WHERE Managing_Faculty__c =: facultyName][0];
			return facultyCustomData;
		} else {
			return null;
		}

	}
}