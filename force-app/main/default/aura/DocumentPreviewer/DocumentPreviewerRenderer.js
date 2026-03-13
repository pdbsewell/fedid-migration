({
	render : function(cmp, helper) {
        var ret = this.superRender();
        document.title = "Document Previewer";
        
        //set favicon
        var link = document.querySelector("link[rel*='icon']") || document.createElement('link');
        link.type = 'image/x-icon';
        link.rel = 'shortcut icon';
        link.href = '/resource/MonashFavicon';
        document.getElementsByTagName('head')[0].appendChild(link);

        return ret;
    }
})