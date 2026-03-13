import { LightningElement } from 'lwc';
import getRedirectUrl from '@salesforce/apex/LoginRedirectController.getRedirectUrl';
import getRedirectUrlWithPath from '@salesforce/apex/LoginRedirectController.getRedirectUrlWithPath';
import makeMemberOfTargetPortal from '@salesforce/apex/LoginRedirectController.makeMemberOfTargetPortal';
import makeMemberOfTargetPortalByName from '@salesforce/apex/LoginRedirectController.makeMemberOfTargetPortalByName';

// We look for these snippets in the URL which tell us we are in experience builder and should not redirect
const BUILDER_URL = '.builder.salesforce-experience.';  
const PREVIEW_URL = '.live-preview.';                   


export default class LoginRedirect extends LightningElement {

    doRedirect = true;      // If true tells us we should redirect
    redirectUrl = '';       // Place to send the user after login. Typically the network switch URL
    siteLabel = null;       // Label used to lookup network name and perm sets
    redirectPath = null;    // Path on target site to send user on redirection
    isCustomRedirect = false; // True if user has specified URL params to select site and target path
    error = '';             

    constructor() {
        
        super();

        // Determine if the component has loaded in an Experience Builder page
        // And if so flag as NO redirection
        const currentUrl = window.location.href;
        this.doRedirect = !(currentUrl.includes(BUILDER_URL) || currentUrl.includes(PREVIEW_URL));

        this.handleRedirect();
    }

    async handleRedirect () {
        try {
            // Clear error
            this.error = undefined;
            const currentUrl = window.location.href;

            // Do we have any query params to control the redirect behaviour...
            // e.g. https://connect.monash.edu/s/loginredirect?siteLabel=myapp&redirectPath=/s/somepage
            this.siteLabel = this.getQueryParamValue(currentUrl, 'siteLabel');
            this.redirectPath = this.getQueryParamValue(currentUrl, 'redirectPath');
            this.isCustomRedirect = (this.siteLabel && this.redirectPath);

            // If so... use them to get the URL to redirect to
            if (this.isCustomRedirect) {
                this.redirectUrl = await getRedirectUrlWithPath({ 
                    redirectPath: this.redirectPath, 
                    siteLabel: this.siteLabel});
            // ...otherwise get default redirect URL
            } else {
                this.redirectUrl = await getRedirectUrl();
            }

            // Now redirect the user
            if (this.doRedirect === true) {
                if (this.isCustomRedirect) {
                    await makeMemberOfTargetPortalByName({
                        siteLabel: this.siteLabel});
                }
                else {
                    await makeMemberOfTargetPortal();
                }
                window.location.href = this.redirectUrl; 
            }

        } catch (error) {
            this.error = error.body.message;
            this.redirectUrl = '';
            console.error(this.error);
        }
    }

    getQueryParamValue(url, paramName) {
        try {
            // Create a new URL object from the provided URL string
            let urlObj = new URL(url);
            
            // Use the searchParams API to get the value of the query parameter
            let paramValue = urlObj.searchParams.get(paramName);
            
            // Return the value, or null if the parameter doesn't exist
            return paramValue ? paramValue : null;
        } catch (error) {
            console.error("Invalid URL:", error);
            return null; // Return null if the URL is invalid or there was an error
        }
    }

    get doNotRedirect() {
        return !this.doRedirect;
    }



}