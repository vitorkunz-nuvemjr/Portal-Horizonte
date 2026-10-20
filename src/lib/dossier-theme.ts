/**
 * Dossier Theme Utility: Dynamic Soft-Tone Color System
 * Produces authentic physical file folder shades (soft pastel paper tinting,
 * borders, stitched-line accents, badges, and inputs) derived from any hex color.
 */

export interface DossierTheme {
	folderBg: string;
	folderBorder: string;
	footerBg: string;
	stitchedColor: string;
	cardBorder: string;
	inputBg: string;
	inputBorder: string;
	accent: string;
	accentDark: string;
	accentShadow: string;
	badgeBg: string;
	badgeText: string;
	badgeBorder: string;
}

export function getDossierTheme(hex?: string | null): DossierTheme {
	const c = (hex && hex.trim()) ? hex.trim().toLowerCase() : '#0058bd';

	// Specific presets for popular corporate palette colors to ensure optimal contrast
	if (c.includes('059669') || c.includes('10b981') || c.includes('047857')) {
		return {
			folderBg: '#f2f9f4',
			folderBorder: '#c6e7d0',
			footerBg: '#e4f3e9',
			stitchedColor: '#96d2a7',
			cardBorder: '#d1edd9',
			inputBg: '#f9fdfa',
			inputBorder: '#86efac',
			accent: '#059669',
			accentDark: '#065f46',
			accentShadow: '#064e3b',
			badgeBg: '#d1fae5',
			badgeText: '#065f46',
			badgeBorder: '#a7f3d0'
		};
	}

	if (c.includes('004190') || c.includes('0058bd') || c.includes('2563eb') || c.includes('3080f9')) {
		return {
			folderBg: '#f2f6fd',
			folderBorder: '#c2d6f8',
			footerBg: '#e5eeff',
			stitchedColor: '#99bdf4',
			cardBorder: '#d4e3fb',
			inputBg: '#f8faff',
			inputBorder: '#93c5fd',
			accent: '#0058bd',
			accentDark: '#003373',
			accentShadow: '#00224d',
			badgeBg: '#dbeafe',
			badgeText: '#1e40af',
			badgeBorder: '#bfdbfe'
		};
	}

	if (c.includes('7c3aed') || c.includes('6b52ae') || c.includes('8b5cf6')) {
		return {
			folderBg: '#f6f3fc',
			folderBorder: '#ded2f7',
			footerBg: '#ece6f9',
			stitchedColor: '#c4b0f0',
			cardBorder: '#e7dff9',
			inputBg: '#faf8fe',
			inputBorder: '#c4b5fd',
			accent: '#7c3aed',
			accentDark: '#5b21b6',
			accentShadow: '#4c1d95',
			badgeBg: '#ede9fe',
			badgeText: '#5b21b6',
			badgeBorder: '#ddd6fe'
		};
	}

	if (c.includes('b30069') || c.includes('db2777') || c.includes('f52a95')) {
		return {
			folderBg: '#fdf2f7',
			folderBorder: '#f8c3df',
			footerBg: '#fbe4f0',
			stitchedColor: '#f19ac9',
			cardBorder: '#f9d5e7',
			inputBg: '#fef8fb',
			inputBorder: '#f472b6',
			accent: '#b30069',
			accentDark: '#83004d',
			accentShadow: '#5c0036',
			badgeBg: '#fce7f3',
			badgeText: '#9d174d',
			badgeBorder: '#fbcfe8'
		};
	}

	if (c.includes('ea580c') || c.includes('f97316') || c.includes('c2410c')) {
		return {
			folderBg: '#fef5ee',
			folderBorder: '#fed5b8',
			footerBg: '#fdebe0',
			stitchedColor: '#fba872',
			cardBorder: '#fee1cb',
			inputBg: '#fffaf6',
			inputBorder: '#fdba74',
			accent: '#ea580c',
			accentDark: '#9a3412',
			accentShadow: '#7c2d12',
			badgeBg: '#ffedd5',
			badgeText: '#9a3412',
			badgeBorder: '#fed7aa'
		};
	}

	if (c.includes('00665a') || c.includes('0d9488') || c.includes('0f766e')) {
		return {
			folderBg: '#f0f9f8',
			folderBorder: '#bee8e3',
			footerBg: '#dff3f0',
			stitchedColor: '#86cfc5',
			cardBorder: '#ceeee8',
			inputBg: '#f7fdfc',
			inputBorder: '#5eead4',
			accent: '#00665a',
			accentDark: '#00473e',
			accentShadow: '#00332d',
			badgeBg: '#ccfbf1',
			badgeText: '#115e59',
			badgeBorder: '#99f6e4'
		};
	}

	if (c.includes('be123c') || c.includes('e11d48') || c.includes('9f1239') || c.includes('fda4af')) {
		return {
			folderBg: '#ffe4e6',
			folderBorder: '#fda4af',
			footerBg: '#fedfe2',
			stitchedColor: '#f43f5e',
			cardBorder: '#fecdd3',
			inputBg: '#fff1f2',
			inputBorder: '#fda4af',
			accent: '#e11d48',
			accentDark: '#9f1239',
			accentShadow: '#881337',
			badgeBg: '#fecdd3',
			badgeText: '#881337',
			badgeBorder: '#fda4af'
		};
	}

	if (c.includes('b45309') || c.includes('ca8a04') || c.includes('d97706') || c.includes('fef08a')) {
		return {
			folderBg: '#fef9c3',
			folderBorder: '#fde047',
			footerBg: '#fef3a0',
			stitchedColor: '#eab308',
			cardBorder: '#fef08a',
			inputBg: '#fefce8',
			inputBorder: '#fde047',
			accent: '#ca8a04',
			accentDark: '#92400e',
			accentShadow: '#78350f',
			badgeBg: '#fde047',
			badgeText: '#78350f',
			badgeBorder: '#facc15'
		};
	}

	if (c.includes('0284c7') || c.includes('0369a1') || c.includes('0ea5e9')) {
		return {
			folderBg: '#f0f8fc',
			folderBorder: '#bfe1f5',
			footerBg: '#e0f1fa',
			stitchedColor: '#84c5eb',
			cardBorder: '#d0e9f7',
			inputBg: '#f7fbfe',
			inputBorder: '#7dd3fc',
			accent: '#0284c7',
			accentDark: '#075985',
			accentShadow: '#0c4a6e',
			badgeBg: '#e0f2fe',
			badgeText: '#0369a1',
			badgeBorder: '#bae6fd'
		};
	}

	// Dynamic fallback for any other hex code using standard CSS color-mix
	return {
		folderBg: `color-mix(in srgb, ${c} 9%, #fffbf5)`,
		folderBorder: `color-mix(in srgb, ${c} 28%, #d5cebe)`,
		footerBg: `color-mix(in srgb, ${c} 14%, #fffbf5)`,
		stitchedColor: `color-mix(in srgb, ${c} 35%, #b4c8b7)`,
		cardBorder: `color-mix(in srgb, ${c} 20%, #e8e2d8)`,
		inputBg: `color-mix(in srgb, ${c} 4%, #ffffff)`,
		inputBorder: `color-mix(in srgb, ${c} 30%, #d5cebe)`,
		accent: c,
		accentDark: `color-mix(in srgb, ${c} 80%, #000000)`,
		accentShadow: `color-mix(in srgb, ${c} 70%, #000000)`,
		badgeBg: `color-mix(in srgb, ${c} 14%, #ffffff)`,
		badgeText: `color-mix(in srgb, ${c} 85%, #000000)`,
		badgeBorder: `color-mix(in srgb, ${c} 30%, #ffffff)`
	};
}
