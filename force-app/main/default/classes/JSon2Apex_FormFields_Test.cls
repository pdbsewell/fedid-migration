/**
* @author Nadula Karunaratna
* @date 22-01-2020
* @group Professional Development
* @description Test class for JSon2Apex_FormFields
*/
@isTest(isParallel=true)
private class JSon2Apex_FormFields_Test {

    @isTest
    static void testFields(){   
        
        String respFFData = '{"created":"2018-09-07 00:42:20","db":"1","deleted":"0","folder":"148353","id":"3185314","language":"en","name":"medform - Leaders","fields":[{"id":"68587674","label":"","hide_label":"0","description":"","name":"","type":"section","options":"","required":"0","uniq":"0","hidden":"0","readonly":"0","colspan":"1","sort":"0","logic":null,"calculation":"","default":"","section_break":false,"section_heading":"","section_text":"","text_editor":"wysiwyg","label_position":"default","num_columns":"1"}]}';
        
        Test.startTest();
        JSon2Apex_FormFields obj = (JSon2Apex_FormFields)JSON.deserialize(respFFData, JSon2Apex_FormFields.class); 
        Test.stopTest();
        
        System.debug('objAbc__c=='+obj);
        System.debug('fields[0].label='+obj.fields[0].label);
        System.assertEquals('68587674',obj.fields[0].id);      

    }    
    
}