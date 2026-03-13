import { LightningElement, track, api, wire } from 'lwc';
import CUSTOM_ICONS from '@salesforce/resourceUrl/CustomFileIcons';

export default class DmsFileCard extends LightningElement {
    @api documentDetail;

    //@track iconURL;
    //@track loaded = false;
    //@track vName = '';
    //@track vExtension = '';
    //@track vCreatedDate = '';
    //@track vCategory = '';

    connectedCallback() {
        
    }

    get loaded() {
        if (this.documentDetail != undefined && this.documentDetail != null) {
            return true;
        } else {
            return false;
        }
    }

    get name() {
        if (this.documentDetail != undefined) {
            return this.documentDetail.name;
        }
        return undefined;
    }

    get extension() {
        if (this.documentDetail != undefined) {
            if (this.documentDetail.extension != undefined && this.documentDetail.extension != null) {
                return this.documentDetail.extension;
            } else {
                return undefined;
            }
        }
        return undefined;
    }

    get iconURL() {
        if (this.documentDetail != undefined) {
            var ext = '';
            if (this.documentDetail.extension != undefined && this.documentDetail.extension != null) {
                ext = this.documentDetail.extension;
            }
            var type = '';
            //Determine correct icon
            switch (ext) {
                case 'txt':
                    type = CUSTOM_ICONS + '/CustomFileIcons/txt.svg';
                    break;
                case 'pdf':
                    type = CUSTOM_ICONS + '/CustomFileIcons/pdf.svg';
                    break;
                case 'word':
                    type = CUSTOM_ICONS + '/CustomFileIcons/doc.svg';
                    break;
                case 'doc':
                    type = CUSTOM_ICONS + '/CustomFileIcons/doc.svg';
                    break;
                case 'jpg':
                    type = CUSTOM_ICONS + '/CustomFileIcons/jpg.svg';
                    break;
                case 'png':
                    type = CUSTOM_ICONS + '/CustomFileIcons/png.svg';
                    break;
                case 'unknown':
                    type = CUSTOM_ICONS + '/CustomFileIcons/unknown.svg';
                    break;
                default:
                    type = CUSTOM_ICONS + '/CustomFileIcons/unknown.svg';
            }
            return type;
        }
        return undefined;
    }

    get createdDate() {
        if (this.documentDetail != undefined) {
            var convertedDate = '';
            // convert createdDate into user friendly format
            if (this.documentDetail.createdDate != undefined && this.documentDetail.createdDate != null && this.documentDetail.createdDate != '') {
                var splittedDate = this.documentDetail.createdDate.split(' ');
                convertedDate = splittedDate[0];
            }
            return convertedDate;
        }
        return undefined;
    }

    get location() {
        //if (this.documentDetail != undefined) {
            //var convertedDate = 'https://docs.google.com/gview?url=';
            // convert createdDate into user friendly format
            //if (this.documentDetail.location != undefined && this.documentDetail.location != null && this.documentDetail.location != '') {
                //if (this.extension === 'doc') {
                    //convertedDate = convertedDate + this.documentDetail.location + '&embedded=true';
                //} else {
                    //convertedDate = this.documentDetail.location;
                //}
            //}
            //return undefined;
        //}
        return this.documentDetail.location;
    }

    get category() {
        if (this.documentDetail != undefined) {
            return this.documentDetail.category;
        }
        return undefined;
    }

    get size() {
        if (this.documentDetail != undefined && this.documentDetail.size != undefined) {
            return this.formatBytes(this.documentDetail.size) ;
        }
        return undefined;
    }

    formatBytes(bytes, decimals = 2) {
        if (bytes === 0) return '0 Bytes';
    
        const k = 1024;
        const dm = decimals < 0 ? 0 : decimals;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    
        const i = Math.floor(Math.log(bytes) / Math.log(k));
    
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }

    get isPDF() {
        if (this.documentDetail != undefined && this.documentDetail.extension != undefined && this.documentDetail.extension === 'pdf') {
            return true;
        } else {
            return false;
        }
    }

    previewFile() {
        window.open(this.documentDetail.location, '_blank');
    }
}