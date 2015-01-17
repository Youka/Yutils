// Prepend child to element
Element.prototype.prependChild = function(child){
	this.insertBefore(child, this.firstChild);
}

// Get computed final style of element
Element.prototype.getStyle = function(){
	return this.currentStyle || window.getComputedStyle(this);
}

// Get width of browser scrollbar
function getScrollBarWidth(){
	// Barwidth not already known?
	if(!getScrollBarWidth.prototype.barWidth){
		// Create outer+inner box
		var outerBox = document.createElement("div"),
			innerBox = document.createElement("div");
		// Set box widths
		outerBox.style.width = "100px";
		innerBox.style.width = "100%";
		// Set outer box invisible (no effect on displayed elements)
		outerBox.style.visibility = "hidden";
		outerBox.style.position = "fixed";
		outerBox.style.left = 0;
		outerBox.style.top = 0;
		// Link boxes to parent elements (for data generation)
		outerBox.appendChild(innerBox);
		document.body.appendChild(outerBox);
		// Save scrollbar width
		outerBox.style.overflow = "scroll";
		var widthWithScrollBar = innerBox.offsetWidth;
		outerBox.style.overflow = "hidden";
		getScrollBarWidth.prototype.barWidth = innerBox.offsetWidth - widthWithScrollBar + "px";
		// Remove boxes (no further need)
		document.body.removeChild(outerBox);
	}
	// Return saved barwidth
	return getScrollBarWidth.prototype.barWidth;
}

// Add element padding/space for scrollbar to not cover content
function fixScrollBar(elem, direction){
	if((!direction || direction == "vertical") && elem.clientHeight < elem.scrollHeight){
		elem.style.paddingRight = getScrollBarWidth();
		elem.style.overflowX = "hidden";
	}
	if((!direction || direction == "horizontal") && elem.clientWidth < elem.scrollWidth){
		elem.style.paddingBottom = getScrollBarWidth();
		elem.style.overflowY = "hidden";
	}
}

// Execute on page load finished
window.addEventListener("load", function(evt){
	// Process contents table and sections
	var contents = document.getElementsByClassName("contents")[0];
		sections = document.getElementsByClassName("section");
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
		// Repeat last steps with subsections / functions
		var functions = section.getElementsByClassName("function"),
			lastLibrary = "";
		for(var j=0; j < functions.length; ++j){
			section = functions[j];
			// Extract function definition
			if(section.firstChild){
				var funcDef = section.firstChild.textContent;
				// Break function in chunks
				var assign = funcDef.indexOf("="),
					bracketOpen = funcDef.indexOf("("),
					bracketClose = funcDef.indexOf(")");
				if(bracketOpen != -1 && bracketClose != -1 && bracketOpen < bracketClose && bracketOpen > 0){
					var funcRet = assign != -1 ? funcDef.slice(0,assign).trim() : "",
						funcName = funcDef.slice(assign != -1 ? assign+1 : 0,bracketOpen).trim(),
						funcParam = funcDef.slice(bracketOpen+1,bracketClose).trim();
					// Add link to function in contents table
					link = document.createElement("a");
					link.href = "#" + funcName;
					link.appendChild(document.createTextNode(funcName));
					link.className = "subcontents";
					contents.appendChild(link);
					// Add function indention & library header to contents
					var libSeparator = funcName.indexOf(".");
					if(libSeparator != -1){
						var libName = funcName.slice(0, libSeparator);
						if(libName == libName.toUpperCase())
							link.style.paddingLeft = parseInt(link.getStyle().paddingLeft) * 3 + "px";
						else{
							if(lastLibrary != libName){
								var libLink = link.cloneNode(true);
								libLink.replaceChild(document.createTextNode(libName), libLink.firstChild);
								contents.insertBefore(libLink, link);
								lastLibrary = libName;
							}
							link.style.paddingLeft = parseInt(link.getStyle().paddingLeft) * 2 + "px";
						}
					}else
						lastLibrary = "";
					// Add anchor to section
					anchor = document.createElement("a");
					anchor.name = funcName;
					section.prependChild(anchor);
					// Style function definition
					var defStyle = document.createElement("span");
					if(funcRet.length > 0){
						var color = document.createElement("span");
						color.className = "function_return";
						color.appendChild(document.createTextNode(funcRet));
						defStyle.appendChild(color);
						defStyle.appendChild(document.createTextNode(" = "));
					}
					defStyle.appendChild(document.createTextNode(funcName + "("));
					var color = document.createElement("span");
					color.className = "function_parameters";
					color.appendChild(document.createTextNode(funcParam));
					defStyle.appendChild(color);
					defStyle.appendChild(document.createTextNode(")"));
					defStyle.className = "definition";
					section.replaceChild(defStyle,section.childNodes[1]);
				}
			}
		}
	}
	fixScrollBar(contents, "vertical");
	// Process code chunks
	var codes = document.getElementsByClassName("code");
	for(var i = 0; i < codes.length; ++i){
		var code = codes[i];
		if(code.tagName.toLowerCase() == "div" && code.lastChild){
			// Add linenumber cell to code
			var numberBar = document.createElement("td"),
				numberText = "1";
			for(var j=2; j<=code.lastChild.textContent.split("\n").length; ++j)
				numberText += "\n" + j;
			numberBar.appendChild(document.createTextNode(numberText));
			numberBar.className = "linenumbers";
			code.appendChild(numberBar);
			// Put code in own cell
			var codeText = document.createElement("td");
			codeText.appendChild(code.firstChild.cloneNode());
			code.replaceChild(codeText,code.firstChild);
			// Transfer padding from code box to cells
			var codeStyle = code.getStyle();
			numberBar.style.paddingLeft = codeStyle.paddingLeft,
			numberBar.style.paddingRight = codeStyle.paddingRight,
			numberBar.style.paddingTop = codeStyle.paddingTop,
			numberBar.style.paddingBottom = codeStyle.paddingBottom,
			codeText.style.paddingLeft = codeStyle.paddingLeft,
			codeText.style.paddingRight = codeStyle.paddingRight,
			codeText.style.paddingTop = codeStyle.paddingTop,
			codeText.style.paddingBottom = codeStyle.paddingBottom,
			code.style.padding = 0;
			// Add right space for vertical scrollbar (on appearance)
			fixScrollBar(code, "vertical");
			// Set code highlight
			code.addEventListener("mouseover", function(evt){
				evt.currentTarget.childNodes[1].style.display = "table-cell";
			})
			code.addEventListener("mouseout", function(evt){
				evt.currentTarget.childNodes[1].style.display = "none";
			})
		}
	}
})