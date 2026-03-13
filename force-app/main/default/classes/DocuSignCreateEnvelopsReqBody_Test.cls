/**
 * @description Test class for DocuSignCreateEnvelopsReqBody
 */
@isTest(isParallel=true)
public class DocuSignCreateEnvelopsReqBody_Test {

    @isTest
    static void shouldDeserializeValidRequest() {
        
        String jsonString = '{"emailSubject":"subject"}';

        DocuSignCreateEnvelopsReqBody reqBody = 
            new DocuSignCreateEnvelopsReqBody();
        DocuSignCreateEnvelopsReqBody deserializedBody = reqBody.deserialize(jsonString);
        
        System.assertEquals('subject', deserializedBody.emailSubject, 
            'Expected email subject to be set');

    }

}