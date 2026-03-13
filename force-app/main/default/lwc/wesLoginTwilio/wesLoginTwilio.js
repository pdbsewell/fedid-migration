import { LightningElement, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import doLogin from '@salesforce/apex/WesLoginAndRegistrationController.checkRegistrationDetails';
import sendCode from '@salesforce/apex/WesLoginAndRegistrationController.sendCode';
import verifyLogin from '@salesforce/apex/WesLoginAndRegistrationController.verifyLogin';

export default class WesRegistration extends NavigationMixin(LightningElement) {

    // Prevent multiple invocations of renderedcallback
    @track hasRendered = false;

    // Error Panel Message
    @track errorMessage;

    // USER INPUT FIELDS

    // User details to be checked
    @track studentId = null;
    @track dateOfBirth = null;
    @track firstName = null;
    @track lastName = null;
    @track firstNamePlaceholderText = 'First Name (s)';

    // OTP Code
    @track verificationCode = null;

    // Obfuscated contact point 
    @track contactPoint = null; // Where OTP was sent
    @track contactPoints = []; // Options for where to send OTP
    @track selectedContactPoint = '';

    @track infoTooltipDisplayData = {};
    @track requiredTooltipDisplayData = {};
    @track errorTooltipDisplayData = {};

    // Results of Apex invocations
    @track loginResult;
    @track sendCodeResult;
    @track verificationResult;

    // Used to conditionally render the UI
    @track isLoading = false;
    @track isError = false;
    @track showStudentDetails = true;
    @track studentDetailsConfirmed = false; // Details match valid student contact
    @track codeSent = false; 
    @track isValidVerificationCode = false;
    @track isMonoName = false;

    // Where to go after login
    @track startUrl;
    @track redirectUrl;
    @track genericLogin = true;

    //Header Value
    get headerTitleValue() {
        let strHeaderVal = 'Student Login';
        if (this.genericLogin === false) {
            strHeaderVal = 'WES Past Student Login';
        }
        return strHeaderVal;
    }

    connectedCallback(){

        this.infoTooltipDisplayData.username = "tooltiptext usernameTooltiptext";

        this.requiredTooltipDisplayData.studentId = 'tooltiptext tooltipHide';
        this.requiredTooltipDisplayData.dateOfBirth = 'tooltiptext tooltipHide';
        this.requiredTooltipDisplayData.firstName = 'tooltiptext tooltipHide';
        this.requiredTooltipDisplayData.lastName = 'tooltiptext tooltipHide';
        this.requiredTooltipDisplayData.contactPoint = 'tooltiptext tooltipHide';
        this.requiredTooltipDisplayData.username = 'tooltiptext tooltipHide';        
        this.requiredTooltipDisplayData.verificationCode = 'tooltiptext tooltipHide';

        this.errorTooltipDisplayData.contactPoint = 'tooltiptext tooltipHide';
    }

    renderedCallback() {
        if (!this.hasRendered) {
            // Get startUrl, this is used to redirect to SP SAML ACS after IDP SSO login
            let queryString = window.location.search;
            let urlParams = new URLSearchParams(queryString);
            this.startUrl= urlParams.get('startURL')
            //Read Start URL and set Generic Login
            let decodedpath = decodeURIComponent(this.startUrl);
            if(decodedpath.includes("/wes/?source=unicrm")){
                this.genericLogin = false;
                // Set title of browser tab
                document.title = 'WES Past Student Login';
            } else {
                document.title = 'Login';
            }
            
            // Make sure we do all of this only once
            this.hasRendered = true;
        }
    }

    // Checks that the details entered match a past student contact record
    // If so, presents contact point options to which user can send OTP verification code
    //
    handleLogin(event){

        if (!this.studentId || !this.dateOfBirth || !this.lastName) {
            return;
        }
        this.isLoading = true;
        doLogin({ studentId: this.studentId.trim(), dateOfBirth: this.dateOfBirth, firstName: this.firstName, lastName: this.lastName })
        .then((result) => {
            this.loginResult = result;
            if (this.loginResult.status === 'SUCCESS') {
                if (!this.firstName) { // Handle mono name
                    this.isMonoName = true;
                    this.firstNamePlaceholderText = '';
                } 
                this.isError = false;
                this.errorMessage = '';
                this.populateContactPointOptions(this.loginResult.contactPoints);
                this.contactPoint = this.contactPoints[0].label;
                this.studentDetailsConfirmed = true;
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(()=>{ // focus on radio group
                    let elem = this.template.querySelector("[data-id='contactPointRadioGroup']"); 
                    elem.focus();
                }, 100);
            } else {
                console.error(this.loginResult.errorMessage);
                this.errorMessage = this.loginResult.errorMessage;    
                if(this.genericLogin && this.loginResult.errorMessage && this.loginResult.errorMessage.includes(' WES ')){
                    // Generic 
                    this.errorMessage = this.loginResult.errorMessage.replace(' WES ',' ');
                }
                this.isError = true;
                this.contactPoint = '';
                this.contactPoints = [];
                this.studentDetailsConfirmed = false;   
            }
            this.isLoading = false;
        })
        .catch((error) => {
            console.error(error.body.message);
            if (error.body.message.includes('permission to view this data')) { // Likely Experian or Twilio is not configured
                this.errorMessage = 'Past student login is experiencing difficulties, please try again later.';  
            } else {
                this.errorMessage = 'Oops, something went wrong at our end, please try again later';  
            }
            this.isError = true;
            this.loginResult = undefined;
            this.studentDetailsConfirmed = false;  
            this.contactPoint = '';
            this.contactPoints = [];
            this.isLoading = false;
        });
    }

    // Triggers sending of OTP code to the selected contact point
    //
    handleSendCode(event) {
        if (!this.selectedContactPoint || !this.studentId || !this.dateOfBirth || !this.lastName) {
            return;
        }
        this.isLoading = true;
        sendCode({ contactPointIndex:this.selectedContactPoint, studentId: this.studentId.trim(), dateOfBirth: this.dateOfBirth, firstName: this.firstName, lastName: this.lastName })
        .then((result) => {
            this.sendCodeResult = result;
            if (this.sendCodeResult.status === 'SUCCESS') {
                this.isError = false;
                this.errorMessage = '';
                this.contactPoint = this.sendCodeResult.contactPoints; // returns the contact point the code was sent to
                this.codeSent = true;
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(()=>{ // place cursor in verification code input box
                    let elem = this.template.querySelector("[data-id='inputVerificationCode']"); 
                    elem.addEventListener("input", event => {
                        this.verificationCode = event.target.value;
                        if (event.target.value && event.target.value.length === 6) {
                            this.isValidVerificationCode = true;
                        } else {
                            this.isValidVerificationCode = false;
                        }
                    });
                    elem.focus();
                }, 100);
            } else {
                console.error(this.sendCodeResult.errorMessage);
                this.errorMessage = this.sendCodeResult.errorMessage;    
                if(this.genericLogin && this.sendCodeResult.errorMessage && this.sendCodeResult.errorMessage.includes(' WES ')){
                    // Generic 
                    this.errorMessage = this.sendCodeResult.errorMessage.replace(' WES ',' ');
                }
                this.isError = true;
                this.codeSent = false; 
            }
            this.isLoading = false;
        })
        .catch((error) => {
            console.error(error.body.message);
            if (error.body.message.includes('permission to view this data')) { // Likely Experian or Twilio is not configured
                this.errorMessage = 'Past student login is experiencing difficulties, please try again later.';  
            } else {
                this.errorMessage = 'Oops, something went wrong at our end, please try again later';  
            }
            this.isError = true;
            this.sendCodeResult = undefined;
            this.codeSent = false;
            this.isLoading = false;
        });
    }

    // Compares the OTP code entered with the one sent
    // If the code matches, logs user into IDP then redirects browser to IDP initiated SP SAML endpoint
    // Which will result in a SAML response being send to WES SAML ACS
    //
    handleVerification(event) {
        this.isLoading = true;
        verifyLogin({ studentId: this.studentId.trim(), code: this.verificationCode, startUrl: this.startUrl })
        .then((result) => {
            this.verificationResult = result;
            if (this.verificationResult.status === 'SUCCESS') {
                this.isError = false;
                this.errorMessage = '';
                this.redirectUrl = this.verificationResult.verificationId; // verificationId contains start URL for SP
                // Redirect to SP ACS URL
                window.location.replace(
                    this.redirectUrl
                  ); 
                  // this.isLoading = false;
            } else {
                this.isError = true;
                this.errorMessage = this.verificationResult.errorMessage;  
                if(this.genericLogin && this.verificationResult.errorMessage && this.verificationResult.errorMessage.includes(' WES ')){
                    // Generic 
                    this.errorMessage = this.verificationResult.errorMessage.replace(' WES ',' ');
                }
                console.error(this.errorMessage);
                let elem = this.template.querySelector("[data-id='inputVerificationCode']"); 
                elem.focus();
                elem.select();
                this.isLoading = false;
            }
        })
        .catch((error) => {
            console.error(error.body.message);
            this.errorMessage = 'Past student login is experiencing difficulties, please try again later.';    
            this.isError = true;
            this.verificationResult = undefined;
            this.isLoading = false;
        });
    }

    // Create radio buttons for contact point options
    //
    populateContactPointOptions(contactPoints) {
        const cpArray = contactPoints.split(','); 
        this.contactPoints = [];
        for (let i=0 ; i<cpArray.length; i++) {
            let channel = cpArray[i].includes('@') ? 'Email' : 'Text';
            const option = { label: channel + ': ' + cpArray[i], value: i.toString()};
            this.contactPoints.push(option);
        }
        if (contactPoints.length > 0) {
            this.selectedContactPoint = "0";
        }
    }

    isPositiveInteger(str) {
        // Use a regular expression to check if the string consists of digits and is not empty
        if (/^\d+$/.test(str)) {
          // Convert the string to a number and check if it's a positive integer
          const number = parseInt(str, 10);
          return Number.isInteger(number) && number >= 0;
        }
        return false;
    }

    handleStudentIdChange(event){
        this.studentId = event.target.value;
    }

    handleDateOfBirthChange(event){
        this.dateOfBirth = event.target.value;
    }
    
    handleFirstNameChange(event){
        this.firstName = event.target.value;
    }

    handleLastNameChange(event){
        this.lastName = event.target.value;
    }

    handleLastNameKeydown(event){
        if (event.key === 'Tab') {
            this.lastName = event.target.value;
        }
    }

    handleVerificationCodeChange(event){
        // this.verificationCode = event.target.value;
    }

    handleContactPointChange(event){
        this.selectedContactPoint = event.detail.value;
    }

    // A Error Panel
    get showErrorPanel() {
        return this.isError;
    }

    // B Student Details Panel
    get showStudentDetailsPanel() {
        return this.showStudentDetails; 
    }

    // B.1 student field enable/disable
    get isStudentDetailFieldsDisabled() {
        return this.studentDetailsConfirmed;
    }

    // C.1 Login Panel
    get showLoginPanel() {
        return !this.studentDetailsConfirmed;
    }

    // C.1.1 Login Button enable/disable
    get isLoginButtonDisabled() {

        let isButtonDisabled = false;

        if (this.isLoading === true) {
            return true;
        }
        
        if (this.studentId == null || this.studentId === '') {
            return true;
        }

        if (this.dateOfBirth == null || this.dateOfBirth === '') {
            return true;
        }

        if (this.lastName == null || this.lastName === '') {
            return true;
        }

        return isButtonDisabled;
    }

    // C.2 Send Code Panel
    get showSendCodePanel() {
        return this.studentDetailsConfirmed && !this.codeSent;
    }

    // C.2.1 Send Code button enable/disable
    get isSendCodeButtonDisabled() {

        let isButtonDisabled = true;

        if (this.isLoading === true) {
            return true;
        }

        if (this.isPositiveInteger(this.selectedContactPoint)) {
            return false;
        }

        return isButtonDisabled;
    }

    // C.2.2 Prompt multiple contact point selection
    get isMultipleContactPoints() {
        return (this.contactPoints && this.contactPoints.length > 1);
    }
    
    // C.3 Verify Code Panel
    get showVerifyCodePanel() {
        return this.studentDetailsConfirmed && this.codeSent;
    }

    // C.3.1 Verify button enable/disable
    get isVerifyCodeButtonDisabled() {

        let isButtonDisabled = true;

        if (this.isLoading === true) {
            return true;
        }

        if (this.isValidVerificationCode) {
            return false
        }

        return isButtonDisabled;
    }

    // C.4 Only show if not mono name
    get showFirstNameInput() {
        return !this.isMonoName;
    }

    get contactPointType() {

        if (this.contactPoint === null) {
            return "mobile number";
        }

        if (this.contactPoint.includes('@')) {
            return "email address";
        }

        return "mobile number";
    }

    get contactPointIcon() {
        if (this.contactPoint === null) {
            return "utility:phone_portrait";
        }

        if (this.contactPoint.includes('@')) {
            return "utility:email";
        }

        return "utility:phone_portrait";
    }
}