const fadeUpdate = (element, newValue, updateFunc) => {
  element.classList.add("fade");
  updateFunc();
  // Assuming whole animation duration == 1s
  setTimeout(() => {
    element.classList.remove("fade");
  }, 1000);
};

const getDiff = (newState, oldState) => {
  const diff = {};
  Object.keys(newState).forEach((key) => {
    if (newState[key] !== oldState[key]) {
      diff[key] = {
        old: oldState[key],
        new: newState[key],
      };
    }
  });
  return diff;
};


function getImgSource(character){
  const char = "./assets/" + character.toLowerCase() + ".png";
  return char;
}

const drawDiffToDom = (diff) => {
  Object.keys(diff).forEach((key) => {
    const element = document.querySelector(`#${key}`);
    if (!element) {
      return;
    } // skip fields not used in DOM

    const newValue = diff[key]["new"];
    const oldValue = diff[key]["old"];


    // Most elements are straightforward to overwrite
    let updateFunc = () => {
      element.innerHTML = newValue;

    };

    // Country needs to be converted from code to flag emoji

    if (key === "p1character"){
      document.getElementById("p1charimg").src = getImgSource(newValue);
      p1char.classList.add("fade");
      updateFunc();
      // Assuming whole animation duration == 1s
      setTimeout(() => {
        p1char.classList.remove("fade");
      }, 1000);

    }
    if (key === "p2character"){
      document.getElementById("p2charimg").src = getImgSource(newValue);
      updateFunc();
      // Assuming whole animation duration == 1s
      setTimeout(() => {
        p2char.classList.remove("fade");
      }, 1000);
    }

    fadeUpdate(element, newValue, updateFunc);
  });
};

const applyNewState = (newState) => {
  // first calculate just what has changed
  const diff = getDiff(newState, window.STATE);

  // then only draw the changed stuff to DOM, complete with animation
  drawDiffToDom(diff);

  // advance the global state
  window.STATE = newState;
};

const fetchHeaders = new Headers();
fetchHeaders.append("pragma", "no-cache");
fetchHeaders.append("cache-control", "no-cache");
const fetchInit = {
  method: "GET",
  headers: fetchHeaders,
};
const pollState = () => {
  fetch("state.json", fetchInit)
    .then((response) => response.json())
    .then(applyNewState);
};

/*
 * ACTUAL CODE FLOW STARTS HERE
 */
window.STATE = {}; // state singleton, globally accessible
pollState(); // immediately populate data to avoid empty values on page load
setInterval(pollState, 1500);
