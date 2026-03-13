import { LightningElement, wire } from 'lwc';
import getBannerDetail from '@salesforce/apex/HDRGraduateResearchBannerCC.getBannerDetail';

export default class myGRAPPBanner extends LightningElement {

    @wire(getBannerDetail) banner;

    get message() {
        return this.banner.data.Message__c+' '+this.banner.data.Additional_Message__c;
    }

    get urlText(){
        return this.banner && this.banner.data ? this.banner.data.URL_Text__c : 'Loading...';
    }

    get urlLink(){
        return this.banner && this.banner.data ? this.banner.data.URL_Link__c : 'Loading...';
    }

    maintenanceStartDate() {
        return this.banner && this.banner.data ? this.banner.data.Start_Date__c : 'Loading...';
    }

    maintenanceEndDate() {
        return this.banner && this.banner.data ? this.banner.data.End_Date__c : 'Loading...';
    }

    isPublished(){
        return this.banner && this.banner.data ? this.banner.data.Active__c : 'Loading...';
    }

    get expression() {

        let today = new Date();

        let plannedMaintenanceStartDate = new Date(this.maintenanceStartDate());
        let maintenanceStartDate = plannedMaintenanceStartDate;
        let plannedMaintenanceEndDate = new Date(this.maintenanceEndDate());
        let maintenanceEndDate = plannedMaintenanceEndDate;
        if (this.isPublished() && today >= new Date(maintenanceStartDate) && today <= new Date(maintenanceEndDate)) {
            return true;
        }
        else {
            return false;
        }
    }
}