/**
 * Dossier Theme Utility: Dynamic Soft-Tone & Muted Color System
 * Produces authentic physical file folder shades (soft pastel paper tinting,
 * muted cardstock surfaces, borders, stitched-line accents, team chips, and inputs)
 * derived from any hex color following the Paper Strategist design system.
 */

export interface DossierTheme {
	rawHex: string;
	folderBg: string;
	folderBorder: string;
	footerBg: string;
	stitchedColor: string;
	cardBg: string;
	cardBorder: string;
	inputBg: string;
	inputBorder: string;
	accent: string;
	accentMuted: string;
	accentDark: string;
	accentShadow: string;
	badgeBg: string;
	badgeText: string;
	badgeBorder: string;
}

export interface ColorPreset {
	name: string;
	hex: string;
}

/**
 * Main canonical project colors displayed in the first stage of the color picker.
 */
export const PROJECT_MAIN_COLORS: ColorPreset[] = [
	{ name: 'Carvão Grafite', hex: '#1d1b17' },
	{ name: 'Laranja Terracota', hex: '#ea580c' },
	{ name: 'Âmbar Solar', hex: '#ca8a04' },
	{ name: 'Verde Esmeralda', hex: '#059669' },
	{ name: 'Azul Céu', hex: '#0284c7' },
	{ name: 'Azul Horizonte', hex: '#0058bd' },
	{ name: 'Roxo Estratégico', hex: '#7c3aed' },
	{ name: 'Framboesa Magenta', hex: '#b30069' }
];

/**
 * Parse any 3, 6, or 8 digit hex string into RGB [0..255].
 */
export function parseHexToRgb(hex?: string | null): [number, number, number] {
	if (!hex) return [0, 88, 189];
	const clean = hex.trim().replace(/^#/, '');
	if (/^[0-9a-fA-F]{3}$/.test(clean)) {
		const r = parseInt(clean[0] + clean[0], 16);
		const g = parseInt(clean[1] + clean[1], 16);
		const b = parseInt(clean[2] + clean[2], 16);
		return [r, g, b];
	}
	if (/^[0-9a-fA-F]{6,8}$/.test(clean)) {
		const r = parseInt(clean.slice(0, 2), 16);
		const g = parseInt(clean.slice(2, 4), 16);
		const b = parseInt(clean.slice(4, 6), 16);
		return [r, g, b];
	}
	return [0, 88, 189];
}

export function rgbToHex(r: number, g: number, b: number): string {
	const clamp = (n: number) => Math.max(0, Math.min(255, Math.round(n)));
	return (
		'#' +
		[clamp(r), clamp(g), clamp(b)]
			.map((v) => v.toString(16).padStart(2, '0'))
			.join('')
	);
}

export function rgbToHsl(r: number, g: number, b: number): [number, number, number] {
	r /= 255;
	g /= 255;
	b /= 255;
	const max = Math.max(r, g, b);
	const min = Math.min(r, g, b);
	let h = 0;
	let s = 0;
	const l = (max + min) / 2;

	if (max !== min) {
		const d = max - min;
		s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
		switch (max) {
			case r:
				h = (g - b) / d + (g < b ? 6 : 0);
				break;
			case g:
				h = (b - r) / d + 2;
				break;
			case b:
				h = (r - g) / d + 4;
				break;
		}
		h /= 6;
	}
	return [Math.round(h * 360), Math.round(s * 100), Math.round(l * 100)];
}

export function hslToRgb(h: number, s: number, l: number): [number, number, number] {
	h = ((h % 360) + 360) % 360;
	s = Math.max(0, Math.min(100, s)) / 100;
	l = Math.max(0, Math.min(100, l)) / 100;

	const c = (1 - Math.abs(2 * l - 1)) * s;
	const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
	const m = l - c / 2;
	let r = 0,
		g = 0,
		b = 0;

	if (h < 60) [r, g, b] = [c, x, 0];
	else if (h < 120) [r, g, b] = [x, c, 0];
	else if (h < 180) [r, g, b] = [0, c, x];
	else if (h < 240) [r, g, b] = [0, x, c];
	else if (h < 300) [r, g, b] = [x, 0, c];
	else [r, g, b] = [c, 0, x];

	return [
		Math.round((r + m) * 255),
		Math.round((g + m) * 255),
		Math.round((b + m) * 255)
	];
}

export function hsvToRgb(h: number, s: number, v: number): [number, number, number] {
	h = ((h % 360) + 360) % 360;
	s = Math.max(0, Math.min(100, s)) / 100;
	v = Math.max(0, Math.min(100, v)) / 100;

	const c = v * s;
	const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
	const m = v - c;
	let r = 0,
		g = 0,
		b = 0;

	if (h < 60) [r, g, b] = [c, x, 0];
	else if (h < 120) [r, g, b] = [x, c, 0];
	else if (h < 180) [r, g, b] = [0, c, x];
	else if (h < 240) [r, g, b] = [0, x, c];
	else if (h < 300) [r, g, b] = [x, 0, c];
	else [r, g, b] = [c, 0, x];

	return [
		Math.round((r + m) * 255),
		Math.round((g + m) * 255),
		Math.round((b + m) * 255)
	];
}

export function rgbToHsv(r: number, g: number, b: number): [number, number, number] {
	r /= 255;
	g /= 255;
	b /= 255;
	const max = Math.max(r, g, b);
	const min = Math.min(r, g, b);
	const d = max - min;
	let h = 0;
	const s = max === 0 ? 0 : d / max;
	const v = max;

	if (max !== min) {
		switch (max) {
			case r:
				h = (g - b) / d + (g < b ? 6 : 0);
				break;
			case g:
				h = (b - r) / d + 2;
				break;
			case b:
				h = (r - g) / d + 4;
				break;
		}
		h /= 6;
	}
	return [Math.round(h * 360), Math.round(s * 100), Math.round(v * 100)];
}

/**
 * Mixes two RGB colors by weight (0 = 100% base, 1 = 100% tint)
 */
function mixRgb(
	c1: [number, number, number],
	c2: [number, number, number],
	ratio: number
): string {
	const w = Math.max(0, Math.min(1, ratio));
	return rgbToHex(
		c1[0] * (1 - w) + c2[0] * w,
		c1[1] * (1 - w) + c2[1] * w,
		c1[2] * (1 - w) + c2[2] * w
	);
}

/**
 * Generates a vibrant, light-tinted Paper Strategist theme from any hex color.
 * Produces a clean, vibrant light pastel card/folder surface paired with rich,
 * high-contrast colorful text, badges, borders, and progress accents.
 */
export function getDossierTheme(hex?: string | null): DossierTheme {
	const rawClean = hex && hex.trim() ? hex.trim() : '#0058bd';
	const [r, g, b] = parseHexToRgb(rawClean);
	const rawHex = rgbToHex(r, g, b);
	const [h, s, l] = rgbToHsl(r, g, b);

	const isAchromatic = s < 10;
	if (isAchromatic) {
		return {
			rawHex,
			folderBg: '#f3f1ed',
			folderBorder: '#cfc9be',
			footerBg: '#e7e3dc',
			stitchedColor: '#b5aea0',
			cardBg: '#f9f8f6',
			cardBorder: '#dbd5ca',
			inputBg: '#ffffff',
			inputBorder: '#c9c2b6',
			accent: '#2d2a24',
			accentMuted: '#3d3931',
			accentDark: '#1d1b17',
			accentShadow: '#12100d',
			badgeBg: '#e5e0d7',
			badgeText: '#1d1b17',
			badgeBorder: '#c2bbb0'
		};
	}

	// Yellow/amber hues (38°..65°) shift slightly warmer in dark text shades so they look rich gold/amber instead of olive
	const isYellowHue = h >= 38 && h <= 65;
	const textHue = isYellowHue ? Math.max(24, h - 12) : h;

	// High saturation for vibrant accents, borders, and colorful text
	const vividSat = Math.min(96, Math.max(76, s));
	const bgSat = Math.min(95, Math.max(75, s));
	const borderSat = Math.min(92, Math.max(74, s));

	// Vibrant primary accent (bars, icons, status dots, active buttons)
	const accentLight = isYellowHue ? 40 : Math.min(46, Math.max(36, l));
	const accentRgb = hslToRgb(h, vividSat, accentLight);
	const accent = rgbToHex(accentRgb[0], accentRgb[1], accentRgb[2]);

	// Slightly softer mid-vibrant accent for avatars/secondary fills
	const mutedRgb = hslToRgb(h, Math.max(70, vividSat - 6), Math.min(48, accentLight + 4));
	const accentMuted = rgbToHex(mutedRgb[0], mutedRgb[1], mutedRgb[2]);

	// Rich, colorful dark ink for card text & labels (high contrast against light cardBg/folderBg)
	const darkRgb = hslToRgb(textHue, Math.min(94, vividSat + 4), isYellowHue ? 28 : 27);
	const shadowRgb = hslToRgb(textHue, Math.min(96, vividSat + 6), isYellowHue ? 21 : 20);
	const accentDark = rgbToHex(darkRgb[0], darkRgb[1], darkRgb[2]);
	const accentShadow = rgbToHex(shadowRgb[0], shadowRgb[1], shadowRgb[2]);

	// Light, vibrant pastel card & folder surfaces (high contrast with accentDark / accentShadow text)
	const folderBgRgb = hslToRgb(h, bgSat, isYellowHue ? 90 : 92);
	const cardBgRgb = hslToRgb(h, bgSat, isYellowHue ? 94 : 95);
	const footerBgRgb = hslToRgb(h, bgSat, isYellowHue ? 85 : 88);

	const folderBorderRgb = hslToRgb(h, borderSat, isYellowHue ? 66 : 75);
	const cardBorderRgb = hslToRgb(h, borderSat, isYellowHue ? 72 : 80);
	const stitchedRgb = hslToRgb(h, borderSat, isYellowHue ? 58 : 66);

	const inputBgRgb = hslToRgb(h, bgSat, 98);
	const inputBorderRgb = hslToRgb(h, borderSat, isYellowHue ? 68 : 74);

	// Vibrant team chip & badge surfaces with deep colorful text
	const badgeBgRgb = hslToRgb(h, Math.min(96, bgSat + 4), isYellowHue ? 81 : 85);
	const badgeBorderRgb = hslToRgb(h, borderSat, isYellowHue ? 58 : 68);

	return {
		rawHex,
		folderBg: rgbToHex(folderBgRgb[0], folderBgRgb[1], folderBgRgb[2]),
		folderBorder: rgbToHex(folderBorderRgb[0], folderBorderRgb[1], folderBorderRgb[2]),
		footerBg: rgbToHex(footerBgRgb[0], footerBgRgb[1], footerBgRgb[2]),
		stitchedColor: rgbToHex(stitchedRgb[0], stitchedRgb[1], stitchedRgb[2]),
		cardBg: rgbToHex(cardBgRgb[0], cardBgRgb[1], cardBgRgb[2]),
		cardBorder: rgbToHex(cardBorderRgb[0], cardBorderRgb[1], cardBorderRgb[2]),
		inputBg: rgbToHex(inputBgRgb[0], inputBgRgb[1], inputBgRgb[2]),
		inputBorder: rgbToHex(inputBorderRgb[0], inputBorderRgb[1], inputBorderRgb[2]),
		accent,
		accentMuted,
		accentDark,
		accentShadow,
		badgeBg: rgbToHex(badgeBgRgb[0], badgeBgRgb[1], badgeBgRgb[2]),
		badgeText: accentDark,
		badgeBorder: rgbToHex(badgeBorderRgb[0], badgeBorderRgb[1], badgeBorderRgb[2])
	};
}
