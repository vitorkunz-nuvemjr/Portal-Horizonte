import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import type {
	Cycle,
	DatabaseSnapshot,
	KpiDirection,
	MetricUpdate,
	NodeAssignee,
	NodeStatus,
	NodeTeam,
	NodeTree,
	NodeType,
	NodeValue,
	Profile,
	StrategyNode,
	Team,
	TeamMember,
	UserRole
} from '$lib/types';

const DATA_DIR = path.resolve(process.cwd(), '.data');
const DB_FILE = path.join(DATA_DIR, 'local-db.json');

export function generateSeedSnapshot(): DatabaseSnapshot {
	const now = '2026-10-18T12:00:00.000Z';

	const teams: Team[] = [
		{
			id: 't-geral',
			name: 'Geral',
			description: 'Diretoria Geral e alinhamento global da EJ.',
			color: '#0284c7',
			created_at: now
		},
		{
			id: 't-presidencia',
			name: 'Presidência',
			description: 'Liderança institucional, conselho e novos parceiros seniores.',
			color: '#2563eb',
			created_at: now
		},
		{
			id: 't-adm-fin',
			name: 'Administrativo-Financeiro',
			description: 'Gestão financeira, precificação, orçamento e frente de inovação.',
			color: '#0891b2',
			created_at: now
		},
		{
			id: 't-comercial',
			name: 'Comercial',
			description: 'Vendas, parcerias com EJs, propostas de cultura e grupos de trabalho.',
			color: '#059669',
			created_at: now
		},
		{
			id: 't-marketing',
			name: 'Marketing',
			description: 'Comunicação, campanhas de vendas, redes sociais, blog e site.',
			color: '#ea580c',
			created_at: now
		},
		{
			id: 't-projetos',
			name: 'Projetos',
			description: 'Consultoria, jornada do cliente, briefing e capacitações técnicas.',
			color: '#7c3aed',
			created_at: now
		},
		{
			id: 't-gp',
			name: 'Gestão de Pessoas',
			description: 'Jornada do membro, acompanhamento e desempenho, seleção e desligamento.',
			color: '#d97706',
			created_at: now
		},
		{
			id: 't-todas',
			name: 'Todas as Diretorias',
			description: 'Processos e modelos transversais a todas as diretorias.',
			color: '#64748b',
			created_at: now
		}
	];

	const profiles: Profile[] = [
		{
			id: 'u-admin-1',
			name: 'Valentina Kunz (Presidente)',
			email: 'presidencia@nuvemej.com.br',
			role: 'admin',
			color: '#2563eb',
			created_at: '2026-01-10T09:00:00.000Z'
		},
		{
			id: 'u-member-1',
			name: 'Lucas Mendes (Dir. Comercial & Marketing)',
			email: 'comercial@nuvemej.com.br',
			role: 'member',
			color: '#059669',
			created_at: '2026-01-10T09:05:00.000Z'
		},
		{
			id: 'u-member-2',
			name: 'Beatriz Costa (Dir. Projetos)',
			email: 'projetos@nuvemej.com.br',
			role: 'member',
			color: '#7c3aed',
			created_at: '2026-01-10T09:10:00.000Z'
		},
		{
			id: 'u-member-3',
			name: 'Rafael Souza (Dir. Gestão de Pessoas)',
			email: 'gp@nuvemej.com.br',
			role: 'member',
			color: '#d97706',
			created_at: '2026-01-10T09:15:00.000Z'
		},
		{
			id: 'u-viewer-1',
			name: 'Conselho Consultivo (Viewer)',
			email: 'conselho@nuvemej.com.br',
			role: 'viewer',
			color: '#64748b',
			created_at: '2026-01-10T09:20:00.000Z'
		}
	];

	const team_members: TeamMember[] = [
		{ team_id: 't-presidencia', user_id: 'u-admin-1' },
		{ team_id: 't-geral', user_id: 'u-admin-1' },
		{ team_id: 't-adm-fin', user_id: 'u-admin-1' },
		{ team_id: 't-comercial', user_id: 'u-member-1' },
		{ team_id: 't-marketing', user_id: 'u-member-1' },
		{ team_id: 't-projetos', user_id: 'u-member-2' },
		{ team_id: 't-gp', user_id: 'u-member-3' }
	];

	const cycles: Cycle[] = [
		{
			id: 'cyc-2024-s1',
			code: '2024-S1',
			year: 2024,
			semester: 1,
			start_date: '2024-01-01',
			end_date: '2024-06-30',
			created_at: now
		},
		{
			id: 'cyc-2024-s2',
			code: '2024-S2',
			year: 2024,
			semester: 2,
			start_date: '2024-07-01',
			end_date: '2024-12-31',
			created_at: now
		},
		{
			id: 'cyc-2025-s1',
			code: '2025-S1',
			year: 2025,
			semester: 1,
			start_date: '2025-01-01',
			end_date: '2025-06-30',
			created_at: now
		},
		{
			id: 'cyc-2025-s2',
			code: '2025-S2',
			year: 2025,
			semester: 2,
			start_date: '2025-07-01',
			end_date: '2025-12-31',
			created_at: now
		},
		{
			id: 'cyc-2026-s1',
			code: '2026-S1',
			year: 2026,
			semester: 1,
			start_date: '2026-01-01',
			end_date: '2026-06-30',
			created_at: now
		},
		{
			id: 'cyc-2026-s2',
			code: '2026-S2',
			year: 2026,
			semester: 2,
			start_date: '2026-07-01',
			end_date: '2026-12-31',
			created_at: now
		},
		{
			id: 'cyc-2027-s1',
			code: '2027-S1',
			year: 2027,
			semester: 1,
			start_date: '2027-01-01',
			end_date: '2027-06-30',
			created_at: now
		},
		{
			id: 'cyc-2027-s2',
			code: '2027-S2',
			year: 2027,
			semester: 2,
			start_date: '2027-07-01',
			end_date: '2027-12-31',
			created_at: now
		}
	];

	const nodes: StrategyNode[] = [
		// ── IDENTITY: ACTIVE ERA (2026 - NUVEM) ──
		{
			id: 'id-mission',
			parent_id: null,
			tree: 'identity',
			type: 'mission',
			title: 'A excelência nasce de uma jornada do membro clara e potencializadora rumo ao desenvolvimento coletivo',
			description: 'Missão do Planejamento Estratégico 2026 - Nuvem',
			year: null,
			quarter: null,
			cycle_id: null,
			start_year: 2026,
			end_year: null,
			status: 'on_track',
			weight: 1,
			sort_order: 0,
			unit: null,
			baseline: null,
			target_value: null,
			current_value: null,
			direction: null,
			manual_progress: null,
			created_by: 'u-admin-1',
			created_at: '2026-01-01T09:00:00.000Z',
			updated_at: '2026-10-18T12:00:00.000Z'
		},
		{
			id: 'val-excelencia',
			parent_id: 'id-mission',
			tree: 'identity',
			type: 'value',
			title: 'Excelência em Cada Entrega',
			description: 'Buscamos o padrão mais alto de qualidade em nossos serviços e projetos, gerando impacto tangível.',
			year: null,
			quarter: null,
			cycle_id: null,
			start_year: 2026,
			end_year: null,
			status: 'on_track',
			weight: 1,
			sort_order: 1,
			unit: null,
			baseline: null,
			target_value: null,
			current_value: null,
			direction: null,
			manual_progress: null,
			created_by: 'u-admin-1',
			created_at: '2026-01-01T09:05:00.000Z',
			updated_at: '2026-10-18T12:00:00.000Z'
		},
		{
			id: 'val-jornada-membro',
			parent_id: 'id-mission',
			tree: 'identity',
			type: 'value',
			title: 'Jornada Potencializadora',
			description: 'Acreditamos no protagonismo e no desenvolvimento contínuo de cada membro ao longo de sua trajetória.',
			year: null,
			quarter: null,
			cycle_id: null,
			start_year: 2026,
			end_year: null,
			status: 'on_track',
			weight: 1,
			sort_order: 2,
			unit: null,
			baseline: null,
			target_value: null,
			current_value: null,
			direction: null,
			manual_progress: null,
			created_by: 'u-admin-1',
			created_at: '2026-01-01T09:10:00.000Z',
			updated_at: '2026-10-18T12:00:00.000Z'
		},
		{
			id: 'val-desenvolvimento-coletivo',
			parent_id: 'id-mission',
			tree: 'identity',
			type: 'value',
			title: 'Desenvolvimento Coletivo',
			description: 'Crescemos juntos: compartilhamos conhecimento, colaboramos ativamente e fortalecemos a equipe.',
			year: null,
			quarter: null,
			cycle_id: null,
			start_year: 2026,
			end_year: null,
			status: 'on_track',
			weight: 1,
			sort_order: 3,
			unit: null,
			baseline: null,
			target_value: null,
			current_value: null,
			direction: null,
			manual_progress: null,
			created_by: 'u-admin-1',
			created_at: '2026-01-01T09:15:00.000Z',
			updated_at: '2026-10-18T12:00:00.000Z'
		},
		{
			id: 'val-sentimento-dono',
			parent_id: 'id-mission',
			tree: 'identity',
			type: 'value',
			title: 'Sentimento de Dono & Inovação',
			description: 'Atitude proativa, responsabilidade pelos resultados e busca constante por soluções inovadoras.',
			year: null,
			quarter: null,
			cycle_id: null,
			start_year: 2026,
			end_year: null,
			status: 'on_track',
			weight: 1,
			sort_order: 4,
			unit: null,
			baseline: null,
			target_value: null,
			current_value: null,
			direction: null,
			manual_progress: null,
			created_by: 'u-admin-1',
			created_at: '2026-01-01T09:20:00.000Z',
			updated_at: '2026-10-18T12:00:00.000Z'
		},

		// ── HISTORICAL STRATEGIC ERA (2021–2023 Archived Cycle) ──
		{
			id: 'id-mission-2021',
			parent_id: null,
			tree: 'identity',
			type: 'mission',
			title: 'Capacitar universitários por meio de projetos de consultoria de gestão e impulsionar pequenos negócios locais.',
			description: 'Missão do triênio 2021–2023 focada na consolidação regional e estruturação inicial dos núcleos de projetos.',
			year: null,
			quarter: null,
			cycle_id: null,
			start_year: 2021,
			end_year: 2023,
			status: 'done',
			weight: 1,
			sort_order: 0,
			unit: null,
			baseline: null,
			target_value: null,
			current_value: null,
			direction: null,
			manual_progress: null,
			created_by: 'u-admin-1',
			created_at: '2021-01-15T10:00:00.000Z',
			updated_at: '2023-12-31T23:59:59.000Z'
		},
		{
			id: 'val-foco-2021',
			parent_id: 'id-mission-2021',
			tree: 'identity',
			type: 'value',
			title: 'Foco no Resultado',
			description: 'Entregas práticas com impacto direto e ágil para o cliente atendido.',
			year: null,
			quarter: null,
			cycle_id: null,
			start_year: 2021,
			end_year: 2023,
			status: 'done',
			weight: 1,
			sort_order: 1,
			unit: null,
			baseline: null,
			target_value: null,
			current_value: null,
			direction: null,
			manual_progress: null,
			created_by: 'u-admin-1',
			created_at: '2021-01-15T10:05:00.000Z',
			updated_at: '2023-12-31T23:59:59.000Z'
		},
		{
			id: 'val-garra-2021',
			parent_id: 'id-mission-2021',
			tree: 'identity',
			type: 'value',
			title: 'Proatividade & Garra',
			description: 'Superar desafios com postura realizadora e espírito empreendedor.',
			year: null,
			quarter: null,
			cycle_id: null,
			start_year: 2021,
			end_year: 2023,
			status: 'done',
			weight: 1,
			sort_order: 2,
			unit: null,
			baseline: null,
			target_value: null,
			current_value: null,
			direction: null,
			manual_progress: null,
			created_by: 'u-admin-1',
			created_at: '2021-01-15T10:10:00.000Z',
			updated_at: '2023-12-31T23:59:59.000Z'
		},

		// ── STRATEGY TREE: OKR 1: Ser EJ de Excelência ──
		{
			id: 'obj-2026-excelencia',
			parent_id: null,
			tree: 'strategy',
			type: 'objective',
			title: 'Ser EJ de Excelência',
			description: 'OKR 1: Ser EJ de Excelência — Planejamento Estratégico 2026 (Nuvem)',
			year: 2026,
			quarter: 4,
			cycle_id: null,
			start_year: null,
			end_year: null,
			status: 'on_track',
			weight: 1,
			sort_order: 1,
			unit: null,
			baseline: null,
			target_value: null,
			current_value: null,
			direction: null,
			manual_progress: null,
			created_by: 'u-admin-1',
			created_at: '2026-01-01T10:00:00.000Z',
			updated_at: '2026-10-18T12:00:00.000Z'
		},

		// ── STRATEGY TREE: OKR 2: Construir uma Jornada do Membro ──
		{
			id: 'obj-2026-jornada-membro',
			parent_id: null,
			tree: 'strategy',
			type: 'objective',
			title: 'Construir uma Jornada do Membro',
			description: 'OKR 2: Construir uma Jornada do Membro — Planejamento Estratégico 2026 (Nuvem)',
			year: 2026,
			quarter: 4,
			cycle_id: null,
			start_year: null,
			end_year: null,
			status: 'on_track',
			weight: 1,
			sort_order: 2,
			unit: null,
			baseline: null,
			target_value: null,
			current_value: null,
			direction: null,
			manual_progress: null,
			created_by: 'u-admin-1',
			created_at: '2026-01-01T10:00:00.000Z',
			updated_at: '2026-10-18T12:00:00.000Z'
		}
	];

	const node_teams: NodeTeam[] = [
		{ node_id: 'obj-2026-excelencia', team_id: 't-geral' },
		{ node_id: 'obj-2026-excelencia', team_id: 't-presidencia' },
		{ node_id: 'obj-2026-excelencia', team_id: 't-adm-fin' },
		{ node_id: 'obj-2026-excelencia', team_id: 't-comercial' },
		{ node_id: 'obj-2026-excelencia', team_id: 't-marketing' },
		{ node_id: 'obj-2026-excelencia', team_id: 't-projetos' },
		{ node_id: 'obj-2026-jornada-membro', team_id: 't-geral' },
		{ node_id: 'obj-2026-jornada-membro', team_id: 't-todas' },
		{ node_id: 'obj-2026-jornada-membro', team_id: 't-adm-fin' },
		{ node_id: 'obj-2026-jornada-membro', team_id: 't-gp' }
	];

	const node_assignees: NodeAssignee[] = [
		{ node_id: 'obj-2026-excelencia', user_id: 'u-admin-1' },
		{ node_id: 'obj-2026-jornada-membro', user_id: 'u-member-3' },
		{ node_id: 'obj-2026-jornada-membro', user_id: 'u-admin-1' }
	];

	const node_values: NodeValue[] = [
		{ node_id: 'obj-2026-excelencia', value_id: 'val-excelencia' },
		{ node_id: 'obj-2026-excelencia', value_id: 'val-sentimento-dono' },
		{ node_id: 'obj-2026-jornada-membro', value_id: 'val-jornada-membro' },
		{ node_id: 'obj-2026-jornada-membro', value_id: 'val-desenvolvimento-coletivo' }
	];

	const teamUserMap: Record<string, string> = {
		't-geral': 'u-admin-1',
		't-presidencia': 'u-admin-1',
		't-adm-fin': 'u-admin-1',
		't-comercial': 'u-member-1',
		't-marketing': 'u-member-1',
		't-projetos': 'u-member-2',
		't-gp': 'u-member-3',
		't-todas': 'u-member-3'
	};

	interface SeedItem {
		krTitle: string;
		kpiTitle: string;
		teamId: string;
		unit: string;
		target: number;
		valId?: string;
	}

	const okr1Items: SeedItem[] = [
		{ krTitle: 'Atingir R$ 46.865,51 de faturamento', kpiTitle: 'Valor do Faturamento (R$)', teamId: 't-geral', unit: 'R$', target: 46865.51, valId: 'val-excelencia' },
		{ krTitle: 'Faturamento colaborativo - R$ 11.952,00', kpiTitle: 'Valor do Faturamento Colaborativo (R$)', teamId: 't-geral', unit: 'R$', target: 11952.00, valId: 'val-excelencia' },
		{ krTitle: 'CSAT 3.5', kpiTitle: 'Nota Média de CSAT', teamId: 't-geral', unit: 'pts', target: 3.5, valId: 'val-excelencia' },
		{ krTitle: 'ECM 75%', kpiTitle: 'Taxa Percentual de ECM (%)', teamId: 't-geral', unit: '%', target: 75, valId: 'val-excelencia' },
		{ krTitle: 'Atingir taxa de 50% do Tempo de permanência médio', kpiTitle: 'Taxa Percentual de Permanência (%)', teamId: 't-geral', unit: '%', target: 50, valId: 'val-jornada-membro' },
		{ krTitle: 'Fechar 2 novos parceiros do mercado sênior', kpiTitle: 'Número de Novos Parceiros', teamId: 't-presidencia', unit: 'parceiros', target: 2, valId: 'val-sentimento-dono' },
		{ krTitle: 'Estabelecer 1 parceria com o Inova Centro', kpiTitle: 'Parceria Estabelecida (Sim/Não)', teamId: 't-presidencia', unit: 'parceria', target: 1, valId: 'val-sentimento-dono' },
		{ krTitle: '100% de presença em RV do conselho', kpiTitle: 'Taxa de Presença em RV (%)', teamId: 't-presidencia', unit: '%', target: 100, valId: 'val-sentimento-dono' },
		{ krTitle: '1 Relatório/tabela de precificação', kpiTitle: 'Relatório/Tabela Entregue (Sim/Não)', teamId: 't-adm-fin', unit: 'tabela', target: 1, valId: 'val-excelencia' },
		{ krTitle: 'Estruturar 1 frente de atuação de diretoria voltada para inovação', kpiTitle: 'Frente Estruturada (Sim/Não)', teamId: 't-adm-fin', unit: 'frente', target: 1, valId: 'val-sentimento-dono' },
		{ krTitle: '3 Capacitações externas - experiência de mercado', kpiTitle: 'Número de Capacitações Realizadas', teamId: 't-comercial', unit: 'capacitações', target: 3, valId: 'val-desenvolvimento-coletivo' },
		{ krTitle: '1 Grupo de Trabalho', kpiTitle: 'Grupo Formado e Ativo (Sim/Não)', teamId: 't-comercial', unit: 'grupo', target: 1, valId: 'val-desenvolvimento-coletivo' },
		{ krTitle: 'Execução de 100% dos passos da Proposta de Cultura', kpiTitle: 'Percentual de Execução da Proposta (%)', teamId: 't-comercial', unit: '%', target: 100, valId: 'val-excelencia' },
		{ krTitle: 'Adicionar a cartela de serviços da Nuvem em outras 2 EJs', kpiTitle: 'Número de EJs Parceiras na Cartela', teamId: 't-comercial', unit: 'EJs', target: 2, valId: 'val-excelencia' },
		{ krTitle: 'Fechar 1 parceria com EJ de design', kpiTitle: 'Parceria Fechada (Sim/Não)', teamId: 't-comercial', unit: 'parceria', target: 1, valId: 'val-excelencia' },
		{ krTitle: 'Definição de 1 público alvo para cada rede social', kpiTitle: 'Número de Públicos Definidos e Registrados', teamId: 't-marketing', unit: 'públicos', target: 1, valId: 'val-excelencia' },
		{ krTitle: 'Rodar 2 campanhas voltadas para vendas (1 no tele para colaborativo)', kpiTitle: 'Número de Campanhas Rodadas', teamId: 't-marketing', unit: 'campanhas', target: 2, valId: 'val-excelencia' },
		{ krTitle: 'Fazer uma lista com 20 temas para o blog', kpiTitle: 'Número de Temas Listados', teamId: 't-marketing', unit: 'temas', target: 20, valId: 'val-excelencia' },
		{ krTitle: 'Fazer 6 capacitações para o time durante o ano', kpiTitle: 'Número de Capacitações Realizadas', teamId: 't-marketing', unit: 'capacitações', target: 6, valId: 'val-desenvolvimento-coletivo' },
		{ krTitle: 'Produção de 1 manual sobre o uso do site', kpiTitle: 'Manual Produzido (Sim/Não)', teamId: 't-marketing', unit: 'manual', target: 1, valId: 'val-excelencia' },
		{ krTitle: 'Reformulação do briefing', kpiTitle: 'Briefing Reformulado e Aprovado (Sim/Não)', teamId: 't-projetos', unit: 'briefing', target: 1, valId: 'val-excelencia' },
		{ krTitle: 'Mapear e documentar 100% da jornada do cliente', kpiTitle: 'Percentual da Jornada Mapeada e Documentada (%)', teamId: 't-projetos', unit: '%', target: 100, valId: 'val-excelencia' },
		{ krTitle: '6 capacitações gerais durante o ano', kpiTitle: 'Número de Capacitações Realizadas', teamId: 't-projetos', unit: 'capacitações', target: 6, valId: 'val-desenvolvimento-coletivo' }
	];

	const okr2Items: SeedItem[] = [
		{ krTitle: 'Mapear 100% dos processos e jornada do membro', kpiTitle: 'Percentual de Processos Globais Mapeados (%)', teamId: 't-geral', unit: '%', target: 100, valId: 'val-jornada-membro' },
		{ krTitle: 'Documentar e padronizar 70% dos processos', kpiTitle: 'Percentual de Processos Globais Documentados (%)', teamId: 't-geral', unit: '%', target: 70, valId: 'val-jornada-membro' },
		{ krTitle: 'Investir em 3 iniciativas de desenvolvimento do membro (software, curso, palestras)', kpiTitle: 'Número de Iniciativas Adquiridas/Realizadas', teamId: 't-geral', unit: 'iniciativas', target: 3, valId: 'val-desenvolvimento-coletivo' },
		{ krTitle: 'Atingir CSAT 3.5 de satisfação geral dos membros', kpiTitle: 'Nota Média de CSAT Interno', teamId: 't-geral', unit: 'pts', target: 3.5, valId: 'val-jornada-membro' },
		{ krTitle: 'Mapeamento de 100% dos processos de diretoria', kpiTitle: 'Percentual de Processos Mapeados (%)', teamId: 't-todas', unit: '%', target: 100, valId: 'val-jornada-membro' },
		{ krTitle: 'Documentação de 70% modelos e processos da área', kpiTitle: 'Percentual de Processos Documentados (%)', teamId: 't-todas', unit: '%', target: 70, valId: 'val-jornada-membro' },
		{ krTitle: 'Definição de 1 orçamento da jornada do membro', kpiTitle: 'Orçamento Definido (Sim/Não)', teamId: 't-adm-fin', unit: 'orçamento', target: 1, valId: 'val-jornada-membro' },
		{ krTitle: 'Definir 1 política de identificação e auxílio para membros minoritários', kpiTitle: 'Política Definida (Sim/Não)', teamId: 't-adm-fin', unit: 'política', target: 1, valId: 'val-jornada-membro' },
		{ krTitle: 'Construir 1 tabela de acompanhamento, desenvolvimento e desempenho do membro', kpiTitle: 'Tabela Construída (Sim/Não)', teamId: 't-gp', unit: 'tabela', target: 1, valId: 'val-jornada-membro' },
		{ krTitle: 'Documentar todas fases do processo de jornada do membro (planejamento, execução, avaliação) - 3 etapas', kpiTitle: 'Número de Etapas Documentadas', teamId: 't-gp', unit: 'etapas', target: 3, valId: 'val-jornada-membro' },
		{ krTitle: 'Atualizar manual de desligamento', kpiTitle: 'Manual Atualizado (Sim/Não)', teamId: 't-gp', unit: 'manual', target: 1, valId: 'val-jornada-membro' },
		{ krTitle: 'Alteração em 100% das etapas do processo seletivo e processo trainee', kpiTitle: 'Percentual de Etapas Alteradas/Revisadas (%)', teamId: 't-gp', unit: '%', target: 100, valId: 'val-jornada-membro' }
	];

	function processOkr(parentId: string, items: SeedItem[], prefix: string) {
		items.forEach((item, idx) => {
			const num = idx + 1;
			const krId = `kr-${prefix}-${num}`;
			const kpiId = `kpi-${prefix}-${num}`;
			const userId = teamUserMap[item.teamId] || 'u-admin-1';

			nodes.push({
				id: krId,
				parent_id: parentId,
				tree: 'strategy',
				type: 'key_result',
				title: item.krTitle,
				description: `Meta associada à diretoria ${item.teamId.replace('t-', '')}`,
				year: null,
				quarter: null,
				cycle_id: null,
				start_year: null,
				end_year: null,
				status: 'on_track',
				weight: 1,
				sort_order: num,
				unit: null,
				baseline: null,
				target_value: null,
				current_value: null,
				direction: null,
				manual_progress: null,
				created_by: userId,
				created_at: '2026-01-01T10:00:00.000Z',
				updated_at: '2026-10-18T12:00:00.000Z'
			});

			nodes.push({
				id: kpiId,
				parent_id: krId,
				tree: 'strategy',
				type: 'kpi',
				title: item.kpiTitle,
				description: `Indicador de performance: ${item.kpiTitle}`,
				year: null,
				quarter: null,
				cycle_id: null,
				start_year: null,
				end_year: null,
				status: 'on_track',
				weight: 1,
				sort_order: 1,
				unit: item.unit,
				baseline: 0,
				target_value: item.target,
				current_value: 0,
				direction: 'up',
				manual_progress: null,
				created_by: userId,
				created_at: '2026-01-01T10:05:00.000Z',
				updated_at: '2026-10-18T12:00:00.000Z'
			});

			node_teams.push({ node_id: krId, team_id: item.teamId });
			node_teams.push({ node_id: kpiId, team_id: item.teamId });

			node_assignees.push({ node_id: krId, user_id: userId });
			node_assignees.push({ node_id: kpiId, user_id: userId });

			if (item.valId) {
				node_values.push({ node_id: krId, value_id: item.valId });
			}
		});
	}

	processOkr('obj-2026-excelencia', okr1Items, '1');
	processOkr('obj-2026-jornada-membro', okr2Items, '2');

	return {
		version: 4,
		exported_at: now,
		profiles,
		teams,
		team_members,
		cycles,
		nodes,
		node_assignees,
		node_teams,
		node_values,
		metric_updates: []
	};
}

let inMemorySnapshot: DatabaseSnapshot | null = null;

function ensureDbFile(): DatabaseSnapshot {
	if (inMemorySnapshot) {
		return inMemorySnapshot;
	}

	try {
		if (fs.existsSync(DB_FILE)) {
			const raw = fs.readFileSync(DB_FILE, 'utf-8');
			const snapshot = JSON.parse(raw) as DatabaseSnapshot;
			// Migration check: ensure all nodes have start_year / end_year keys
			let modified = false;
			for (const n of snapshot.nodes) {
				if (n.tree === 'identity') {
					if (n.start_year === undefined) {
						n.start_year = 2024;
						modified = true;
					}
					if (n.end_year === undefined) {
						n.end_year = null;
						modified = true;
					}
				} else {
					if (n.start_year === undefined) n.start_year = null;
					if (n.end_year === undefined) n.end_year = null;
				}
			}
			// If DB lacks the archived sample era, inject it
			if (!snapshot.nodes.some((n) => n.id === 'id-mission-2021')) {
				const seed = generateSeedSnapshot();
				const historicalNodes = seed.nodes.filter(
					(n) => n.id === 'id-mission-2021' || n.parent_id === 'id-mission-2021'
				);
				snapshot.nodes.push(...historicalNodes);
				modified = true;
			}
			// Migration check: ensure teams, team_members, node_teams exist
			if (!Array.isArray(snapshot.teams)) {
				const seed = generateSeedSnapshot();
				snapshot.teams = seed.teams;
				snapshot.team_members = seed.team_members;
				snapshot.node_teams = seed.node_teams;
				modified = true;
			}
			if (!Array.isArray(snapshot.team_members)) {
				snapshot.team_members = [];
				modified = true;
			}
			if (!Array.isArray(snapshot.node_teams)) {
				snapshot.node_teams = [];
				modified = true;
			}
			if (modified) {
				writeDb(snapshot);
			}
			inMemorySnapshot = snapshot;
			return inMemorySnapshot;
		}
	} catch {
		// Ignore disk read error and fallback to seed
	}

	inMemorySnapshot = generateSeedSnapshot();
	try {
		if (!fs.existsSync(DATA_DIR)) {
			fs.mkdirSync(DATA_DIR, { recursive: true });
		}
		fs.writeFileSync(DB_FILE, JSON.stringify(inMemorySnapshot, null, 2), 'utf-8');
	} catch {
		// Ignore EROFS on read-only serverless filesystems (e.g. Vercel)
	}
	return inMemorySnapshot;
}

export function readDb(): DatabaseSnapshot {
	return ensureDbFile();
}

export function writeDb(snapshot: DatabaseSnapshot): void {
	inMemorySnapshot = snapshot;
	snapshot.exported_at = new Date().toISOString();
	try {
		if (!fs.existsSync(DATA_DIR)) {
			fs.mkdirSync(DATA_DIR, { recursive: true });
		}
		fs.writeFileSync(DB_FILE, JSON.stringify(snapshot, null, 2), 'utf-8');
	} catch {
		// Ignore EROFS on read-only serverless filesystems (e.g. Vercel)
	}
}

export function resetToSeedTemplate(): DatabaseSnapshot {
	const seed = generateSeedSnapshot();
	writeDb(seed);
	return seed;
}

// ═══════════════════════════════════════════════════════════════
// TRIGGER EQUIVALENTS (Enforces §7 & §8 in Local Mode)
// ═══════════════════════════════════════════════════════════════

const ALLOWED_PARENT_CHILD: Array<[NodeType, NodeType]> = [
	['objective', 'key_result'],
	['objective', 'kpi'],
	['key_result', 'kpi'],
	['mission', 'value']
];

export function validateAndPrepareNode(
	db: DatabaseSnapshot,
	candidate: Partial<StrategyNode> & { type: NodeType; tree: NodeTree; title: string },
	existingId?: string
): {
	parent_id: string | null;
	tree: NodeTree;
	type: NodeType;
	year: number | null;
	quarter: 1 | 2 | 3 | 4 | null;
	cycle_id: string | null;
	start_year: number | null;
	end_year: number | null;
} {
	const parent_id = candidate.parent_id || null;
	const type = candidate.type;
	const tree: NodeTree =
		type === 'mission' || type === 'value' ? 'identity' : 'strategy';

	let year = candidate.year ?? null;
	let quarter = (candidate.quarter as 1 | 2 | 3 | 4 | null) ?? null;
	let cycle_id = candidate.cycle_id || null;
	let start_year = candidate.start_year ?? null;
	let end_year = candidate.end_year ?? null;

	// Temporal validity period for Mission (prevents overlapping mission windows)
	if (type === 'mission') {
		start_year = start_year ?? 2024;
		if (end_year != null && end_year < start_year) {
			throw new Error('O ano final da missão não pode ser anterior ao ano inicial.');
		}

		const s1 = start_year;
		const e1 = end_year ?? 9999;
		const otherMissions = db.nodes.filter(
			(n) => n.type === 'mission' && n.id !== existingId
		);
		for (const other of otherMissions) {
			const s2 = other.start_year ?? 2024;
			const e2 = other.end_year ?? 9999;
			if (Math.max(s1, s2) <= Math.min(e1, e2)) {
				throw new Error(
					`O período da missão (${s1}–${end_year ?? 'presente'}) se sobrepõe a uma missão existente (${s2}–${other.end_year ?? 'presente'}).`
				);
			}
		}
	}

	// Root validation
	if (parent_id === null) {
		if (type !== 'objective' && type !== 'mission') {
			throw new Error(`Apenas Objetivo ou Missão podem ser itens raiz (recebido: ${type}).`);
		}
		if (type === 'objective' && !year) {
			throw new Error('Objetivos devem especificar um ano.');
		}
		if (type === 'mission') {
			year = null;
			quarter = null;
			cycle_id = null;
		}
		return { parent_id: null, tree, type, year, quarter, cycle_id, start_year, end_year };
	}

	// Prevent self-parenting or cycles
	if (existingId && parent_id === existingId) {
		throw new Error('Um item não pode ser pai de si mesmo.');
	}
	if (existingId) {
		let cur: string | null = parent_id;
		while (cur) {
			if (cur === existingId) {
				throw new Error('Não é possível mover um item para dentro de um de seus próprios descendentes.');
			}
			const p = db.nodes.find((n) => n.id === cur);
			cur = p?.parent_id ?? null;
		}
	}

	const parent = db.nodes.find((n) => n.id === parent_id);
	if (!parent) {
		throw new Error(`Item pai ${parent_id} não encontrado.`);
	}
	if (parent.tree !== tree) {
		throw new Error(`Incompatibilidade de árvore: o pai é ${parent.tree} e o filho é ${tree}.`);
	}

	const isValidPair = ALLOWED_PARENT_CHILD.some(
		([pType, cType]) => pType === parent.type && cType === type
	);
	if (!isValidPair) {
		throw new Error(`Hierarquia inválida: ${parent.type} não pode ser pai de ${type}.`);
	}

	if (type === 'key_result' || type === 'kpi') {
		year = null;
		quarter = null;
		start_year = null;
		end_year = null;
		// Inherit parent KR's cycle_id for KPI if not explicitly provided
		if (type === 'kpi' && !cycle_id && parent.cycle_id) {
			cycle_id = parent.cycle_id;
		}
	}

	if (type === 'value') {
		year = null;
		quarter = null;
		cycle_id = null;
		// Inherit era window from parent mission if not specified
		if (start_year == null) start_year = parent.start_year ?? 2024;
		if (end_year == null && parent.end_year != null) end_year = parent.end_year;
	}

	return { parent_id, tree, type, year, quarter, cycle_id, start_year, end_year };
}

export function requireEditor(user: Profile | null): Profile {
	if (!user) throw new Error('Autenticação necessária.');
	if (user.role !== 'admin' && user.role !== 'member') {
		throw new Error('O perfil de Visualizador é somente leitura. Alterne para Membro ou Administrador para fazer alterações.');
	}
	return user;
}

export function requireAdmin(user: Profile | null): Profile {
	if (!user) throw new Error('Autenticação necessária.');
	if (user.role !== 'admin') {
		throw new Error('Privilégios de Administrador são necessários para esta ação.');
	}
	return user;
}

// ═══════════════════════════════════════════════════════════════
// CRUD OPERATIONS
// ═══════════════════════════════════════════════════════════════

export function createNodeRecord(
	user: Profile | null,
	input: {
		parent_id?: string | null;
		type: NodeType;
		title: string;
		description?: string | null;
		year?: number | null;
		quarter?: number | null;
		cycle_id?: string | null;
		start_year?: number | null;
		end_year?: number | null;
		status?: NodeStatus;
		weight?: number;
		unit?: string | null;
		baseline?: number | null;
		target_value?: number | null;
		current_value?: number | null;
		direction?: KpiDirection | null;
		manual_progress?: number | null;
	}
): StrategyNode {
	const actor = requireEditor(user);
	const db = readDb();

	const title = input.title?.trim();
	if (!title) throw new Error('O título é obrigatório.');

	const tree: NodeTree =
		input.type === 'mission' || input.type === 'value' ? 'identity' : 'strategy';

	const validated = validateAndPrepareNode(db, {
		...input,
		quarter: (input.quarter as 1 | 2 | 3 | 4 | null) ?? null,
		tree,
		title
	});

	const siblings = db.nodes.filter((n) => n.parent_id === validated.parent_id && n.tree === tree);
	const maxSort = siblings.reduce((m, s) => Math.max(m, s.sort_order), 0);
	const now = new Date().toISOString();

	const newNode: StrategyNode = {
		id: `node-${crypto.randomUUID().slice(0, 8)}`,
		parent_id: validated.parent_id,
		tree: validated.tree,
		type: validated.type,
		title,
		description: input.description?.trim() || null,
		year: validated.year,
		quarter: validated.quarter,
		cycle_id: validated.cycle_id,
		start_year: validated.start_year,
		end_year: validated.end_year,
		status: input.status || 'not_started',
		weight: input.weight != null && !Number.isNaN(input.weight) ? Number(input.weight) : 1,
		sort_order: maxSort + 1,
		unit: validated.type === 'kpi' ? input.unit?.trim() || null : null,
		baseline:
			validated.type === 'kpi' && input.baseline != null && !Number.isNaN(input.baseline)
				? Number(input.baseline)
				: null,
		target_value:
			validated.type === 'kpi' && input.target_value != null && !Number.isNaN(input.target_value)
				? Number(input.target_value)
				: null,
		current_value:
			validated.type === 'kpi' && input.current_value != null && !Number.isNaN(input.current_value)
				? Number(input.current_value)
				: validated.type === 'kpi' && input.baseline != null && !Number.isNaN(input.baseline)
					? Number(input.baseline)
					: null,
		direction: validated.type === 'kpi' ? input.direction || 'up' : null,
		manual_progress:
			input.manual_progress != null && !Number.isNaN(input.manual_progress)
				? Math.max(0, Math.min(1, Number(input.manual_progress)))
				: null,
		created_by: actor.id,
		created_at: now,
		updated_at: now
	};

	db.nodes.push(newNode);

	// If KPI created with initial current_value, also log initial metric update
	if (newNode.type === 'kpi' && newNode.current_value != null) {
		db.metric_updates.push({
			id: `mu-${crypto.randomUUID().slice(0, 8)}`,
			node_id: newNode.id,
			value: newNode.current_value,
			note: 'Linha de base / valor atual inicial',
			user_id: actor.id,
			created_at: now
		});
	}

	writeDb(db);
	return newNode;
}

export function updateNodeRecord(
	user: Profile | null,
	nodeId: string,
	patch: Partial<StrategyNode>
): StrategyNode {
	requireEditor(user);
	const db = readDb();
	const idx = db.nodes.findIndex((n) => n.id === nodeId);
	if (idx === -1) throw new Error('Item não encontrado.');

	const existing = db.nodes[idx];
	const merged = {
		...existing,
		...patch,
		title: patch.title !== undefined ? patch.title.trim() : existing.title
	};
	if (!merged.title) throw new Error('O título não pode ficar vazio.');

	const validated = validateAndPrepareNode(db, merged, existing.id);

	const updated: StrategyNode = {
		...merged,
		parent_id: validated.parent_id,
		tree: validated.tree,
		type: validated.type,
		year: validated.year,
		quarter: validated.quarter,
		cycle_id: validated.cycle_id,
		start_year: validated.start_year,
		end_year: validated.end_year,
		updated_at: new Date().toISOString()
	};

	db.nodes[idx] = updated;
	writeDb(db);
	return updated;
}

export function archiveAndCreateEraRecord(
	user: Profile | null,
	input: {
		archivePriorEndYear: number;
		newStartYear: number;
		newEndYear?: number | null;
		missionTitle: string;
		missionDescription?: string | null;
		values: Array<{ title: string; description?: string | null }>;
	}
): { mission: StrategyNode; values: StrategyNode[] } {
	requireAdmin(user);
	const db = readDb();

	// 1. Archive active missions and values whose end_year is null
	for (const n of db.nodes) {
		if (n.tree === 'identity' && (n.end_year == null || n.end_year > input.archivePriorEndYear)) {
			n.end_year = input.archivePriorEndYear;
			n.updated_at = new Date().toISOString();
		}
	}

	// 2. Create the new Mission
	const newMission = createNodeRecord(user, {
		type: 'mission',
		title: input.missionTitle,
		description: input.missionDescription,
		start_year: input.newStartYear,
		end_year: input.newEndYear ?? null
	});

	// 3. Create initial values under this mission
	const createdValues: StrategyNode[] = [];
	for (const v of input.values) {
		if (!v.title?.trim()) continue;
		const valNode = createNodeRecord(user, {
			parent_id: newMission.id,
			type: 'value',
			title: v.title,
			description: v.description,
			start_year: input.newStartYear,
			end_year: input.newEndYear ?? null
		});
		createdValues.push(valNode);
	}

	return { mission: newMission, values: createdValues };
}

export function deleteNodeRecord(
	user: Profile | null,
	nodeId: string,
	promoteChildren: boolean = false
): void {
	requireEditor(user);
	const db = readDb();
	const target = db.nodes.find((n) => n.id === nodeId);
	if (!target) throw new Error('Item não encontrado.');

	if (promoteChildren) {
		const children = db.nodes.filter((n) => n.parent_id === nodeId);
		for (const child of children) {
			const validated = validateAndPrepareNode(
				db,
				{
					...child,
					parent_id: target.parent_id
				},
				child.id
			);
			child.parent_id = validated.parent_id;
			child.updated_at = new Date().toISOString();
		}
		db.nodes = db.nodes.filter((n) => n.id !== nodeId);
		db.node_assignees = db.node_assignees.filter((a) => a.node_id !== nodeId);
		db.node_teams = db.node_teams.filter((nt) => nt.node_id !== nodeId);
		db.node_values = db.node_values.filter(
			(nv) => nv.node_id !== nodeId && nv.value_id !== nodeId
		);
		db.metric_updates = db.metric_updates.filter((m) => m.node_id !== nodeId);
	} else {
		// Cascade collect all descendant IDs
		const toDelete = new Set<string>([nodeId]);
		let added = true;
		while (added) {
			added = false;
			for (const n of db.nodes) {
				if (n.parent_id && toDelete.has(n.parent_id) && !toDelete.has(n.id)) {
					toDelete.add(n.id);
					added = true;
				}
			}
		}
		db.nodes = db.nodes.filter((n) => !toDelete.has(n.id));
		db.node_assignees = db.node_assignees.filter((a) => !toDelete.has(a.node_id));
		db.node_teams = db.node_teams.filter((nt) => !toDelete.has(nt.node_id));
		db.node_values = db.node_values.filter(
			(nv) => !toDelete.has(nv.node_id) && !toDelete.has(nv.value_id)
		);
		db.metric_updates = db.metric_updates.filter((m) => !toDelete.has(m.node_id));
	}

	writeDb(db);
}

export function setNodeValuesRecord(
	user: Profile | null,
	nodeId: string,
	valueIds: string[]
): void {
	requireEditor(user);
	const db = readDb();
	const node = db.nodes.find((n) => n.id === nodeId);
	if (!node) throw new Error('Item não encontrado.');
	if (node.tree !== 'strategy') {
		throw new Error('Apenas itens estratégicos podem ser alinhados a valores.');
	}

	const validValueIds = new Set(
		db.nodes.filter((n) => n.type === 'value').map((n) => n.id)
	);
	for (const vid of valueIds) {
		if (!validValueIds.has(vid)) {
			throw new Error(`ID de valor inválido: ${vid}`);
		}
	}

	db.node_values = db.node_values.filter((nv) => nv.node_id !== nodeId);
	const uniqueIds = Array.from(new Set(valueIds));
	for (const vid of uniqueIds) {
		db.node_values.push({ node_id: nodeId, value_id: vid });
	}
	writeDb(db);
}

export function setNodeAssigneesRecord(
	user: Profile | null,
	nodeId: string,
	userIds: string[]
): void {
	requireEditor(user);
	const db = readDb();
	const node = db.nodes.find((n) => n.id === nodeId);
	if (!node) throw new Error('Item não encontrado.');

	const validUsers = new Set(db.profiles.map((p) => p.id));
	db.node_assignees = db.node_assignees.filter((a) => a.node_id !== nodeId);
	const uniqueIds = Array.from(new Set(userIds)).filter((uid) => validUsers.has(uid));
	for (const uid of uniqueIds) {
		db.node_assignees.push({ node_id: nodeId, user_id: uid });
	}
	writeDb(db);
}

export function setNodeTeamsRecord(
	user: Profile | null,
	nodeId: string,
	teamIds: string[]
): void {
	requireEditor(user);
	const db = readDb();
	const node = db.nodes.find((n) => n.id === nodeId);
	if (!node) throw new Error('Item não encontrado.');

	const validTeams = new Set(db.teams.map((t) => t.id));
	db.node_teams = db.node_teams.filter((nt) => nt.node_id !== nodeId);
	const uniqueIds = Array.from(new Set(teamIds)).filter((tid) => validTeams.has(tid));
	for (const tid of uniqueIds) {
		db.node_teams.push({ node_id: nodeId, team_id: tid });
	}
	writeDb(db);
}

export function logMetricUpdateRecord(
	user: Profile | null,
	nodeId: string,
	value: number,
	note: string | null
): MetricUpdate {
	const actor = requireEditor(user);
	const db = readDb();
	const kpi = db.nodes.find((n) => n.id === nodeId);
	if (!kpi || kpi.type !== 'kpi') {
		throw new Error('Atualizações de métrica só podem ser registradas em itens de KPI.');
	}
	if (Number.isNaN(value)) {
		throw new Error('Um valor numérico é obrigatório.');
	}

	const now = new Date().toISOString();
	const entry: MetricUpdate = {
		id: `mu-${crypto.randomUUID().slice(0, 8)}`,
		node_id: nodeId,
		value: Number(value),
		note: note?.trim() || null,
		user_id: actor.id,
		created_at: now
	};

	db.metric_updates.push(entry);
	// Trigger equivalent: sync_kpi_current_value
	kpi.current_value = Number(value);
	kpi.updated_at = now;
	if (kpi.status === 'not_started') {
		kpi.status = 'on_track';
	}

	writeDb(db);
	return entry;
}

export function createCycleRecord(
	user: Profile | null,
	input: { year: number; semester: 1 | 2; start_date: string; end_date: string }
): Cycle {
	requireAdmin(user);
	const db = readDb();
	const code = `${input.year}-S${input.semester}`;
	if (db.cycles.some((c) => c.code === code)) {
		throw new Error(`O ciclo ${code} já existe.`);
	}
	const cycle: Cycle = {
		id: `cyc-${input.year}-s${input.semester}`,
		code,
		year: input.year,
		semester: input.semester,
		start_date: input.start_date,
		end_date: input.end_date,
		created_at: new Date().toISOString()
	};
	db.cycles.push(cycle);
	db.cycles.sort((a, b) => a.code.localeCompare(b.code));
	writeDb(db);
	return cycle;
}

export function deleteCycleRecord(user: Profile | null, cycleId: string): void {
	requireAdmin(user);
	const db = readDb();
	db.cycles = db.cycles.filter((c) => c.id !== cycleId);
	for (const n of db.nodes) {
		if (n.cycle_id === cycleId) n.cycle_id = null;
	}
	writeDb(db);
}

export function upsertProfileRecord(
	user: Profile | null,
	input: { id?: string; name: string; email?: string; role: UserRole; color?: string | null }
): Profile {
	requireAdmin(user);
	const db = readDb();
	if (input.id) {
		const existing = db.profiles.find((p) => p.id === input.id);
		if (!existing) throw new Error('Perfil não encontrado.');
		existing.name = input.name.trim();
		if (input.email !== undefined) existing.email = input.email.trim();
		existing.role = input.role;
		if (input.color !== undefined) existing.color = input.color;
		writeDb(db);
		return existing;
	} else {
		const created: Profile = {
			id: `u-${crypto.randomUUID().slice(0, 8)}`,
			name: input.name.trim(),
			email: input.email?.trim() || `${input.name.toLowerCase().replace(/\s+/g, '.')}@jestrategy.org`,
			role: input.role,
			color: input.color || '#2563eb',
			created_at: new Date().toISOString()
		};
		db.profiles.push(created);
		writeDb(db);
		return created;
	}
}

export function createTeamRecord(
	user: Profile | null,
	input: { name: string; description?: string | null; color?: string | null }
): Team {
	requireAdmin(user);
	const db = readDb();
	const trimmed = input.name.trim();
	if (!trimmed) throw new Error('O nome da equipe é obrigatório.');

	const id = `t-${trimmed.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') || crypto.randomUUID().slice(0, 6)}`;
	if (db.teams.some((t) => t.id === id || t.name.toLowerCase() === trimmed.toLowerCase())) {
		throw new Error(`Já existe uma equipe com o nome "${trimmed}".`);
	}

	const team: Team = {
		id,
		name: trimmed,
		description: input.description?.trim() || null,
		color: input.color || '#2563eb',
		created_at: new Date().toISOString()
	};

	db.teams.push(team);
	writeDb(db);
	return team;
}

export function updateTeamRecord(
	user: Profile | null,
	teamId: string,
	input: { name?: string; description?: string | null; color?: string | null }
): Team {
	requireAdmin(user);
	const db = readDb();
	const team = db.teams.find((t) => t.id === teamId);
	if (!team) throw new Error('Equipe não encontrada.');

	if (input.name !== undefined) {
		const trimmed = input.name.trim();
		if (!trimmed) throw new Error('O nome da equipe não pode ficar vazio.');
		team.name = trimmed;
	}
	if (input.description !== undefined) {
		team.description = input.description?.trim() || null;
	}
	if (input.color !== undefined) {
		team.color = input.color;
	}

	writeDb(db);
	return team;
}

export function deleteTeamRecord(user: Profile | null, teamId: string): void {
	requireAdmin(user);
	const db = readDb();
	db.teams = db.teams.filter((t) => t.id !== teamId);
	db.team_members = db.team_members.filter((tm) => tm.team_id !== teamId);
	db.node_teams = db.node_teams.filter((nt) => nt.team_id !== teamId);
	writeDb(db);
}

export function setUserTeamsRecord(
	user: Profile | null,
	userId: string,
	teamIds: string[]
): void {
	requireAdmin(user);
	const db = readDb();
	const profile = db.profiles.find((p) => p.id === userId);
	if (!profile) throw new Error('Perfil não encontrado.');

	const validTeams = new Set(db.teams.map((t) => t.id));
	// Remove all current team memberships for this user
	db.team_members = db.team_members.filter((tm) => tm.user_id !== userId);
	// Add updated team memberships
	const uniqueIds = Array.from(new Set(teamIds)).filter((tid) => validTeams.has(tid));
	for (const tid of uniqueIds) {
		db.team_members.push({ team_id: tid, user_id: userId });
	}
	writeDb(db);
}

export function importDatabaseSnapshot(user: Profile | null, jsonText: string): void {
	requireAdmin(user);
	let parsed: DatabaseSnapshot;
	try {
		parsed = JSON.parse(jsonText);
	} catch {
		throw new Error('Arquivo JSON inválido.');
	}
	if (!Array.isArray(parsed.nodes) || !Array.isArray(parsed.cycles)) {
		throw new Error('O snapshot não contém as listas obrigatórias "nodes" ou "cycles".');
	}
	const existingDb = readDb();
	writeDb({
		version: parsed.version ?? 4,
		exported_at: new Date().toISOString(),
		profiles: Array.isArray(parsed.profiles) && parsed.profiles.length > 0 ? parsed.profiles : existingDb.profiles,
		teams: Array.isArray(parsed.teams) ? parsed.teams : existingDb.teams,
		team_members: Array.isArray(parsed.team_members) ? parsed.team_members : existingDb.team_members,
		cycles: parsed.cycles,
		nodes: parsed.nodes,
		node_assignees: parsed.node_assignees ?? [],
		node_teams: parsed.node_teams ?? [],
		node_values: parsed.node_values ?? [],
		metric_updates: parsed.metric_updates ?? []
	});
}
