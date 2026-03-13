import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';

/* custom methods */
import registerUserWithCaptcha from '@salesforce/apex/ExperienceAuthenticationServices.registerUserWithCaptcha';

/* assets */
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';

export default class MyAppRegistration extends NavigationMixin(LightningElement) {
    //url parameters
    parameters = {};

    //retrieve static resource images
    backgroundImage = communityMyAppAssets + '/images/myApp-bg-panel.jpg';
    //backgroundImage = communityMyAppAssets + '/images/myApp-bg-panel-large.jpg';
    //backgroundImage = communityMyAppAssets + '/images/17P-0061-Professional-Development-title-web-banner-2.jpg';
    //backgroundImage = communityMyAppAssets + '/images/19P-0480_Static-Banner_2194x550-1.jpg';
    blurryMonashLogo = communityMyAppAssets + '/images/Monash_Logo_Blurry.png';
    editApplicationLogo = communityMyAppAssets + '/images/editApplication.png';

    //track if assets have been loaded
    @track resourcesReady = false;
    
    //page variables
    @track firstname;
    @track lastname;
    @track username;
    @track showRegistrationSuccessNotification;

    @track autofocus = true;
    @track credsError;
    @track hasError;
    @track firstNameError;
    @track lastNameError;
    @track usernameError;
    @track message;
    @track buttonText = 'Sign Up';

    isMononymousName = false;
    mononynmHelpText = 'In case you have a single name without a First or Last Name, please select this';
    
    get backgroundStyle() {
        return 'background-image: url(' + this.backgroundImage +'); min-height: 500px;';
    }

    //import asset css file
    connectedCallback() {
        Promise.all([
            loadStyle(this, communityMyAppAssets + '/MonashStyling.css')
        ]).then(() => {
            this.resourcesReady = true;
        });

        //set defaults
        this.hasError = false;
        this.isRegistering = false;
        this.showRegistrationSuccessNotification = false;
        this.captchaToken = '';
        this.isDisableBTN =  true;
        
        //retrieve url parameters
        this.parameters = this.getQueryParameters();
    }

    //on first name change
    changeFirstName(event){
        this.firstname = event.detail.value;

        this.firstNameError = '';
        //clear error
        this.template.querySelectorAll(".firstNameField").forEach(function(element) {            
            element.classList.value = element.classList.value.replace("invalidCorneredInput", "corneredInput");
            if(!element.classList.value.includes("corneredInput")){
                element.classList.value = element.classList.value + ' corneredInput';
            }
        });
        //missing details first name
        if(!this.firstname){
            this.firstNameError = '* Please enter your First Name';
            this.template.querySelectorAll(".firstNameField").forEach(function(element) {            
                element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
            });
        }
    }

    //on last name change
    changeLastName(event){
        this.lastname = event.detail.value;
        
        this.lastNameError = '';
        //clear error
        this.template.querySelectorAll(".lastNameField").forEach(function(element) {            
            element.classList.value = element.classList.value.replace("invalidCorneredInput", "corneredInput");
            if(!element.classList.value.includes("corneredInput")){
                element.classList.value = element.classList.value + ' corneredInput';
            }
        });
        //missing details last name
        if(!this.lastname){
            this.lastNameError = '* Please enter your Last Name';
            this.template.querySelectorAll(".lastNameField").forEach(function(element) {            
                element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
            });
        } 
    }

    //on username change
    changeUsername(event){
        this.username = event.detail.value;
        
        this.usernameError = '';
        //clear error
        this.template.querySelectorAll(".emailField").forEach(function(element) {            
            element.classList.value = element.classList.value.replace("invalidCorneredInput", "corneredInput");
            if(!element.classList.value.includes("corneredInput")){
                element.classList.value = element.classList.value + ' corneredInput';
            }
            element.setCustomValidity('');
            if(!element.checkValidity()){
                element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
            }
            element.reportValidity();
        });
        //monash email check
        this.emailCheck();

        //missing details email
        if(!this.username){
            this.usernameError = '* Please enter your Email';
            this.template.querySelectorAll(".emailField").forEach(function(element) {            
                element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
                element.setCustomValidity('');
                element.reportValidity();
            });
        }
    }    

    //auto focus email input
    renderedCallback() {
        let thisPage = this;
        if(thisPage.autofocus) {
            thisPage.template.querySelectorAll(".firstNameField").forEach(function(element) {
                element.focus();
                thisPage.autofocus = false;       
            });
        }
    }

    //register action - validate fields
    handleButtonClick(event) {
        this.hasError = false;
        this.validateInput();

        if (this.isMononymousName) {
            this.firstname = "";
        }

        //check if has error
        if(!this.hasError){
            //Run register user logic
            registerUserWithCaptcha({
                firstName : this.firstname.trim(),
                lastName : this.lastname.trim(),
                email : this.username.trim(),
                captchaToken : event.detail.captchaToken
            }).then(registerResult => { 
                if(registerResult.result === 'OK'){
                    //show success notification page
                    this.showRegistrationSuccessNotification = true;
                    //reset error notification
                    this.credsError = '';
                 }else if (registerResult.result === 'ERROR') {
                    this.credsError = registerResult.message; 
                 }else if(registerResult.result === 'NoPermissionSet'){
                   this.showRegistrationSuccessNotification = true;
                }else if(registerResult.result === 'HAS_DUPLICATE'){
                        this.credsError = registerResult.message; 
                }else{
                    this.credsError = '* Sorry, we encountered an issue. Please try again later.'; 
                }
            })
            .catch(authError =>{
                console.log(JSON.stringify(authError));
                this.message = 'Error received: code' + authError.errorCode + ', ' +
                            'message ' + authError.body.message;
            });
        }
        this.resetCaptchaButton();  
    }

    resetCaptchaButton(){
        let crmcaptchabuttonlwc = this.template.querySelector(
             '[data-id="crmcaptchabuttonlwc"]'
        );
        // Resets and gets new token
        if(crmcaptchabuttonlwc){
            crmcaptchabuttonlwc.resetButton();
        }
   }
    //validate input
    validateInput(){
        //clear messages
        this.hasError = false;
        this.credsError = '';
        this.firstNameError = '';
        this.lastNameError = '';
        this.usernameError = '';
        
        //clear error messages
        this.template.querySelectorAll(".inputField").forEach(function(element) {            
            element.classList.value = element.classList.value.replace("invalidCorneredInput", "corneredInput");
            if(!element.classList.value.includes("corneredInput")){
                element.classList.value = element.classList.value + ' corneredInput';
            }
        });

        //monash email check
        this.emailCheck();

        //missing details first name
        if (!this.isMononymousName && !this.firstname){
            this.firstNameError = '* Please enter your First Name';
            this.template.querySelectorAll(".firstNameField").forEach(function(element) {            
                element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
            });
            //flag there's an error
            this.hasError = true;
        }
        
        //missing details last name
        if (!this.lastname || !this.lastname.trim()){
            if (!this.isMononymousName) {
                this.lastNameError = '* Please enter your Last Name';
            } else {
                this.lastNameError = '* Please enter your Name';
            } 
            this.template.querySelectorAll(".lastNameField").forEach(function(element) {            
                element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
            });
            //flag there's an error
            this.hasError = true;
        } 

        //missing details email
        if(!this.username){
            this.usernameError = '* Please enter your Email';
            this.template.querySelectorAll(".emailField").forEach(function(element) {            
                element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
            });
            //flag there's an error
            this.hasError = true;
        }
    }

    emailCheck() {
        if(this.username){
            if(this.username.includes('@')){                
                if(this.username.split('@')[1].toLowerCase().includes('monash.edu') || this.username.split('@')[1].toLowerCase().includes('monashcollege')){      
                    this.usernameError = '* Sorry, we can’t sign you up using a Monash email address. Please use a different email address to continue.';
                    this.template.querySelectorAll(".emailField").forEach(function(element) {            
                        element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
                    });
                    //flag there's an error
                    this.hasError = true;
                }
            }
        }
    }

    //collect url parameters into a key/value pair object
    getQueryParameters() {
        var params = {};
        var search = location.search.substring(1);

        if (search) {
            params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
                return key === "" ? value : decodeURIComponent(value)
            });
        }

        return params;
    }

    //handle key presses
    handleKeyPress(event){
        //handle enter key
        if(event.which === 13){
            this.doRegister();
        }
    }

    //handle register redirection
    redirectRegister(){
        window.location.href = '/admissions/s/login/SelfRegister';
    }

    //handle register redirection
    redirectLogin(){
        window.location.href = '/admissions/s/login';
    }
    // handle mononymous names
    handleMononyms() {
        this.isMononymousName = !this.isMononymousName;
    }
}