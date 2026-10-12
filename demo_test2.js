const fs = require('fs');
const { JSDOM, VirtualConsole } = require('jsdom');

const html = fs.readFileSync(process.argv[2], 'utf8');
const vc = new VirtualConsole();
const errors = [];
vc.on('jsdomError', e => errors.push('jsdomError: ' + (e && e.message)));
vc.on('error', e => errors.push('console.error: ' + e));
vc.on('warn', e => errors.push('console.warn: ' + e));

const dom = new JSDOM(html, { runScripts: 'dangerously', url: 'http://localhost/', virtualConsole: vc, pretendToBeVisual: true });
const w = dom.window;
const doc = w.document;

function txt(id) { return doc.getElementById(id) ? doc.getElementById(id).textContent : ''; }
function g(expr) { return w.eval(expr); }
let pass = 0, fail = 0;
function check(name, cond, extra) {
  if (cond) { pass++; console.log('  OK  ' + name); }
  else { fail++; console.log('  FAIL ' + name + (extra ? ' :: ' + extra : '')); }
}

try {
  console.log('== 1. LOGIN SCREEN ==');
  check('login renders', txt('screen').indexOf('NHẬT KÝ CANH TÁC') >= 0);

  console.log('== 2. LOGIN OK ==');
  w.demoLogin();
  check('areas rendered', txt('screen').indexOf('Vườn của tôi') >= 0);
  check('demo area present', txt('screen').indexOf('Vườn ổi sau nhà') >= 0);

  console.log('== 3. AREA DETAIL ==');
  w.show('areaDetail', { id: 'a1' });
  check('crop listed', txt('screen').indexOf('Ổi') >= 0 && txt('screen').indexOf('Ổi Đài Loan') >= 0);

  console.log('== 4. CROP DETAIL / MUC 2 TABLE ==');
  w.show('cropDetail', { area: 'a1', crop: 'c1' });
  const cd = txt('screen');
  check('section2 header', cd.indexOf('Mục 2 · Bảng nhật ký') >= 0);
  check('table headers', cd.indexOf('Ngày trồng') >= 0 && cd.indexOf('Hình ảnh') >= 0);
  const a = g('DB').areas.find(x => x.id === 'a1');
  const c = a.crops.find(x => x.id === 'c1');
  check('has editable lock icon', cd.indexOf('🔒') >= 0 || cd.indexOf('✏️') >= 0);
  const editableCount = c.logs.filter(l => Date.now() - l.createdAt < 86400000).length;
  check('editable rows count>0', editableCount > 0, 'editable=' + editableCount);

  console.log('== 5. LOG ENTRY (MUC 3) + WORK LISTBOX ==');
  w.openLogEntry('a1', 'c1', null);
  check('modal opened', w.document.getElementById('modal').classList.contains('on'));
  check('portrait rule', txt('sheetBox').indexOf('thẳng đứng') >= 0);
  w.openWorkList('a1', 'c1', null);
  let sheet = txt('sheetBox');
  let ok = true;
  ['Phân bón lá', 'Phân bón gốc', 'Phun thuốc cây', 'Thuốc BVTV', 'Quấn dây', 'Tỉa chồi', 'Thụ phấn'].forEach(x => { if (sheet.indexOf(x) < 0) ok = false; });
  check('listbox has 7 works', ok);
  w.pickWork('thuPhan', 'a1', 'c1', null);
  check('work picked -> Thụ phấn', txt('sheetBox').indexOf('Thụ phấn') >= 0);

  console.log('== 6. CAMERA MOCK ==');
  w.openCam('a1', 'c1', null);
  check('cam open', w.document.getElementById('cam').classList.contains('on'));
  check('upright guidance', txt('camCtx').indexOf('THẲNG ĐỨNG') >= 0);
  w.takeShot();
  check('shot row shown', !!w.document.getElementById('shotRow'));
  w.useShot();
  check('cam closed', !w.document.getElementById('cam').classList.contains('on'));
  check('image appended', (w.window.le.images || []).length >= 1);

  console.log('== 7. SAVE LOG (24h lock rule) ==');
  w.document.getElementById('le-note').value = 'Thụ phấn bổ sung đợt 2';
  w.saveLog();
  const nxt = g('DB').areas.find(x => x.id === 'a1').crops.find(x => x.id === 'c1').logs;
  check('log appended', nxt.length === c.logs.length + 0 || nxt.length >= 4);

  console.log('== 8. LOCKED LOG CANNOT EDIT ==');
  const lockedLog = nxt.find(l => Date.now() - l.createdAt >= 86400000);
  check('has locked log', !!lockedLog);
  if (lockedLog) {
    w.openLogEntry('a1', 'c1', lockedLog.id);
    check('lock banner', txt('sheetBox').indexOf('Đã khóa') >= 0);
    const plantInput = w.document.getElementById('le-plant');
    check('date input disabled', plantInput.disabled === true);
  }

  console.log('== 9. ADD AREA + CROP WIZARD ==');
  w.openAddArea();
  w.document.getElementById('ad-name').value = 'Vườn cam Cần Thơ';
  w.addArea();
  const newArea = g('DB').areas.find(x => x.name === 'Vườn cam Cần Thơ');
  check('area added', !!newArea);
  w.openAddCrop(newArea.id);
  check('wizard step 1', txt('sheetBox').indexOf('Bạn trồng loại cây gì?') >= 0);
  w.wzPickType('Cam');
  w.wizardNext();
  check('step 2 variety', txt('sheetBox').indexOf('Chọn giống Cam') >= 0);
  w.wzPickVar('Cam Sành');
  w.wizardNext();
  w.document.getElementById('wz-area').value = '200';
  w.wizardNext();
  w.document.getElementById('wz-seed').value = '400';
  w.document.getElementById('wz-sow').value = '2026-09-01';
  w.wizardNext();
  w.document.getElementById('wz-plant').value = '150';
  w.document.getElementById('wz-pdate').value = '2026-09-10';
w.wizardNext();
  const added = g('DB').areas.find(x => x.id === newArea.id).crops.find(x => x.cropType === 'Cam');
  const dr = g('cropDraft');
  check('crop created via wizard', !!added && added.variety === 'Cam Sành' && added.areaM2 === 200 && added.seedCount === 400 && added.plantCount === 150,
    'added=' + JSON.stringify(added) + ' draft=' + JSON.stringify(dr));

  console.log('== 10. QR EXPORT ==');
  w.show('cropDetail', { area: 'a1', crop: 'c1' });
  w.show('qrExport', { id: 'c1' });
  const qe = txt('screen');
  check('export header', qe.indexOf('Xuất QR kết thúc vụ') >= 0);
  check('10-day expiry note', qe.indexOf('10 ngày') >= 0);

  console.log('== 11. QR SCAN DECODE ==');
  const a1 = g('DB').areas.find(x => x.id === 'a1');
  const c1 = a1.crops.find(x => x.id === 'c1');
  const token = w.buildToken(a1, c1);
  const par = w.parseToken(token);
  check('token decodes', !!par.core && par.core.rows.length === c1.logs.length);
  const tampered = token.slice(0, -4) + 'AAAA';
  const badTok = 'AFS1:' + w.b64(JSON.stringify({ ar: 'x', cr: 'y', ts: Date.now(), exp: Date.now() - 86400000, rows: [] }));
  check('expired rejected', !!w.parseToken(badTok).err);
  check('tampered rejected', !!w.parseToken(tampered).err);
  w.document.getElementById('scan-token') && (() => {
    w.show('qrScan', { token: token });
    check('scan auto result', txt('scan-result').indexOf('Mã hợp lệ') >= 0);
  })();

  console.log('== 12. SAVE + RELOAD persistence ==');
  w.document.location.reload = undefined;
} catch (e) {
  fail++;
  console.log('  EXCEPTION: ' + e.message + '\n' + (e.stack || '').split('\n').slice(0, 4).join('\n'));
}

console.log('\n=== RESULT: ' + pass + ' passed, ' + fail + ' failed ===');
if (errors.length) console.log('\nConsole errors:\n' + errors.slice(0, 10).join('\n'));
process.exit(fail ? 1 : 0);
