/***
 * This class is a temporary fix for the LivePerson Anywhere (LivePerson Embedded UI) package.
 * The package has a Lightning Container that references ApexForLPIntegration.cls but it does not include it.
 * Creating this class and granting access to it fixes the issue.
 */
global with sharing class ApexForLPIntegration {
    public ApexForLPIntegration() {
        
    }
}