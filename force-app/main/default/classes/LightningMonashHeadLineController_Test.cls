/**************************************************************************************************   
Apex Class Name      :  LightningMonashHeadLineController_Test
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is test class for LightningMonashHeadLineController.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Veera Gandi                    03/07/2017                        Created.
***************************************************************************************************/
@isTest(isParallel=true)
public class LightningMonashHeadLineController_Test {
	
	@testSetup
    public static void createData() {
        TestUtil.createCustomSettings();
    }
    
    @istest
    public static void getUserFirstName() {
        
        User sysAdmin = [select id,FirstName from User where Profile.Name ='System Administrator' and isactive=true Limit 1];
        
        system.runAs(sysAdmin) {
            String Firstname = LightningMonashHeadLineController.getUserFirstName();
			string validateFirstName = ' '+sysAdmin.FirstName;
            system.assertEquals(Firstname, validateFirstName);
        }
    }
	
	@istest
    public static void csmeathod() {
        string homepageUrl = LightningMonashHeadLineController.getHomePageUrl();
        system.assertEquals('www.homepageURL.com', homepageUrl);
    }
    
}