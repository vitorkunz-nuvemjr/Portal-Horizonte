import type { Profile, Team, Cycle } from '$lib/types';
import { getDossierTheme } from '$lib/dossier-theme';

export function formatDate(iso: string | null | undefined): string {
	if (!iso) return '—';
	const parts = iso.split('-');
	if (parts.length === 3) {
		return `${parts[2]}/${parts[1]}/${parts[0]}`;
	}
	return iso;
}

export function getUserTeams(data: { teams?: Team[]; teamMembers?: any[] }, userId: string): Team[] {
	const tids = (data.teamMembers ?? [])
		.filter((tm: any) => tm.user_id === userId)
		.map((tm: any) => tm.team_id);
	return (data.teams ?? []).filter((t: Team) => tids.includes(t.id));
}

export function getTeamMembers(data: { profiles?: Profile[]; teamMembers?: any[] }, teamId: string): Profile[] {
	const uids = (data.teamMembers ?? [])
		.filter((tm: any) => tm.team_id === teamId)
		.map((tm: any) => tm.user_id);
	return (data.profiles ?? []).filter((p: Profile) => uids.includes(p.id));
}

export function getTeamVisual(name: string, fallbackColor?: string | null, fallbackIcon?: string | null) {
	const n = (name || '').toLowerCase();
	let icon = fallbackIcon && fallbackIcon.trim() ? fallbackIcon.trim() : 'apartment';
	let defaultHex = '#0058bd';

	if (!fallbackIcon || !fallbackIcon.trim()) {
		if (n.includes('presid') || n.includes('governan') || n.includes('institu')) {
			icon = 'account_balance';
			defaultHex = '#0058bd';
		} else if (n.includes('finan') || n.includes('adm') || n.includes('juríd') || n.includes('jurid')) {
			icon = 'payments';
			defaultHex = '#0284c7';
		} else if (n.includes('comerc') || n.includes('venda')) {
			icon = 'storefront';
			defaultHex = '#059669';
		} else if (n.includes('market') || n.includes('mkt') || n.includes('comunic')) {
			icon = 'campaign';
			defaultHex = '#ea580c';
		} else if (n.includes('projet') || n.includes('dev') || n.includes('consult')) {
			icon = 'rocket_launch';
			defaultHex = '#7c3aed';
		} else if (n.includes('pesso') || n.includes('gp') || n.includes('gente') || n.includes('rh')) {
			icon = 'groups';
			defaultHex = '#ca8a04';
		} else if (n.includes('todas') || n.includes('geral')) {
			icon = 'hub';
			defaultHex = '#ca8a04';
		}
	}

	const activeHex = fallbackColor && fallbackColor.trim() ? fallbackColor : defaultHex;
	const theme = getDossierTheme(activeHex);

	return {
		icon,
		theme,
		iconColor: theme.accent,
		bgStyle: `background-color: ${theme.folderBg}; border-color: ${theme.folderBorder};`,
		pillStyle: `background-color: ${theme.badgeBg}; border-color: ${theme.badgeBorder}; color: ${theme.badgeText};`,
		dotColor: theme.accent
	};
}

export function generateSnapshot(data: any) {
	return {
		version: 4,
		exported_at: new Date().toISOString(),
		profiles: data.profiles ?? [],
		teams: data.teams ?? [],
		team_members: data.teamMembers ?? [],
		cycles: data.cycles ?? [],
		nodes: data.nodes ?? [],
		node_assignees: data.assigns ?? [],
		node_teams: data.nodeTeams ?? [],
		node_values: data.values ?? [],
		metric_updates: data.metricUpdates ?? []
	};
}

export function downloadSnapshot(data: any) {
	const snapshot = generateSnapshot(data);
	const blob = new Blob([JSON.stringify(snapshot, null, 2)], { type: 'application/json' });
	const url = URL.createObjectURL(blob);
	const a = document.createElement('a');
	a.href = url;
	a.download = `horizonte-okrs-export-${new Date().toISOString().slice(0, 10)}.json`;
	a.click();
	URL.revokeObjectURL(url);
}
