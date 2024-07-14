function trigger_image(img) {
  var imgs = img.parentNode.parentNode.getElementsByTagName("img");
  var halos = document.getElementById("halo-list").children;
  var n = 0;
  
  // Reset all but img
  for (var i=0, l=halos.length; i<l; i++) {
	if (imgs[i]!=img) {
	  imgs[i].style.outline = "";
	  halos[i].style.display = "none";
	}
	else {
	  n=i;
	}
  }
  
  // If img isn't triggered trigger it
  if (halos[n].style.display=="none") {
	img.style.outline = "2px solid blue";
	halos[n].style.display = "block";
  }
  // Else reset it too
  else {
	img.style.outline = "";
	halos[n].style.display = "none";
  }
  
}