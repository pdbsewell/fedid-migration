import { LightningElement, api } from 'lwc';
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';
import sortUPOrder from '@salesforce/apex/StudyPreferenceService.sortUPOrder';

export default class Drag_Drop_Sorting extends LightningElement {

 @api selectedUPList;
 @api studyPlanText;
 @api appId;
 loadingData;
 needsPreReq = false;
 Data = [];
 showSaveButton = false;
 dragVal ='';

 removeUnitPreference(event){
    var val = event.detail.id;
    var target = event.target;
    this.c = true;
    var remItem  = '';
    this.selectedUPList.forEach((item)=>{
        if(item.UnitCode == target.name) 
        {
            remItem = item;  
             if(item.PreReq=='color:#FF0000')
            {
                this.needsPreReq = false;
            }
        }
    })
    const index = this.selectedUPList.indexOf(remItem)
    var def = [...this.selectedUPList];
  
    var ooo = def.splice(index, 1);
    this.selectedUPList = def;

    const removedUnit = remItem;
    //Send back to the parent
    const dispatchEvent = new CustomEvent('removeitem', {
        detail: { removedUnit }
    });
    this.dispatchEvent(dispatchEvent);
    this.loadingData = false;
 }

 connectedCallback(){
    if(!this.selectedUPList){
        this.selectedUPList = [...this.Data]
    }
}

 renderedCallback() {
   this.showSaveButton = this.selectedUPList.length>0?true:false;
    this.selectedUPList.forEach((item)=>{
        if(item.PreReq == 'color:#FF0000')
        {
            this.needsPreReq = true;

           return;
        }
    })


}

Change(event){
    this.Data = event.detail.join(', ');
}

 DragStart(event) {
    event.target.classList.add('drag')
    //fix here? 
    this.dragVal = event.target.textContent;
}

DragOver(event) {
   // console.log('DragOver dragtext=='+event.target.textContent);
    event.preventDefault()
    return false
}

Drop(event) {
        event.stopPropagation()
    
        const Element = this.template.querySelectorAll('.Items')
        //fix here
        const DragValName = this.dragVal; //this.template.querySelector('.drag').textContent
        const DropValName = event.target.textContent
    
        if(DragValName === DropValName){ return false }
        var rowDragName = '';
        this.selectedUPList.forEach((item)=>{
            if(item.UnitCode == DragValName)
            {
                rowDragName = item;
            }
        })
        var rowDropName = '';
        this.selectedUPList.forEach((item)=>{
            if(item.UnitCode == DropValName)
            {
                rowDropName = item;
            }
        })
        const index = this.selectedUPList.indexOf(rowDropName)
        this.selectedUPList = this.selectedUPList.reduce((acc, curVal, CurIndex) => {

            if(CurIndex === index){
                return  [...acc, rowDragName, curVal];
            }
            else if(curVal !== rowDragName){
                return [...acc, curVal]

            }
            return acc
        }, [])

        Element.forEach(element => {
            element.classList.remove('drag')
        })
        console.log(JSON.stringify('1this.selectedUPList='+JSON.stringify(this.selectedUPList)))
        let str ='';
        console.log('hey')
        sortUPOrder({records: JSON.stringify(this.selectedUPList)}).then(res=>console.log(res));
        console.log('hey1')

        /*sortUPOrder({records : JSON.stringify(this.selectedUPList)}).then(result => {
            console.log(result)
            this.saving = false;
        }).catch(err => {
            console.log(err)
            this.saving = false;
        })*/
        return this.selectedUPList
        }
    }