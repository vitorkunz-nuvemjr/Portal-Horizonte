import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
	return twMerge(clsx(inputs));
}

export function formatPct(val: number): string {
	return `${Math.round(Math.max(0, Math.min(1, val)) * 100)}%`;
}

export function formatNumber(val: number | null | undefined, unit?: string | null): string {
	if (val == null || Number.isNaN(val)) return '—';
	const formatted = new Intl.NumberFormat('pt-BR', {
		maximumFractionDigits: 2
	}).format(val);
	if (!unit) return formatted;
	if (unit === '%' || unit === 'h' || unit === 'x') return `${formatted}${unit}`;
	if (unit === 'R$' || unit === '$' || unit === '€') return `${unit} ${formatted}`;
	return `${formatted} ${unit}`;
}

export function getInitials(name: string): string {
	return name
		.split(/\s+/)
		.filter(Boolean)
		.slice(0, 2)
		.map((part) => part[0]?.toUpperCase() ?? '')
		.join('');
}

/**
 * Form action attachment that implements the `:user-invalid` ARIA state bridge
 * and fallback for browsers without `:user-invalid` support.
 */
export function enhanceFormValidation(form: HTMLFormElement) {
	const dirtyState = new WeakMap<HTMLElement, { hasInteracted: boolean; hasBlurred: boolean }>();
	const supportsUserInvalid =
		typeof CSS !== 'undefined' && typeof CSS.supports === 'function'
			? CSS.supports('selector(:user-invalid)')
			: true;

	const syncAriaInvalid = (input: HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement) => {
		if (!input.checkValidity) return;
		const isValid = input.checkValidity();
		if (!supportsUserInvalid) {
			input.classList.toggle('user-invalid-fallback', !isValid);
			input.classList.toggle('user-valid-fallback', isValid);
		}
		if (!isValid) {
			input.setAttribute('aria-invalid', 'true');
		} else {
			input.removeAttribute('aria-invalid');
		}
	};

	const onBlur = (e: Event) => {
		const target = e.target as HTMLInputElement | null;
		if (!target || typeof target.matches !== 'function') return;
		if (target.matches('input[required], select[required], textarea[required]')) {
			const state = dirtyState.get(target) || { hasInteracted: false, hasBlurred: false };
			state.hasBlurred = true;
			dirtyState.set(target, state);
			if (supportsUserInvalid) {
				target.setAttribute('aria-invalid', target.matches(':user-invalid') ? 'true' : 'false');
			} else if (state.hasInteracted) {
				syncAriaInvalid(target);
			}
		}
	};

	const onInput = (e: Event) => {
		const target = e.target as HTMLInputElement | null;
		if (!target || typeof target.matches !== 'function') return;
		if (target.matches('input[required], select[required], textarea[required]')) {
			const state = dirtyState.get(target) || { hasInteracted: false, hasBlurred: false };
			state.hasInteracted = true;
			dirtyState.set(target, state);
			if (target.checkValidity()) {
				target.removeAttribute('aria-invalid');
				target.classList.remove('user-invalid-fallback');
			} else if (!supportsUserInvalid && state.hasBlurred) {
				syncAriaInvalid(target);
			}
		}
	};

	const onSubmit = () => {
		form
			.querySelectorAll<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>(
				'input[required], select[required], textarea[required]'
			)
			.forEach(syncAriaInvalid);
	};

	form.addEventListener('blur', onBlur, true);
	form.addEventListener('input', onInput);
	form.addEventListener('submit', onSubmit);

	return {
		destroy() {
			form.removeEventListener('blur', onBlur, true);
			form.removeEventListener('input', onInput);
			form.removeEventListener('submit', onSubmit);
		}
	};
}
