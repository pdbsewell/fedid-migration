/**
 * @author          Tom Gangemi
 * @description    	Controller for Email to PDF LWC component
 * @revision        2022-10-12 - Tom Gangemi - SA-1878 Initial version
 */

public with sharing class EmailToPdfController {

    /**
     * Inject a string into the body of an HTML document
     * @param htmlBody string to inject into
     * @param stringToInject string to inject into htmlBody
     */
    public static String injectStringAfterBodyTag(String htmlBody, String stringToInject) {
        Pattern bodyPattern = Pattern.compile('(?s)(<body.*?>)');

        // Create a Matcher object to find matches of the pattern in the input string
        Matcher bodyMatcher = bodyPattern.matcher(htmlBody);

        // Check if the Matcher found a match
        if (bodyMatcher.find()) {
            // Replace the matched pattern with the pattern followed by the string you want to inject
            String modifiedInput = bodyMatcher.replaceAll('$1' + stringToInject);
            return modifiedInput;
        } else {
            // If no match was found, prepend the stringToInject to the input string
            return stringToInject + htmlBody;
        }
    }

    /**
     * Generate a 2 column (label, value) table row with inline styling
     */
    private static String createHeaderTableRow(String label, String value) {
        String html = '<tr style="height: 18px;"><td style="width: 70px; text-align: right; padding-right:10px"><strong>';
        html += label + '</strong></td><td>' + value + '</td></tr>';
        return html;
    }

    /**
     * For a given EmailMessage, create a printable HTML string and
     * send it to an external service which returns a PDF as a blob.
     *
     * @return PDF as Base64 encoded blob
     */
    @AuraEnabled(Cacheable=true)
    public static String getEmailAsBase64PdfBlob(Id emailMessageId) {
        EmailMessage em = [
            SELECT HtmlBody, Subject, ToAddress, FromAddress, CcAddress, BccAddress, CreatedDate
            FROM EmailMessage WHERE Id = :emailMessageId
        ];

        // add header to email HTML
        String infoTableHtml = '<table style="border-collapse:collapse; border:none; width:100%; font-family:arial"><tbody>';
        infoTableHtml += createHeaderTableRow('From', em.FromAddress);
        infoTableHtml += createHeaderTableRow('To', em.ToAddress);
        if(String.isNotBlank(em.CcAddress)) {
            infoTableHtml += createHeaderTableRow('CC', em.CcAddress);
        }
        if(String.isNotBlank(em.BccAddress)) {
            infoTableHtml += createHeaderTableRow('BCC', em.BccAddress);
        }
        infoTableHtml += createHeaderTableRow('Subject', em.Subject);
        infoTableHtml += createHeaderTableRow('Date', em.CreatedDate.format('yyyy-MM-dd HH:mm'));
        infoTableHtml += '</tbody></table><hr>';

        // setup request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GCP_PDF_Generator');
        req.setHeader('X-Access-Token', '{!$Credential.Password}');
        req.setMethod('POST');
        req.setBody(JSON.serialize(new Map<String,String>{
            'html' => injectStringAfterBodyTag(em.HtmlBody, infoTableHtml)
        }));

        // send request
        Http h = new Http();
        HttpResponse res = h.send(req);

        // encode and return
        return EncodingUtil.base64Encode(res.getBodyAsBlob());
    }

}