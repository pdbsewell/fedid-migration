/**
 * @description Creates the DocuSign JWT Token based on the 
 * implementation details provided:
 * https://developers.docusign.com/esign-rest-api/guides/authentication/oauth2-jsonwebtoken
 * @group DocuSign Authorization
 */
public class CreateDocuSignJwtToken {

    @testVisible
    private String privateKey;
    
    @testVisible
    private String iss;

    @testVisible
    private String sub;

    @testVisible
    private String aud;

    @testVisible
    private String scope;

    @testVisible
    Long dateTimeJwtIssuedInUnixTime;

    public CreateDocuSignJwtToken() {
        dateTimeJwtIssuedInUnixTime = Datetime.now().getTime()/1000;    // convert to sec from ms

        DocuSignAuthProviderSetting setting  = new DocuSignAuthProviderSetting();
        privateKey = setting.getPrivateKey();
        iss = setting.getIss();
        sub = setting.getSub();
        aud = setting.getAud();
        
        // This is the only DocuSign supported scope
        scope = 'signature impersonation';
    }

    /**
     * @description Creates the JWT token that can be used to obtain 
     * an access token
     * @return Returns a JWT token
     */
    public String createToken() {
        String header = createJwtHeader();

        Long iat = dateTimeJwtIssuedInUnixTime;
        Long exp = dateTimeJwtIssuedInUnixTime + 300;

        String body = createJwtBody(this.iss, this.sub, iat, exp, this.aud, this.scope);

        String jwtToken = header + '.' + body + '.' + createJwtSignature(header, body);
        return jwtToken;
    }

    private String createJwtHeader() {
        /**
            The header is alway base64URL encoded of the follow JSON:
            {
                "typ": "JWT",
                "alg": "RS256"
            }
            To reduce processing,the hardcode string will be used as
            this header doesn't change for each token request
            If it does change, it will be due to DocuSign changing their
            JWT Token process/authentication and that would require 
            code changes anyway.
         */
        return 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9';
    }

    @testVisible
    private String createJwtBody(String iss, String sub, Long iat, Long exp, String aud, String scope) {
        /*
            SAMPLE JWT BODY FOR DOCUSIGN
            {
                "iss": "4320e42e-289a-4784-8700-6b268a61c93c",
                "aud": "account-d.docusign.com",
                "iat": 1578611141,
                "exp": 1578611441,
                "sub": "daf0b78f-8ef4-48ab-8952-f2949d1b8843",
                "scope": "signature impersonation"
            }
        */

        // Constructing a JSON from a string as it will be 
        // quicker than serialization/deserialization JSONS
        // the structure does not change

        // Also not using the Salesforce JWT class as the JWT class 
        // appears to add in extra parameters. This approach 
        // seems easier to unit test
        String jsonBody = '{"iss":"' + iss + '",'
            + '"aud":"' + aud + '",'
            + '"iat":' + String.valueOf(iat) +','
            + '"exp":' + String.valueOf(exp) +','
            + '"sub":"' + sub + '",'
            + '"scope":"' + scope + '"'
            + '}';  

        // encode in base 64
        String jwtBody = EncodingUtil.base64Encode(Blob.valueOf(jsonBody));

        // convert to base64url   
        return base64URLEncode(jwtBody);
    }

    @testVisible
    private String createJwtSignature(String base64UrlEncodedHeader, String base64UrlEncodedBody) {

        String jwtHeaderAndBody = base64UrlEncodedHeader + '.' + base64UrlEncodedBody;

        Blob signature = null;
        
        Blob privateKeyBlob = EncodingUtil.base64Decode(this.privateKey.deleteWhitespace());
        //construct the signature
        signature = Crypto.sign('RSA-SHA256', Blob.valueOf(jwtHeaderAndBody), privateKeyBlob);
        System.debug('signature: ' + signature);
        System.debug('base64URLencode(signature): ' + encodingUtil.base64Encode(signature));

        return base64URLEncode(String.valueOf(encodingUtil.base64Encode(signature)));
    }

    @testVisible
    private String base64URLEncode(String base64Input) {
        String output = base64Input;
        if (base64Input != null) {
            output = output.replace('+', '-');
            output = output.replace('/', '_');
            while ( output.endsWith('=')){
                output = output.subString(0,output.length()-1);
            }
        }    
        return output;
    }

}