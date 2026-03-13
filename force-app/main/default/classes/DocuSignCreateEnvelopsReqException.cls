/**
 * @description Exception for DocuSign Envelop creation.
 * @group DocuSign
 * @revision
 * 		2025-17-08	-	Sachin Shetty	-	Added a default method
 */
public class DocuSignCreateEnvelopsReqException extends Exception {
    public static String getDefaultMessage() {
        return 'DocuSignCreateEnvelopsReqException';
    }
}