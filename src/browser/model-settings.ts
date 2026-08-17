type CodexConfiguration = {
  baseUrl: string | null;
  configPath: string;
  model: string | null;
  provider: string | null;
  requiresOpenaiAuth: boolean | null;
  token: string | null;
  wireApi: string | null;
};

const API_PATH = "/__backend/config/codex";
const PANEL_ID = "codex-web-provider-settings";
const CHATGPT_MODEL_PICKER_STYLE_ID = "codex-web-hide-chatgpt-model-picker";

function hideChatGptModelPicker(): void {
  if (document.getElementById(CHATGPT_MODEL_PICKER_STYLE_ID)) return;

  const styles = element("style");
  styles.id = CHATGPT_MODEL_PICKER_STYLE_ID;
  styles.textContent = `
    [data-codex-intelligence-trigger] { display: none !important; }
  `;
  document.head.append(styles);
}

function element<K extends keyof HTMLElementTagNameMap>(
  tagName: K,
  className?: string,
): HTMLElementTagNameMap[K] {
  const result = document.createElement(tagName);
  if (className) result.className = className;
  return result;
}

function input(name: string, label: string, type = "text"): HTMLInputElement {
  const field = element("label", "codex-web-config-field");
  field.textContent = label;
  const control = element("input");
  control.name = name;
  control.type = type;
  control.autocomplete = "off";
  field.append(control);
  return control;
}

function select(name: string, label: string, options: string[]): HTMLSelectElement {
  const field = element("label", "codex-web-config-field");
  field.textContent = label;
  const control = element("select");
  control.name = name;
  for (const value of options) {
    const option = element("option");
    option.value = value;
    option.textContent = value;
    control.append(option);
  }
  field.append(control);
  return control;
}

async function getConfiguration(): Promise<CodexConfiguration> {
  const response = await fetch(API_PATH);
  if (!response.ok) throw new Error("Could not load Codex configuration.");
  return response.json() as Promise<CodexConfiguration>;
}

async function saveConfiguration(
  configuration: CodexConfiguration,
): Promise<CodexConfiguration> {
  const response = await fetch(API_PATH, {
    method: "PUT",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(configuration),
  });
  if (!response.ok) {
    const payload = (await response.json().catch(() => null)) as {
      error?: unknown;
    } | null;
    throw new Error(
      typeof payload?.error === "string"
        ? payload.error
        : "Could not save Codex configuration.",
    );
  }
  return response.json() as Promise<CodexConfiguration>;
}

export function installModelSettings(): void {
  const mount = (): void => {
    hideChatGptModelPicker();
    if (document.getElementById(PANEL_ID)) return;

    const styles = element("style");
    styles.textContent = `
      #${PANEL_ID} { display:none; position:fixed; z-index:2147483647; top:50%; left:50%; box-sizing:border-box; width:min(680px,calc(100vw - 32px)); max-height:calc(100vh - 32px); overflow:auto; transform:translate(-50%,-50%); color:inherit; font:13px ui-sans-serif,system-ui,sans-serif; }
      #${PANEL_ID}[data-visible="true"] { display:block; }
      .codex-web-config-card { border:1px solid rgba(127,127,127,.42); border-radius:12px; padding:24px; background:#202020; color:#f4f4f4; box-shadow:0 20px 60px rgba(0,0,0,.48); }
      .codex-web-config-heading { display:flex; align-items:flex-start; justify-content:space-between; gap:16px; } .codex-web-config-card h2 { margin:0 0 7px; font-size:18px; } .codex-web-config-card p { margin:0 0 18px; color:inherit; opacity:.72; font-size:13px; line-height:1.5; }
      .codex-web-config-grid { display:grid; grid-template-columns:1fr 1fr; gap:14px; } .codex-web-config-field { display:grid; gap:6px; color:inherit; font-size:13px; } .codex-web-config-field:first-child, .codex-web-config-field:nth-child(4), .codex-web-config-field:nth-child(5) { grid-column:1 / -1; }
      .codex-web-config-field input, .codex-web-config-field select { min-width:0; box-sizing:border-box; width:100%; border:1px solid rgba(127,127,127,.65); border-radius:7px; padding:9px; color:inherit; background:#151515; font:inherit; }
      .codex-web-config-switch { display:flex; align-items:center; gap:8px; margin-top:16px; font-size:13px; } .codex-web-config-switch input { accent-color:currentColor; }
      .codex-web-config-actions { display:flex; justify-content:flex-end; gap:8px; margin-top:18px; } .codex-web-config-actions button, .codex-web-config-close { border:1px solid rgba(127,127,127,.55); border-radius:7px; padding:8px 12px; cursor:pointer; font:inherit; } .codex-web-config-save { border-color:#e7e7e7 !important; background:#e7e7e7; color:#151515; font-weight:650; } .codex-web-config-close { display:grid; place-items:center; min-width:32px; padding:4px; background:transparent; color:#f4f4f4; font-size:20px; line-height:1; }
      .codex-web-config-status { min-height:18px; margin-top:11px !important; } .codex-web-config-status[data-error="true"] { color:#d95050; opacity:1; }
      @media (max-width: 600px) { .codex-web-config-grid { grid-template-columns:1fr; } .codex-web-config-field { grid-column:1 / -1 !important; } .codex-web-config-card { padding:16px; } }
    `;
    document.head.append(styles);

    const root = element("section");
    root.id = PANEL_ID;
    root.dataset.visible = "false";
    const card = element("div", "codex-web-config-card");
    const cardHeading = element("div", "codex-web-config-heading");
    const titleContainer = element("div");
    const heading = element("h2");
    heading.textContent = "Codex Web provider";
    const description = element("p");
    description.textContent = "These settings are saved locally in your Codex configuration. Restart the server after saving to apply the updated provider and model.";
    titleContainer.append(heading, description);
    const close = element("button", "codex-web-config-close");
    close.type = "button";
    close.textContent = "×";
    close.setAttribute("aria-label", "Close provider configuration");
    cardHeading.append(titleContainer, close);
    const grid = element("div", "codex-web-config-grid");
    const model = input("model", "Model");
    const provider = input("provider", "Provider ID");
    const wireApi = select("wireApi", "Wire API", [
      "responses",
      "chat_completions",
    ]);
    const baseUrl = input("baseUrl", "Base URL");
    const token = input("token", "API token", "password");
    token.placeholder = "Leave blank to keep the current token";
    grid.append(
      model.parentElement!,
      provider.parentElement!,
      wireApi.parentElement!,
      baseUrl.parentElement!,
      token.parentElement!,
    );
    const authLabel = element("label", "codex-web-config-switch");
    const requiresOpenaiAuth = element("input");
    requiresOpenaiAuth.type = "checkbox";
    authLabel.append(requiresOpenaiAuth, "Use OpenAI account authentication");
    const actions = element("div", "codex-web-config-actions");
    const save = element("button", "codex-web-config-save");
    save.type = "button";
    save.textContent = "Save configuration";
    actions.append(save);
    const status = element("p", "codex-web-config-status");
    card.append(cardHeading, grid, authLabel, actions, status);
    root.append(card);
    document.body.append(root);

    let loaded: CodexConfiguration | null = null;
    const setStatus = (message: string, failed = false): void => {
      status.textContent = message;
      status.dataset.error = String(failed);
    };
    const populate = (config: CodexConfiguration): void => {
      loaded = config;
      model.value = config.model ?? "";
      provider.value = config.provider ?? "";
      wireApi.value = config.wireApi === "chat_completions" ? "chat_completions" : "responses";
      baseUrl.value = config.baseUrl ?? "";
      token.value = "";
      requiresOpenaiAuth.checked = config.requiresOpenaiAuth ?? false;
      setStatus(`Loaded from ${config.configPath}`);
    };
    const load = (): void => {
      setStatus("Loading configuration…");
      void getConfiguration()
        .then(populate)
        .catch((error: unknown) =>
          setStatus(error instanceof Error ? error.message : String(error), true),
        );
    };
    const open = (): void => {
      root.dataset.visible = "true";
      if (!loaded) {
        load();
      }
    };

    window.addEventListener("codex-web-open-provider-settings", open);
    close.addEventListener("click", () => {
      root.dataset.visible = "false";
    });
    window.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && root.dataset.visible === "true") {
        root.dataset.visible = "false";
      }
    });
    root.addEventListener("click", (event) => {
      if (event.target === root) root.dataset.visible = "false";
    });

    save.addEventListener("click", () => {
      if (!loaded) return;
      const next = {
        ...loaded,
        model: model.value.trim() || null,
        provider: provider.value.trim() || null,
        wireApi: wireApi.value.trim() || null,
        baseUrl: baseUrl.value.trim() || null,
        token: token.value.trim() || loaded.token,
        requiresOpenaiAuth: requiresOpenaiAuth.checked,
      };
      save.disabled = true;
      setStatus("Saving configuration…");
      void saveConfiguration(next)
        .then((config) => {
          populate(config);
          setStatus("Saved. Restart the server to use the updated settings.");
        })
        .catch((error: unknown) =>
          setStatus(error instanceof Error ? error.message : String(error), true),
        )
        .finally(() => {
          save.disabled = false;
        });
    });

  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", mount, { once: true });
  } else {
    mount();
  }
}
