const TOKEN = 'axel-feedback-7q2k';

const SCALE_5 = ['1', '2', '3', '4', '5'];
const QUESTIONS = [
  { id: 'overall', title: 'Overall enjoyment (1-5)', opts: SCALE_5, chart: 'COLUMN' },
  { id: 'combat_fun', title: 'Slot-machine combat fun (1-5)', opts: SCALE_5, chart: 'COLUMN' },
  { id: 'difficulty', title: 'Difficulty', opts: ['Too easy', 'A bit easy', 'Just right', 'A bit hard', 'Too hard'], chart: 'COLUMN' },
  { id: 'atmosphere', title: 'Mood and atmosphere (1-5)', opts: SCALE_5, chart: 'COLUMN' },
  { id: 'story', title: 'Understood story / what to do', opts: ['Yes', 'Partly', 'No'], chart: 'PIE' },
  { id: 'progress', title: 'How far players got', opts: ['Outside', 'Corridor & locker', 'Cafeteria', 'Classrooms', 'Basement', 'An ending'], chart: 'BAR' },
  { id: 'bugs', title: 'Bugs found', opts: ['None', 'Minor', 'Game-breaking'], chart: 'PIE' },
  { id: 'performance', title: 'Performance', opts: ['Smooth', 'Some stutter', 'Laggy'], chart: 'PIE' },
  { id: 'play_again', title: 'Would play again', opts: ['Yes', 'Maybe', 'No'], chart: 'PIE' },
  { id: 'age_group', title: 'Age group', opts: ['10-17', '18-24', '25-34', '35-49', '50-64', '65+'], chart: 'COLUMN' },
  { id: 'gender', title: 'Gender', opts: ['Male', 'Female', 'Non-binary'], chart: 'PIE' },
];

const RESP_HEADERS = [
  'received', 'id', 'version', 'platform', 'debug', 'locale',
  'overall', 'one_word', 'combat_fun', 'difficulty', 'atmosphere', 'story', 'progress',
  'bugs', 'performance', 'play_again', 'age', 'age_group', 'gender', 'occupation',
  'game_data_sent', 'fights_won', 'balance', 'playtime_min', 'run_seed', 'dread_pct',
];
const TEXT_COLS = ['id', 'version', 'platform', 'debug', 'locale', 'overall', 'one_word', 'combat_fun',
  'difficulty', 'atmosphere', 'story', 'progress', 'bugs', 'performance', 'play_again', 'age_group',
  'gender', 'occupation', 'game_data_sent'];
const COMMENT_HEADERS = ['received', 'id', 'version', 'one_word', 'bugs', 'bug_text', 'comments'];
const GAME_HEADERS = [
  'received', 'id', 'version', 'run_seed', 'balance', 'fights_won', 'memories', 'playtime_min',
  'dread_pct', 'tickets', 'tickets_bought', 'travel_uses', 'in_fight', 'scene',
  'owned_items', 'equipped_items', 'visited_rooms', 'flags_json',
];
const FIGHT_HEADERS = [
  'received', 'id', 'version', 'fight', 'run_seed', 'seed', 'goal', 'reason', 'tutorial', 'result',
  'spins_used', 'bets_used', 'balance_start', 'balance_end', 'free_spins', 'vice_rounds',
  'best_payout', 'items', 'dread_pct',
];
const SPIN_HEADERS = [
  'received', 'id', 'version', 'fight', 'fight_seed', 'spin', 'seed', 'bet', 'payout', 'line_payout',
  'cascades', 'wilds', 'power', 'free_spin', 'vice', 'grid_cleared', 'balance_before', 'balance_after',
];

function setup() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const props = PropertiesService.getScriptProperties();
  props.setProperty('SHEET_ID', ss.getId());
  const resp = ensureSheet_(ss, 'Responses', RESP_HEADERS);
  TEXT_COLS.forEach(function (name) {
    const col = RESP_HEADERS.indexOf(name) + 1;
    resp.getRange(2, col, resp.getMaxRows() - 1, 1).setNumberFormat('@');
  });
  ensureSheet_(ss, 'Comments', COMMENT_HEADERS);
  ensureSheet_(ss, 'GameData', GAME_HEADERS);
  ensureSheet_(ss, 'Fights', FIGHT_HEADERS);
  ensureSheet_(ss, 'Spins', SPIN_HEADERS);
  buildCharts_(ss);
  ensureDoc_(ss);
  const sheet1 = ss.getSheetByName('Sheet1');
  if (sheet1 && ss.getSheets().length > 1 && sheet1.getLastRow() === 0) {
    ss.deleteSheet(sheet1);
  }
}

function doGet() {
  return json_({ ok: true, service: 'AXEL feedback' });
}

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    const data = JSON.parse(e.postData.contents);
    if (data.token !== TOKEN) {
      return json_({ ok: false, error: 'bad token' });
    }
    const ss = SpreadsheetApp.openById(PropertiesService.getScriptProperties().getProperty('SHEET_ID'));
    const resp = ss.getSheetByName('Responses');
    const id = String(data.id || '');
    if (id === '' || hasId_(resp, id)) {
      return json_({ ok: true, duplicate: true });
    }
    const now = new Date();
    const a = data.answers || {};
    const g = data.game_data || {};
    const hasGame = Object.keys(g).length > 0;
    const version = String(data.version || '');
    const ageNum = parseInt(a.age, 10);
    const answers = {
      overall: a.overall, one_word: String(a.one_word || '').toLowerCase(), combat_fun: a.combat_fun,
      difficulty: a.difficulty, atmosphere: a.atmosphere, story: a.story, progress: a.progress,
      bugs: a.bugs, performance: a.performance, play_again: a.play_again,
      age: isNaN(ageNum) ? '' : ageNum, age_group: ageGroup_(ageNum), gender: a.gender, occupation: a.occupation,
    };
    const respRow = RESP_HEADERS.map(function (h) {
      switch (h) {
        case 'received': return now;
        case 'id': return id;
        case 'version': return version;
        case 'platform': return data.platform || '';
        case 'debug': return data.debug ? 'yes' : 'no';
        case 'locale': return data.locale || '';
        case 'game_data_sent': return hasGame ? 'yes' : 'no';
        case 'fights_won': return hasGame ? num_(g.fights_won) : '';
        case 'balance': return hasGame ? num_(g.balance) : '';
        case 'playtime_min': return hasGame ? num_(g.playtime_min) : '';
        case 'run_seed': return hasGame ? String(g.run_seed) : '';
        case 'dread_pct': return hasGame ? num_(g.dread_pct) : '';
        default: return answers[h] === undefined || answers[h] === null ? '' : answers[h];
      }
    });
    resp.appendRow(respRow);
    if (a.one_word || a.bug_text || a.comments) {
      ss.getSheetByName('Comments').appendRow([now, id, version, answers.one_word, a.bugs || '', a.bug_text || '', a.comments || '']);
    }
    if (hasGame) {
      appendGame_(ss, now, id, version, g);
    }
    appendDoc_(ss, now, data, answers);
    return json_({ ok: true });
  } catch (err) {
    return json_({ ok: false, error: String(err) });
  } finally {
    lock.releaseLock();
  }
}

function appendGame_(ss, now, id, version, g) {
  ss.getSheetByName('GameData').appendRow([
    now, id, version, String(g.run_seed || ''), num_(g.balance), num_(g.fights_won), num_(g.memories),
    num_(g.playtime_min), num_(g.dread_pct), num_(g.tickets), num_(g.tickets_bought), num_(g.travel_uses),
    g.in_fight ? 'yes' : 'no', g.scene || '', list_(g.owned_items), list_(g.equipped_items),
    list_(g.visited_rooms), JSON.stringify(g.flags || {}),
  ]);
  const fights = (g.fights || []).map(function (f) {
    return [now, id, version, num_(f.fight), String(f.run_seed || ''), String(f.seed || ''), num_(f.goal),
      f.reason || '', f.tutorial ? 'yes' : 'no', f.result || '', num_(f.spins_used), num_(f.bets_used),
      num_(f.balance_start), num_(f.balance_end), num_(f.free_spins), num_(f.vice_rounds),
      num_(f.best_payout), list_(f.items), num_(f.dread_pct)];
  });
  appendRows_(ss.getSheetByName('Fights'), fights);
  const spins = (g.spins || []).map(function (s) {
    return [now, id, version, num_(s.fight), String(s.fight_seed || ''), num_(s.spin), String(s.seed || ''),
      num_(s.bet), num_(s.payout), num_(s.line_payout), num_(s.cascades), num_(s.wilds),
      s.power ? 'yes' : 'no', s.free_spin ? 'yes' : 'no', s.vice ? 'yes' : 'no',
      s.grid_cleared ? 'yes' : 'no', num_(s.balance_before), num_(s.balance_after)];
  });
  appendRows_(ss.getSheetByName('Spins'), spins);
}

function appendRows_(sheet, rows) {
  if (rows.length === 0) {
    return;
  }
  sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, rows[0].length).setValues(rows);
}

function appendDoc_(ss, now, data, answers) {
  const a = data.answers || {};
  if (!a.one_word && !a.bug_text && !a.comments) {
    return;
  }
  const docId = PropertiesService.getScriptProperties().getProperty('DOC_ID');
  if (!docId) {
    return;
  }
  const body = DocumentApp.openById(docId).getBody();
  const stamp = Utilities.formatDate(now, ss.getSpreadsheetTimeZone(), 'yyyy-MM-dd HH:mm');
  const head = stamp + '  |  v' + (data.version || '?') + '  |  ' + (data.platform || '?') + (data.debug ? '  |  debug' : '');
  body.appendParagraph(head).setHeading(DocumentApp.ParagraphHeading.HEADING2);
  const facts = [];
  if (answers.overall) facts.push('Overall ' + answers.overall + '/5');
  if (answers.one_word) facts.push('One word: "' + answers.one_word + '"');
  if (answers.age_group) facts.push('Age ' + answers.age_group);
  if (answers.gender) facts.push(answers.gender);
  if (answers.occupation) facts.push(answers.occupation);
  if (facts.length > 0) {
    body.appendParagraph(facts.join('  ·  ')).setItalic(true);
  }
  if (a.bug_text) {
    body.appendParagraph('Bug (' + (a.bugs || 'not rated') + '):').setBold(true);
    body.appendParagraph(String(a.bug_text)).setBold(false);
  }
  if (a.comments) {
    body.appendParagraph('Comments:').setBold(true);
    body.appendParagraph(String(a.comments)).setBold(false);
  }
  body.appendParagraph('Response id ' + data.id).setFontSize(8).setItalic(false);
  body.appendHorizontalRule();
}

function ensureDoc_(ss) {
  const props = PropertiesService.getScriptProperties();
  let docId = props.getProperty('DOC_ID');
  if (docId) {
    try {
      DocumentApp.openById(docId);
      return;
    } catch (err) {
      docId = null;
    }
  }
  const doc = DocumentApp.create('AXEL Feedback Comments');
  doc.getBody().appendParagraph('AXEL Feedback Comments').setHeading(DocumentApp.ParagraphHeading.TITLE);
  doc.getBody().appendParagraph('Every written answer from the in-game feedback form lands here, newest at the bottom.');
  props.setProperty('DOC_ID', doc.getId());
  const file = DriveApp.getFileById(doc.getId());
  const parents = DriveApp.getFileById(ss.getId()).getParents();
  if (parents.hasNext()) {
    file.moveTo(parents.next());
  }
}

function buildCharts_(ss) {
  let sheet = ss.getSheetByName('Charts');
  if (!sheet) {
    sheet = ss.insertSheet('Charts', 0);
  }
  sheet.getCharts().forEach(function (c) { sheet.removeChart(c); });
  sheet.clear();
  sheet.getDataRange().clearDataValidations();
  sheet.getRange('A1').setValue('Version').setFontWeight('bold');
  sheet.getRange('A2').setValue('Include debug builds').setFontWeight('bold');
  sheet.getRange('A3').setValue('Responses shown').setFontWeight('bold');
  sheet.getRange('Z1').setValue('All');
  sheet.getRange('Z2').setFormula('=IFERROR(SORT(UNIQUE(FILTER(Responses!C2:C, Responses!C2:C<>""))), "")');
  sheet.getRange('Z:Z').setNumberFormat('@');
  sheet.getRange('B1').setValue('All').setNumberFormat('@').setDataValidation(
    SpreadsheetApp.newDataValidation().requireValueInRange(sheet.getRange('Z1:Z200'), true).build());
  sheet.getRange('B2').insertCheckboxes().setValue(false);
  sheet.getRange('B3').setFormula('=SUMPRODUCT((Responses!B2:B<>"")*' + filter_() + ')');
  sheet.setColumnWidth(1, 190);
  sheet.setColumnWidth(2, 110);
  let row = 6;
  QUESTIONS.forEach(function (q) {
    const col = colLetter_(RESP_HEADERS.indexOf(q.id) + 1);
    sheet.getRange(row, 1).setValue(q.title).setFontWeight('bold');
    sheet.getRange(row + 1, 1, 1, 2).setValues([['Answer', 'Count']]).setFontWeight('bold');
    q.opts.forEach(function (opt, i) {
      const r = row + 2 + i;
      sheet.getRange(r, 1).setNumberFormat('@').setValue(opt);
      sheet.getRange(r, 2).setFormula('=SUMPRODUCT((Responses!' + col + '2:' + col + '=$A' + r + ')*' + filter_() + ')');
    });
    const range = sheet.getRange(row + 1, 1, q.opts.length + 1, 2);
    const type = q.chart === 'PIE' ? Charts.ChartType.PIE : (q.chart === 'BAR' ? Charts.ChartType.BAR : Charts.ChartType.COLUMN);
    const chart = sheet.newChart().setChartType(type).addRange(range)
      .setNumHeaders(1)
      .setPosition(row, 4, 0, 0)
      .setOption('title', q.title)
      .setOption('legend', { position: q.chart === 'PIE' ? 'right' : 'none' })
      .setOption('colors', ['#c41414', '#7a2e2e', '#e06666', '#3d0a0a', '#b7a6a6', '#ea9999'])
      .setOption('width', 560)
      .setOption('height', 300)
      .build();
    sheet.insertChart(chart);
    row += 16;
  });
  sheet.getRange(row, 1).setValue('Average scores by version').setFontWeight('bold');
  sheet.getRange(row + 1, 1, 1, 4).setValues([['Version', 'Overall', 'Combat fun', 'Atmosphere']]).setFontWeight('bold');
  sheet.getRange(row + 2, 1).setFormula('=IFERROR(SORT(UNIQUE(FILTER(Responses!C2:C, Responses!C2:C<>""))), "")');
  for (let i = 0; i < 30; i++) {
    const r = row + 2 + i;
    ['overall', 'combat_fun', 'atmosphere'].forEach(function (id, j) {
      const c = colLetter_(RESP_HEADERS.indexOf(id) + 1);
      sheet.getRange(r, 2 + j).setFormula('=IF($A' + r + '="", "", IFERROR(AVERAGE(ARRAYFORMULA(VALUE(FILTER(Responses!' + c + '2:' + c + ', Responses!C2:C=$A' + r + ', Responses!' + c + '2:' + c + '<>"")))), ""))');
    });
  }
  const avgChart = sheet.newChart().setChartType(Charts.ChartType.LINE)
    .addRange(sheet.getRange(row + 1, 1, 31, 4))
    .setNumHeaders(1)
    .setPosition(row, 6, 0, 0)
    .setOption('title', 'Average scores by version')
    .setOption('vAxis', { minValue: 1, maxValue: 5 })
    .setOption('colors', ['#c41414', '#7a2e2e', '#b7a6a6'])
    .setOption('width', 620)
    .setOption('height', 320)
    .build();
  sheet.insertChart(avgChart);
  row += 36;
  sheet.getRange(row, 1).setValue('Top one-word answers').setFontWeight('bold');
  sheet.getRange(row + 1, 1).setFormula('=IFERROR(QUERY(Responses!H2:H, "select H, count(H) where H <> \'\' group by H order by count(H) desc limit 20 label H \'Word\', count(H) \'Count\'", 0), "")');
}

function filter_() {
  return '((($B$1="All")+(Responses!C2:C=$B$1))>0)*((($B$2=TRUE)+(Responses!E2:E<>"yes"))>0)';
}

function ensureSheet_(ss, name, headers) {
  let sheet = ss.getSheetByName(name);
  if (!sheet) {
    sheet = ss.insertSheet(name);
  }
  sheet.getRange(1, 1, 1, headers.length).setValues([headers]).setFontWeight('bold');
  sheet.setFrozenRows(1);
  return sheet;
}

function hasId_(sheet, id) {
  if (sheet.getLastRow() < 2) {
    return false;
  }
  return sheet.getRange(2, 2, sheet.getLastRow() - 1, 1).createTextFinder(id).matchEntireCell(true).findNext() !== null;
}

function ageGroup_(age) {
  if (isNaN(age) || age < 10 || age > 110) return '';
  if (age <= 17) return '10-17';
  if (age <= 24) return '18-24';
  if (age <= 34) return '25-34';
  if (age <= 49) return '35-49';
  if (age <= 64) return '50-64';
  return '65+';
}

function colLetter_(n) {
  let s = '';
  while (n > 0) {
    const m = (n - 1) % 26;
    s = String.fromCharCode(65 + m) + s;
    n = Math.floor((n - 1) / 26);
  }
  return s;
}

function num_(v) {
  const n = Number(v);
  return v === undefined || v === null || v === '' || isNaN(n) ? '' : n;
}

function list_(v) {
  return Array.isArray(v) ? v.join(', ') : (v || '');
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
