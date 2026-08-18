(function () {
  "use strict";

  var btn = document.getElementById("btn-health");
  var result = document.getElementById("health-result");

  if (!btn || !result) {
    return;
  }

  btn.addEventListener("click", function () {
    result.className = "health-result";
    result.textContent = "Verificando...";

    fetch("/health")
      .then(function (res) {
        if (!res.ok) {
          throw new Error("HTTP " + res.status);
        }
        return res.json();
      })
      .then(function (data) {
        result.className = "health-result ok";
        result.textContent = "OK — " + (data.status || "saudável");
      })
      .catch(function () {
        result.className = "health-result err";
        result.textContent = "Endpoint /health indisponível.";
      });
  });
})();
