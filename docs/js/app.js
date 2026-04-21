const theme = localStorage.getItem("theme") || "auto";

if (theme === "dark") {
  document.documentElement.setAttribute("data-theme", "dark");
} else if (theme === "light") {
  document.documentElement.setAttribute("data-theme", "light");
} else {
  // auto
  if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
    document.documentElement.setAttribute("data-theme", "dark");
  }
}
