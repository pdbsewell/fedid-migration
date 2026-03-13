/**
* @author Nadula Karunaratna
* @date 22-01-2020
* @group Professional Development
* @description Test class for JSON2Apex_Submission
*/
@isTest(isParallel=true)
private class JSON2Apex_Submission_Test {
    
    @isTest
    static void testGetFieldIDValueMap(){   

		//Setup test data
        String respData = '{"id": "437119814","timestamp": "2018-09-07 15:25:06","user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36","remote_addr": "130.194.84.131","payment_status": "","form": "3185314","latitude": "-37.916698455811","longitude": "145.11669921875","data": [{"field": "68587676","value": "a205D0000005Uak"},{"field": "68587679","value": "text1"},{"field": "68587680","value": "RAGCP NUMBER"}]}';   
                               
        JSON2Apex_Submission subObj = (JSON2Apex_Submission)JSON.deserialize(respData, JSON2Apex_Submission.class);
              
        Test.startTest();
        Map<String, String> fldIDValMap = subObj.getFieldIDValueMap(); 
        Test.stopTest();
		
        System.debug('fldIDValMap.get(68587676)='+fldIDValMap.get('68587676'));
        System.assertEquals('a205D0000005Uak',fldIDValMap.get('68587676'));

    }
    
    @isTest
    static void testGetFormId(){
        String respData = '{"id":"437119814","form":"3185314","data":[{"id":"68587682","label":"If you are a member of any other colleges not listed above please provide the name of your college and your membership number","hide_label":"0","description":"","name":"if_you_are_a_member_of_any_other_colleges_not_listed_above_please_provide_the_name_of_your_college_and_your_membership_number","type":"text","options":"","required":"0","uniq":"0","hidden":"0","readonly":"0","colspan":"1","sort":"8","logic":null,"calculation":"","default":"","text_size":50,"maxlength":0,"placeholder":"","field_one_calculation":0,"field_two_calculation":0,"calculation_units":"","calculation_operator":"","calculation_type":"","calculation_allow_negatives":0}]}';
        JSON2Apex_Submission subObj = (JSON2Apex_Submission)JSON.deserialize(respData, JSON2Apex_Submission.class);
        
        Test.startTest();
        String formId = subObj.getFormId();
        Test.stopTest();
        
        System.debug('formId='+formId);
        System.assertEquals('3185314',formId);          
    }

}