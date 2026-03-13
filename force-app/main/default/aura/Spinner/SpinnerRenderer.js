({ 
    afterRender: function(component, helper) { 
        console.log('component.get("v.type")'+component.get("v.type"));
        var svg = component.find(component.get("v.type"));
        var width = component.get("v.width");
        var height = component.get("v.height");
        var color = component.get("v.color");
        console.log('change 11');
        console.log('svg.getElement() line 9 SpinnerRenderer.js '+svg.getElement());
        if(svg.getElement()!==null)
        {
            var value = svg.getElement().innerText; 
            console.log('change 12');
            value = value.replace(/wwww/g, width); 
            value = value.replace(/hhhh/g, height); 
            value = value.replace(/cccc/g, color);
            svg.getElement().innerHTML = value;
            console.log('spinner loaded sucessfully');
            helper.showHideSpinner(component); 
        }
	}
})