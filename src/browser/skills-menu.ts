const PLUGINS_SETTINGS_PATH = "plugins-settings";

function hasExactText(element: HTMLElement, value: string): boolean {
  return element.textContent?.trim() === value;
}

function replaceExactText(element: HTMLElement, from: string, to: string): void {
  const textNodes = document.createTreeWalker(element, NodeFilter.SHOW_TEXT);
  let node: Text | null;
  while ((node = textNodes.nextNode() as Text | null)) {
    if (node.nodeValue?.trim() === from) {
      node.nodeValue = node.nodeValue.replace(from, to);
    }
  }
}

function renamePluginsSettingsMenuItem(): void {
  for (const link of document.querySelectorAll<HTMLAnchorElement>(
    `a[href*="${PLUGINS_SETTINGS_PATH}"]`,
  )) {
    if (hasExactText(link, "Plugins")) {
      replaceExactText(link, "Plugins", "Skills");
    }

    if (link.getAttribute("aria-label") === "Plugins") {
      link.setAttribute("aria-label", "Skills");
    }
  }
}

function findTab(label: string): HTMLElement | null {
  return Array.from(
    document.querySelectorAll<HTMLElement>("[role='tab'], [role='tablist'] button"),
  ).find((element) => hasExactText(element, label)) ?? null;
}

function placeSkillsBeforePluginsTab(): void {
  const skillsTab = findTab("Skills");
  const pluginsTab = findTab("Plugins");
  const tabList = skillsTab?.closest<HTMLElement>("[role='tablist']");

  if (!skillsTab || !pluginsTab || !tabList || pluginsTab.parentElement !== tabList) {
    return;
  }
  if (skillsTab.nextElementSibling === pluginsTab) {
    return;
  }

  tabList.insertBefore(skillsTab, pluginsTab);
}

export function installSkillsMenuCustomization(): void {
  let scheduled = false;
  const update = (): void => {
    scheduled = false;
    renamePluginsSettingsMenuItem();
    placeSkillsBeforePluginsTab();
  };
  const scheduleUpdate = (): void => {
    if (scheduled) return;
    scheduled = true;
    queueMicrotask(update);
  };

  const mount = (): void => {
    scheduleUpdate();
    new MutationObserver(scheduleUpdate).observe(document.body, {
      childList: true,
      subtree: true,
    });
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", mount, { once: true });
  } else {
    mount();
  }
}
