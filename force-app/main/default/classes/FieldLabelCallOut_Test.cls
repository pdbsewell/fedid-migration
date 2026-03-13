/**
* @author Nadula Karunaratna
* @date 22-01-2020
* @group Professional Development
* @description Test class for FieldLabelCallOut
*/
@isTest(isParallel=true)
private class FieldLabelCallOut_Test {
	@isTest
    static void testGetSubmissionData(){
        String testsubmissionId = 'test'; 
        
        Test.startTest();
        String respData = FieldLabelCallOut.getSubmissionData(testsubmissionId); 
        Test.stopTest();
        
        JSONParser parser = JSON.createParser(respData);
		while (parser.nextToken() != null) {
            if(parser.getText() == 'form'){
                parser.nextToken();
				System.assertEquals('3185314',parser.getText()); 
            }
        }
        
    }

	@isTest
    static void testGetFormData(){
        String testformId = 'test';
        
        Test.startTest();
        String respFFData = FieldLabelCallOut.getFormData(testformId);
        Test.stopTest();
        
        JSONParser parser = JSON.createParser(respFFData);
		while (parser.nextToken() != null) {
            if(parser.getText() == 'folder'){
                parser.nextToken();
				System.assertEquals('148353',parser.getText()); 
            }
        }        
    }    
    
}