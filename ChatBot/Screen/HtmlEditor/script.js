let optionsButtons = document.querySelectorAll(".option-button");
let advancedOptionButton = document.querySelectorAll(".adv-option-button");
let fontName = document.getElementById("fontName");
let fontSizeRef = document.getElementById("fontSize");
let writingArea = document.getElementById("text-input");
let formatButtons = document.querySelectorAll(".format");

//List of fontlist
let fontList = [
    "Arial",
    "Verdana",
    "Times New Roman",
    "Garamond",
    "Georgia",
    "Courier New",
    "cursive",
];

//Initial Settings
const initializer = () => {
    
    highlighter(formatButtons, false);
    //create options for font names
    fontList.map((value) => {
        let option = document.createElement("option");
        option.value = value;
        option.innerHTML = value;
        fontName.appendChild(option);
    });
    
    //fontSize allows only till 7
    for (let i = 1; i <= 7; i++) {
        let option = document.createElement("option");
        option.value = i;
        option.innerHTML = i;
        fontSizeRef.appendChild(option);
    }
    
    //default size
    fontSizeRef.value = 3;
    convertTextToImages();
};

//main logic
const modifyText = (command, defaultUi, value) => {
    //execCommand executes command on selected text
    document.execCommand(command, defaultUi, value);
};

//For basic operations which don't need value parameter
optionsButtons.forEach((button) => {
    button.addEventListener("click", () => {
        modifyText(button.id, false, null);
    });
});

//options that require value parameter (e.g colors, fonts)
advancedOptionButton.forEach((button) => {
    button.addEventListener("change", () => {
        modifyText(button.id, false, button.value);
    });
});

//Highlight clicked button
const highlighter = (className, needsRemoval) => {
    className.forEach((button) => {
        button.addEventListener("click", () => {
            //needsRemoval = true means only one button should be highlight and other would be normal
            if (needsRemoval) {
                let alreadyActive = false;
                
                //If currently clicked button is already active
                if (button.classList.contains("active")) {
                    alreadyActive = true;
                }
                
                //Remove highlight from other buttons
                highlighterRemover(className);
                if (!alreadyActive) {
                    //highlight clicked button
                    button.classList.add("active");
                }
            } else {
                //if other buttons can be highlighted
                button.classList.toggle("active");
            }
        });
    });
};

const highlighterRemover = (className) => {
    className.forEach((button) => {
        button.classList.remove("active");
    });
};

// Function to convert image URLs in <a> tags to <img> tags(不正常)
const convertLinksToImages = () => {
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
};

// Function to set cursor to the end of the content
const setCursorToEnd = (element) => {
    let range = document.createRange();
    let sel = window.getSelection();
    range.selectNodeContents(element);
    range.collapse(false);
    sel.removeAllRanges();
    sel.addRange(range);
};

window.onload = initializer();
