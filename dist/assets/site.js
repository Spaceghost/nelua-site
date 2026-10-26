const $=(s,r=document)=>r.querySelector(s),$$=(s,r=document)=>[...r.querySelectorAll(s)];
const profiles={
  hybrid:{measured:true,exports:55,delegated:15,missing:30,label:'Hybrid coverage',detail:'Nelibc provides 813 of 1,471 tracked musl function symbols in at least one hybrid profile. The remaining surface can come from the host libc or is still unimplemented.'},
  standalone:{measured:false,label:'Separate runtime profile',detail:'Standalone is a separate profile with its own completion gaps. The 1,471-symbol chart tracks hybrid coverage only; standalone percentages are not shown here.'}
};
$$('[data-profile]').forEach(button=>button.addEventListener('click',()=>{
  const profile=profiles[button.dataset.profile];
  $$('[data-profile]').forEach(other=>other.setAttribute('aria-pressed',String(other===button)));
  const chart=$('.progress'),note=$('[data-standalone-note]');
  if(profile.measured){
    chart?.classList.remove('hide');note?.classList.add('hide');
    const bar=$('[data-profile-bar]');
    if(bar){bar.children[0].style.width=profile.exports+'%';bar.children[1].style.width=profile.delegated+'%';bar.children[2].style.width=profile.missing+'%'}
    $('[data-profile-label]').textContent=profile.label;
  }else{chart?.classList.add('hide');note?.classList.remove('hide')}
  $('[data-profile-detail]').textContent=profile.detail;
}));
$$('[data-copy]').forEach(button=>button.addEventListener('click',async()=>{
  try{await navigator.clipboard.writeText(button.dataset.copy);const toast=$('.toast');if(toast){toast.textContent='Copied to clipboard';toast.classList.add('show');setTimeout(()=>toast.classList.remove('show'),1400)}}
  catch{button.textContent='Select and copy'}
}));
const table=$('[data-symbol-table]');
if(table){
  const body=$('tbody',table),search=$('[data-symbol-search]'),filters=$$('[data-symbol-filter]');let all=[],status='all';
  const draw=()=>{
    const query=search.value.trim().toLowerCase();
    const rows=all.filter(row=>(status==='all'||row.status===status)&&(!query||row.api.toLowerCase().includes(query)||row.exports.toLowerCase().includes(query)));
    body.innerHTML=rows.slice(0,120).map(row=>`<tr><td>${row.api.replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}</td><td><span class="status ${row.status}">${row.status}</span></td><td>${row.exports?row.exports.split(';').join(' · '):'—'}</td></tr>`).join('');
    $('[data-result-count]').textContent=`${rows.length.toLocaleString()} matching symbols${rows.length>120?' · first 120 shown':''}`;
  };
  fetch('../assets/api-coverage.json').then(response=>response.json()).then(rows=>{all=rows;draw()}).catch(()=>{$('[data-result-count]').textContent='Symbol inventory could not be loaded.'});
  search.addEventListener('input',draw);
  filters.forEach(button=>button.addEventListener('click',()=>{status=button.dataset.symbolFilter;filters.forEach(other=>other.setAttribute('aria-pressed',String(other===button)));draw()}));
}
const year=$('[data-year]');if(year)year.textContent=new Date().getFullYear();
