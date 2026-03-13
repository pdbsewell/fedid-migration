/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@IsTest
global with sharing class SiteLoginController_Test {
    @IsTest
    global static void testSiteLoginController() {
        // Instantiate a new controller with all parameters in the page.
        SiteLoginController controller = new SiteLoginController();
        controller.username = 'test@salesforce.com';
        controller.password = '123456'; 
                
        System.assertEquals(controller.login(), null);                           
    }    
}