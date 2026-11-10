import fs from 'node:fs';
import { chromium } from '@playwright/test';
const BASE='https://afonsolelis.github.io/aulas_mackenzie/';
const API='https://aulas-mackenzie-api.afonsolelis.tech';
const fs_=fs.readFileSync(process.argv[2],'utf8').split('\n').filter(l=>l && !l.startsWith('scripts/'));
const b=await chromium.launch(); let ruins=0;
for (const f of fs_) {
  const p=await (await b.newContext()).newPage();
  const errs=[]; let api=0, apiFalha=0, supa=0;
  p.on('console',m=>{ if(m.type()==='error') errs.push(m.text().slice(0,120)); });
  p.on('pageerror',e=>errs.push('JS: '+e.message.slice(0,120)));
  p.on('request',r=>{ if(r.url().includes('supabase')) supa++; });
  p.on('response',r=>{ if(r.url().startsWith(API)){ api++; if(r.status()>=400) apiFalha++; } });
  const r=await p.goto(BASE+f+'?v='+Date.now(),{waitUntil:'networkidle'}).catch(e=>null);
  await p.waitForTimeout(2500);
  const temCliente=await p.evaluate(()=>!!window.aulasApi);
  const st=r?r.status():'erro';
  const bom= st===200 && temCliente && !errs.length && !apiFalha && !supa;
  if(!bom) ruins++;
  console.log(`${bom?'ok   ':'FALHA'} ${f.split('/').slice(-2).join('/')} http=${st} cliente=${temCliente} api=${api} apiFalha=${apiFalha} supabase=${supa}${errs.length?' erros='+JSON.stringify(errs.slice(0,2)):''}`);
  await p.context().close();
}
await b.close(); console.log(ruins?`\n${ruins} página(s) com problema`:'\ntodas as páginas carregam sem erro');
