import { LightningElement } from 'lwc';

/**CSV Export */
export function exportCSVFile(headers, totalData, fileTitle){

    if(!totalData || !totalData.length){
        return null;
    }
    const jsonObject = JSON.stringify(totalData);
    const result = convertToCSV(jsonObject, headers);
    if(result === null){
        return null;
    }
    const exportedFileName = fileTitle? fileTitle+'.csv':'FileExport.csv';
    if(navigator.msSaveBlob){
        navigator.msSaveBlob(blob, exportedFileName);
    }
    else{
        const link = window.document.createElement('a');
        link.href ='data:text/csv;charset=utf-8,'+encodeURIComponent(result);
        console.log('link.href--->'+link.href);
        link.target = '_blank';
        link.download = exportedFileName;
        link.click();
    }
    function convertToCSV(objArray, headers){
        const columnDelimiter =',';
        const lineDelimiter = '\r\n';
        //let resu = headers.map(a => a.label.replace(/,/g,''));
        const actualHeaderKey = headers.map(a => a.label.replace(/,/g,''));
        const headerToShow = headers.map(a => a.label.replace(/,/g,''));

        let str='';
        str += headerToShow.join(columnDelimiter);
        str += lineDelimiter;
        const data = typeof objArray != 'object' ? JSON.parse(objArray):objArray;

        data.forEach(obj=>{
            let line='';
            actualHeaderKey.forEach(key=>{
                if(line != ''){
                    line += columnDelimiter;
                }
                let strItem = obj[key] ? obj[key] + '' : '';
                line += strItem ? strItem.replace(/,/g,''):strItem;
            })
            str += line + lineDelimiter;
        })
        return str;
    }
}