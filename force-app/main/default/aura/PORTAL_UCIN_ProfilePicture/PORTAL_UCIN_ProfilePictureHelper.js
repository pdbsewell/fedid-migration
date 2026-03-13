({
    setOrientationInfo : function(component, profilePictureVersionDataBase64) {
        var exif = EXIF.readFromBinaryFile(base64ToArrayBuffer(profilePictureVersionDataBase64));
        function base64ToArrayBuffer (base64) {
            var binaryString = atob(base64);
            var len = binaryString.length;
            var bytes = new Uint8Array(len);

            for (var i = 0; i < len; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }
            return bytes.buffer;
        }
        component.set('v.orientation', exif.Orientation);
    },

    setPictureInfo : function(component, helper, profilePictureInfoMap) {
        if (profilePictureInfoMap != undefined && profilePictureInfoMap != null) {
            var contentDocId = profilePictureInfoMap.profilePictureId;
            var profilePictureVersionDataBase64 = profilePictureInfoMap.profilePictureVersionDataBase64;

            // based on recordId, get the image base64 encoded value at server side.
            // based on base64 value and external js library, get orientation value.
            // based on orientation value, add css to rotate image.
            helper.setOrientationInfo(component, profilePictureVersionDataBase64);
            var baseURL = component.get("v.baseURL");
            component.set('v.pictureSrc', baseURL + '/sfc/servlet.shepherd/version/download/' + contentDocId);
            component.set('v.profilePictureId', contentDocId);
        } else {
            component.set('v.pictureSrc', $A.get('$Resource.Portal_DefaultImage'));
            component.set('v.profilePictureId', '');
        }
    },
})