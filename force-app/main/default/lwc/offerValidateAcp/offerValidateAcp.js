import { LightningElement, api } from 'lwc';


export default class OfferValidateAcp extends LightningElement {
    @api offerLapseDate;

    @api acps;
    initialRender = true;

    constructor() {
       super();
    }

    @api isInputsValid() {
        let acpUpdateCard = this.template.querySelectorAll('c-offer-wizard-a-c-p-update-card');
        const isAcpCardsValid = [...acpUpdateCard].reduce((validSoFar, acpCard) => {
                return validSoFar && acpCard.isInputsValid();
        }, true);
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
        return allValid && isAcpCardsValid;
    }

    @api getOfferLapseDate() {
        return this.offerLapseDate;
    }

    @api getAcpCardUpdates() {
        let acpUpdateCard = this.template.querySelectorAll('c-offer-wizard-a-c-p-update-card');
        let acpUpdateResults = [];
        acpUpdateCard.forEach(acpCard => {
            acpUpdateResults.push(acpCard.acp);
        });
        console.log('acpUpdateResults: ' + JSON.stringify(acpUpdateResults));
        return acpUpdateResults;
    }

    handleLapseDateInputChange(event) {
        this.offerLapseDate = event.target.value;
        console.log("offerLapseDate value: " + event.target.value);
    }

}