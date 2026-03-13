import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';

/* custom methods */
import requestResetPasswordWithCaptcha from '@salesforce/apex/ExperienceAuthenticationServices.requestResetPasswordWithCaptcha';

/* assets */
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';
export default class MyAppResetPassword extends NavigationMixin(LightningElement) {
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
    @track showResetPasswordSuccessNotification;

    @track autofocus = true;
    @track credsError;
    @track hasError;
    @track usernameError;
    @track message;
    @track buttonText = 'Send Reset Email';


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
        this.showResetPasswordSuccessNotification = false;
        //retrieve url parameters
        this.parameters = this.getQueryParameters();
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
            thisPage.template.querySelectorAll(".emailField").forEach(function(element) {
                element.focus();
                thisPage.autofocus = false;
            });
        }
    }


    resetCaptcha(){
        let crmcaptchalwc = this.template.querySelector(
             '[data-id="crmcaptchalwc"]'
        );
        // Resets and gets new token
        if(crmcaptchalwc){
             crmcaptchalwc.resetCaptchaForm();
        }
        this.isDisableBTN = true;
   }
    //reset password
    handleButtonClick(event) {
        this.hasError = false;
        this.validateInput();

        //check if has error
        if(!this.hasError){
            //Run reset password logic
            requestResetPasswordWithCaptcha({
                username : this.username.trim(),
                captchaToken : event.detail.captchaToken
            }).then(resetPasswordResult => { 
                if(resetPasswordResult.result === 'OK'){
                    //show success notification page
                    this.showResetPasswordSuccessNotification = true;
                    //reset error notification
                    this.credsError = '';
                }else if(resetPasswordResult.result === 'NO_MATCH'){
                    this.credsError = '* Sorry, we could not find your My.App account. Please make sure you typed in the correct email address.';
                }else if (resetPasswordResult.result === 'LOCKED'){
                    this.credsError = '* Your account has been temporarily locked due to too many unsuccessful login attempts. Try again in 15 minutes. You will not be able to reset your password during this time.';
                }else{
                    this.credsError = '* Sorry, the details you\'ve entered are incorrect. Please check your spelling and try again.';
            }
            })
            .catch(resetPasswordError =>{
                this.message = 'Error received: code' + resetPasswordError.errorCode + ', ' +
                            'message ' + resetPasswordError.body.message; 
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
        this.usernameError = '';
        
        //clear error messages
        this.template.querySelectorAll(".inputField").forEach(function(element) {            
            element.classList.value = element.classList.value.replace("invalidCorneredInput", "corneredInput");
            if(!element.classList.value.includes("corneredInput")){
                element.classList.value = element.classList.value + ' corneredInput';
            }
        });

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
            this.doResetPassword();
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
}