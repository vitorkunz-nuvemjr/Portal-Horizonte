// Paper Strategist semantic category colors & pastels
const PALETTE = [
	{ solid: '#0058bd', bg: '#d8e2ff', text: '#001a41' }, // Electric Blue
	{ solid: '#b30069', bg: '#ffd9e4', text: '#3e0021' }, // Punchy Magenta
	{ solid: '#c2ac00', bg: '#FAF1D0', text: '#494000' }, // Sunshine / Butter Amber
	{ solid: '#2D6E42', bg: '#DEEFE3', text: '#14532D' }, // Sage Mint
	{ solid: '#6B52AE', bg: '#E8E2F8', text: '#3b0764' }, // Soft Lavender
	{ solid: '#9C4728', bg: '#FCE4DB', text: '#7C2D12' } // Coral Peach
];

function pickEntry(valueId: string) {
	if (valueId.includes('excelencia')) return PALETTE[0];
	if (valueId.includes('nuvem') || valueId.includes('orgulho')) return PALETTE[2];
	if (valueId.includes('cliente') || valueId.includes('foco')) return PALETTE[1];
	let h = 0;
	for (let i = 0; i < valueId.length; i++) {
		h = (h * 31 + valueId.charCodeAt(i)) | 0;
	}
	return PALETTE[Math.abs(h) % PALETTE.length];
}

export function valueColor(valueId: string): string {
	return pickEntry(valueId).solid;
}

export function valueBgColor(valueId: string): string {
	return pickEntry(valueId).bg;
}

export function valueTextColor(valueId: string): string {
	return pickEntry(valueId).text;
}
