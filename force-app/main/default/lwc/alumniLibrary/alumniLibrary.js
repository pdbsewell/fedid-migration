import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import FORM_FACTOR from "@salesforce/client/formFactor";
/* assets */
import monashPortalCssMinified from '@salesforce/resourceUrl/Monash_Portal_CSS_Minified';
/* APEX SERVICES */
import retrieveLinks from "@salesforce/apex/AlumniLibraryController.retrieveLinks";

export default class AlumniLibrary extends LightningElement {
    data = [];
    dataLoaded = false;
    sectionOne = '';
    sectionTwo = '';
    sectionThree = '';

    connectedCallback(){

        Promise.all([
            loadStyle(this, monashPortalCssMinified)
        ]).then(() => {
            this.resourcesReady = true;
        });

        this.dataLoaded = false;
        retrieveLinks({})
        .then((result) => {
            if (result.length > 0) {
                result.forEach((rec) => {

                    if(rec.category === 'Catalog'){
                        this.data.push(rec);
                    }
                    if(rec.category === 'RightSectionOne'){
                        this.sectionOne = rec.headerDescription;
                    }
                    if(rec.category === 'RightSectionTwo'){
                        this.sectionTwo = rec.headerDescription;
                    }
                    if(rec.category === 'RightSectionThree'){
                        this.sectionThree = rec.headerDescription;
                    }
                });
            }
            this.dataLoaded = true;
        })
        .catch((error) => {
            this.showToast(
                "Error",
                "An error has occurred: " + error?.body?.message,
                "Error"
            );
            this.hasData = false;
            this.dataLoaded = true;
        });
    }

    /*
     * Method Name: deviceTypeDesktop
     * Description: getter method to determine if the client device is desktop or mobile
     */
    get deviceTypeDesktop (){
        switch(FORM_FACTOR) {
            case 'Large' :
                return true;
            default :
                return false;
        }
    }

    /*
     * Method Name: showToast
     * Description: method to show toast
     */
    showToast(toastTitle, toastMessage, toastVariant) {
        const toast = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
        });
        this.dispatchEvent(toast);
    }
}