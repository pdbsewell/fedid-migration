/* eslint-disable no-console */
/* eslint-disable vars-on-top */
/* eslint-disable no-unused-vars */
import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import static_resource from '@salesforce/resourceUrl/admission_assets'

export default class OfferIconNav extends LightningElement {
    @track homeImg;
    @track contactUsImg;
    @track profileImg;
    @track homeUrl;
    @track contactUsUrl;
    @track profileUrl;

    connectedCallback(){
        loadStyle(this, static_resource + '/css/desktop-style-sheet.css');
        loadStyle(this, static_resource + '/css/mobile-style-sheet.css');

        this.homeImg = static_resource + '/mobile-footer/home.png';
        this.contactUsImg = static_resource + '/mobile-footer/contact-us.png';
        this.profileImg = static_resource + '/mobile-footer/profile.png';
        var urlString = window.location.origin;
        var path = window.location.pathname;
        this.homeUrl = urlString + '/admissions/s/';
        this.contactUsUrl = urlString + '/admissions/s/contact-us';
        this.profileUrl = urlString + '/admissions/s/my-details';
    }
}