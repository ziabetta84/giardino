// docs/js/tabs.js
// Delega generica per gruppi di tab (.tab-btn / .tab-content con data-tab/id
// corrispondenti). Usato da edit-pianta.html e agente.html per l'editor specie.

document.addEventListener("click", (e) => {
  if (!e.target.classList.contains("tab-btn")) return;

  const tab = e.target.dataset.tab;

  document.querySelectorAll(".tab-btn").forEach(btn =>
    btn.classList.toggle("active", btn === e.target)
  );

  document.querySelectorAll(".tab-content").forEach(box =>
    box.classList.toggle("active", box.id === tab)
  );
});
