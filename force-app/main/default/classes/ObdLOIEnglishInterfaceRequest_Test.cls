/*******************************************************************************
* @author:      Shalini Mendu
* @date:        12 Feb.2020
* @description: Test class for ObdLOIEnglishInterfaceRequest
* @revision: 
*******************************************************************************/
@isTest
public  class ObdLOIEnglishInterfaceRequest_Test {
    @IsTest
        static void test_AssignEnglishTestScorePropertyValues() {
            ObdLOIEnglishInterfaceRequest request = new ObdLOIEnglishInterfaceRequest();
            System.assert(request != null, 'Unable to create the ObdLOIEnglishInterfaceRequest Request');
    
            request.resultType = 'TestResult Type';
            request.verificationStatus = 'UNKNOWN';
            request.completed = true;
            request.testType = 'Online';
            request.type = 'testScore';
    
            ObdLOIEnglishInterfaceRequest.coursePreferences coursePreference = new ObdLOIEnglishInterfaceRequest.coursePreferences();
            System.assert(coursePreference != null, 'Unable to create the ObdLOIEnglishInterfaceRequest.coursePreferences');
            coursePreference.type = 'Test Course';
            coursePreference.courseCode = 'Test CourseCode';
            coursePreference.admissionApplNumber = 12345;
    
             
            ObdLOIEnglishInterfaceRequest.subscores subscores = new ObdLOIEnglishInterfaceRequest.subscores();
            System.assert(subscores != null, 'Unable to create the EnglishTestScoreRequest.subscores');
            subscores.type = 'Test SubScore Type';
            subscores.score = 'Test Score';
            subscores.scoreType = 'English';
            
            List<ObdLOIEnglishInterfaceRequest.subscores> subscolist = new  List<ObdLOIEnglishInterfaceRequest.subscores>{subscores};
             request.subscores = subscolist;

             ObdLOIEnglishInterfaceRequest.applications applications = new ObdLOIEnglishInterfaceRequest.applications();
             System.assert(applications != null, 'Unable to create the ObdLOIEnglishInterfaceRequest.applications');
             applications.type = 'INT';
             List<ObdLOIEnglishInterfaceRequest.coursePreferences> ac = new list<ObdLOIEnglishInterfaceRequest.coursePreferences>{coursePreference};
             applications.coursePreferences = ac;
              System.assert(applications.coursePreferences != null, 'No Course Preferences Found For EnglishTestScore');
        
           
    
        }
    
}