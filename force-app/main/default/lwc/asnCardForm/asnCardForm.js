/**
 * Created by rcad0001 on 23/06/2020.
 */

/* LWC services */
import { LightningElement, api, track } from 'lwc';
/* Apex services */
import getTeachingPeriods from '@salesforce/apex/ASNController.retrieveStudentTeachingPeriods';
import retrieveUserContact from '@salesforce/apex/ASNController.retrieveUserContact';
import updateUnitAttempts from '@salesforce/apex/ASNController.updateUnitAttempts';
import encumberanceCheck from '@salesforce/apex/ASNController.checkEncumbrance';
import CONTACT_OBJ from '@salesforce/schema/Contact';
import USER_ID from '@salesforce/user/Id';
//Labels
import WhoShouldUseTheFormLabel from '@salesforce/label/c.ASN_Who_Uses_The_Form';
import howProcessWorksLabelP1 from '@salesforce/label/c.ASN_How_Process_Works_P1';
import howProcessWorksLabelP2 from '@salesforce/label/c.ASN_How_Process_Works_P2';
import selectTeachingPeriodH from '@salesforce/label/c.ASN_Select_TeachingPeriodH';
import StudentDetailsLabelH from '@salesforce/label/c.ASN_Student_DetailsH';
import encumberanceChkLabel from '@salesforce/label/c.ASN_Encumbrance_Check_Label';
import asnSFRDesc from '@salesforce/label/c.ASN_SFR_Description';
import asnWDNDesc from '@salesforce/label/c.ASN_WDN_Description';
import asnNCDesc from '@salesforce/label/c.ASN_NC_Description';
import noTeachingPeriod from '@salesforce/label/c.ASN_No_TeachingPeiods';
import noChanges from '@salesforce/label/c.ASN_NoChanges';
import asnTitle from '@salesforce/label/c.ASN_Title';
import asnSuppAU from '@salesforce/label/c.ASN_Support_Australia';
import asnSuppMal from '@salesforce/label/c.ASN_Support_Malaysia';
import asnSuppSA from '@salesforce/label/c.ASN_Support_South_Africa';
import asnSuppHeader from '@salesforce/label/c.ASN_Support_Header';
import sfrMaxPoints48 from '@salesforce/label/c.ASN_SFR_Max_48';
import sfrMaxPoints24 from '@salesforce/label/c.ASN_SFR_Max_24';
import asnCapLimitDesc from '@salesforce/label/c.ASN_Cap_Limit_Desc';

export default class AsnCardForm extends LightningElement {
    @track userId = USER_ID;
    @track conRecord = CONTACT_OBJ;
    @track teachingPeriodList = [];
    @track teachingPeriodListSize = 0;
    @track unitAttemptList = [];
    @track unitAttemptListSize = 0;
    @track convertToSFR = false;
    @track teachingPeriodName = '';
    @track selectedTeachingPeriod = '';
    @track picklistOptions;
    @track userFlow1 = false;
    @track userFlow2 = false;
    @track userFlow3 = false;
    @track userFlow4 = false;
    @track userFlow5 = false;
    @track userFlow6 = false;
    @track userFlow7 = false;
    @track userFlow8 = false;
    @track userFlow = '';
    @track isSummary = false;
    @track hasChanges = false;
    @track isLoading = false;
    @track defaultValue = '';
    @track chkEncumberance = false;
    @track emptyTeachingPeriod = false;
    @track maxSFRPointsAllowed = 0;
    @track remainingSFRPoints = 0;
    @track selectedTPCreditPoints = 0;
    //Store Old Values
    selectedTeachingPeriodObject;
    origunitAttemptList = [];
    label = {
        WhoShouldUseTheFormLabel,
        StudentDetailsLabelH,
        howProcessWorksLabelP1,
        howProcessWorksLabelP2,
        selectTeachingPeriodH,
        encumberanceChkLabel,
        noTeachingPeriod,
        asnSFRDesc,
        asnWDNDesc,
        asnNCDesc,
        noChanges,
        asnTitle,
        asnSuppAU,
        asnSuppMal,
        asnSuppSA,
        asnSuppHeader,
        sfrMaxPoints48,
        sfrMaxPoints24,
        asnCapLimitDesc
    };

    /*
    Method to retrieve Teaching Periods and child Unit Attempts under a certain Contact
     */
    connectedCallback() {
        //
        this.selectedTeachingPeriodObject = null;
        this.selectedTeachingPeriod = '';
        this.toggle()
            .then(rsp => {
                return retrieveUserContact({ userId: this.userId });
            })
            .then(conObj => {
                this.conRecord = conObj;
                return encumberanceCheck({ conId: this.conRecord.Id });
            })
            .then(result => {
                if (result) {
                    this.chkEncumberance = true;

                }
                return Promise.resolve('Complete');
            })
            .then(result => {
                return getTeachingPeriods({ conId: this.conRecord.Id });
            })
            .then(result => {
                this.teachingPeriodList = result;
                this.teachingPeriodListSize = result.length;
                if (this.teachingPeriodListSize == 0) {
                    this.emptyTeachingPeriod = true;
                }
                this.picklistOptions = this.populatePicklistOptions(this.teachingPeriodList);
                this.calculateSFRPoints(this.teachingPeriodList);
                this.showDefaultUnitAttempt();
                this.defaultValue = this.teachingPeriodName;
                return Promise.resolve('Complete');
            })
            .then(result => {
                return this.toggle();
            })
            .catch(err => {
                this.toggle();
                console.error(err);
            });
    }
    /*
    Method to get and set all the Teaching Periods as Select Options
     */
    get options() {
        var optionsList = [];
        for (var i = 0; i < this.teachingPeriodList.length; i++) {
            var option = { label: this.teachingPeriodList[i].teachingPeriodName, value: this.teachingPeriodList[i].teachingPeriodName }
            optionsList[i] = option;
        }
        return optionsList;
    }
    get hasselectedtc() {
        let isSelec = false;
        if (this.selectedTeachingPeriod !== '' && this.unitAttemptListSize > 0) {
            isSelec = true;
        }
        return isSelec;
    }
    get studentName() {
        let fname = '';
        if (this.conRecord) {
            fname = this.conRecord.FirstName + ' ' + this.conRecord.LastName;
        }
        return fname;
    }
    get studentNumber() {
        let snum = '';
        if (this.conRecord) {
            snum = this.conRecord.Person_ID__c;
        }
        return snum;
    }
    get studentEmail() {
        let snum = '';
        if (this.conRecord) {
            snum = this.conRecord.Email;
        }
        return snum;
    }
    get showNormalForm() {
        let isShow = false;
        if (this.isSummary == false) {
            if (this.userFlow1 || this.userFlow3) {
                isShow = true;
            }
        }
        return isShow;
    }
    get showSummaryView() {
        let isShow = false;
        if (this.isSummary == true) {
            if (this.userFlow1 || this.userFlow3) {
                isShow = true;
            }
        }
        return isShow;
    }

    toggle() {
        console.log('Toggled Loading...', this.isLoading);
        this.isLoading = !this.isLoading;
        return Promise.resolve(this.isLoading);
    }
    /**
     * DEtermines UserFLow3 specific disables
     *
     *
     * Revision     Russell C.      - Not needed as buttons not rendered for UserFlow3: ASNF-38
    processStudentTeachingPeriods() {
        let isDisabled = false;
        if (this.userFlow === 'UserFlow3') {
            isDisabled = true;
        }
        this.userFlow3 = isDisabled;
        let allCards = this.template.querySelectorAll('c-asn-unit-cards');
        if (allCards !== null) {
            allCards.forEach((card) => {
                card.disableAllActions(isDisabled);
            });
        }
    }
     */
    populatePicklistOptions(list) {
        let options =  list.map(function (element) {
            if(element.hasCompletedUnitAttempt == true){
                return { value: element.teachingPeriodName, label: element.teachingPeriodName }
            }
        })

        let optionList = [];

        options.forEach(element=>{
            if(element){
                optionList.push(element);
            }
        });

        return optionList;
    }
    resetValues() {
        this.selectedTeachingPeriod = '';
        this.unitAttemptList = [];
        this.unitAttemptListSize = 0;
        this.origunitAttemptList = [];
        this.selectedTeachingPeriodObject = null;
        this.userFlow1 = false;
        this.userFlow2 = false;
        this.userFlow3 = false;
        this.userFlow4 = false;
        this.userFlow5 = false;
        this.userFlow6 = false;
        this.userFlow7 = false;
        this.userFlow8 = false;
        this.isSummary = false;
        this.hasChanges = false;
    }
    /*
    Method to populate the data table with Unit Attempts based from the selected Teaching Period
     */
    showUnitAttempts(event) {
        try {
            this.resetHandler(event);
            this.resetValues();
            if (this.teachingPeriodList) {
                for (var i = 0; i < this.teachingPeriodList.length; i++) {
                    if (this.teachingPeriodList[i].teachingPeriodName === event.target.value) {
                        //Store original array
                        this.selectedTeachingPeriodObject = this.teachingPeriodList[i];
                        const nArr = JSON.parse(JSON.stringify(this.selectedTeachingPeriodObject.unitAttemptList));
                        this.origunitAttemptList = [...nArr];
                        this.teachingPeriodName = event.target.value
                        this.selectedTeachingPeriod = event.target.value;
                        this.unitAttemptList = this.teachingPeriodList[i].unitAttemptList;
                        this.unitAttemptListSize = this.teachingPeriodList[i].unitAttemptList.length;
                        this.userFlow = this.teachingPeriodList[i].userFlowNumber;
                        this.selectedTPCreditPoints = this.teachingPeriodList[i].totalCreditPoints;
                        switch (this.userFlow) {
                            case 'UserFlow1':
                                this.userFlow1 = true;
                                if(this.selectedTPCreditPoints > this.remainingSFRPoints){
                                    this.userFlow1 = false;
                                    this.userFlow8 = true;
                                }
                                break;
                            case 'UserFlow2':
                                this.userFlow2 = true;
                                break;
                            case 'UserFlow3':
                                this.userFlow3 = true;
                                break;
                            case 'UserFlow4':
                                this.userFlow4 = true;
                                break;
                            case 'UserFlow6':
                                this.userFlow6 = true;
                                break;
                            case 'UserFlow7':
                                this.userFlow7 = true;
                                break;
                            case 'UserFlow8':
                                this.userFlow8 = true;
                                break;
                        }
                        break;
                    }
                }
            }
        } catch (error) {
            console.error(error);
        }
    }

    showDefaultUnitAttempt() {
        this.resetValues();
        let hasElibileTeachingPeriod = false;
        if (this.teachingPeriodList && this.teachingPeriodList.length > 0) {
            for(var i=0;i<this.teachingPeriodList.length;i++){
                if(this.teachingPeriodList[i].hasCompletedUnitAttempt){
                    hasElibileTeachingPeriod = true;
                    //Store original array
                    this.selectedTeachingPeriodObject = this.teachingPeriodList[i];

                    const nArr = JSON.parse(JSON.stringify(this.teachingPeriodList[i].unitAttemptList));
                    this.origunitAttemptList = [...nArr];
                    this.teachingPeriodName = this.teachingPeriodList[i].teachingPeriodName;

                    this.selectedTeachingPeriod = this.teachingPeriodName;
                    this.unitAttemptList = this.teachingPeriodList[i].unitAttemptList;
                    this.unitAttemptListSize = this.teachingPeriodList[i].unitAttemptList.length;
                    this.userFlow = this.teachingPeriodList[i].userFlowNumber;
                    this.selectedTPCreditPoints = this.teachingPeriodList[i].totalCreditPoints;
                    switch (this.userFlow) {
                        case 'UserFlow1':
                            this.userFlow1 = true;
                            if(this.selectedTPCreditPoints > this.remainingSFRPoints){
                                this.userFlow1 = false;
                                this.userFlow8 = true;
                            }
                            break;
                        case 'UserFlow2':
                            this.userFlow2 = true;
                            break;
                        case 'UserFlow3':
                            this.userFlow3 = true;
                            break;
                        case 'UserFlow4':
                            this.userFlow4 = true;
                            break;
                        case 'UserFlow6':
                            this.userFlow6 = true;
                            break;
                        case 'UserFlow7':
                            this.userFlow7 = true;
                            break;
                        case 'UserFlow8':
                            this.userFlow8 = true;
                    }
                    break;
                }
            }
        }
        if(!hasElibileTeachingPeriod){
            this.emptyTeachingPeriod = true;
        }
    }

    handleUnitAttempChange(event) {
        if (event.detail.type === 'SFR') {
            let allCards = this.template.querySelectorAll('c-asn-unit-cards');
            if (allCards !== null) {
                allCards.forEach((card) => {
                    card.setSFRState(event.detail.sfrvalue);
                });
            }
        }

        this.unitAttemptList.forEach((ua) => {
            if (ua.unitAttemptId === event.detail.recordId) {
                ua.withDraw = event.detail.wdrvalue;
                ua.convertToSFR = event.detail.sfrvalue;
            }
            if (event.detail.type === 'SFR' && ua.withDraw === false) {
                ua.convertToSFR = event.detail.sfrvalue;
            }
        });
    }

    resetHandler(event) {
        //Reset main list
        if (this.unitAttemptList) {
            this.unitAttemptList.forEach((o, i) => {
                o.newoutcome = 'Keep result';
                o.withDraw = false;
                o.convertToSFR = false;
            });
        }
        if (this.selectedTeachingPeriodObject) {
            this.selectedTeachingPeriodObject.studentUpdated = false;
        }
        this.isSummary = false;
        //
        let allCards = this.template.querySelectorAll('c-asn-unit-cards');
        if (allCards !== null) {
            allCards.forEach((card) => {
                card.resetCard();
            });
        }
        this.hasChanges = false;
    }
    submitHandler(event) {
        //Get if there are changes 
        let hasChanges = false;
        this.unitAttemptList.forEach((o, i) => {
            let other = this.origunitAttemptList[i];
            o.newoutcome = 'Keep result';
            for (var key in o) {
                if (o.hasOwnProperty(key) && other.hasOwnProperty(key)) {
                    if (o[key] !== other[key] && key !== 'newoutcome') {
                        hasChanges = true;
                        break;
                    }
                }
            }
            if (hasChanges) {
                if (o.withDraw == true && o.convertToSFR == false) {
                    o.newoutcome = 'Withdraw (WDN)';
                } else if (o.withDraw === false && o.convertToSFR === true) {
                    o.newoutcome = 'Satisfied Faculty Requirements (SFR)';
                }
            }
        });

        this.selectedTeachingPeriodObject.studentUpdated = hasChanges;
        this.hasChanges = hasChanges;
        //Checks for another confirm from Page
        this.isSummary = true;
    }
    confirmBackHandler(evt) {
        this.isSummary = false;
        this.toggle()
            .then(() => {
                let allCards = this.template.querySelectorAll('c-asn-unit-cards');
                this.unitAttemptList.forEach((o, i) => {
                    if (o.withDraw === true) {
                        allCards[i].setWdrawState();
                    } else if (o.convertToSFR === true) {
                        allCards[i].setSFRState(true);
                    }
                });
            }).catch(err => {
                console.error(err);
            }).finally(() => {
                this.toggle();
            });
    }
    performApexSave(evt) {
        if (this.selectedTeachingPeriodObject) {
            this.toggle()
                .then(res => {
                    return updateUnitAttempts({
                        teachingPeriod: this.selectedTeachingPeriodObject,
                        conRecord: this.conRecord
                    });
                })
                .then(result => {
                    if (result) {
                        this.selectedTeachingPeriodObject.userFlowNumber = 'UserFlow4';
                        this.userFlow1 = false;
                        this.userFlow2 = false;
                        this.userFlow3 = false;
                        this.userFlow4 = false;
                        this.userFlow5 = true;
                        this.userFlow6 = false;
                        this.userFlow7 = false;
                        this.userFlow8 = false;
                        this.remainingSFRPoints = this.remainingSFRPoints - this.selectedTPCreditPoints;
                    }
                })
                .catch(err => {
                    console.error(err);
                })
                .finally(() => {
                    this.toggle();
                });

        }
    }

    calculateSFRPoints(tpList){
        let totalConvertedSFR = 0;
        let hasSpecialCourse = false;
        let maxPointAllowed;
        tpList.forEach((tp) => {
            totalConvertedSFR += tp.totalSFRConverted;
            if(tp.hasSpecialCourse){
                hasSpecialCourse = true;
            }
        });

        if(hasSpecialCourse){
            this.maxSFRPointsAllowed = this.label.sfrMaxPoints24;
        }
        else{
            this.maxSFRPointsAllowed = this.label.sfrMaxPoints48;
        }

        this.remainingSFRPoints = this.maxSFRPointsAllowed - totalConvertedSFR;
    }
}