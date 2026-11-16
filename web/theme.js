// GENERATED from tokens.toml by tools/gen.py. Edit tokens.toml (or templates/web/), then run `make`.
// The day/night switch for brand pages. Load it in <head> (before the page renders) so a saved
// choice applies without a flash. Any element with data-theme-toggle switches the mode; its label
// comes from brand.css, so this script never touches page markup (Elm's virtual DOM owns that).
(function () {
  var KEY = "zd-theme";
  var root = document.documentElement;
  try {
    var saved = localStorage.getItem(KEY);
    if (saved === "dark" || saved === "light") root.setAttribute("data-theme", saved);
  } catch (e) { /* storage blocked: follow the system setting */ }

  function current() {
    var set = root.getAttribute("data-theme");
    if (set) return set;
    return window.matchMedia && matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  document.addEventListener("click", function (event) {
    var target = event.target;
    if (!(target instanceof Element) || !target.closest("[data-theme-toggle]")) return;
    var next = current() === "dark" ? "light" : "dark";
    root.setAttribute("data-theme", next);
    try { localStorage.setItem(KEY, next); } catch (e) { /* not saved, still switched */ }
  });
})();
