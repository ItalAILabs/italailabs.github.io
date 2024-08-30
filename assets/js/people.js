function show_info(person_a) {
  var person = person_a.parentNode.parentNode;
  var people = document.querySelectorAll('.person');
  var people_info = document.getElementById("people-info").children;
  
  // Hide all info except the selected person's
  for (var i=0, l=people.length; i<l; i++) {
	if (people[i]==person) {
	  people_info[i].style.display = "flex";
	}
	else {
	  people_info[i].style.display = "none";
	}
  }
  
  // Give some extra space between sections
  document.getElementById("just-padding").style.display = "flex";
  document.getElementById("just-more-padding").style.display = "flex";
}