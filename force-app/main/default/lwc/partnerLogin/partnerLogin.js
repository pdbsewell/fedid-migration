import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';

/* custom methods */
import loginAuthenticateWithCaptcha from '@salesforce/apex/ExperienceAuthenticationServices.loginAuthenticateWithCaptcha';

/* assets */
import communityPartnerAssets from '@salesforce/resourceUrl/CommunityPartnerAssets';

export default class PartnerLogin extends NavigationMixin(LightningElement) {
    //url parameters
    parameters = {};

    //retrieve static resource images
    backgroundImage = communityPartnerAssets + '/images/myApp-bg-panel.jpg';
    //backgroundImage = communityPartnerAssets + '/images/myApp-bg-panel-large.jpg';
    //backgroundImage = communityPartnerAssets + '/images/17P-0061-Professional-Development-title-web-banner-2.jpg';
    //backgroundImage = communityPartnerAssets + '/images/19P-0480_Static-Banner_2194x550-1.jpg';
    blurryMonashLogo = communityPartnerAssets + '/images/Monash_Logo_Blurry.png';
    editApplicationLogo = communityPartnerAssets + '/images/editApplication.png';

    //track if assets have been loaded
    @track resourcesReady = false;
    
    //page variables
    @track username;
    @track password;

    @track passwordType;
    @track passwordIcon;
    @track passwordIconTitle;

    @track autofocus = true;
    @track credsError;
    @track hasError;
    @track usernameError;
    @track passwordError;
    @track message;
    @track buttonText = 'Log In';

    get backgroundStyle() {
        return 'background-image: url(' + this.backgroundImage +'); min-height: 525px;';
    }

    //import asset css file
    connectedCallback() {
        Promise.all([
            loadStyle(this, communityPartnerAssets + '/MonashStyling.css')
        ]).then(() => {
            this.resourcesReady = true;
        });

        //set defaults
        this.passwordType = 'password';
        this.passwordIcon = 'utility:preview';
        this.passwordIconTitle = 'Show password';


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
            loginAuthenticateWithCaptcha({
                username : this.username.trim(),
                password : this.password.trim(),
                startUrl : this.parameters.startURL ? this.parameters.startURL : '/partner', //if startURL is blank default to navigating to the myapp community home page
                captchaToken : event.detail.captchaToken
            }).then(authResult => { 
                if(authResult.result === 'OK'){
                    window.location.href = authResult.message;
                    this.credsError = '';
                }else{
                    //clear password
                    this.password = '';
                    // Error message with Reset Password link
                    this.credsError = '* ' + authResult.message.replace("reset your password", "<a href=\"/partner/s/login/ForgotPassword\">reset your password</a>");
                }
            })
            .catch(authError =>{
                this.credsError = '* Sorry, we encountered issues on our end. Please try again later.';
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
        this.usernameError = '';
        this.passwordError = '';
        
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
        window.location.href = '/partner/s/login/SelfRegister';
    }
}