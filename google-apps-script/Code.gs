/**
 * ============================================================================
 *  AFS · NHẬT KÝ CANH TÁC — Google Apps Script nhận dữ liệu từ app iOS
 * ============================================================================
 *  Nhiệm vụ: nhận JSON do app gửi (doPost) và ghi vào Google Sheet.
 *  Quy tắc: mỗi KHU VỰC (Area) = một sheet riêng.
 *  Trong mỗi sheet: thông tin khu vực + từng VỤ (cây trồng) kèm bảng NHẬT KÝ
 *  và ảnh minh chứng (gửi dạng base64, app đã co nhỏ sẵn).
 *
 *  CÀI ĐẶT:
 *   1. Mở Google Sheet đích → menu  Tiện ích mở rộng (Extensions) → Apps Script.
 *   2. Dán toàn bộ file này vào Code.gs (thay nội dung cũ).
 *   3. Bấm Triển khai (Deploy) → Triển khai mới (New deployment)
 *      → Loại: Ứng dụng web (Web app)
 *      → Thực thi dưới danh nghĩa: Tôi (Me)
 *      → Ai có quyền truy cập: Bất kỳ ai (Anyone)
 *      → Deploy → copy URL /exec → dán vào GoogleSheetService.swift
 *
 *  LƯU Ý: Đổi URL sau khi deploy thì phải cập nhật lại trong app.
 *
 *  GHI CHÚ ẢNH MINH CHỨNG (dạng LINK):
 *  - App gửi ảnh dạng base64 (đã co nhỏ ~480px, nén JPEG).
 *  - Script tải ảnh lên Google Drive (thư mục AFS_NhatKyCanhTac_Images/<areaKey>),
 *    mở quyền "ai có link đều xem được", rồi ghi LINK vào ô "Ảnh 1, Ảnh 2...".
 *    Bấm vào link trong Sheet để XEM hoặc TẢI ảnh trực tiếp.
 *  - Mỗi lần ghi lại (resync) thì xoá ảnh cũ trong thư mục của khu vực trước,
 *    tránh tạo file trùng lặp trên Drive.
 *  - CẦN quyền Google Drive khi cấp quyền cho script.
 * ============================================================================
 */

// ID của Google Sheet đích (lấy từ URL: /spreadsheets/d/<ID>/edit)
const SPREADSHEET_ID = '1Jk461TKiDvHJv6dh8LZQ6lBltJpWFkChzI2coYo4QQQ';

// Sheet ẩn lưu bảng ánh xạ areaKey (UUID) → tên sheet
const INDEX_SHEET = '_AFS_INDEX';

// Thư mục Google Drive gốc chứa ảnh minh chứng (mỗi khu vực = 1 thư mục con)
const IMAGE_FOLDER_NAME = 'AFS_NhatKyCanhTac_Images';

// Bảng màu & kiểu chữ cho trang tính (tông xanh nông nghiệp)
const THEME = {
  titleBg:    '#1B5E20', // xanh lá đậm  – nền tiêu đề
  sectionBg:  '#2E7D32', // xanh lá       – nền tiêu đề VỤ
  tableHeadBg:'#43A047', // xanh lá sáng  – nền tiêu đề bảng
  labelBg:    '#C8E6C9', // xanh nhạt     – nền ô nhãn
  infoBg:     '#F1F8E9', // xanh rất nhạt – nền ô giá trị
  zebraBg:    '#F7FBF3', // sọc so le
  border:     '#A5D6A7', // viền
  textDark:   '#1B2E1B',
  footer:     '#7A8B7A'
};
const FONT = 'Arial';

// ---------------------------------------------------------------------------
//  Entry points
// ---------------------------------------------------------------------------
function doGet() {
  return json_({ ok: true, service: 'AFS Nhat Ky Canh Tac', time: new Date().toISOString() });
}

/**
 * CHẠY HÀM NÀY ĐỂ CẤP QUYỀN (chạy lại bất cứ lúc nào cần cấp lại).
 * Cách làm: chọn hàm 'authorize' ở thanh trên → bấm Run (Chạy)
 *   → Review permissions → chọn tài khoản → Advanced → Go to project → Allow.
 *
 * Hàm này chủ động tạo thử 1 file trong thư mục ảnh rồi xoá đi, để Google
 * thực sự xin và ghi nhớ quyền GHI + chia sẻ Google Drive. Nếu chỉ ĐỌC thì
 * quyền upload ảnh sẽ bị thiếu, khiến script không tạo được LINK.
 *
 * Nếu bấm Run mà KHÔNG hiện bảng xin quyền (Google còn nhớ quyền cũ):
 *   vào https://myaccount.google.com/permissions → xoá quyền của project này,
 *   rồi quay lại Apps Script bấm Run lại.
 *
 * Sau khi cấp quyền: Deploy → Manage deployments → (bút chì) → Version: New version → Deploy.
 */
function authorize() {
  // 1) Quyền Google Sheets (đọc spreadsheet đích).
  var ss = getSpreadsheet_();
  Logger.log('OK đọc spreadsheet: ' + ss.getName());

  // 2) Quyền Google Drive: lấy hoặc tạo thư mục gốc chứa ảnh.
  var root;
  var found = DriveApp.getFoldersByName(IMAGE_FOLDER_NAME);
  root = found.hasNext() ? found.next() : DriveApp.createFolder(IMAGE_FOLDER_NAME);
  Logger.log('OK thư mục ảnh: ' + root.getName());

  // 3) Quyền GHI + CHIA SẺ Drive: tạo thử 1 file, mở quyền xem, rồi xoá.
  var probe = root.createFile(Utilities.newBlob('AFS', 'text/plain', 'afs_authorize_probe.txt'));
  try {
    probe.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    Logger.log('OK chia sẻ công khai file thử.');
  } catch (e) {
    Logger.log('CANH BAO: không đặt được quyền công khai: ' + e);
  }
  Logger.log('OK link file thử: https://drive.google.com/file/d/' + probe.getId() + '/view');
  probe.setTrashed(true);
  Logger.log('ĐÃ XOÁ file thử. HOÀN TẤT CẤP QUYỀN.');

  return 'Đã cấp quyền Google Sheets + Drive. Giờ vào Deploy → Manage deployments → New version → Deploy.';
}

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return json_({ ok: false, error: 'Empty request body' });
    }
    const body = JSON.parse(e.postData.contents);
    const action = body.action;

    if (action === 'syncArea')   return json_(syncArea_(body));
    if (action === 'deleteArea') return json_(deleteArea_(body));
    if (action === 'syncAll')    return json_(syncAll_(body));

    return json_({ ok: false, error: 'Unknown action: ' + action });
  } catch (err) {
    return json_({ ok: false, error: String(err && err.message ? err.message : err) });
  }
}

// ---------------------------------------------------------------------------
//  Helpers
// ---------------------------------------------------------------------------
function json_(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function getSpreadsheet_() {
  if (SPREADSHEET_ID && SPREADSHEET_ID.length > 0) {
    return SpreadsheetApp.openById(SPREADSHEET_ID);
  }
  return SpreadsheetApp.getActiveSpreadsheet();
}

/** Loại bỏ ký tự không hợp lệ cho tên sheet, giới hạn 100 ký tự. */
function sanitizeSheetName_(name) {
  var s = String(name || 'Khu vực').replace(/[\\\/\?\*\[\]:]/g, ' ').replace(/\s+/g, ' ').trim();
  if (!s) s = 'Khu vực';
  return s.substring(0, 100);
}

/** Lấy (hoặc tạo) sheet ẩn chứa bảng ánh xạ. */
function ensureIndex_(ss) {
  var idx = ss.getSheetByName(INDEX_SHEET);
  if (!idx) {
    idx = ss.insertSheet(INDEX_SHEET);
    idx.getRange(1, 1, 1, 5).setValues([['Key', 'SheetName', 'User', 'AreaName', 'UpdatedAt']]);
    idx.setFrozenRows(1);
    try { idx.hideSheet(); } catch (e) {}
  }
  return idx;
}

/** Tìm số dòng (1-based) trong index theo areaKey. Trả -1 nếu không có. */
function findIndexRow_(idx, key) {
  var last = idx.getLastRow();
  if (last < 2) return -1;
  var values = idx.getRange(2, 1, last - 1, 1).getValues();
  for (var i = 0; i < values.length; i++) {
    if (String(values[i][0]) === String(key)) return i + 2;
  }
  return -1;
}

/** Tạo tên sheet duy nhất từ tên khu vực. */
function uniqueSheetName_(ss, base) {
  var name = base;
  var n = 2;
  while (ss.getSheetByName(name)) {
    name = base + ' (' + n + ')';
    n++;
  }
  return name;
}

/** Đệm mọi dòng cho đủ số cột để setValues không lỗi. */
function padRows_(rows) {
  var width = 0;
  for (var i = 0; i < rows.length; i++) width = Math.max(width, rows[i].length);
  var out = [];
  for (var r = 0; r < rows.length; r++) {
    var row = rows[r].slice();
    while (row.length < width) row.push('');
    out.push(row);
  }
  return out;
}

/**
 * Chuẩn hoá chuỗi base64 ảnh: bỏ tiền tố "data:image/...;base64," (nếu có),
 * bỏ khoảng trắng/xuống dòng. Trả '' nếu không hợp lệ.
 */
function cleanImage_(b64) {
  if (typeof b64 !== 'string') return '';
  var i = b64.indexOf('base64,');
  if (i >= 0) b64 = b64.substring(i + 7);
  b64 = b64.replace(/\s+/g, '');
  return /^[A-Za-z0-9+/=]+$/.test(b64) ? b64 : '';
}

// ---------------------------------------------------------------------------
//  Google Drive: lưu ảnh & tạo link xem/tải
// ---------------------------------------------------------------------------

/** Lấy (hoặc tạo) thư mục Drive con cho một khu vực. */
function getAreaImageFolder_(areaKey) {
  var root;
  var found = DriveApp.getFoldersByName(IMAGE_FOLDER_NAME);
  root = found.hasNext() ? found.next() : DriveApp.createFolder(IMAGE_FOLDER_NAME);
  var sub = root.getFoldersByName(areaKey);
  return sub.hasNext() ? sub.next() : root.createFolder(areaKey);
}

/** Đưa toàn bộ file cũ vào thùng rác để resync không tạo file trùng. */
function clearFolder_(folder) {
  var files = folder.getFiles();
  while (files.hasNext()) {
    try { files.next().setTrashed(true); } catch (e) {}
  }
}

/**
 * Tải 1 ảnh base64 lên Drive, mở quyền xem cho mọi người có link.
 * Trả URL xem/tải (file view page) hoặc ném lỗi.
 */
function uploadImageLink_(folder, b64, name) {
  var blob = Utilities.newBlob(Utilities.base64Decode(b64), 'image/jpeg', name);
  var file = folder.createFile(blob);
  try {
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  } catch (e) {}
  var id = file.getId();
  return 'https://drive.google.com/file/d/' + id + '/view';
}


// ---------------------------------------------------------------------------
//  Core: ghi 1 khu vực
// ---------------------------------------------------------------------------
function syncArea_(body) {
  var ss = getSpreadsheet_();
  var area = body.area || {};
  var key = String(area.key || '');
  var areaName = String(area.name || 'Khu vực');
  var username = String(body.username || '');
  if (!key) return { ok: false, error: 'Missing area.key' };

  var idx = ensureIndex_(ss);
  var row = findIndexRow_(idx, key);
  var sheetName;

  if (row > 0) {
    sheetName = String(idx.getRange(row, 2).getValue());
  } else {
    sheetName = uniqueSheetName_(ss, sanitizeSheetName_(areaName));
    idx.appendRow([key, sheetName, username, areaName, new Date()]);
    row = idx.getLastRow();
  }

  var sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
  }

  // Nếu khu vực đổi tên và tên mới chưa bị chiếm → đổi tên sheet.
  var desired = sanitizeSheetName_(areaName);
  if (desired !== sheetName && !ss.getSheetByName(desired)) {
    try { sheet.setName(desired); sheetName = desired; } catch (e) {}
  }

  var imgStats = writeArea_(sheet, area, username);

  idx.getRange(row, 2).setValue(sheetName);
  idx.getRange(row, 3).setValue(username);
  idx.getRange(row, 4).setValue(areaName);
  idx.getRange(row, 5).setValue(new Date());

  return {
    ok: true,
    sheet: sheetName,
    crops: (area.crops || []).length,
    imagesLinked: imgStats.linked,
    imageErrors: imgStats.imageErrors
  };
}

function writeArea_(sheet, area, username) {
  var crops = area.crops || [];
  var rows = [];
  var logRows = [];      // { rowIndex, images[] }
  var infoRows = [];     // dòng nhãn/giá trị (khu vực và vụ)
  var sectionRows = [];  // dòng tiêu đề VỤ
  var spacerRows = [];   // dòng phân cách
  var tableHeaders = []; // dòng tiêu đề bảng nhật ký
  var tableBodies = [];  // { first, last, cols } vùng dữ liệu bảng

  // ----- Tiêu đề chính -----
  rows.push(['🌱  NHẬT KÝ CANH TÁC AFS']);
  var titleRow = rows.length;

  // ----- Thông tin khu vực -----
  function info(label, value) {
    if (value === undefined || value === null || value === '') return;
    rows.push([label, String(value)]);
    infoRows.push(rows.length);
  }
  info('KHU VỰC', area.name || '');
  info('ĐỊA CHỈ', area.address || '');
  info('GHI CHÚ', area.note || '');
  info('NGÀY TẠO', area.createdAt || '');
  info('NGƯỜI DÙNG', username);
  info('CẬP NHẬT', Utilities.formatDate(new Date(), 'Asia/Ho_Chi_Minh', 'dd/MM/yyyy HH:mm'));

  rows.push([]);
  spacerRows.push(rows.length);

  if (crops.length === 0) {
    rows.push(['Chưa có vụ canh tác nào trong khu vực.']);
  }

  crops.forEach(function (crop) {
    // ----- Tiêu đề vụ -----
    rows.push(['🌾  VỤ · ' + String(crop.cropType || '') + '  ·  ' + String(crop.variety || '')]);
    sectionRows.push(rows.length);

    function cinfo(label, value) {
      if (value === undefined || value === null || value === '') return;
      rows.push([label, String(value)]);
      infoRows.push(rows.length);
    }
    cinfo('GIỐNG', crop.variety || '');
    cinfo('DIỆN TÍCH (m²)', crop.areaM2 || '');
    cinfo('SỐ HẠT GIEO', crop.seedCount != null ? crop.seedCount : '');
    cinfo('NGÀY GIEO', crop.sowDate || '');
    cinfo('SỐ CÂY TRỒNG', crop.plantCount != null ? crop.plantCount : '');
    cinfo('NGÀY TRỒNG', crop.plantDate || '');

    var logs = crop.logs || [];
    var maxImgs = 0;
    logs.forEach(function (log) {
      var imgs = (log.images || []).map(cleanImage_).filter(function (s) { return s.length > 0; });
      if (imgs.length > maxImgs) maxImgs = imgs.length;
    });

    rows.push([]);
    spacerRows.push(rows.length);

    // ----- Bảng nhật ký -----
    var header = ['STT', 'Ngày trồng', 'Công việc', 'Ngày thực hiện', 'Ghi chú'];
    for (var h = 1; h <= maxImgs; h++) header.push('Ảnh ' + h);
    rows.push(header);
    tableHeaders.push(rows.length);

    var bodyFirst = rows.length + 1;
    if (logs.length === 0) {
      var empty = ['', '', '(chưa có nhật ký)', '', ''];
      for (var e = 0; e < maxImgs; e++) empty.push('');
      rows.push(empty);
    }
    logs.forEach(function (log, i) {
      var imgs = (log.images || []).map(cleanImage_).filter(function (s) { return s.length > 0; });
      var row = [
        String(i + 1),
        String(log.plantDate || ''),
        String(log.work || ''),
        String(log.performDate || ''),
        String(log.note || '')
      ];
      for (var j = 0; j < maxImgs; j++) row.push('');
      rows.push(row);
      if (imgs.length > 0) {
        logRows.push({ rowIndex: rows.length, images: imgs });
      }
    });
    tableBodies.push({ first: bodyFirst, last: rows.length, cols: 5 + maxImgs });
  });

  rows.push([]);
  spacerRows.push(rows.length);
  rows.push(['Báo cáo tạo tự động bởi ứng dụng AFS · ' +
             Utilities.formatDate(new Date(), 'Asia/Ho_Chi_Minh', 'dd/MM/yyyy HH:mm')]);
  var footerRow = rows.length;

  sheet.clear();

  // Xoá ảnh overlay còn sót (sheet.clear() không xoá ảnh đã gắn bằng insertImage).
  try { sheet.getImages().forEach(function (img) { img.remove(); }); } catch (e) {}

  var data = padRows_(rows);
  var lastCol = data.length > 0 ? data[0].length : 5;
  if (data.length > 0) {
    sheet.getRange(1, 1, data.length, lastCol).setValues(data);
  }

  // Tải ảnh minh chứng lên Google Drive rồi ghi LINK vào ô "Ảnh 1, Ảnh 2...".
  // Bấm vào link để XEM / TẢI ảnh.
  var imgCols = [];
  var imgCells = [];     // ô chứa link ảnh (để căn giữa)
  var linked = 0;
  var imageErrors = [];
  var folder = null;
  if (logRows.length > 0) {
    try {
      folder = getAreaImageFolder_(String(area.key || 'unknown'));
      clearFolder_(folder);
    } catch (e) {
      folder = null;
      imageErrors.push('drive:' + String(e && e.message ? e.message : e));
    }
  }
  logRows.forEach(function (lr) {
    lr.images.forEach(function (b64, j) {
      var col = 6 + j;
      try {
        if (!folder) throw new Error('Không tạo được thư mục Drive (thiếu quyền?)');
        var name = 'img_' + lr.rowIndex + '_' + col + '.jpg';
        var url = uploadImageLink_(folder, b64, name);
        var link = SpreadsheetApp.newRichTextValue()
          .setText('Xem / Tải ảnh')
          .setLinkUrl(url)
          .build();
        sheet.getRange(lr.rowIndex, col).setRichTextValue(link);
        linked++;
        if (imgCols.indexOf(col) < 0) imgCols.push(col);
        imgCells.push({ row: lr.rowIndex, col: col });
      } catch (e) {
        imageErrors.push('row' + lr.rowIndex + ':col' + col + ':' + String(e && e.message ? e.message : e));
        if (imageErrors.length > 5) imageErrors.length = 5;
      }
    });
  });

  applyAreaFormat_(sheet, {
    titleRow: titleRow,
    infoRows: infoRows,
    sectionRows: sectionRows,
    spacerRows: spacerRows,
    tableHeaders: tableHeaders,
    tableBodies: tableBodies,
    footerRow: footerRow
  }, lastCol, imgCols, imgCells);

  return { linked: linked, imageErrors: imageErrors };
}

// ---------------------------------------------------------------------------
//  Trang trí: màu sắc, viền, gộp ô, kích thước cột/dòng
// ---------------------------------------------------------------------------
function applyAreaFormat_(sheet, meta, lastCol, imgCols, imgCells) {
  var all = sheet.getRange(1, 1, sheet.getMaxRows(), sheet.getMaxColumns());
  all.setBackground(null)
     .setFontColor(THEME.textDark)
     .setFontFamily(FONT)
     .setFontSize(10)
     .setFontWeight('normal')
     .setFontStyle('normal')
     .setHorizontalAlignment('left')
     .setVerticalAlignment('middle')
     .setWrap(false)
     .setBorder(false, false, false, false, false, false);

  var solid = SpreadsheetApp.BorderStyle.SOLID;

  // Tiêu đề chính
  var title = sheet.getRange(meta.titleRow, 1, 1, lastCol);
  if (lastCol > 1) title.merge();
  title.setBackground(THEME.titleBg)
       .setFontColor('#FFFFFF')
       .setFontSize(16)
       .setFontWeight('bold')
       .setHorizontalAlignment('center')
       .setVerticalAlignment('middle');
  sheet.setRowHeight(meta.titleRow, 46);

  // Ô nhãn / giá trị
  meta.infoRows.forEach(function (r) {
    sheet.getRange(r, 1).setBackground(THEME.labelBg)
         .setFontWeight('bold').setFontColor(THEME.textDark);
    if (lastCol > 2) {
      var val = sheet.getRange(r, 2, 1, lastCol - 1);
      val.merge();
      val.setBackground(THEME.infoBg);
    } else {
      sheet.getRange(r, 2).setBackground(THEME.infoBg);
    }
    sheet.getRange(r, 1, 1, lastCol)
         .setBorder(true, true, true, true, true, true, THEME.border, solid);
  });

  // Tiêu đề VỤ
  meta.sectionRows.forEach(function (r) {
    var g = sheet.getRange(r, 1, 1, lastCol);
    if (lastCol > 1) g.merge();
    g.setBackground(THEME.sectionBg)
     .setFontColor('#FFFFFF')
     .setFontSize(12)
     .setFontWeight('bold')
     .setVerticalAlignment('middle');
    sheet.setRowHeight(r, 30);
  });

  // Tiêu đề bảng nhật ký
  meta.tableHeaders.forEach(function (r) {
    sheet.getRange(r, 1, 1, lastCol)
         .setBackground(THEME.tableHeadBg)
         .setFontColor('#FFFFFF')
         .setFontWeight('bold')
         .setHorizontalAlignment('center')
         .setVerticalAlignment('middle')
         .setWrap(true)
         .setBorder(true, true, true, true, true, true, THEME.border, solid);
    sheet.setRowHeight(r, 30);
  });

  // Dữ liệu bảng: sọc so le + viền + xuống dòng
  meta.tableBodies.forEach(function (b) {
    var n = b.last - b.first + 1;
    if (n <= 0) return;
    var range = sheet.getRange(b.first, 1, n, b.cols);
    range.setWrap(true).setVerticalAlignment('middle')
         .setBorder(true, true, true, true, true, true, THEME.border, solid);
    for (var i = 1; i < n; i += 2) {
      sheet.getRange(b.first + i, 1, 1, b.cols).setBackground(THEME.zebraBg);
    }
    sheet.getRange(b.first, 1, n, 1).setHorizontalAlignment('center');
    if (b.cols >= 2) sheet.getRange(b.first, 2, n, 1).setHorizontalAlignment('center');
    if (b.cols >= 4) sheet.getRange(b.first, 4, n, 1).setHorizontalAlignment('center');
  });

  // Ô link ảnh: căn giữa + độ rộng cột
  (imgCells || []).forEach(function (c) {
    try { sheet.getRange(c.row, c.col).setHorizontalAlignment('center'); } catch (e) {}
  });
  (imgCols || []).forEach(function (col) {
    try { sheet.setColumnWidth(col, 130); } catch (e) {}
  });

  // Dòng phân cách mỏng
  meta.spacerRows.forEach(function (r) {
    try { sheet.setRowHeight(r, 8); } catch (e) {}
  });

  // Dòng chân trang
  var foot = sheet.getRange(meta.footerRow, 1, 1, lastCol);
  if (lastCol > 1) foot.merge();
  foot.setFontColor(THEME.footer).setFontStyle('italic').setFontSize(9)
      .setHorizontalAlignment('center');

  // Kích thước cột
  sheet.setColumnWidth(1, 140);
  if (lastCol >= 2) sheet.setColumnWidth(2, 190);
  if (lastCol >= 3) sheet.setColumnWidth(3, 170);
  if (lastCol >= 4) sheet.setColumnWidth(4, 130);
  if (lastCol >= 5) sheet.setColumnWidth(5, 300);
  sheet.setFrozenRows(meta.titleRow);
}

// ---------------------------------------------------------------------------
//  Xoá sheet khi khu vực bị xoá
// ---------------------------------------------------------------------------
function deleteArea_(body) {
  var ss = getSpreadsheet_();
  var key = String(body.key || '');
  var idx = ss.getSheetByName(INDEX_SHEET);
  if (idx) {
    var row = findIndexRow_(idx, key);
    if (row > 0) {
      var name = String(idx.getRange(row, 2).getValue());
      var sh = ss.getSheetByName(name);
      if (sh) ss.deleteSheet(sh);
      idx.deleteRow(row);
      return { ok: true, deleted: name };
    }
  }
  return { ok: true, deleted: null };
}

// ---------------------------------------------------------------------------
//  Đồng bộ toàn bộ (tuỳ chọn): body = { action:'syncAll', username, areas:[...] }
// ---------------------------------------------------------------------------
function syncAll_(body) {
  var areas = body.areas || [];
  var n = 0;
  areas.forEach(function (area) {
    syncArea_({ action: 'syncArea', username: body.username, area: area });
    n++;
  });
  return { ok: true, synced: n };
}
