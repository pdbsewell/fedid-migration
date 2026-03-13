import { LightningElement, api, track } from 'lwc';

export default class AddApplicationCoursePreferenceWizardResult extends LightningElement {
    @api courseOffering;
    @api isSelected;
    @api cardClass;
    @api selectedAttendanceModeType;
    
    @api isCurrent;
    
    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        this.cardClass = 'slds-card slds-card_boundary slds-m-around_xx-small result-card';

        if(!this.selectedAttendanceModeType){
            this.isCurrent = true;
            this.cardClass = 'slds-card slds-card_boundary slds-m-around_xx-small';
            this.selectedAttendanceModeType = this.convertAttendanceTypeName(this.courseOffering.Attendance_Type__c) + ' - ' + this.convertAttendanceModeName(this.courseOffering.Attendance_Mode__c);
        }
    }

    //toggle selected
    toggleSelected(){
        if(!this.isCurrent){
            this.isSelected = !this.isSelected;
            
            //Send back details about the selected card
            const parameters = {
                'courseOfferingId' : this.courseOffering.Id,
                'selected' : this.isSelected
            };
            this.dispatchEvent(new CustomEvent('select', {
                detail: { parameters }
            }));

            //set class based on state
            if(this.isSelected){
                this.cardClass = 'slds-card slds-card_boundary slds-m-around_xx-small result-card-selected';
            }else{
                this.cardClass = 'slds-card slds-card_boundary slds-m-around_xx-small result-card';
            }
        }
    }

    //unselect the card from parent
    @api
    unselectCard(){
        if(!this.isCurrent){
            this.isSelected = false;
            this.cardClass = 'slds-card slds-card_boundary slds-m-around_xx-small result-card';
        }
    }

    /* for converting attendance mode friendly name */
    convertAttendanceModeName(attendanceMode){
        let name;
        switch(attendanceMode) {
            case 'IN':
                name = 'On Campus';
                break;
            case 'EX':
                name = 'Off Campus';
                break;
            case 'MO':
                name = 'Online';
                break;
            case 'MM':
                name = 'Multi Modal';
                break;
            default:
        }

        return name;
    }

    /* for converting attendance type friendly name */
    convertAttendanceTypeName(attendanceType){
        let name;
        switch(attendanceType) {
            case 'FT':
                name = 'Full time';
                break;
            case 'PT':
                name = 'Part time';
                break;
            default:
        }

        return name;
    }
}