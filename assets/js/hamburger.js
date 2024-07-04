function trigger_hamburger() {
  var x = document.getElementById("nav-links");
  var h = document.getElementById("hambar")
  if (x.style.display === "block") {
    x.style.display = "none";
	h.style.backgroundColor = "rgba(14, 40, 70, 0)";
  } else {
    x.style.display = "block";
	h.style.backgroundColor = "rgba(14, 40, 70, 255)";
  }
}