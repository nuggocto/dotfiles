import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const stateHome = process.env.XDG_STATE_HOME ?? join(process.env.HOME ?? "", ".local/state");
const colorsPath = join(stateHome, "omarchy/current/theme/colors.toml");

function activeTheme(): "rose-pine-dawn" | "solitude" {
	try {
		return /^mode\s*=\s*["']light["']/m.test(readFileSync(colorsPath, "utf8"))
			? "rose-pine-dawn"
			: "solitude";
	} catch {
		return "solitude";
	}
}

export default function (pi: ExtensionAPI) {
	let intervalId: ReturnType<typeof setInterval> | undefined;

	pi.on("session_start", (_event, ctx) => {
		let currentTheme = activeTheme();
		ctx.ui.setTheme(currentTheme);

		intervalId = setInterval(() => {
			const nextTheme = activeTheme();
			if (nextTheme !== currentTheme) {
				currentTheme = nextTheme;
				ctx.ui.setTheme(currentTheme);
			}
		}, 2000);
	});

	pi.on("session_shutdown", () => {
		if (intervalId) clearInterval(intervalId);
		intervalId = undefined;
	});
}
