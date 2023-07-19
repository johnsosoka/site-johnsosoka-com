(() => {
  // Theme switch
  const body = document.body;
  const lamp = document.getElementById("mode");

  const toggleTheme = (state) => {
    if (state === "dark") {
      localStorage.setItem("theme", "light");
      body.removeAttribute("data-theme");
    } else if (state === "light") {
      localStorage.setItem("theme", "dark");
      body.setAttribute("data-theme", "dark");
    } else {
      initTheme(state);
    }
  };

  // lamp.addEventListener("click", () =>
  //   toggleTheme(localStorage.getItem("theme"))
  // );

  // Blur the content when the menu is open
  const cbox = document.getElementById("menu-trigger");

  cbox.addEventListener("change", function () {
    const area = document.querySelector(".wrapper");
    const area2 = document.querySelector(".wrapper-2");
    this.checked
      ? area.classList.add("blurry") && area2.classList.add("blurry")
      : area.classList.remove("blurry") && area2.classList.remove("blurry");
    if (this.checked) {
      $("html").toggleClass("blurry");
    }
  });
})();
