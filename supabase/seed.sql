-- ═══════════════════════════════════════════════════════════════
-- JE Strategy OS - Seed Data from Local Store
-- ═══════════════════════════════════════════════════════════════

-- 1. Teams
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-presidencia', 'Presidência', 'Liderança institucional, conselho e novos parceiros seniores.', '#2563eb', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-adm-fin', 'Administrativo-Financeiro', 'Gestão financeira, precificação, orçamento e frente de inovação.', '#0891b2', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-comercial', 'Comercial', 'Vendas, parcerias com EJs, propostas de cultura e grupos de trabalho.', '#059669', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-marketing', 'Marketing', 'Comunicação, campanhas de vendas, redes sociais, blog e site.', '#ea580c', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-projetos', 'Projetos', 'Consultoria, jornada do cliente, briefing e capacitações técnicas.', '#7c3aed', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-gp', 'Gestão de Pessoas', 'Jornada do membro, acompanhamento e desempenho, seleção e desligamento.', '#d97706', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-todas', 'Todas as Diretorias', 'Processos e modelos transversais a todas as diretorias.', '#64748b', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;

-- 2. Cycles
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2024-s1', '2024-S1', 2024, 1, '2024-01-01', '2024-06-30', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2024-s2', '2024-S2', 2024, 2, '2024-07-01', '2024-12-31', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2025-s1', '2025-S1', 2025, 1, '2025-01-01', '2025-06-30', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2025-s2', '2025-S2', 2025, 2, '2025-07-01', '2025-12-31', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2026-s1', '2026-S1', 2026, 1, '2026-01-01', '2026-06-30', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2026-s2', '2026-S2', 2026, 2, '2026-07-01', '2026-12-31', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2027-s1', '2027-S1', 2027, 1, '2027-01-01', '2027-06-30', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2027-s2', '2027-S2', 2027, 2, '2027-07-01', '2027-12-31', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;

-- 3. Nodes
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'id-mission', NULL, 'identity', 'mission', 'A excelência nasce de uma jornada do membro clara e potencializadora rumo ao desenvolvimento coletivo', 'Missão do Planejamento Estratégico 2026 - Nuvem',
  NULL, NULL, NULL, 2026, NULL,
  'on_track', 1, 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T09:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-excelencia', 'id-mission', 'identity', 'value', 'Excelência em Cada Entrega', 'Buscamos o padrão mais alto de qualidade em nossos serviços e projetos, gerando impacto tangível.',
  NULL, NULL, NULL, 2026, NULL,
  'on_track', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T09:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-jornada-membro', 'id-mission', 'identity', 'value', 'Jornada Potencializadora', 'Acreditamos no protagonismo e no desenvolvimento contínuo de cada membro ao longo de sua trajetória.',
  NULL, NULL, NULL, 2026, NULL,
  'on_track', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T09:10:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-desenvolvimento-coletivo', 'id-mission', 'identity', 'value', 'Desenvolvimento Coletivo', 'Crescemos juntos: compartilhamos conhecimento, colaboramos ativamente e fortalecemos a equipe.',
  NULL, NULL, NULL, 2026, NULL,
  'on_track', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T09:15:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-sentimento-dono', 'id-mission', 'identity', 'value', 'Sentimento de Dono & Inovação', 'Atitude proativa, responsabilidade pelos resultados e busca constante por soluções inovadoras.',
  NULL, NULL, NULL, 2026, NULL,
  'on_track', 1, 4, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T09:20:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'id-mission-2021', NULL, 'identity', 'mission', 'Capacitar universitários por meio de projetos de consultoria de gestão e impulsionar pequenos negócios locais.', 'Missão do triênio 2021–2023 focada na consolidação regional e estruturação inicial dos núcleos de projetos.',
  NULL, NULL, NULL, 2021, 2023,
  'done', 1, 0, NULL, NULL, NULL, NULL, NULL, NULL, '2021-01-15T10:00:00.000Z', '2023-12-31T23:59:59.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-foco-2021', 'id-mission-2021', 'identity', 'value', 'Foco no Resultado', 'Entregas práticas com impacto direto e ágil para o cliente atendido.',
  NULL, NULL, NULL, 2021, 2023,
  'done', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2021-01-15T10:05:00.000Z', '2023-12-31T23:59:59.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-garra-2021', 'id-mission-2021', 'identity', 'value', 'Proatividade & Garra', 'Superar desafios com postura realizadora e espírito empreendedor.',
  NULL, NULL, NULL, 2021, 2023,
  'done', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2021-01-15T10:10:00.000Z', '2023-12-31T23:59:59.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'obj-2026-excelencia', NULL, 'strategy', 'objective', 'Ser EJ de Excelência', 'OKR 1: Ser EJ de Excelência — Planejamento Estratégico 2026 (Nuvem)',
  2026, 4, NULL, NULL, NULL,
  'on_track', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'obj-2026-jornada-membro', NULL, 'strategy', 'objective', 'Construir uma Jornada do Membro', 'OKR 2: Construir uma Jornada do Membro — Planejamento Estratégico 2026 (Nuvem)',
  2026, 4, NULL, NULL, NULL,
  'on_track', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-1', 'obj-2026-excelencia', 'strategy', 'key_result', 'Atingir R$ 46.865,51 de faturamento', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-1', 'kr-1-1', 'strategy', 'kpi', 'Valor do Faturamento (R$)', 'Indicador de performance: Valor do Faturamento (R$)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'R$', 0, 46865.51, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-2', 'obj-2026-excelencia', 'strategy', 'key_result', 'Faturamento colaborativo - R$ 11.952,00', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-2', 'kr-1-2', 'strategy', 'kpi', 'Valor do Faturamento Colaborativo (R$)', 'Indicador de performance: Valor do Faturamento Colaborativo (R$)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'R$', 0, 11952, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-3', 'obj-2026-excelencia', 'strategy', 'key_result', 'CSAT 3.5', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-3', 'kr-1-3', 'strategy', 'kpi', 'Nota Média de CSAT', 'Indicador de performance: Nota Média de CSAT',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'pts', 0, 3.5, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-4', 'obj-2026-excelencia', 'strategy', 'key_result', 'ECM 75%', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 4, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-4', 'kr-1-4', 'strategy', 'kpi', 'Taxa Percentual de ECM (%)', 'Indicador de performance: Taxa Percentual de ECM (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 75, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-5', 'obj-2026-excelencia', 'strategy', 'key_result', 'Atingir taxa de 50% do Tempo de permanência médio', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 5, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-5', 'kr-1-5', 'strategy', 'kpi', 'Taxa Percentual de Permanência (%)', 'Indicador de performance: Taxa Percentual de Permanência (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 50, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-8', 'obj-2026-excelencia', 'strategy', 'key_result', '100% de presença em RV do conselho', 'Meta associada à diretoria presidencia',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 8, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-8', 'kr-1-8', 'strategy', 'kpi', 'Taxa de Presença em RV (%)', 'Indicador de performance: Taxa de Presença em RV (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-9', 'obj-2026-excelencia', 'strategy', 'key_result', '1 Relatório/tabela de precificação', 'Meta associada à diretoria adm-fin',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 9, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-9', 'kr-1-9', 'strategy', 'kpi', 'Relatório/Tabela Entregue (Sim/Não)', 'Indicador de performance: Relatório/Tabela Entregue (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'tabela', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-10', 'obj-2026-excelencia', 'strategy', 'key_result', 'Estruturar 1 frente de atuação de diretoria voltada para inovação', 'Meta associada à diretoria adm-fin',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 10, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-10', 'kr-1-10', 'strategy', 'kpi', 'Frente Estruturada (Sim/Não)', 'Indicador de performance: Frente Estruturada (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'frente', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-11', 'obj-2026-excelencia', 'strategy', 'key_result', '3 Capacitações externas - experiência de mercado', 'Meta associada à diretoria comercial',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 11, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-11', 'kr-1-11', 'strategy', 'kpi', 'Número de Capacitações Realizadas', 'Indicador de performance: Número de Capacitações Realizadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'capacitações', 0, 3, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-13', 'obj-2026-excelencia', 'strategy', 'key_result', 'Execução de 100% dos passos da Proposta de Cultura', 'Meta associada à diretoria comercial',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 13, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-13', 'kr-1-13', 'strategy', 'kpi', 'Percentual de Execução da Proposta (%)', 'Indicador de performance: Percentual de Execução da Proposta (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-14', 'obj-2026-excelencia', 'strategy', 'key_result', 'Adicionar a cartela de serviços da Nuvem em outras 2 EJs', 'Meta associada à diretoria comercial',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 14, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-14', 'kr-1-14', 'strategy', 'kpi', 'Número de EJs Parceiras na Cartela', 'Indicador de performance: Número de EJs Parceiras na Cartela',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'EJs', 0, 2, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-15', 'obj-2026-excelencia', 'strategy', 'key_result', 'Fechar 1 parceria com EJ de design', 'Meta associada à diretoria comercial',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 15, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-15', 'kr-1-15', 'strategy', 'kpi', 'Parceria Fechada (Sim/Não)', 'Indicador de performance: Parceria Fechada (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'parceria', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-16', 'obj-2026-excelencia', 'strategy', 'key_result', 'Definição de 1 público alvo para cada rede social', 'Meta associada à diretoria marketing',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 16, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-16', 'kr-1-16', 'strategy', 'kpi', 'Número de Públicos Definidos e Registrados', 'Indicador de performance: Número de Públicos Definidos e Registrados',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'públicos', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-17', 'obj-2026-excelencia', 'strategy', 'key_result', 'Rodar 2 campanhas voltadas para vendas (1 no tele para colaborativo)', 'Meta associada à diretoria marketing',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 17, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-17', 'kr-1-17', 'strategy', 'kpi', 'Número de Campanhas Rodadas', 'Indicador de performance: Número de Campanhas Rodadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'campanhas', 0, 2, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-18', 'obj-2026-excelencia', 'strategy', 'key_result', 'Fazer uma lista com 20 temas para o blog', 'Meta associada à diretoria marketing',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-18', 'kr-1-18', 'strategy', 'kpi', 'Número de Temas Listados', 'Indicador de performance: Número de Temas Listados',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'temas', 0, 20, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-19', 'obj-2026-excelencia', 'strategy', 'key_result', 'Fazer 6 capacitações para o time durante o ano', 'Meta associada à diretoria marketing',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 19, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-19', 'kr-1-19', 'strategy', 'kpi', 'Número de Capacitações Realizadas', 'Indicador de performance: Número de Capacitações Realizadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'capacitações', 0, 6, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-20', 'obj-2026-excelencia', 'strategy', 'key_result', 'Produção de 1 manual sobre o uso do site', 'Meta associada à diretoria marketing',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 20, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-20', 'kr-1-20', 'strategy', 'kpi', 'Manual Produzido (Sim/Não)', 'Indicador de performance: Manual Produzido (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'manual', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-21', 'obj-2026-excelencia', 'strategy', 'key_result', 'Reformulação do briefing', 'Meta associada à diretoria projetos',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 21, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-21', 'kr-1-21', 'strategy', 'kpi', 'Briefing Reformulado e Aprovado (Sim/Não)', 'Indicador de performance: Briefing Reformulado e Aprovado (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'briefing', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-22', 'obj-2026-excelencia', 'strategy', 'key_result', 'Mapear e documentar 100% da jornada do cliente', 'Meta associada à diretoria projetos',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 22, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-22', 'kr-1-22', 'strategy', 'kpi', 'Percentual da Jornada Mapeada e Documentada (%)', 'Indicador de performance: Percentual da Jornada Mapeada e Documentada (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-23', 'obj-2026-excelencia', 'strategy', 'key_result', '6 capacitações gerais durante o ano', 'Meta associada à diretoria projetos',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 23, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-23', 'kr-1-23', 'strategy', 'kpi', 'Número de Capacitações Realizadas', 'Indicador de performance: Número de Capacitações Realizadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'capacitações', 0, 6, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-1', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Mapear 100% dos processos e jornada do membro', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-1', 'kr-2-1', 'strategy', 'kpi', 'Percentual de Processos Globais Mapeados (%)', 'Indicador de performance: Percentual de Processos Globais Mapeados (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-2', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Documentar e padronizar 70% dos processos', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-2', 'kr-2-2', 'strategy', 'kpi', 'Percentual de Processos Globais Documentados (%)', 'Indicador de performance: Percentual de Processos Globais Documentados (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 70, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-3', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Investir em 3 iniciativas de desenvolvimento do membro (software, curso, palestras)', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-3', 'kr-2-3', 'strategy', 'kpi', 'Número de Iniciativas Adquiridas/Realizadas', 'Indicador de performance: Número de Iniciativas Adquiridas/Realizadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'iniciativas', 0, 3, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-4', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Atingir CSAT 3.5 de satisfação geral dos membros', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 4, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-4', 'kr-2-4', 'strategy', 'kpi', 'Nota Média de CSAT Interno', 'Indicador de performance: Nota Média de CSAT Interno',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'pts', 0, 3.5, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-5', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Mapeamento de 100% dos processos de diretoria', 'Meta associada à diretoria todas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 5, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-5', 'kr-2-5', 'strategy', 'kpi', 'Percentual de Processos Mapeados (%)', 'Indicador de performance: Percentual de Processos Mapeados (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-6', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Documentação de 70% modelos e processos da área', 'Meta associada à diretoria todas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 6, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-6', 'kr-2-6', 'strategy', 'kpi', 'Percentual de Processos Documentados (%)', 'Indicador de performance: Percentual de Processos Documentados (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 70, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-7', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Definição de 1 orçamento da jornada do membro', 'Meta associada à diretoria adm-fin',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 7, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-7', 'kr-2-7', 'strategy', 'kpi', 'Orçamento Definido (Sim/Não)', 'Indicador de performance: Orçamento Definido (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'orçamento', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-8', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Definir 1 política de identificação e auxílio para membros minoritários', 'Meta associada à diretoria adm-fin',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 8, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-8', 'kr-2-8', 'strategy', 'kpi', 'Política Definida (Sim/Não)', 'Indicador de performance: Política Definida (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'política', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-9', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Construir 1 tabela de acompanhamento, desenvolvimento e desempenho do membro', 'Meta associada à diretoria gp',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 9, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-9', 'kr-2-9', 'strategy', 'kpi', 'Tabela Construída (Sim/Não)', 'Indicador de performance: Tabela Construída (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'tabela', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-10', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Documentar todas fases do processo de jornada do membro (planejamento, execução, avaliação) - 3 etapas', 'Meta associada à diretoria gp',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 10, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-10', 'kr-2-10', 'strategy', 'kpi', 'Número de Etapas Documentadas', 'Indicador de performance: Número de Etapas Documentadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'etapas', 0, 3, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-11', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Atualizar manual de desligamento', 'Meta associada à diretoria gp',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 11, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-11', 'kr-2-11', 'strategy', 'kpi', 'Manual Atualizado (Sim/Não)', 'Indicador de performance: Manual Atualizado (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'manual', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-12', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Alteração em 100% das etapas do processo seletivo e processo trainee', 'Meta associada à diretoria gp',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 12, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-12', 'kr-2-12', 'strategy', 'kpi', 'Percentual de Etapas Alteradas/Revisadas (%)', 'Indicador de performance: Percentual de Etapas Alteradas/Revisadas (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;

-- 4. Node Values (Alignment)
INSERT INTO node_values (node_id, value_id) VALUES ('obj-2026-excelencia', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('obj-2026-excelencia', 'val-sentimento-dono') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('obj-2026-jornada-membro', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('obj-2026-jornada-membro', 'val-desenvolvimento-coletivo') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-1', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-2', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-3', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-4', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-5', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-8', 'val-sentimento-dono') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-9', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-10', 'val-sentimento-dono') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-11', 'val-desenvolvimento-coletivo') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-13', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-14', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-15', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-16', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-17', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-18', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-19', 'val-desenvolvimento-coletivo') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-20', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-21', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-22', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-23', 'val-desenvolvimento-coletivo') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-1', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-2', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-3', 'val-desenvolvimento-coletivo') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-4', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-5', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-6', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-7', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-8', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-9', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-10', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-11', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-12', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;

-- 5. Node Teams
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-excelencia', 't-presidencia') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-excelencia', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-excelencia', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-excelencia', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-excelencia', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-jornada-membro', 't-todas') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-jornada-membro', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-jornada-membro', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-8', 't-presidencia') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-8', 't-presidencia') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-9', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-9', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-10', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-10', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-11', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-11', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-13', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-13', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-14', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-14', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-15', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-15', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-16', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-16', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-17', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-17', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-18', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-18', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-19', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-19', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-20', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-20', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-21', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-21', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-22', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-22', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-23', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-23', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-5', 't-todas') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-5', 't-todas') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-6', 't-todas') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-6', 't-todas') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-7', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-7', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-8', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-8', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-9', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-9', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-10', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-10', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-11', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-11', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-12', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-12', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
