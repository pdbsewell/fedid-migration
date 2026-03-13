({
    waitForImages: function(component) {
        return new Promise(function(resolve, reject) {
            const printArea = component.find("printArea").getElement();
            const images = printArea.getElementsByTagName('img');
            const totalImages = images.length;
            let loadedImages = 0;

            // If no images, resolve immediately
            if (totalImages === 0) {
                resolve();
                return;
            }

            // Function to check if all images are loaded
            function imageLoaded() {
                loadedImages++;
                if (loadedImages === totalImages) {
                    resolve();
                }
            }

            // Add load event listener to each image
            for (let i = 0; i < images.length; i++) {
                if (images[i].complete) {
                    imageLoaded();
                } else {
                    images[i].addEventListener('load', imageLoaded);
                    images[i].addEventListener('error', imageLoaded); // Handle failed loads
                }
            }

            // Set a timeout in case images take too long
            setTimeout(function() {
                if (loadedImages < totalImages) {
                    resolve(); // Resolve anyway after 8 seconds
                }
            }, 8000);
        });
    },

    printAndClose: function(component) {
        console.log('printAndClose');

        window.print();
        setTimeout(window.close, 100);

    }
})