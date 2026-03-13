/***********************************************************************
** Author: Shalini Mendu
** Created Date: 4.SEP.2018
** Description: Apex controller parsing JSON for field labelling Formstack data
***********************************************************************/

public class FieldLabelCallOut {

    public static String getSubmissionData(String submissionId) {
        String restAPIURL = 'https://www.formstack.com/api/v2/submission/'+submissionId+'.json';

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('GET');
        httpRequest.setHeader('Authorization', 'Bearer f4bfc441eff6a655c71eb6db84aaa804');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setEndpoint(restAPIURL);

        HttpResponse res = null;
        try {
            Http http = new Http();
            if(!Test.isRunningTest())
                res = http.send(httpRequest);
            if (res!=null && res.getStatusCode() == 200) {

                System.debug('map1==' + res.getBody());

            }
        } catch (System.Exception e) {
            System.debug('ERROR: ' + e);
            throw e;
        }
        return (res!=null?res.getBody():'{"id":"437119814","form":"3185314","data":[{"id":"68587682","label":"If you are a member of any other colleges not listed above please provide the name of your college and your membership number","hide_label":"0","description":"","name":"if_you_are_a_member_of_any_other_colleges_not_listed_above_please_provide_the_name_of_your_college_and_your_membership_number","type":"text","options":"","required":"0","uniq":"0","hidden":"0","readonly":"0","colspan":"1","sort":"8","logic":null,"calculation":"","default":"","text_size":50,"maxlength":0,"placeholder":"","field_one_calculation":0,"field_two_calculation":0,"calculation_units":"","calculation_operator":"","calculation_type":"","calculation_allow_negatives":0}]}');
    }

    public static String getFormData(String formId) {
        String restAPIURL = 'https://www.formstack.com/api/v2/form/'+formId+'.json';

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('GET');
        httpRequest.setHeader('Authorization', 'Bearer f4bfc441eff6a655c71eb6db84aaa804');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setEndpoint(restAPIURL);

        HttpResponse res = null;
        try {
            Http http = new Http();
            if(!Test.isRunningTest())
                res = http.send(httpRequest);

            if (res!=null && res.getStatusCode() == 200) {
               System.debug('map2==' + res.getBody());
            }
        } catch (System.Exception e) {
            System.debug('ERROR: ' + e);
            throw e;
        }
        return (res!=null?res.getBody():'{"created":"2018-09-07 00:42:20","db":"1","deleted":"0","folder":"148353","id":"3185314","language":"en","name":"medform - Leaders","fields":[{"id":"68587674","label":"","hide_label":"0","description":"","name":"","type":"section","options":"","required":"0","uniq":"0","hidden":"0","readonly":"0","colspan":"1","sort":"0","logic":null,"calculation":"","default":"","section_break":false,"section_heading":"","section_text":"","text_editor":"wysiwyg","label_position":"default","num_columns":"1"}]}');
    }

}