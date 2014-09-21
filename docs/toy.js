// Prepend child to element
Element.prototype.prependChild = function(child){
	this.insertBefore(child, this.firstChild);
}

// Execute on page load finished
window.addEventListener("load", function(evt){
	// Query html containers for contents table and sections
	var contents = document.getElementsByClassName("contents")[0];
		sections = document.getElementsByClassName("section");
	// Iterate through sections
	for(var i = 0; i < sections.length; ++i){
		var section = sections[i];
		// Add link to section in contents table
		var link = document.createElement("a");
		link.href = "#" + section.id;
		link.appendChild(document.createTextNode(section.id));
		link.className = "contents";
		contents.appendChild(link);
		// Add anchor to section
		var anchor = document.createElement("a");
		anchor.name = section.id;
		section.prependChild(anchor);
		// Set section title (text on top of section box)
		var title = document.createElement("span");
		title.appendChild(document.createTextNode(section.id));
		title.id = "section";
		section.parentNode.insertBefore(title, section);
	}
})