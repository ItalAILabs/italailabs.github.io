function activate_webcam() {
  const webCamElement = document.getElementById("webCam");
  const webCamMessage = document.getElementById("webCamMessage");
  const webCamRequest = document.getElementById("webCamRequest");
  const webCam = new Webcam(webCamElement,"user");
    webCam.start()
	  .then(result => {
		if(webCamElement.style.display=="none") {
	      webCamElement.style.display = "block";
	      webCamMessage.style.display = "none";
		  webCamRequest.style.display = "none";
		}
	    console.log(result);
	  })
	  .catch(err => {
		if(webCamElement.style.display=="none") {
	      webCamMessage.innerText = "Sorry, but the demo can't proceed\nwithout access to the webcam";
		  webCamRequest.style.display = "block";
		}
		console.log(err);
	  });
}
activate_webcam();