/**
 * @dsecription Test class for CreateDocuSignJwtToken
 */
@isTest(isParallel=true)
public class CreateDocuSignJwtToken_Test {

    private static final String PRIVATE_KEY = 'MIIEowIBAAKCAQEAwUXz2Y7/alHCSGpag4g4/8zhIGjiIJFPZo8cggQWDoIq/jg8bGAX40+02etOLrDE0pNSernotAVzcP0CtRNL5SCtuMhm2hkG7RJarnx6ds3g/KTqRkAhv5lNPuW+D5GFFKI0B9f6CL8+SWbLD4C/Set8kaoOVVlkUhCA3tUMgxNLuyLhJAtOhCNE3dOz07MAgjhzu0ZfpJ3iMe8HKtdIuATPhhYadJrlC07a/fIa+O67SKjpI8RnryyPW7AydFUbbXxYHGvWFf59mpNAX7FjSS0fA7R9Gcyd2ZnLfVSc7JCOZcuDCjO6DIypckFS7ZfinpmJE6rTGF9jtE1DCmnolwIDAQABAoIBAAJbNvjdDHIgYwz89vOJkqBTwB7kCHW7L8uhTQiswhQVNC77QolTtpbX3u2VN9PL5epnT2cdox+mvVyQSRsqDA/UESoij1ZzXalAQwjDjb6rDeYmoJCQsZijZtSwelu4O3Yf8CB0WqEGq9y7OxiKSkq9azxfZWNW/qkdeGS/FjL24NWxK+4zbHNvacHuWhUwB8dfWB7/OwDy0fcXsSn2E3lwJbnQ23CfYWKi4LLZ6rtU2/JgXNuku3e4zNPudNOAq4nWV/GR5b5/gn/M6DvJ5XUxGwNfH/bE2vsN4euOgWCPhjh40LfVmIP7KVcwRECD1IlV/RhG7owYk6yvnSFq6MkCgYEA4yLTpaSsKQ2X+IEs2Mjv+PhxPv9jJJxAksmIor9+fOwKguqIW3FJiuIjBodtD4nygXFEXfkXc9J6HtP6dS/Yq74EE5nDK6L//svoPFw/5W82TzsQAsfoijPnh0NuFk8sRzmFZ5qmudtLi6RQS/wHA0vPPHOQCaGgHOkHXPqMA8MCgYEA2dWBA/LsO++y91hzlk2wdPxxLjdzFxcoyso7YF1+JLQRos6hh24RlwgV73akk9g1KwcIg3mgGdggKSqz5QKlHS4Q2TQ2LqXbQIzbEJtFhI01OVzxljqPQDY9piDF3b4ap+9i4eA7L79LlimzsIFmPhvVYBWu3kftzuFJzWGOXp0CgYARX7eawwbcOQr32kGo723TuIVJEVXvFfimgb3u3QD64z9GllQJ0peShQuy0ycXejDPj+9v1L7jgCUROJu+3QMQ1/8N1MQmEVjNj6FbBJ9qmGAqHVVzMQFrmN7L7O99y16SsCaxLxYzvz9/FfmCZmvO57yZXimVYwSRUY3bodqV6wKBgECdhFeXh1uADqYwJpk/EkihWTFMYWdIB2Gf+1zqXrCkeVbB1EhH7g/O5jLSDp+MUrkgrPXS7hq8cU3EzPfxgOjW8Uh8pFXR/Od44MJcTJK1EESjvUXCuRti+4Z70jWkXmPSLpKx4NyY8eLpG9QPjjR+LR0DUYu96lyjlzDE72ZBAoGBANEdaGB5n0I4TEmUGQGGwZ6pkKBQTvZ/NzoG7hZbNnmzjG6Uoz9G/MCxrA1DRbHYrEYmFNtZdQ2tojb7/Ls3iH3T55k18QQOH0tFQZlXAEcNzIRlpIyDZtvVMgS4DkuqDpBsg7sIjDIEAidQbI86ldo1G0nu6BMYh1HDcYbPbUYE';

    @isTest
    static void shouldCreateJwtTokenCorrectly() {

        /**
        ========================
        TEST DATA
        ========================

        Decoded JWT:
        Header:
        {"typ": "JWT","alg": "RS256"}

        Payload/Body:
        {
            "iss": "4320e42e-289a-4784-8700-6b268a61c93c",
            "aud": "account-d.docusign.com",
            "iat": 1578611141,
            "exp": 1578611441,
            "sub": "daf0b78f-8ef4-48ab-8952-f2949d1b8843",
            "scope": "signature impersonation"
        }

        Public Key:
        -----BEGIN PUBLIC KEY-----
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwUXz2Y7/alHCSGpag4g4
        /8zhIGjiIJFPZo8cggQWDoIq/jg8bGAX40+02etOLrDE0pNSernotAVzcP0CtRNL
        5SCtuMhm2hkG7RJarnx6ds3g/KTqRkAhv5lNPuW+D5GFFKI0B9f6CL8+SWbLD4C/
        Set8kaoOVVlkUhCA3tUMgxNLuyLhJAtOhCNE3dOz07MAgjhzu0ZfpJ3iMe8HKtdI
        uATPhhYadJrlC07a/fIa+O67SKjpI8RnryyPW7AydFUbbXxYHGvWFf59mpNAX7Fj
        SS0fA7R9Gcyd2ZnLfVSc7JCOZcuDCjO6DIypckFS7ZfinpmJE6rTGF9jtE1DCmno
        lwIDAQAB
        -----END PUBLIC KEY-----

        Private Key:
        -----BEGIN RSA PRIVATE KEY-----
        MIIEowIBAAKCAQEAwUXz2Y7/alHCSGpag4g4/8zhIGjiIJFPZo8cggQWDoIq/jg8
        bGAX40+02etOLrDE0pNSernotAVzcP0CtRNL5SCtuMhm2hkG7RJarnx6ds3g/KTq
        RkAhv5lNPuW+D5GFFKI0B9f6CL8+SWbLD4C/Set8kaoOVVlkUhCA3tUMgxNLuyLh
        JAtOhCNE3dOz07MAgjhzu0ZfpJ3iMe8HKtdIuATPhhYadJrlC07a/fIa+O67SKjp
        I8RnryyPW7AydFUbbXxYHGvWFf59mpNAX7FjSS0fA7R9Gcyd2ZnLfVSc7JCOZcuD
        CjO6DIypckFS7ZfinpmJE6rTGF9jtE1DCmnolwIDAQABAoIBAAJbNvjdDHIgYwz8
        9vOJkqBTwB7kCHW7L8uhTQiswhQVNC77QolTtpbX3u2VN9PL5epnT2cdox+mvVyQ
        SRsqDA/UESoij1ZzXalAQwjDjb6rDeYmoJCQsZijZtSwelu4O3Yf8CB0WqEGq9y7
        OxiKSkq9azxfZWNW/qkdeGS/FjL24NWxK+4zbHNvacHuWhUwB8dfWB7/OwDy0fcX
        sSn2E3lwJbnQ23CfYWKi4LLZ6rtU2/JgXNuku3e4zNPudNOAq4nWV/GR5b5/gn/M
        6DvJ5XUxGwNfH/bE2vsN4euOgWCPhjh40LfVmIP7KVcwRECD1IlV/RhG7owYk6yv
        nSFq6MkCgYEA4yLTpaSsKQ2X+IEs2Mjv+PhxPv9jJJxAksmIor9+fOwKguqIW3FJ
        iuIjBodtD4nygXFEXfkXc9J6HtP6dS/Yq74EE5nDK6L//svoPFw/5W82TzsQAsfo
        ijPnh0NuFk8sRzmFZ5qmudtLi6RQS/wHA0vPPHOQCaGgHOkHXPqMA8MCgYEA2dWB
        A/LsO++y91hzlk2wdPxxLjdzFxcoyso7YF1+JLQRos6hh24RlwgV73akk9g1KwcI
        g3mgGdggKSqz5QKlHS4Q2TQ2LqXbQIzbEJtFhI01OVzxljqPQDY9piDF3b4ap+9i
        4eA7L79LlimzsIFmPhvVYBWu3kftzuFJzWGOXp0CgYARX7eawwbcOQr32kGo723T
        uIVJEVXvFfimgb3u3QD64z9GllQJ0peShQuy0ycXejDPj+9v1L7jgCUROJu+3QMQ
        1/8N1MQmEVjNj6FbBJ9qmGAqHVVzMQFrmN7L7O99y16SsCaxLxYzvz9/FfmCZmvO
        57yZXimVYwSRUY3bodqV6wKBgECdhFeXh1uADqYwJpk/EkihWTFMYWdIB2Gf+1zq
        XrCkeVbB1EhH7g/O5jLSDp+MUrkgrPXS7hq8cU3EzPfxgOjW8Uh8pFXR/Od44MJc
        TJK1EESjvUXCuRti+4Z70jWkXmPSLpKx4NyY8eLpG9QPjjR+LR0DUYu96lyjlzDE
        72ZBAoGBANEdaGB5n0I4TEmUGQGGwZ6pkKBQTvZ/NzoG7hZbNnmzjG6Uoz9G/MCx
        rA1DRbHYrEYmFNtZdQ2tojb7/Ls3iH3T55k18QQOH0tFQZlXAEcNzIRlpIyDZtvV
        MgS4DkuqDpBsg7sIjDIEAidQbI86ldo1G0nu6BMYh1HDcYbPbUYE
        -----END RSA PRIVATE KEY-----

        Expected JWT
        eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiI0MzIwZTQyZS0yODlhLTQ3ODQtODcwMC02YjI2OGE2MWM5M2MiLCJhdWQiOiJhY2NvdW50LWQuZG9jdXNpZ24uY29tIiwiaWF0IjoxNTc4NjExMTQxLCJleHAiOjE1Nzg2MTE0NDEsInN1YiI6ImRhZjBiNzhmLThlZjQtNDhhYi04OTUyLWYyOTQ5ZDFiODg0MyIsInNjb3BlIjoic2lnbmF0dXJlIGltcGVyc29uYXRpb24ifQ.Yv-rygwn3hYQvgjswpXhkkus949QZ4cBZTp3PEC3ILLFYr0qRKaDBJUZ9IJu8aOAD6MJaQDZz7Z2KhAnaaPPteVv27SOGXOXNIFNtxgBMblRzO2FWdTfBy6-5jyK5lZKciNz-orpHR2s1zxu3Uihr6lIy-HeBUEsK8AwlDUjAhChDJBdoT-fBYM-B9ek58AHfbHZ6dWWKhiEvCJxtqONtfd2wuISftrF93AIwr2ZLjTptJlp-d_buElpVU9t4SLj07BHg3q8XHtErDMEUhlAWRbXLnOIdG4fED9P_J-UHBi-bTC5n1IdoA3Cu9Y0HCCrfEi5pJ9VB301yefR5rOIPg

         */
        CreateDocuSignJwtToken jwtToken = new CreateDocuSignJwtToken();

        jwtToken.iss = '4320e42e-289a-4784-8700-6b268a61c93c';
        jwtToken.sub = 'daf0b78f-8ef4-48ab-8952-f2949d1b8843';
        jwtToken.dateTimeJwtIssuedInUnixTime = 1578611141;
        jwtToken.aud = 'account-d.docusign.com';
        jwtToken.scope = 'signature impersonation';
        jwtToken.privateKey = PRIVATE_KEY;

        String tokenResult = jwtToken.createToken();
        String expectedToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiI0MzIwZTQyZS0yODlhLTQ3ODQtODcwMC02YjI2OGE2MWM5M2MiLCJhdWQiOiJhY2NvdW50LWQuZG9jdXNpZ24uY29tIiwiaWF0IjoxNTc4NjExMTQxLCJleHAiOjE1Nzg2MTE0NDEsInN1YiI6ImRhZjBiNzhmLThlZjQtNDhhYi04OTUyLWYyOTQ5ZDFiODg0MyIsInNjb3BlIjoic2lnbmF0dXJlIGltcGVyc29uYXRpb24ifQ.Yv-rygwn3hYQvgjswpXhkkus949QZ4cBZTp3PEC3ILLFYr0qRKaDBJUZ9IJu8aOAD6MJaQDZz7Z2KhAnaaPPteVv27SOGXOXNIFNtxgBMblRzO2FWdTfBy6-5jyK5lZKciNz-orpHR2s1zxu3Uihr6lIy-HeBUEsK8AwlDUjAhChDJBdoT-fBYM-B9ek58AHfbHZ6dWWKhiEvCJxtqONtfd2wuISftrF93AIwr2ZLjTptJlp-d_buElpVU9t4SLj07BHg3q8XHtErDMEUhlAWRbXLnOIdG4fED9P_J-UHBi-bTC5n1IdoA3Cu9Y0HCCrfEi5pJ9VB301yefR5rOIPg';
        
        System.assertEquals(expectedToken, tokenResult, 'Token did not match expected result.');
    }

    @isTest
    static void shouldCreateJwtBodyCorrectly() {
        CreateDocuSignJwtToken jwtToken = new CreateDocuSignJwtToken();
        /** 
            INPUT

            {
                "iss": "4320e42e-289a-4784-8700-6b268a61c93c",
                "aud": "account-d.docusign.com",
                "iat": 1578611141,
                "exp": 1578611441,
                "sub": "daf0b78f-8ef4-48ab-8952-f2949d1b8843",
                "scope": "signature impersonation"
            }
         */

        String jwtBody = jwtToken.createJwtBody('4320e42e-289a-4784-8700-6b268a61c93c', 'daf0b78f-8ef4-48ab-8952-f2949d1b8843',
            1578611141, 1578611441, 'account-d.docusign.com', 'signature impersonation');

        String expectedJwtBody = 'eyJpc3MiOiI0MzIwZTQyZS0yODlhLTQ3ODQtODcwMC02YjI2OGE2MWM5M2MiLCJhdWQiOiJhY2NvdW50LWQuZG9jdXNpZ24uY29tIiwiaWF0IjoxNTc4NjExMTQxLCJleHAiOjE1Nzg2MTE0NDEsInN1YiI6ImRhZjBiNzhmLThlZjQtNDhhYi04OTUyLWYyOTQ5ZDFiODg0MyIsInNjb3BlIjoic2lnbmF0dXJlIGltcGVyc29uYXRpb24ifQ';
        System.assertEquals(expectedJwtBody, jwtBody, 'JWT Body did not match expected values');
    }

    @isTest
    static void shouldCreateJwtSignature() {
        String base64URLHeader = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9';
        String base64URLBody = 'eyJpc3MiOiI0MzIwZTQyZS0yODlhLTQ3ODQtODcwMC02YjI2OGE2MWM5M2MiLCJzdWIiOiJkYWYwYjc4Zi04ZWY0LTQ4YWItODk1Mi1mMjk0OWQxYjg4NDMiLCJhdWQiOiJhY2NvdW50LWQuZG9jdXNpZ24uY29tIiwiaWF0IjoxNTc4NjEwMjQwLCJuYmYiOjE1Nzg2MTAyMTAsImV4cCI6MTU3ODYxMDU0MCwianRpIjoiMjA4M2MwYzQtMmVkMi00MGE4LTkxZGQtNWE4Nzk3MGZlNGY2Iiwic2NvcGUiOiJzaWduYXR1cmUgaW1wZXJzb25hdGlvbiJ9';

        String expectedSignature = 'WUI-t-ZyhClEGowC9-BnP82Tpk6XREHys7Hx67fmQR5SXu3zKEjTvrhticyEAnudVkkhjkZxf5mMT4yFznfd_LKUIft-gAJXRiu9tHJ1f3-fvfpaR6jy_Kxvcd4XSme6pbYUf1Z5FCzt76QDMBWlJ7kVJfP4ljRSF4vxN3vl4QQIwaseHP_BEY262zcAq5A1PaI0fFnChhbi2_zOR2ZkUChS9j3xCqtLPBsthDSJw3_efCLVu4toAZl6ZfXXc-YDycXOqZeWbdx4Tbs17o7wgdGUv-FCE9AyF66uwmohA8FyHei4Ap_-6GRiu3dMieWr8ZpCTaHfjLMZ-3am4970HA';

        CreateDocuSignJwtToken jwtToken = new CreateDocuSignJwtToken();
        jwtToken.privateKey = PRIVATE_KEY;

        String signatureResult = jwtToken.createJwtSignature(base64URLHeader, base64URLBody);
        System.assertEquals(expectedSignature, signatureResult, 'Signature generated for the JWT did not match expected results.');
    }

    @isTest
    static void shouldConvertBase64ToBase64URLCorrectly() {
        String base64String = 'PDw/Pz8+Pg==';
        String expectedBase64UrlString = 'PDw_Pz8-Pg';

        CreateDocuSignJwtToken jwtToken = new CreateDocuSignJwtToken();
        System.assertEquals(expectedBase64UrlString, jwtToken.base64URLEncode(base64String), 'Base64Url did not convert to the expected value.');

    }

}