let optionsButtons = document.querySelectorAll(".option-button");
let advancedOptionButton = document.querySelectorAll(".adv-option-button");
let fontName = document.getElementById("fontName");
let fontSizeRef = document.getElementById("fontSize");
let writingArea = document.getElementById("text-input");
let formatButtons = document.querySelectorAll(".format");
let bottomButtons = document.querySelectorAll(".bottom-button");
let showCodeButton = document.getElementById('show-code');

// List of font list
let fontList = [
    "Arial",
    "Verdana",
    "Times New Roman",
    "Garamond",
    "Georgia",
    "Courier New",
    "cursive",
];

// Initial Settings
function initializer() {
    highlighter(formatButtons, false);
    // Create options for font names
    fontList.map((value) => {
        let option = document.createElement("option");
        option.value = value;
        option.innerHTML = value;
        fontName.appendChild(option);
    });
    // FontSize allows only till 7
    for (let i = 1; i <= 7; i++) {
        let option = document.createElement("option");
        option.value = i;
        option.innerHTML = i;
        fontSizeRef.appendChild(option);
    }
    // Default size
    fontSizeRef.value = 3;
}

// Main logic
function modifyText(command, defaultUi, value) {
    // execCommand executes command on selected text
    document.execCommand(command, defaultUi, value);
}

// For basic operations which don't need value parameter
optionsButtons.forEach((button) => {
    button.addEventListener("click", () => {
        modifyText(button.id, false, null);
    });
});

// Options that require value parameter (e.g colors, fonts)
advancedOptionButton.forEach((button) => {
    button.addEventListener("change", () => {
        modifyText(button.id, false, button.value);
    });
});

// Highlight clicked button
function highlighter(className, needsRemoval) {
    className.forEach((button) => {
        button.addEventListener("click", () => {
            // needsRemoval = true means only one button should be highlight and other would be normal
            if (needsRemoval) {
                let alreadyActive = false;
                // If currently clicked button is already active
                if (button.classList.contains("active")) {
                    alreadyActive = true;
                }
                // Remove highlight from other buttons
                highlighterRemover(className);
                if (!alreadyActive) {
                    // Highlight clicked button
                    button.classList.add("active");
                }
            } else {
                // If other buttons can be highlighted
                button.classList.toggle("active");
            }
        });
    });
}

function highlighterRemover(className) {
    className.forEach((button) => {
        button.classList.remove("active");
    });
}

// Function to convert image URLs in <a> tags to <img> tags (不正常)
function convertLinksToImages() {
    let textInput = document.getElementById("text-input");
    // Define regex pattern to find image URLs
    const imagePattern = /(https?:\/\/.*\.(?:png|jpg|jpeg|gif))/i;
    // Find all <a> tags within the #text-input element
    let links = textInput.querySelectorAll("a");
    links.forEach(link => {
        let url = link.href;
        // Check if the href matches the image pattern
        if (imagePattern.test(url)) {
            // Create a new <img> element
            let imgTag = document.createElement("img");
            imgTag.src = url;
            imgTag.alt = "Image";
            imgTag.style.maxWidth = "100%";
            imgTag.style.height = "auto";
            // Replace the link with the image
            link.parentNode.replaceChild(imgTag, link);
        }
    });
    // Optionally, set the cursor to the end of the content
    setCursorToEnd(textInput);
}

// Function to set cursor to the end of the content
function setCursorToEnd(element) {
    let range = document.createRange();
    let sel = window.getSelection();
    range.selectNodeContents(element);
    range.collapse(false);
    sel.removeAllRanges();
    sel.addRange(range);
}

bottomButtons.forEach((button) => {
    button.addEventListener("click", () => {
        postMessage(button.id);
    });
});

let active = false;
showCodeButton.addEventListener("click", () => {
	showCodeButton.dataset.active = !active;
	active = !active
	if(active) {
        console.log("show code active  " + writingArea.innerHTML)
		writingArea.textContent = writingArea.innerHTML;
		writingArea.setAttribute('contenteditable', false);
	} else {
        console.log("show code not active")
		writingArea.innerHTML = writingArea.textContent;
		writingArea.setAttribute('contenteditable', true);
	}
});

function postMessage(id) {
    console.log("postMessage: " + id);
    /// for iOS
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.task) {
        window.webkit.messageHandlers.task.postMessage(id);
    }
}

function adjustInputHeight() {
    const container = document.querySelector('.container');
    const options = document.querySelector('.options');
    const textInput = document.getElementById('text-input');

    const containerRect = container.getBoundingClientRect();
    const optionsRect = options.getBoundingClientRect();
    const height = `calc(100vh - ${containerRect.top + optionsRect.height + 20}px)`;
    console.log("adjustInputHeight" + height)
    textInput.style.height = height
}

window.addEventListener('resize', adjustInputHeight);
// window.addEventListener('DOMContentLoaded', adjustInputHeight);

window.addEventListener('focusin', (event) => {
    if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA' || event.target.isContentEditable) {
        console.log("keyboard-open")
        document.body.classList.add('keyboard-open');
    }
});

window.addEventListener('focusout', () => {
    console.log("keyboard-close")
    document.body.classList.remove('keyboard-open');
});

window.onload = initializer();
