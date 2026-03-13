/**
 * @description Class for retrieving DocuSign Authorization settings
 * @group DocuSign Authorization
 */
public with sharing class DocuSignAuthProviderSetting {
    
    @testVisible
    private DocuSign_Auth_Provider_Setting__mdt setting;
    
    public DocuSignAuthProviderSetting() {

        /**
        Custom metadata types are queried against data in the system
        e.g. as if seeAllData=true
        This means the unit tests will fail if the values are not populated
        e.g. during a deployment when the the custom metadata type
        does not already exist in the system, for example, if the custom 
        metadata type and was deployed for the very first time to the 
        environment. Hence, if this code excutes during unit tests,
        the custom metadata type values will use a mock provided instead 
        of the actual system values.
         */        

        if (Test.isRunningTest()) {
            this.setting = new DocuSign_Auth_Provider_Setting__mdt(
                MasterLabel = 'DocuSign',
                DeveloperName = 'DocuSign', 
                Private_Key__c = 'MIIEowIBAAKCAQEAwUXz2Y7/alHCSGpag4g4/8zhIGjiIJFPZo8cggQWDoIq/jg8bGAX40+02etOLrDE0pNSernotAVzcP0CtRNL5SCtuMhm2hkG7RJarnx6ds3g/KTqRkAhv5lNPuW+D5GFFKI0B9f6CL8+SWbLD4C/Set8kaoOVVlkUhCA3tUMgxNLuyLhJAtOhCNE3dOz07MAgjhzu0ZfpJ3iMe8HKtdIuATPhhYadJrlC07a/fIa+O67SKjpI8RnryyPW7AydFUbbXxYHGvWFf59mpNAX7FjSS0fA7R9Gcyd2ZnLfVSc7JCOZcuDCjO6DIypckFS7ZfinpmJE6rTGF9jtE1DCmnolwIDAQABAoIBAAJbNvjdDHIgYwz89vOJkqBTwB7kCHW7L8uhTQiswhQVNC77QolTtpbX3u2VN9PL5epnT2cdox+mvVyQSRsqDA/UESoij1ZzXalAQwjDjb6rDeYmoJCQsZijZtSwelu4O3Yf8CB0WqEGq9y7OxiKSkq9azxfZWNW/qkdeGS/FjL24NWxK+4zbHNvacHuWhUwB8dfWB7/OwDy0fcXsSn2E3lwJbnQ23CfYWKi4LLZ6rtU2/JgXNuku3e4zNPudNOAq4nWV/GR5b5/gn/M6DvJ5XUxGwNfH/bE2vsN4euOgWCPhjh40LfVmIP7KVcwRECD1IlV/RhG7owYk6yvnSFq6MkCgYEA4yLTpaSsKQ2X+IEs2Mjv+PhxPv9jJJxAksmIor9+fOwKguqIW3FJiuIjBodtD4nygXFEXfkXc9J6HtP6dS/Yq74EE5nDK6L//svoPFw/5W82TzsQAsfoijPnh0NuFk8sRzmFZ5qmudtLi6RQS/wHA0vPPHOQCaGgHOkHXPqMA8MCgYEA2dWBA/LsO++y91hzlk2wdPxxLjdzFxcoyso7YF1+JLQRos6hh24RlwgV73akk9g1KwcIg3mgGdggKSqz5QKlHS4Q2TQ2LqXbQIzbEJtFhI01OVzxljqPQDY9piDF3b4ap+9i4eA7L79LlimzsIFmPhvVYBWu3kftzuFJzWGOXp0CgYARX7eawwbcOQr32kGo723TuIVJEVXvFfimgb3u3QD64z9GllQJ0peShQuy0ycXejDPj+9v1L7jgCUROJu+3QMQ1/8N1MQmEVjNj6FbBJ9qmGAqHVVzMQFrmN7L7O99y16SsCaxLxYzvz9/FfmCZmvO57yZXimVYwSRUY3bodqV6wKBgECdhFeXh1uADqYwJpk/EkihWTFMYWdIB2Gf+1zqXrCkeVbB1EhH7g/O5jLSDp+MUrkgrPXS7hq8cU3EzPfxgOjW8Uh8pFXR/Od44MJcTJK1EESjvUXCuRti+4Z70jWkXmPSLpKx4NyY8eLpG9QPjjR+LR0DUYu96lyjlzDE72ZBAoGBANEdaGB5n0I4TEmUGQGGwZ6pkKBQTvZ/NzoG7hZbNnmzjG6Uoz9G/MCxrA1DRbHYrEYmFNtZdQ2tojb7/Ls3iH3T55k18QQOH0tFQZlXAEcNzIRlpIyDZtvVMgS4DkuqDpBsg7sIjDIEAidQbI86ldo1G0nu6BMYh1HDcYbPbUYE', 
                iss__c = '4320e42e-289a-4784-8700-6b268a61c93c', 
                sub__c = 'daf0b78f-8ef4-48ab-8952-f2949d1b8843', 
                aud__C = 'account-d.docusign.com',
                Access_Token_URI__c = 'https://account-d.docusign.com/oauth/token',
                Account_Id__c = '6a6b498e-b3d8-4d1b-ade2-68ca24f09b10'
            );
        } else {
            this.setting = [SELECT Id, MasterLabel, DeveloperName, Private_Key__c, iss__c, sub__c, aud__c, Access_Token_URI__c, Account_Id__c FROM DocuSign_Auth_Provider_Setting__mdt WHERE DeveloperName = 'DocuSign' LIMIT 1];
        }
    }

    public String getPrivateKey() {
        return setting.Private_Key__c;
    }

    public String getIss() {
        return setting.iss__c;
    }

    public String getSub() {
        return setting.sub__c;
    }

    public String getAud() {
        return setting.aud__c;
    }

    public String getAccessTokenUrl() {
        return setting.Access_Token_URI__c;
    }

    public String getAccountId() {
        return setting.Account_Id__c;
    }
}