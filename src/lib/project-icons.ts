export type IconCategory =
	| 'teams'
	| 'strategy'
	| 'finance'
	| 'tech'
	| 'culture'
	| 'comms'
	| 'operations';

export interface IconCategoryDef {
	id: IconCategory;
	label: string;
	icon: string;
}

export interface ProjectIcon {
	name: string;
	label: string;
	desc: string;
	category: IconCategory;
	tags: string[];
}

export const PROJECT_ICON_CATEGORIES: IconCategoryDef[] = [
	{ id: 'teams', label: 'Equipes & Gestão', icon: 'groups' },
	{ id: 'strategy', label: 'Estratégia & Metas', icon: 'flag' },
	{ id: 'finance', label: 'Finanças & Métricas', icon: 'payments' },
	{ id: 'tech', label: 'Tecnologia & Produto', icon: 'code' },
	{ id: 'culture', label: 'Pessoas & Cultura', icon: 'diversity_3' },
	{ id: 'comms', label: 'Comunicação & Mídia', icon: 'campaign' },
	{ id: 'operations', label: 'Operações & Logística', icon: 'inventory_2' }
];

export const PROJECT_ICONS: ProjectIcon[] = [
	// --- EQUIPES & GESTÃO (Inclui os ícones padrão do projeto) ---
	{
		name: 'storefront',
		label: 'Storefront',
		desc: 'Comercial & Vendas',
		category: 'teams',
		tags: ['comercial', 'vendas', 'loja', 'storefront', 'mercado', 'negócios']
	},
	{
		name: 'handshake',
		label: 'Handshake',
		desc: 'Parcerias & Alianças',
		category: 'teams',
		tags: ['parcerias', 'alianças', 'acordos', 'handshake', 'sociedade', 'relações']
	},
	{
		name: 'trending_up',
		label: 'Trending Up',
		desc: 'Vendas & Crescimento',
		category: 'teams',
		tags: ['vendas', 'crescimento', 'alta', 'trending_up', 'evolução', 'receita']
	},
	{
		name: 'campaign',
		label: 'Campaign',
		desc: 'Marketing & Divulgação',
		category: 'teams',
		tags: ['marketing', 'divulgação', 'propaganda', 'campaign', 'anúncio', 'campanha']
	},
	{
		name: 'groups',
		label: 'Groups',
		desc: 'Pessoas & Time',
		category: 'teams',
		tags: ['pessoas', 'time', 'equipe', 'groups', 'gente', 'rh', 'colaboradores']
	},
	{
		name: 'rocket_launch',
		label: 'Rocket Launch',
		desc: 'Projetos & Inovação',
		category: 'teams',
		tags: ['projetos', 'lançamento', 'foguete', 'rocket_launch', 'startups', 'inovação']
	},
	{
		name: 'account_balance',
		label: 'Account Balance',
		desc: 'Presidência & Governança',
		category: 'teams',
		tags: ['presidência', 'governança', 'institucional', 'account_balance', 'diretoria']
	},
	{
		name: 'payments',
		label: 'Payments',
		desc: 'Financeiro & Pagamentos',
		category: 'teams',
		tags: ['financeiro', 'pagamentos', 'dinheiro', 'payments', 'caixa', 'custos']
	},
	{
		name: 'hub',
		label: 'Hub',
		desc: 'Transversal & Integração',
		category: 'teams',
		tags: ['transversal', 'geral', 'todas', 'hub', 'integração', 'conector']
	},
	{
		name: 'apartment',
		label: 'Apartment',
		desc: 'Diretoria & Departamentos',
		category: 'teams',
		tags: ['departamento', 'área', 'setor', 'apartment', 'escritório', 'diretoria']
	},
	{
		name: 'corporate_fare',
		label: 'Corporate Fare',
		desc: 'Corporativo & Empresa',
		category: 'teams',
		tags: ['empresa', 'corporativo', 'corporate_fare', 'sede', 'organização']
	},
	{
		name: 'domain',
		label: 'Domain',
		desc: 'Organização & Espaço',
		category: 'teams',
		tags: ['organização', 'espaço', 'domínio', 'domain', 'campus']
	},
	{
		name: 'badge',
		label: 'Badge',
		desc: 'Identidade & Membros',
		category: 'teams',
		tags: ['crachá', 'membro', 'identidade', 'badge', 'perfil']
	},

	// --- ESTRATÉGIA & METAS ---
	{
		name: 'flag',
		label: 'Flag',
		desc: 'Objetivos Estratégicos',
		category: 'strategy',
		tags: ['objetivo', 'meta', 'bandeira', 'flag', 'marco', 'estratégia']
	},
	{
		name: 'track_changes',
		label: 'Track Changes',
		desc: 'Alvos & Foco',
		category: 'strategy',
		tags: ['alvo', 'foco', 'mira', 'track_changes', 'precisão', 'okr']
	},
	{
		name: 'explore',
		label: 'Explore',
		desc: 'Visão & Direção',
		category: 'strategy',
		tags: ['bússola', 'direção', 'visão', 'explore', 'futuro', 'estratégia']
	},
	{
		name: 'account_tree',
		label: 'Account Tree',
		desc: 'Desdobramento & Hierarquia',
		category: 'strategy',
		tags: ['árvore', 'cascata', 'organograma', 'account_tree', 'hierarquia']
	},
	{
		name: 'ads_click',
		label: 'Ads Click',
		desc: 'Conversão & Ação',
		category: 'strategy',
		tags: ['clique', 'conversão', 'meta', 'ads_click', 'ação']
	},
	{
		name: 'speed',
		label: 'Speed',
		desc: 'Velocidade & Tração',
		category: 'strategy',
		tags: ['velocidade', 'ritmo', 'agilidade', 'speed', 'tração']
	},
	{
		name: 'verified',
		label: 'Verified',
		desc: 'Validação & Qualidade',
		category: 'strategy',
		tags: ['verificado', 'aprovado', 'qualidade', 'verified', 'selo', 'sucesso']
	},
	{
		name: 'workspace_premium',
		label: 'Premium',
		desc: 'Excelência & Reconhecimento',
		category: 'strategy',
		tags: ['medalha', 'excelência', 'prêmio', 'workspace_premium', 'ouro']
	},
	{
		name: 'military_tech',
		label: 'Military Tech',
		desc: 'Liderança & Conquistas',
		category: 'strategy',
		tags: ['conquista', 'liderança', 'troféu', 'military_tech', 'vitória']
	},
	{
		name: 'diamond',
		label: 'Diamond',
		desc: 'Alto Valor & Destaque',
		category: 'strategy',
		tags: ['diamante', 'joia', 'valor', 'diamond', 'premium']
	},
	{
		name: 'trophy',
		label: 'Trophy',
		desc: 'Troféu & Vitória',
		category: 'strategy',
		tags: ['troféu', 'vitória', 'campeão', 'trophy', 'sucesso']
	},
	{
		name: 'stars',
		label: 'Stars',
		desc: 'Destaque & Aspirações',
		category: 'strategy',
		tags: ['estrelas', 'aspiração', 'sonho', 'stars', 'alto padrão']
	},
	{
		name: 'bolt',
		label: 'Bolt',
		desc: 'Energia & Impacto Rápido',
		category: 'strategy',
		tags: ['raio', 'impacto', 'energia', 'bolt', 'rapidez']
	},
	{
		name: 'timer',
		label: 'Timer',
		desc: 'Prazos & SLA',
		category: 'strategy',
		tags: ['tempo', 'prazo', 'sla', 'timer', 'cronômetro']
	},

	// --- FINANÇAS & MÉTRICAS ---
	{
		name: 'monitoring',
		label: 'Monitoring',
		desc: 'Monitoramento & Indicadores',
		category: 'finance',
		tags: ['kpi', 'monitoramento', 'indicador', 'monitoring', 'métricas']
	},
	{
		name: 'analytics',
		label: 'Analytics',
		desc: 'Métricas & BI',
		category: 'finance',
		tags: ['gráficos', 'bi', 'estatística', 'analytics', 'dados']
	},
	{
		name: 'query_stats',
		label: 'Query Stats',
		desc: 'Análise de Desempenho',
		category: 'finance',
		tags: ['análise', 'estatísticas', 'query_stats', 'performance']
	},
	{
		name: 'calculate',
		label: 'Calculate',
		desc: 'Cálculos & Controladoria',
		category: 'finance',
		tags: ['calculadora', 'contas', 'orçamento', 'calculate', 'matemática']
	},
	{
		name: 'account_balance_wallet',
		label: 'Wallet',
		desc: 'Carteira & Orçamento',
		category: 'finance',
		tags: ['carteira', 'orçamento', 'capital', 'account_balance_wallet', 'saldo']
	},
	{
		name: 'price_check',
		label: 'Price Check',
		desc: 'Precificação & Custos',
		category: 'finance',
		tags: ['preço', 'margem', 'custo', 'price_check', 'auditoria']
	},
	{
		name: 'receipt_long',
		label: 'Receipt Long',
		desc: 'Notas & Faturamento',
		category: 'finance',
		tags: ['recibo', 'nota', 'faturamento', 'receipt_long', 'fiscal']
	},
	{
		name: 'paid',
		label: 'Paid',
		desc: 'Receita & Lucro',
		category: 'finance',
		tags: ['pago', 'receita', 'lucro', 'paid', 'entrada', 'retorno']
	},
	{
		name: 'savings',
		label: 'Savings',
		desc: 'Economia & Eficiência',
		category: 'finance',
		tags: ['poupança', 'economia', 'eficiência', 'savings', 'reserva']
	},
	{
		name: 'tune',
		label: 'Tune',
		desc: 'Ajustes & Parâmetros',
		category: 'finance',
		tags: ['ajustes', 'parâmetros', 'tune', 'calibração', 'configuração']
	},
	{
		name: 'pie_chart',
		label: 'Pie Chart',
		desc: 'Distribuição & Quotas',
		category: 'finance',
		tags: ['pizza', 'gráfico', 'pie_chart', 'distribuição', 'divisão']
	},
	{
		name: 'credit_card',
		label: 'Credit Card',
		desc: 'Cartões & Transações',
		category: 'finance',
		tags: ['cartão', 'transação', 'crédito', 'credit_card', 'banco']
	},

	// --- TECNOLOGIA & PRODUTO ---
	{
		name: 'code',
		label: 'Code',
		desc: 'Programação & Engenharia',
		category: 'tech',
		tags: ['código', 'dev', 'programação', 'code', 'software']
	},
	{
		name: 'terminal',
		label: 'Terminal',
		desc: 'Sistemas & Backend',
		category: 'tech',
		tags: ['terminal', 'console', 'backend', 'servidor', 'devops']
	},
	{
		name: 'database',
		label: 'Database',
		desc: 'Banco de Dados',
		category: 'tech',
		tags: ['dados', 'database', 'sql', 'armazenamento', 'tabelas']
	},
	{
		name: 'cloud',
		label: 'Cloud',
		desc: 'Nuvem & Infraestrutura',
		category: 'tech',
		tags: ['nuvem', 'cloud', 'hospedagem', 'deploy', 'infra']
	},
	{
		name: 'lan',
		label: 'LAN',
		desc: 'Rede & Arquitetura',
		category: 'tech',
		tags: ['rede', 'conexão', 'lan', 'arquitetura', 'nós']
	},
	{
		name: 'devices',
		label: 'Devices',
		desc: 'Produtos & Multiplataforma',
		category: 'tech',
		tags: ['dispositivos', 'telas', 'multiplataforma', 'devices', 'app']
	},
	{
		name: 'laptop_mac',
		label: 'Laptop',
		desc: 'Estações & Equipamentos',
		category: 'tech',
		tags: ['computador', 'notebook', 'hardware', 'laptop_mac', 'estação']
	},
	{
		name: 'lock',
		label: 'Lock',
		desc: 'Segurança & Privacidade',
		category: 'tech',
		tags: ['segurança', 'cadeado', 'acesso', 'lock', 'proteção']
	},
	{
		name: 'shield',
		label: 'Shield',
		desc: 'Blindagem & Proteção',
		category: 'tech',
		tags: ['escudo', 'blindagem', 'defesa', 'shield', 'auditoria']
	},
	{
		name: 'api',
		label: 'API',
		desc: 'Integrações & APIs',
		category: 'tech',
		tags: ['api', 'integração', 'webhook', 'serviços', 'conectores']
	},
	{
		name: 'bug_report',
		label: 'Bug Report',
		desc: 'Qualidade & Testes QA',
		category: 'tech',
		tags: ['bug', 'qualidade', 'testes', 'bug_report', 'correção']
	},
	{
		name: 'build',
		label: 'Build',
		desc: 'Manutenção & Ferramentas',
		category: 'tech',
		tags: ['construção', 'ferramenta', 'build', 'manutenção']
	},

	// --- PESSOAS & CULTURA ---
	{
		name: 'diversity_3',
		label: 'Diversity',
		desc: 'Diversidade & Inclusão',
		category: 'culture',
		tags: ['diversidade', 'inclusão', 'comunidade', 'diversity_3', 'time']
	},
	{
		name: 'person',
		label: 'Person',
		desc: 'Indivíduo & Responsável',
		category: 'culture',
		tags: ['pessoa', 'indivíduo', 'responsável', 'person', 'líder']
	},
	{
		name: 'school',
		label: 'School',
		desc: 'Capacitação & Treinamento',
		category: 'culture',
		tags: ['escola', 'treinamento', 'educação', 'school', 'estudo']
	},
	{
		name: 'psychology',
		label: 'Psychology',
		desc: 'Mentalidade & Estratégia',
		category: 'culture',
		tags: ['mente', 'psicologia', 'pensamento', 'psychology', 'estratégia']
	},
	{
		name: 'lightbulb',
		label: 'Lightbulb',
		desc: 'Inovação & Ideias',
		category: 'culture',
		tags: ['ideia', 'lâmpada', 'inovação', 'lightbulb', 'criatividade']
	},
	{
		name: 'volunteer_activism',
		label: 'Volunteer',
		desc: 'Propósito & ESG',
		category: 'culture',
		tags: ['voluntariado', 'esg', 'propósito', 'volunteer_activism', 'social']
	},
	{
		name: 'favorite',
		label: 'Favorite',
		desc: 'Cuidado & Engajamento',
		category: 'culture',
		tags: ['coração', 'cuidado', 'engajamento', 'favorite', 'amor']
	},
	{
		name: 'thumb_up',
		label: 'Thumb Up',
		desc: 'Aprovação & Reconhecimento',
		category: 'culture',
		tags: ['positivo', 'curtida', 'aprovação', 'thumb_up', 'joinha']
	},
	{
		name: 'sentiment_satisfied',
		label: 'Satisfaction',
		desc: 'Clima Organizacional & NPS',
		category: 'culture',
		tags: ['clima', 'felicidade', 'nps', 'sentiment_satisfied', 'satisfação']
	},
	{
		name: 'support_agent',
		label: 'Support Agent',
		desc: 'Atendimento & Ouvidoria',
		category: 'culture',
		tags: ['suporte', 'atendimento', 'ajuda', 'support_agent', 'sac']
	},

	// --- COMUNICAÇÃO & MÍDIA ---
	{
		name: 'forum',
		label: 'Forum',
		desc: 'Discussões & Reuniões',
		category: 'comms',
		tags: ['fórum', 'discussão', 'chat', 'forum', 'comunicação']
	},
	{
		name: 'mail',
		label: 'Mail',
		desc: 'E-mails & Correspondência',
		category: 'comms',
		tags: ['email', 'mensagem', 'mail', 'correspondência']
	},
	{
		name: 'mark_email_read',
		label: 'Read Mail',
		desc: 'Comunicados Oficiais',
		category: 'comms',
		tags: ['comunicado', 'aviso', 'oficial', 'mark_email_read']
	},
	{
		name: 'public',
		label: 'Public',
		desc: 'Presença Global',
		category: 'comms',
		tags: ['globo', 'mundo', 'internacional', 'public', 'aberto']
	},
	{
		name: 'language',
		label: 'Language',
		desc: 'Idiomas & Expansão',
		category: 'comms',
		tags: ['idioma', 'língua', 'expansão', 'language', 'regional']
	},
	{
		name: 'connect_without_contact',
		label: 'Connect',
		desc: 'Networking & Contatos',
		category: 'comms',
		tags: ['networking', 'contato', 'conexão', 'connect_without_contact']
	},
	{
		name: 'share',
		label: 'Share',
		desc: 'Divulgação & Redes',
		category: 'comms',
		tags: ['compartilhar', 'divulgação', 'redes', 'share']
	},
	{
		name: 'rss_feed',
		label: 'RSS Feed',
		desc: 'Canais & Atualizações',
		category: 'comms',
		tags: ['feed', 'notícias', 'atualizações', 'rss_feed']
	},
	{
		name: 'newspaper',
		label: 'Newspaper',
		desc: 'Imprensa & Editorial',
		category: 'comms',
		tags: ['jornal', 'imprensa', 'artigos', 'newspaper', 'mídia']
	},

	// --- OPERAÇÕES & LOGÍSTICA ---
	{
		name: 'inventory_2',
		label: 'Inventory',
		desc: 'Estoque & Materiais',
		category: 'operations',
		tags: ['estoque', 'caixas', 'materiais', 'inventory_2', 'inventário']
	},
	{
		name: 'fact_check',
		label: 'Fact Check',
		desc: 'Conformidade & Auditoria',
		category: 'operations',
		tags: ['auditoria', 'conformidade', 'checklist', 'fact_check']
	},
	{
		name: 'local_shipping',
		label: 'Shipping',
		desc: 'Entregas & Distribuição',
		category: 'operations',
		tags: ['transporte', 'entrega', 'frete', 'local_shipping', 'logística']
	},
	{
		name: 'warehouse',
		label: 'Warehouse',
		desc: 'Infraestrutura & Operação',
		category: 'operations',
		tags: ['armazém', 'galpão', 'fábrica', 'warehouse', 'base']
	},
	{
		name: 'schedule',
		label: 'Schedule',
		desc: 'Cronograma & Prazos',
		category: 'operations',
		tags: ['cronograma', 'relógio', 'horário', 'schedule', 'agenda']
	},
	{
		name: 'calendar_month',
		label: 'Calendar Month',
		desc: 'Planejamento Mensal',
		category: 'operations',
		tags: ['calendário', 'mês', 'trimestre', 'calendar_month', 'planejamento']
	},
	{
		name: 'event_note',
		label: 'Event Note',
		desc: 'Notas & Reuniões',
		category: 'operations',
		tags: ['reunião', 'ata', 'anotação', 'event_note', 'evento']
	},
	{
		name: 'assignment',
		label: 'Assignment',
		desc: 'Tarefas & Demandas',
		category: 'operations',
		tags: ['tarefa', 'demanda', 'prancheta', 'assignment', 'atribuição']
	},
	{
		name: 'checklist',
		label: 'Checklist',
		desc: 'Listas & Verificações',
		category: 'operations',
		tags: ['checklist', 'lista', 'itens', 'checklist', 'controle']
	}
];

export function getProjectIcon(name?: string | null): ProjectIcon | null {
	if (!name) return null;
	const clean = name.trim().toLowerCase();
	return PROJECT_ICONS.find((i) => i.name.toLowerCase() === clean) ?? null;
}
