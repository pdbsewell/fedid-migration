import {ShowToastEvent} from 'lightning/platformShowToastEvent'
import retrieveCredentialProvider from '@salesforce/apex/DigitaryServices.retrieveCredentialProvider';

/**
 * Check if the feature switch is on and the qualification's country has supported credential providers
 *
 * @param {Object} context - The context object containing contact qualification details.
 * @param {Object} context.contactQualification - The contact qualification information.
 * @param {Object} context.contactQualification.Qualification_Country__r - Reference to the qualification country.
 * @param {string} context.contactQualification.Qualification_Country__r.ISO_Alpha_2__c - The ISO Alpha-2 country code.
 * @param {string} context.contactQualification.Qualification_Type__c - The type of the qualification.
 * @returns {Promise<void>} A promise that resolves when the credential provider information is retrieved.
 */
const checkDigitaryIntegrationAvailability = (context) => {
    return retrieveCredentialProvider({
        countryCode: context.contactQualification?.Qualification_Country__r?.ISO_Alpha_2__c,
        qualificationType: context.contactQualification?.Qualification_Type__c
    })
        .then((result) => {
            context.credentialProviderInfos = result;
        })
        .catch((error) => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message,
                    variant: 'error',
                    mode: 'sticky'
                }),
            );
        })
}

export {checkDigitaryIntegrationAvailability};