// Adiciona um botão "Copiar" a cada elemento .copiavel da página.
document.querySelectorAll(".copiavel").forEach(function (bloco) {
  var botao = document.createElement("button");
  botao.className = "copiar";
  botao.type = "button";
  botao.textContent = "Copiar";
  botao.addEventListener("click", function () {
    var texto = bloco.querySelector("code").innerText;
    navigator.clipboard.writeText(texto).then(function () {
      botao.textContent = "Copiado";
      setTimeout(function () { botao.textContent = "Copiar"; }, 1500);
    });
  });
  bloco.appendChild(botao);
});
