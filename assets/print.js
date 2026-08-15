/* ==========================================================================
   print.js  -  Exportar PDF nos materiais
   Vanilla, sem dependencias. Funciona em file:// e em GitHub Pages.
   Estilos correspondentes: assets/styles.css, secoes 14 e 15.
   ========================================================================== */

(function () {
  'use strict';

  var CLASSE_RODAPE = 'print-source';

  /* Monta, uma unica vez, o rodape de procedencia que so aparece no papel. */
  function montarRodape() {
    if (document.querySelector('.' + CLASSE_RODAPE)) return;

    var rodape = document.createElement('footer');
    rodape.className = 'print-only ' + CLASSE_RODAPE;

    var titulo = document.createElement('span');
    titulo.textContent = document.title;
    rodape.appendChild(titulo);

    /* Em file:// o caminho local nao ajuda o leitor: so publicamos origem web. */
    if (window.location.protocol !== 'file:') {
      var origem = document.createElement('span');
      origem.textContent = window.location.href;
      rodape.appendChild(origem);
    }

    var data = document.createElement('span');
    data.textContent = 'Gerado em ' + new Date().toLocaleDateString('pt-BR', {
      day: '2-digit', month: '2-digit', year: 'numeric'
    });
    rodape.appendChild(data);

    document.body.appendChild(rodape);
  }

  /* Remove o rodape apos imprimir, para nao duplicar na proxima exportacao. */
  function removerRodape() {
    var rodape = document.querySelector('.' + CLASSE_RODAPE);
    if (rodape && rodape.parentNode) rodape.parentNode.removeChild(rodape);
  }

  function iniciar() {
    var gatilhos = document.querySelectorAll('[data-print]');
    if (!gatilhos.length) return;   /* guarda defensiva: pagina sem botao */

    Array.prototype.forEach.call(gatilhos, function (gatilho) {
      gatilho.addEventListener('click', function () {
        montarRodape();             /* fallback p/ navegador sem beforeprint */
        window.print();
      });
    });

    window.addEventListener('beforeprint', montarRodape);
    window.addEventListener('afterprint', removerRodape);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', iniciar);
  } else {
    iniciar();                      /* script com defer ou no fim do <body> */
  }
})();
