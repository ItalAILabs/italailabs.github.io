(function () {
    const grid = document.getElementById("projectsGrid");
    const loadMoreBtn = document.getElementById("projectsLoadMoreBtn");
    const itemsShown = document.getElementById("projectsItemsShown");

    if (!grid) return;

    const USE_NDJSON = true; // prefer streaming when CDN allows

    const state = {
        nextPagePath: null,
        totalItems: 0,
        totalPages: 0,
        perPage: 12,
        loadedPages: new Set(),
    };

    async function fetchNdjson(url) {
        const res = await fetch(url);
        if (!res.ok) throw new Error(`Failed to fetch ${url}: ${res.status}`);

        const reader = res.body.getReader();
        const decoder = new TextDecoder();
        let buffer = "";
        const meta = {};
        const items = [];

        while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            buffer += decoder.decode(value, { stream: true });
            let idx;
            while ((idx = buffer.indexOf("\n")) >= 0) {
                const line = buffer.slice(0, idx).trim();
                buffer = buffer.slice(idx + 1);
                if (!line) continue;
                const obj = JSON.parse(line);
                if (obj.type === "meta") {
                    Object.assign(meta, obj);
                } else if (obj.type === "item") {
                    items.push(obj);
                }
            }
        }
        const tail = buffer.trim();
        if (tail) {
            const obj = JSON.parse(tail);
            if (obj.type === "meta") Object.assign(meta, obj);
            else if (obj.type === "item") items.push(obj);
        }
        return { meta, items };
    }

    async function fetchJson(url) {
        const res = await fetch(url);
        if (!res.ok) throw new Error(`Failed to fetch ${url}: ${res.status}`);
        const data = await res.json();
        const { items = [] } = data;
        const meta = {
            page: data.page,
            per_page: data.per_page,
            total_pages: data.total_pages,
            total_items: data.total_items,
            next_page_path: data.next_page_path,
        };
        return { meta, items };
    }

    async function fetchManifest(url) {
        const ndjsonUrl = url.replace(/\.json$/, ".ndjson");
        if (USE_NDJSON) {
            try {
                return await fetchNdjson(ndjsonUrl);
            } catch (err) {
                console.warn("NDJSON fetch failed, falling back to JSON", err);
            }
        }
        return fetchJson(url);
    }

    function escapeHtml(str) {
        return String(str)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }

    function renderStats(stats) {
        if (!Array.isArray(stats) || !stats.length) return "";
        return `<div class="project-card-stats">${stats
            .map(
                (stat) => `
          <div class="project-card-stat">
            <div class="project-card-stat-value">${escapeHtml(stat.value || "")}</div>
            <div class="project-card-stat-label">${escapeHtml(stat.label || "")}</div>
          </div>`,
            )
            .join("")}</div>`;
    }

    function renderCta(item) {
        if (item.has_writeup) {
            return `<a class="cta-dark project-card-cta" href="${item.url}">${escapeHtml(item.cta_label || "VIEW PROJECT")} &rarr;</a>`;
        }
        return `<a class="cta-dark project-card-cta" href="${item.external_url}" target="_blank" rel="noopener">${escapeHtml(item.cta_label || "READ THE PAPER")} &#8599;</a>`;
    }

    function renderCard(item) {
        const el = document.createElement("div");
        el.className = "project-card";
        el.innerHTML = `
      <div class="project-card-media">
        <video src="${item.video || ""}" autoplay muted loop playsinline${item.video_zoom ? ` style="transform: scale(${item.video_zoom});"` : ""}></video>
        ${item.tag ? `<span class="project-card-tag">${escapeHtml(item.tag)}</span>` : ""}
      </div>
      <div class="project-card-content">
        ${item.category ? `<div class="project-card-category">${escapeHtml(item.category)}</div>` : ""}
        <h3 class="project-card-title">${escapeHtml(item.title || "")}</h3>
        <p class="project-card-excerpt">${escapeHtml(item.excerpt || "")}</p>
        ${renderStats(item.stats)}
        ${renderCta(item)}
      </div>
    `;
        return el;
    }

    function updateMeta(meta) {
        state.perPage = meta.per_page || state.perPage;
        state.totalPages = meta.total_pages || state.totalPages;
        state.totalItems = meta.total_items || state.totalItems;
        state.nextPagePath = meta.next_page_path || null;
    }

    function updateCounters(renderedCount, totalAvailable) {
        if (!itemsShown) return;
        const total =
            typeof totalAvailable === "number" ? totalAvailable : renderedCount;
        itemsShown.textContent = `Showing ${renderedCount} of ${total} projects`;
    }

    function toggleLoadMore(visible) {
        if (!loadMoreBtn) return;
        loadMoreBtn.style.display = visible ? "block" : "none";
    }

    function appendItems(items) {
        const frag = document.createDocumentFragment();
        items.forEach((item) => frag.appendChild(renderCard(item)));
        grid.appendChild(frag);
    }

    async function loadPage(url) {
        try {
            const { meta, items } = await fetchManifest(url);
            appendItems(items);
            updateMeta(meta);
            const renderedCount = grid.querySelectorAll(".project-card").length;
            updateCounters(renderedCount, meta.total_items);
            toggleLoadMore(Boolean(meta.next_page_path));
            state.loadedPages.add(url);
        } catch (err) {
            console.error(err);
            toggleLoadMore(false);
        }
    }

    async function handleLoadMore() {
        if (!state.nextPagePath) {
            toggleLoadMore(false);
            return;
        }
        if (state.loadedPages.has(state.nextPagePath)) return;
        loadMoreBtn.disabled = true;
        await loadPage(state.nextPagePath);
        loadMoreBtn.disabled = false;
    }

    function bindLoadMore() {
        if (!loadMoreBtn) return;
        loadMoreBtn.addEventListener("click", handleLoadMore);
    }

    function setupInitialState() {
        const renderedCount = grid.querySelectorAll(".project-card").length;
        const totalItems = Number(grid.dataset.totalItems) || renderedCount;
        const perPage = Number(grid.dataset.perPage) || state.perPage;
        const nextPage = grid.dataset.nextPage || null;

        state.totalItems = totalItems;
        state.perPage = perPage;
        state.totalPages = perPage ? Math.ceil(totalItems / perPage) : 0;
        state.nextPagePath = nextPage || null;

        updateCounters(renderedCount, totalItems);
        toggleLoadMore(Boolean(nextPage));
    }

    function init() {
        bindLoadMore();
        setupInitialState();
    }

    document.addEventListener("DOMContentLoaded", init);
})();
