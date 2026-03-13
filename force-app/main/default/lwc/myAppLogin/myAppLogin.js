import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import fetchMyAppFeatureToggle from '@salesforce/apex/MyAppWelcomeEmailController.fetchMyAppFeatureToggle';
import fetchURLS from '@salesforce/apex/MyAppWelcomeEmailController.fetchURLS';

/* custom methods */
import loginAuthenticateWithCaptcha from '@salesforce/apex/ExperienceAuthenticationServices.loginAuthenticateWithCaptcha';

/* assets */
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';

export default class MyAppLogin extends NavigationMixin(LightningElement) {
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
    @track username;
    @track password;

    @track passwordType;
    @track passwordIcon;
    @track passwordIconTitle;
    @track buttonText;

    @track autofocus = true;
    @track isLoggingIn;
    @track credsError;
    @track hasError;
    @track usernameError;
    @track passwordError;
    @track message;
    showSSOLogin;
    ssoRelativeUrl;


    get backgroundStyle() {
        return 'background-image: url(' + this.backgroundImage +'); min-height: 525px;';
    }

    //import asset css file
    connectedCallback() {
        Promise.all([
            loadStyle(this, communityMyAppAssets + '/MonashStyling.css')
        ]).then(() => {
            this.resourcesReady = true;
        });

        //set defaults
        this.passwordType = 'password';
        this.passwordIcon = 'utility:preview';
        this.passwordIconTitle = 'Show password';
        this.buttonText = 'Log In';

        //retrieve url parameters
        this.parameters = this.getQueryParameters();

        //default username
        this.username = this.parameters.un;

        //retrieve feature toggle
        this.retrieveFeatureToggle();
        this.retrieveURLS();
    }

    /**
    * @description get the feature toggle for Grad Research program
    * @return n/a
    **/
    retrieveFeatureToggle() {
        fetchMyAppFeatureToggle()//getting the feature toggle custom settings
        .then(result => {            
            if(result) {
                this.showSSOLogin = result.Okta_login_enabled__c;
            }
        }).catch(error => {
        });        
    }

     /**
    * @description get the sso relatiove url
    * @return n/a
    **/
     retrieveURLS() {
        fetchURLS()
        .then(result => {            
            if(result) {
                this.ssoRelativeUrl = result.My_App_SSO_Relative_URL__c;
            }
        }).catch(error => {
        });        
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
        //missing details email
        this.emailCheck();
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
    //on password change
    changePassword(event){
        this.password = event.detail.value;

        this.passwordError = '';
        //clear error
        this.template.querySelectorAll(".passwordField").forEach(function(element) {            
            element.classList.value = element.classList.value.replace("invalidCorneredInput", "corneredInput");
            if(!element.classList.value.includes("corneredInput")){
                element.classList.value = element.classList.value + ' corneredInput';
            }
        });
        //missing details email
        if(!this.password){
            this.passwordError = '* Please enter your Password';
            this.template.querySelectorAll(".passwordField").forEach(function(element) {            
                element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
            });
        }
    }

    //auto focus email input
    renderedCallback() {
        let thisPage = this;
        if(thisPage.autofocus) {
            thisPage.template.querySelectorAll(".emailField").forEach(function(element) {
                element.focus();
                thisPage.autofocus = false;
            });
        }
    }

    //toggle password visibility
    togglePasswordVisibility(){
        if(this.passwordType === 'password'){
            this.passwordType = 'text';
            this.passwordIcon = 'utility:hide';
            this.passwordIconTitle = 'Hide password';
        }else{
            this.passwordType = 'password';
            this.passwordIcon = 'utility:preview';
            this.passwordIconTitle = 'Show password';
        }
    }


    //login button
    handleButtonClick(event) {
        this.hasError = false;
        this.validateInput();
        //check if has error
        if(!this.hasError){
            //Run login logic
            this.isLoggingIn = true;
            //if startURL is blank default to navigating to the myapp community home page
            var token = event.detail.captchaToken;
            loginAuthenticateWithCaptcha({
                username : this.username.trim(),
                password : this.password.trim(),
                startUrl : this.parameters.startURL ? this.parameters.startURL : '/admissions', 
                captchaToken : token
            }).then(authResult => { 
                if(authResult.result === 'OK'){
                   window.location.href = authResult.message;
                   this.credsError = '';
                }else if (authResult.result === 'ERROR') {
                    this.credsError = registerResult.message; 
                 }else if(authResult.result === 'NoPermissionSet'){
                   this.password = '';
                    this.credsError = '* Sorry, you do not have a my.application account yet. Please click "Sign Up" for access.';            
                }else{
                    //clear password
                    this.password = '';
                    // Error message with Reset Password link
                    this.credsError = '* ' + authResult.message.replace("reset your password.", "<a href=\"/admissions/s/login/ForgotPassword\">reset your password</a>.");
                }
                this.isLoggingIn = false; 
            })
            .catch(authError =>{
                this.credsError = '* Sorry, we encountered issues on our end. Please try again later.';
                if(authError.body){
                    this.message = 'Error received: code' + authError.errorCode + ', ' + 'message ' + authError.body.message;
                    this.credsError = message;
                }
                this.isLoggingIn = false; 
            });
        }
        this.resetCaptchaButton();
    }

    //validate input
    validateInput(){
        //clear messages
        this.hasError = false;
        this.credsError = '';
        this.usernameError = '';
        this.passwordError = '';
        
        //clear error messages
        this.template.querySelectorAll(".inputField").forEach(function(element) {            
            element.classList.value = element.classList.value.replace("invalidCorneredInput", "corneredInput");
            if(!element.classList.value.includes("corneredInput")){
                element.classList.value = element.classList.value + ' corneredInput';
            }
        });

        this.emailCheck();

        //missing details password
        if(!this.password){
            this.passwordError = '* Please enter your Password';
            this.template.querySelectorAll(".passwordField").forEach(function(element) {            
                element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
            });
            //flag there's an error
            this.hasError = true;
        }
    }

    // check email address
    emailCheck() {
        if(this.username) {
            if(this.username.includes('@')){                
                if(this.username.split('@')[1].toLowerCase().includes('monash.edu') || this.username.split('@')[1].toLowerCase().includes('monashcollege')){      
                    this.usernameError = '* You cannot sign into My.App using a Monash email address. Please sign in with a different email address.';
                    this.template.querySelectorAll(".emailField").forEach(function(element) {            
                        element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
                    });
                    //flag there's an error
                    this.hasError = true;
                }
            }
        } else {
            //missing details email
            this.hasError = true;
            this.usernameError = '* Please enter your Email';
            this.template.querySelectorAll(".emailField").forEach(function(element) {            
                element.classList.value = element.classList.value.replace("corneredInput", "invalidCorneredInput");
                element.setCustomValidity('');
                element.reportValidity();
            });
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
            this.doLogin();         
        }
    }
    //handle register redirection
    redirectRegister(){
        window.location.href = '/admissions/s/login/SelfRegister';
    }
    //redirect to SSO
    redirectSSO(){
        if(this.ssoRelativeUrl)
            window.location.href = this.ssoRelativeUrl;
    }
}