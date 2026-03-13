/**
 * @description Exception for DocuSign Getting Signing URL.
 * Should be thrown whenever the request to DocuSign has failed
 * for example, in the case of a 400 or 500 response.
 * @group DocuSign Exceptions
 */
public class DocuSignGetSignUrlReqFailException extends Exception {

    public static String getDefaultMessage() {
        return 'DocuSign signing URL request failed';
    }
}