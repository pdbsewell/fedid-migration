import { LightningElement, api, wire } from 'lwc';
import * as util from 'c/util';
import getFile from '@salesforce/apex/OfferLightningEnabledClass.fetchAttachment';
import ConsoleCaseIcon from '@salesforce/resourceUrl/ConsoleCaseIcon';
import { loadStyle } from 'lightning/platformResourceLoader';
import static_resource from '@salesforce/resourceUrl/admission_pdf_assets'

export default class RenderPdf extends LightningElement {

    @api fileId;
    @api heightInRem;
    pdfData;
    
    get attachmentId(){
        loadStyle(this, static_resource + '/build/pdf.js');
        let urlParameter = util.urlParameter(window.location.href);
        let docuId = urlParameter.get('docuId');
        return docuId;
    }

    @wire(getFile, {attachmentId: '$attachmentId'})
    wiredAttachment({ error, data }) {
        if (data) {
            this.pdfData = data;
            this.onLoad();
        } else if (error) {
            console.log(error);
        }
    }

    onLoad() {
        console.log('attachmentId: ', this.fileId);
        if(this.attachmentId && this.pdfData){
            var iframe = this.template.querySelector("iframe");
            iframe.contentWindow.postMessage(this.pdfData, "*");
            //iframe.contentWindow.print();
            this.ready = true;
        }
    }
}