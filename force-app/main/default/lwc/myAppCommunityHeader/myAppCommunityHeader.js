import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';
import retrieveHomeDetails from '@salesforce/apex/MyAppHomeServices.retrieveHomeDetails';

import USER_ID from '@salesforce/user/Id';

export default class MyAppCommunityHeader extends NavigationMixin(LightningElement) {
    //retrieve static resource images
    monashLogoUrl = communityMyAppAssets + '/images/monash-logo.svg';
    callLogoUrl = communityMyAppAssets + '/images/ContactUs@3x.png';
    userLogoUrl = communityMyAppAssets + '/images/person_icon2x.png';
    callLogoUrlInverse = communityMyAppAssets + '/images/ContactUs@3xBlack.png';
    userLogoUrlInverse = communityMyAppAssets + '/images/person_icon2xblack.png';
    @track resourcesReady = false;

    @track menuToggled;
    @track menuClass;
    
    @track mobileNavToggled;
    @track navClass;
    @track navBtnClass;
    @track navMenuClass;
    @track navMenuAriaExpanded;
    @track hideHeader;
    submittedApplications;
    draftApplications;
    hasApplications;

    get isAuthenticated() {
        let authenticated = true;
        if (window.location.href.includes('/login/') || window.location.href.includes('/ask-us/')) { 
            authenticated = false;
        }
        return authenticated;
    }
    get isShowLogin() {
        let showLogin = true;
        if (window.location.href.includes('/ask-us/')) { 
            showLogin = false;
        }
        return showLogin;
    }
    //showHomeIcon - show/hide logic
    get isShowHomeIcon() {
        this.retrieveApplicationsData();
       if (this.isAuthenticated && this.hasApplications)
            return true;
       else
            return false;
    }

    get getMobileHeaderLabel() {
        let mobileHeaderLabel;
        if (window.location.href.includes('login')) { 
            mobileHeaderLabel = 'Login';
        }else if (window.location.href.includes('course-selection')) { 
            mobileHeaderLabel = 'Course Preferences';
        }else if (window.location.href.includes('signup-declaration')) { 
            mobileHeaderLabel = 'Declaration';
        }else if (window.location.href.includes('personal-details')) { 
            mobileHeaderLabel = 'Personal Details';
        }else if (window.location.href.includes('qualifications-work-experience')) { 
            mobileHeaderLabel = 'Credentials';
        }else if (window.location.href.includes('external-scholarship')) { 
            mobileHeaderLabel = 'Scholarship';
        }else if (window.location.href.includes('document-upload')) { 
            mobileHeaderLabel = 'Documents';
        }else if (window.location.href.includes('payment')) { 
            mobileHeaderLabel = 'Application Fee';
        }else if (window.location.href.includes('submission-declaration')) { 
            mobileHeaderLabel = 'Submit';
        }else if (window.location.href.includes('review')) { 
            mobileHeaderLabel = 'Review';
        }else if (window.location.href.includes('my-details')) { 
            mobileHeaderLabel = 'My Details';
        }else if (window.location.href.includes('offer-acceptance')) { 
            mobileHeaderLabel = 'Offer Acceptance';
        }else if (window.location.href.includes('application/')) { 
            mobileHeaderLabel = 'Application Form';
        }else if(window.location.href.includes('Offer') || window.location.href.includes('offer')){
            mobileHeaderLabel = undefined;
        } else{
            mobileHeaderLabel = 'Home';
        }
        return mobileHeaderLabel;
    }

    //import asset css file
    connectedCallback() {
        Promise.all([
            loadStyle(this, communityMyAppAssets + '/MonashStyling.css')
        ]).then(() => {
            this.resourcesReady = true;
        });

        //menu popover
        this.menuToggled = false;
        this.menuClass = 'popover__content';
    
        //mobile nav
        this.mobileNavToggled = false;
        this.navClass = 'navbar uber-accordion';
        this.navBtnClass = 'navbar__toggle uber-accordion__button';
        if (window.location.href.includes('login')) { 
            this.navBtnClass = this.navBtnClass + ' slds-hidden';
        }
        this.navMenuClass = 'navbar__dropdown uber-accordion__target navbar__dropdown--mobile';
        this.navMenuAriaExpanded = false;
    }

    //action to show/hide menu popover
    toggleMenu() {
        if(this.menuToggled){
            this.menuClass = 'popover__content';
        }else if(!this.menuToggled){
            this.menuClass = 'popover__content popover__content__selected';
        }
        this.menuToggled = !this.menuToggled;
    }

    //action to show/hide mobile navigation menu
    toggleMobileNav() {
        if(this.mobileNavToggled){
            this.navClass = 'navbar uber-accordion';
            this.navBtnClass = 'navbar__toggle uber-accordion__button';
            this.navMenuClass = 'navbar__dropdown uber-accordion__target navbar__dropdown--mobile';
            this.navMenuAriaExpanded = 'false';
        }else if(!this.mobileNavToggled){
            this.navClass = 'navbar uber-accordion accordion__item-heading--active';
            this.navBtnClass = 'navbar__toggle uber-accordion__button uber-accordion__button-active';
            this.navMenuClass = 'navbar__dropdown uber-accordion__target navbar__dropdown--mobile uber-accordion__target-active js-navbar__dropdown--active navbar__dropdown--slide-right';
            this.navMenuAriaExpanded = 'true';
        }
        this.mobileNavToggled = !this.mobileNavToggled;
    }

    closeMenu() {
        this.menuClass = 'popover__content';
    }

    redirectHome() {
        //navigate to the application edit page
        this[NavigationMixin.GenerateUrl]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'home'
            }
        }).then(url => {
            window.location.href = url;
        });
        
        if(this.menuToggled){
            this.toggleMenu();
            this.toggleMobileNav();  
        } 
    }

    logout() {
        //navigate to the Logout page
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'logout'
            }
        });
        
        if(this.menuToggled){
            this.toggleMenu();
            this.toggleMobileNav();  
        } 
    }

    login() {
        //navigate to the Logout page
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'login'
            }
        });
        
        if(this.menuToggled){
            this.toggleMenu();
            this.toggleMobileNav();  
        } 
    }

    myDetails() {
        //navigate to the application edit page
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/admissions/s/my-details'
            }
        }).then(url => {
            window.location.href = url;
        });
        
        if(this.menuToggled){
            this.toggleMenu();
            this.toggleMobileNav();  
        } 
    }

    redirectFaq() {
        //navigate to the application edit page
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/admissions/s/faq'
            }
        }).then(url => {
            window.location.href = url;
        });
        
        if(this.menuToggled){
            this.toggleMenu();
            this.toggleMobileNav();  
        } 
    }
    //Retrieve Applications - Draft/Submitted
    retrieveApplicationsData()
    {
       retrieveHomeDetails({ communityUserId : USER_ID })
        .then(constructorResult => {
            this.submittedApplications = constructorResult.SUBMITTED_APPLICATIONS;
            this.draftApplications = constructorResult.DRAFT_APPLICATIONS;
            if(this.draftApplications || this.submittedApplications)
                this.hasApplications = true;
            else
                this.hasApplications= false;
        });
    }

    handleKeyDown(event) {
        // Support Enter and Space keys
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault(); // Prevent scrolling on Space
            const target = event.currentTarget;
    
            // Match action based on the element triggering it
            if (target.alt === 'View Profile') {
                this.toggleMenu();
            } else if (target.innerText?.includes('MY DETAILS')) {
                this.myDetails();
            } else if (target.innerText?.includes('LOGOUT')) {
                this.logout();
            } else if (target.innerText?.includes('LOGIN')) {
                this.login();
            } else if (target.innerText?.includes('HOME')) {
                this.redirectHome();
            }
        }
    }
    
}