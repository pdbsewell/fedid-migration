/**
 * @author          Tom Gangemi
 * @description    	Controller for Email to PDF LWC component
 * @revision        2022-10-12 - Tom Gangemi - SA-1878 Initial version
 */

@isTest
public with sharing class EmailToPdfController_Test {

    public class PdfGenHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Assert.areEqual('POST', req.getMethod());
            // ensure request is expected JSON
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(req.getBody());
            Assert.isTrue(m.containsKey('html'));
            HttpResponse res = new HttpResponse();
            // reflect body back to caller
            res.setBody(req.getBody());
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    public static void testGetPdf() {
        EmailMessage em = new EmailMessage(
            Subject = 'Test Subject',
            HtmlBody = '<body><p>Hello HTML</p></body>',
            ToAddress = 'reciever@example.com',
            FromAddress = 'sender@example.com'
        );
        insert em;
        Test.setMock(HttpCalloutMock.class, new PdfGenHttpCalloutMock());

        Test.startTest();
        String resultBase64 = EmailToPdfController.getEmailAsBase64PdfBlob(em.Id);
        Test.stopTest();

        Blob resultBlob = EncodingUtil.base64Decode(resultBase64);
        // Ensure correct json response and html injected correctly
        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(resultBlob.toString());
        Assert.isTrue(m.containsKey('html'), String.valueOf(m.keySet()));
        String resultHtml = (String)m.get('html');
        Assert.isTrue(resultHtml.endsWith('</table><hr><p>Hello HTML</p></body>'), resultHtml);
    }

    @isTest
    public static void testInjection() {
        String bodyFull = '<html><body><p>Hello HTML</p></body></html>';
        String bodyFullParams = '<html><body style="font-family: sans-serif"><p>Hello HTML</p></body></html>';
        String bodyFullLineBreak = '<html><body \n style="font-family: sans-serif"><p>Hello HTML</p></body></html>';
        String bodyNoHtml = '<p>Hello HTML</p><h1>Other Stuff</h1>';

        String injection = '##!!##';
        String result1 = EmailToPdfController.injectStringAfterBodyTag(bodyFull, injection);
        Assert.isTrue(result1.contains('<body>' + injection), bodyFull);

        String result2 = EmailToPdfController.injectStringAfterBodyTag(bodyFullParams, injection);
        Assert.isTrue(result2.contains('<body style="font-family: sans-serif">' + injection), bodyFullParams);

        String result3 = EmailToPdfController.injectStringAfterBodyTag(bodyFullLineBreak, injection);
        Assert.isTrue(result3.contains('<body \n style="font-family: sans-serif">' + injection), bodyFullLineBreak);

        String result4 = EmailToPdfController.injectStringAfterBodyTag(bodyNoHtml, injection);
        Assert.isTrue(result4.startsWith(injection), bodyNoHtml);
    }

}