/**
 * @description Exception for DocuSign Envelop update.
 * @group DocuSign
 * @revision
 * 		2025-17-08	-	Sachin Shetty	-	Added a default method
 */
public class DocuSignUpdateEnvelopsReqException extends Exception {
    public static String getDefaultMessage() {
        return 'DocuSignUpdateEnvelopsReqException';
    }
}