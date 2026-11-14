// Botão "Console do RustFS da turma" com login automático.
// Em todo link com data-rustfs-entrar, o clique pede ao RustFS credenciais
// temporárias (STS AssumeRole) com o usuário da turma e abre o console pela
// rota de callback, que aceita essas credenciais no fragmento da URL.
// Se algo falhar, abre a tela de login normal do console.
(function () {
  var S3 = "https://lake-aulas-mackenzie.afonsolelis.tech";
  var CONSOLE = "https://lake-console-aulas-mackenzie.afonsolelis.tech/rustfs/console/";
  var USUARIO = "turma-mackenzie";
  var SENHA = "Mack5fb631Dados2026";
  var REGIAO = "us-east-1";
  var enc = new TextEncoder();

  function hex(buf) {
    return Array.prototype.map.call(new Uint8Array(buf), function (b) {
      return ("0" + b.toString(16)).slice(-2);
    }).join("");
  }
  function sha256(texto) { return crypto.subtle.digest("SHA-256", enc.encode(texto)); }
  function hmac(chave, texto) {
    var k = typeof chave === "string" ? enc.encode(chave) : chave;
    return crypto.subtle.importKey("raw", k, { name: "HMAC", hash: "SHA-256" }, false, ["sign"])
      .then(function (ck) { return crypto.subtle.sign("HMAC", ck, enc.encode(texto)); });
  }

  function credenciaisTemporarias() {
    var corpo = "Action=AssumeRole&Version=2011-06-15&DurationSeconds=28800";
    var agora = new Date().toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
    var dia = agora.slice(0, 8);
    var host = new URL(S3).host;
    var escopo = dia + "/" + REGIAO + "/sts/aws4_request";
    var hashCorpo;
    return sha256(corpo).then(function (h) {
      hashCorpo = hex(h);
      var canonico = [
        "POST", "/", "",
        "content-type:application/x-www-form-urlencoded",
        "host:" + host,
        "x-amz-content-sha256:" + hashCorpo,
        "x-amz-date:" + agora, "",
        "content-type;host;x-amz-content-sha256;x-amz-date",
        hashCorpo
      ].join("\n");
      return sha256(canonico);
    }).then(function (hc) {
      var assinar = ["AWS4-HMAC-SHA256", agora, escopo, hex(hc)].join("\n");
      return hmac("AWS4" + SENHA, dia)
        .then(function (k) { return hmac(k, REGIAO); })
        .then(function (k) { return hmac(k, "sts"); })
        .then(function (k) { return hmac(k, "aws4_request"); })
        .then(function (k) { return hmac(k, assinar); });
    }).then(function (assinatura) {
      return fetch(S3 + "/", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-Amz-Date": agora,
          "X-Amz-Content-Sha256": hashCorpo,
          "Authorization": "AWS4-HMAC-SHA256 Credential=" + USUARIO + "/" + escopo +
            ", SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date, Signature=" + hex(assinatura)
        },
        body: corpo
      });
    }).then(function (r) {
      if (!r.ok) throw new Error("AssumeRole " + r.status);
      return r.text();
    }).then(function (xml) {
      var doc = new DOMParser().parseFromString(xml, "application/xml");
      function campo(nome) {
        var el = doc.getElementsByTagName(nome)[0];
        return el ? el.textContent : "";
      }
      var c = {
        accessKey: campo("AccessKeyId"),
        secretKey: campo("SecretAccessKey"),
        sessionToken: campo("SessionToken"),
        expiration: campo("Expiration")
      };
      if (!c.accessKey || !c.secretKey || !c.sessionToken) throw new Error("resposta sem credenciais");
      return c;
    });
  }

  document.querySelectorAll("a[data-rustfs-entrar]").forEach(function (link) {
    link.addEventListener("click", function (ev) {
      ev.preventDefault();
      // A aba é aberta já no clique para o navegador não bloquear o pop-up.
      var aba = window.open("about:blank", "_blank");
      credenciaisTemporarias().then(function (c) {
        var destino = CONSOLE + "auth/oidc-callback/#" + new URLSearchParams(c).toString();
        if (aba) { aba.location.href = destino; } else { window.location.href = destino; }
      }).catch(function () {
        var destino = CONSOLE + "auth/login/";
        if (aba) { aba.location.href = destino; } else { window.location.href = destino; }
      });
    });
  });
})();
