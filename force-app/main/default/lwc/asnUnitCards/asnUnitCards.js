import { LightningElement, track, api } from 'lwc';
import asnResource from '@salesforce/resourceUrl/ASN';
export default class AsnUnitCards extends LightningElement {
	@track
	unitCode;
	@track
	unitTitle;
	@track
	creditPoints;
	@track
	mark;
	@track
	grade;
	@track
	isSelectedwdraw;
	@track
	isSelectedsfr;
	@track
	unitAttemptId;
	@track
	newOutcome;
	@track
	isNotAvailable = false;
	//
	@api
	unitattempt;
	@api
	isConfirm = false;
	@api
	isreadonly = false;
	isRenderProcessed = false;
	@api
	allUnitAttempts;
	sfrlogo = asnResource + '/ASN/redo-24px.svg';
	wdnlogo = asnResource + '/ASN/call_missed_outgoing-black-24dp.svg';

	/* Constructor step defaults */
	constructor() {
		super();
		this.isSelectedwdraw = false;
		this.isSelectedsfr = false;
		this.isRenderProcessed = false;
	}
	/* Getters */
	get cssClassSFR() {
		return this.isSelectedsfr ? 'slds-button button-success active' : 'slds-button button-inactive inactive';
	}
	get cssClassWdraw() {
		return this.isSelectedwdraw ? 'slds-button button-destructive active' : 'slds-button button-inactive inactive';
	}
	get iconNameSFR() {
		let iconTyp = 'utility:preview';
		if (this.isSelectedwdraw === true) {
			iconTyp = 'utility:hide';
		}
		return this.isSelectedsfr ? 'utility:success' : iconTyp;
	}
	get iconNameWdraw() {
		let iconTyp = 'utility:preview';
		if (this.isSelectedsfr === true) {
			iconTyp = 'utility:hide';
		}
		return this.isSelectedwdraw ? 'utility:success' : iconTyp;
	}
	get isShowConfirm() {
		return this.isConfirm;
	}
	/**
	 * public Methods
	 */
	connectedCallback() {
		this.populateUnitAttempt(this.unitattempt);
	}
	renderedCallback() {
		//Disable the contents on Render
		if (this.isreadonly && this.isRenderProcessed === false) {
			this.disableAllActions(true);
			this.isRenderProcessed = true;
		}
	}
	/* populates variables  from unitAttempt Object */
	populateUnitAttempt(value) {
		if (value !== null) {
			if (value.hasOwnProperty('unitCode')) {
				this.unitCode = value.unitCode;
			}
			if (value.hasOwnProperty('unitTitle')) {
				this.unitTitle = value.unitTitle;
			}
			if (value.hasOwnProperty('acvdCreditPoints')) {
				this.creditPoints = value.acvdCreditPoints;
			}
			if (value.hasOwnProperty('mark')) {
				this.mark = value.mark;
			}
			if (value.hasOwnProperty('grade')) {
				this.grade = value.grade;
			}
			if (value.hasOwnProperty('unitAttemptId')) {
				this.unitAttemptId = value.unitAttemptId;
			}
			if (value.hasOwnProperty('newoutcome')) {
				this.newOutcome = value.newoutcome;
			}
		}
	}

	clickHandler(event) {
		let targetBtn = event.currentTarget.name;
		let btnSFR = this.template.querySelector('button[name=sfrBtn]');
		let btnWdraw = this.template.querySelector('button[name=wdrawBtn]');
		let objReq = null;
		try {
			if (targetBtn === 'sfrBtn') {

				this.isSelectedsfr = !this.isSelectedsfr;
				this.isSelectedwdraw = false;

				objReq = { recordId: this.unitAttemptId, type: 'SFR', sfrvalue: this.isSelectedsfr, wdrvalue: this.isSelectedwdraw };

			} else if (targetBtn === 'wdrawBtn') {

				this.isSelectedwdraw = !this.isSelectedwdraw;
				this.isSelectedsfr = false;
				if (this.isSelectedwdraw === false) {

					// check if other UA is converted to SFR
					for (var i = 0; i < this.allUnitAttempts.length; i++) {
						if (this.unitAttemptId != this.allUnitAttempts[i].unitAttemptId) {
							if (this.allUnitAttempts[i].convertToSFR === true) {
								this.isSelectedsfr = true;
							}
						}
					}
				}
				objReq = { recordId: this.unitAttemptId, type: 'Withdraw', sfrvalue: this.isSelectedsfr, wdrvalue: this.isSelectedwdraw };
			}
			if (objReq !== null) {
				const stdChangeEvt = new CustomEvent('studentchange', { detail: objReq });
				this.dispatchEvent(stdChangeEvt);
			}
		} catch (error) {
			console.error(error);
		}
	}
	/* Public Functions */
	@api
	disableAllActions(value) {
		let btnSFR = this.template.querySelector('button[name=sfrBtn]');
		let btnWdraw = this.template.querySelector('button[name=wdrawBtn]');
		if (value === true) {
			btnWdraw.setAttribute('disabled', true);
			btnSFR.setAttribute('disabled', true);
		} else {
			btnWdraw.removeAttribute('disabled');
			btnSFR.removeAttribute('disabled');
		}
		this.isNotAvailable = true;
	}
	@api
	setSFRState(value) {
		let btnSFR = this.template.querySelector('button[name=sfrBtn]');
		let btnWdraw = this.template.querySelector('button[name=wdrawBtn]');
		if (this.isSelectedwdraw === false) {
			if (value === true) {
				this.isSelectedsfr = true;
				this.isSelectedwdraw = false;

			} else {
				this.isSelectedsfr = false;
				this.isSelectedwdraw = false;

			}
		}
	}
	@api
	setWdrawState() {
		let btnSFR = this.template.querySelector('button[name=sfrBtn]');
		let btnWdraw = this.template.querySelector('button[name=wdrawBtn]');
		this.isSelectedwdraw = true;
		this.isSelectedsfr = false;

	}
	@api
	resetCard() {
		let btnSFR = this.template.querySelector('button[name=sfrBtn]');
		let btnWdraw = this.template.querySelector('button[name=wdrawBtn]');
		if (btnSFR) {
			btnSFR.removeAttribute('disabled');
		}
		if (btnWdraw) {
			btnWdraw.removeAttribute('disabled');
		}
		this.isSelectedsfr = false;
		this.isSelectedwdraw = false
	}
}