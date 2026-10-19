import fs from 'node:fs';

const db = JSON.parse(fs.readFileSync('.data/local-db.json', 'utf8'));

function escapeSql(str) {
  if (str === null || str === undefined) return 'NULL';
  return `'` + String(str).replace(/'/g, `''`) + `'`;
}

const out = [];
out.push('-- ═══════════════════════════════════════════════════════════════');
out.push('-- JE Strategy OS - Seed Data from Local Store');
out.push('-- ═══════════════════════════════════════════════════════════════\n');

// 1. Teams
out.push('-- 1. Teams');
for (const t of db.teams) {
  out.push(`INSERT INTO teams (id, name, description, color, created_at) VALUES (${escapeSql(t.id)}, ${escapeSql(t.name)}, ${escapeSql(t.description)}, ${escapeSql(t.color)}, ${escapeSql(t.created_at)}) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;`);
}
out.push('');

// 2. Cycles
out.push('-- 2. Cycles');
for (const c of db.cycles) {
  out.push(`INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES (${escapeSql(c.id)}, ${escapeSql(c.code)}, ${c.year}, ${c.semester}, ${escapeSql(c.start_date)}, ${escapeSql(c.end_date)}, ${escapeSql(c.created_at)}) ON CONFLICT (code) DO NOTHING;`);
}
out.push('');

// 3. Nodes (Sort order: roots first, so parents exist before children)
out.push('-- 3. Nodes');
const sortedNodes = [];
const visited = new Set();
function visit(node) {
  if (visited.has(node.id)) return;
  if (node.parent_id) {
    const parent = db.nodes.find(n => n.id === node.parent_id);
    if (parent) visit(parent);
  }
  visited.add(node.id);
  sortedNodes.push(node);
}
for (const n of db.nodes) visit(n);

for (const n of sortedNodes) {
  out.push(`INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  ${escapeSql(n.id)}, ${escapeSql(n.parent_id)}, ${escapeSql(n.tree)}, ${escapeSql(n.type)}, ${escapeSql(n.title)}, ${escapeSql(n.description)},
  ${n.year ?? 'NULL'}, ${n.quarter ?? 'NULL'}, ${escapeSql(n.cycle_id)}, ${n.start_year ?? 'NULL'}, ${n.end_year ?? 'NULL'},
  ${escapeSql(n.status)}, ${n.weight ?? 1}, ${n.sort_order ?? 0}, ${escapeSql(n.unit)}, ${n.baseline ?? 'NULL'}, ${n.target_value ?? 'NULL'}, ${n.current_value ?? 'NULL'}, ${escapeSql(n.direction)}, ${n.manual_progress ?? 'NULL'}, ${escapeSql(n.created_at)}, ${escapeSql(n.updated_at)}
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;`);
}
out.push('');

// 4. Node Values
out.push('-- 4. Node Values (Alignment)');
for (const nv of db.node_values) {
  out.push(`INSERT INTO node_values (node_id, value_id) VALUES (${escapeSql(nv.node_id)}, ${escapeSql(nv.value_id)}) ON CONFLICT (node_id, value_id) DO NOTHING;`);
}
out.push('');

// 5. Node Teams
out.push('-- 5. Node Teams');
for (const nt of db.node_teams) {
  out.push(`INSERT INTO node_teams (node_id, team_id) VALUES (${escapeSql(nt.node_id)}, ${escapeSql(nt.team_id)}) ON CONFLICT (node_id, team_id) DO NOTHING;`);
}
out.push('');

fs.writeFileSync('supabase/seed.sql', out.join('\n'), 'utf8');
console.log(`Generated supabase/seed.sql with ${out.length} lines.`);
