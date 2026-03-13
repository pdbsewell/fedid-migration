@RestResource(urlMapping='/PAG/persona-state')
global with sharing class PAG_PersonaIngestApi {
    @HttpPost
    global static String post(){
        RestRequest req = RestContext.request;
        String body = (req != null && req.requestBody != null) ? req.requestBody.toString() : null;
        try {
            PAG_PersonaService.Result r = PAG_PersonaService.ingest(body);
            RestContext.response.addHeader('Content-Type', 'application/json');
            return JSON.serialize(r);
        } catch (PAG_Errors.ValidationException ve) {
            RestContext.response.statusCode = 400;
            RestContext.response.addHeader('Content-Type', 'application/json');
            return PAG_Errors.toJson('bad_request', ve.getMessage());
        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            RestContext.response.addHeader('Content-Type', 'application/json');
            return PAG_Errors.toJson('internal_error', 'Unexpected error');
        }
    }
}