import { LightningElement } from 'lwc';
import { wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getSessionStatus from '@salesforce/apex/FC_SessionController.getSessionStatus';
import getUserStatus from '@salesforce/apex/FC_SessionController.getUserStatus';

// importing Custom Label
import sessionRenewalInterval from '@salesforce/label/c.Session_Renewal_Interval';

export default class FC_sessionRenewal extends LightningElement {
  @track sessionStatus;

  connectedCallback() {
    getUserStatus()
      .then((result) => {
        if (result) {
          setInterval(this.checkSessionStatus.bind(this), sessionRenewalInterval); // Check session status every 110 minute or 6600000 milliseconds
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }

  checkSessionStatus() {
    getSessionStatus()
      .then((result) => {
        this.sessionStatus = result;
        if (this.sessionStatus.inactiveForOneHour) { 
          this.extendSession();
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }

  extendSession() {
    refreshApex(this.sessionStatus);
  }
}