@IsTest
global class StudFirst_MockHttpResponseError implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        String endPoint = req.getEndpoint();

        if(endPoint.contains('/la/admissions/v1/applications') && req.getMethod() == 'POST') {
            res.setBody('{"applications":[{"success":true,"isNewApplicant":true,"externalApplicantId":"0030k000001tbfEAAQ","smsApplicantId":"809580","smsApplications":[{"applicationId":682348,"updatedDate":"2017-05-04T23:55:08+0000","isNewApplication":true,"coursePreferences":[{"transferStatus":"PENDING","preferenceNumber":1,"sequenceNumber":1,"courseCode":"4102","courseVersionNumber":1,"locationCode":"CLAYTON","attendanceMode":"IN","attendanceType":"FT","academicCiSequenceNumber":7717,"admissionCalendarType":"ADM-2","admissionCiSequenceNumber":7736,"typeOfPlaceCode":null}]}],"info":["New Applicant ID 809580 created for Agent Applicant ID 0030k000001tbfEAAQ.","Preference 1 for application 123 has been successfully loaded into Applicant Portal.","No document has been inserted as no information has been provided.","Applicant Application data has been inserted, even though error(s) did occur. The data that caused the error has been ignored or the error has been ignored."],"errors":[]}]}');
            res.setStatusCode(500);
            res.setStatus('OK');
        }
        return res;
    }
}