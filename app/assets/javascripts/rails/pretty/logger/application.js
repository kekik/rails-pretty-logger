(function () {
  function confirmMessage(element) {
    return element.dataset.turboConfirm || element.dataset.confirm;
  }

  document.addEventListener("click", function (event) {
    var element = event.target.closest("a[data-confirm], a[data-turbo-confirm]");

    if (!element) return;

    var message = confirmMessage(element);
    if (message && !window.confirm(message)) event.preventDefault();
  });

  document.addEventListener("submit", function (event) {
    var message = confirmMessage(event.target);

    if (message && !window.confirm(message)) event.preventDefault();
  });
})();
