import { LightningElement, api } from 'lwc';

export default class DocumentViewerFrame extends LightningElement {
    @api fileUrl;
    @api fileBlob;
    @api requestedSplitPages;
    @api fileType;

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
    }
   
    //Sends file data to the viewer
    frameLoad(){
        try{
            let pdfjsframe = this.template.querySelector('iframe');
			if(this.fileType === 'pdf'){
				pdfjsframe.contentWindow.postMessage(this.fileBlob,'*');	
            }else if(this.fileType === 'jpg'){
                let reader = new FileReader();
                reader.readAsDataURL(this.fileBlob); 
                reader.onloadend = function() {
                    let base64data = reader.result.replace('data:application/pdf;base64,', '');                     
                    pdfjsframe.contentWindow.postMessage(base64data,'*');
                }
            }
		}catch(error){
			// eslint-disable-next-line no-console
			console.log('Error: ' + error.message);
        }
    }

    get isHtmlFile(){
        return this.fileType === 'html';
    }
}