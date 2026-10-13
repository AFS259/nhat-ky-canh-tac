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
 * ============================================================================
 */

// ID của Google Sheet đích (lấy từ URL: /spreadsheets/d/<ID>/edit)
const SPREADSHEET_ID = '1Jk461TKiDvHJv6dh8LZQ6lBltJpWFkChzI2coYo4QQQ';

// Sheet ẩn lưu bảng ánh xạ areaKey (UUID) → tên sheet
const INDEX_SHEET = '_AFS_INDEX';

// ---------------------------------------------------------------------------
//  Entry points
// ---------------------------------------------------------------------------
function doGet() {
  return json_({ ok: true, service: 'AFS Nhat Ky Canh Tac', time: new Date().toISOString() });
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

/** Kiểm tra chuỗi base64 hợp lệ. */
function isValidImage_(b64) {
  return typeof b64 === 'string' && b64.length > 0 && /^[A-Za-z0-9+/=]+$/.test(b64);
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

  writeArea_(sheet, area, username);

  idx.getRange(row, 2).setValue(sheetName);
  idx.getRange(row, 3).setValue(username);
  idx.getRange(row, 4).setValue(areaName);
  idx.getRange(row, 5).setValue(new Date());

  return { ok: true, sheet: sheetName, crops: (area.crops || []).length };
}

function writeArea_(sheet, area, username) {
  var rows = [];
  var logRows = []; // { rowIndex, images[] } dòng nhật ký có ảnh
  var crops = area.crops || [];

  rows.push(['NHẬT KÝ CANH TÁC AFS']);
  rows.push(['Khu vực', String(area.name || '')]);
  if (area.address) rows.push(['Địa chỉ', String(area.address)]);
  if (area.note) rows.push(['Ghi chú', String(area.note)]);
  rows.push(['Ngày tạo', String(area.createdAt || '')]);
  rows.push(['Người dùng', username]);
  rows.push(['Cập nhật', Utilities.formatDate(new Date(), 'Asia/Ho_Chi_Minh', 'dd/MM/yyyy HH:mm')]);
  rows.push([]);

  if (crops.length === 0) {
    rows.push(['Chưa có vụ canh tác nào trong khu vực.']);
  }

  crops.forEach(function (crop) {
    rows.push(['VỤ', String(crop.cropType || '') + ' · ' + String(crop.variety || '')]);
    rows.push(['Giống', String(crop.variety || '')]);
    rows.push(['Diện tích (m²)', String(crop.areaM2 || '')]);
    rows.push(['Số hạt gieo', String(crop.seedCount != null ? crop.seedCount : '')]);
    rows.push(['Ngày gieo', String(crop.sowDate || '')]);
    rows.push(['Số cây trồng', String(crop.plantCount != null ? crop.plantCount : '')]);
    rows.push(['Ngày trồng', String(crop.plantDate || '')]);

    var logs = crop.logs || [];
    var maxImgs = 0;
    logs.forEach(function (log) {
      var imgs = (log.images || []).filter(isValidImage_);
      if (imgs.length > maxImgs) maxImgs = imgs.length;
    });

    var header = ['STT', 'Ngày trồng', 'Công việc', 'Ngày thực hiện', 'Ghi chú'];
    for (var h = 1; h <= maxImgs; h++) header.push('Ảnh ' + h);
    rows.push(header);

    if (logs.length === 0) {
      rows.push(['', '', '(chưa có nhật ký)', '', '']);
    }
    logs.forEach(function (log, i) {
      var imgs = (log.images || []).filter(isValidImage_);
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
    rows.push([]);
  });

  sheet.clear();
  var data = padRows_(rows);
  if (data.length > 0) {
    sheet.getRange(1, 1, data.length, data[0].length).setValues(data);
  }

  // Gắn ảnh minh chứng (base64) vào sheet, bắt đầu từ cột F (6).
  var imgCols = [];
  logRows.forEach(function (lr) {
    lr.images.forEach(function (b64, j) {
      try {
        var blob = Utilities.newBlob(Utilities.base64Decode(b64), 'image/jpeg');
        sheet.insertImage(blob, 6 + j, lr.rowIndex);
        if (imgCols.indexOf(6 + j) < 0) imgCols.push(6 + j);
      } catch (e) {}
    });
    try { sheet.setRowHeight(lr.rowIndex, 150); } catch (e) {}
  });
  imgCols.forEach(function (col) {
    try { sheet.setColumnWidth(col, 150); } catch (e) {}
  });

  // Định dạng nhẹ cho dễ nhìn.
  sheet.getRange(1, 1).setFontSize(14).setFontWeight('bold');
  sheet.setColumnWidth(1, 110);
  sheet.setColumnWidth(3, 160);
  sheet.setColumnWidth(5, 280);
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
