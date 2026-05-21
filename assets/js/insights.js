(function () {
    const grid = document.getElementById("insightsGrid");
    const loadMoreBtn = document.getElementById("loadMoreBtn");
    const itemsShown = document.getElementById("itemsShown");
    const filterButtons = Array.from(document.querySelectorAll(".filter-btn"));
    const categoryDropdown = document.getElementById("categoryDropdown");
    const clearFilterBtn = document.getElementById("clearFilter");
    const filterCount = document.getElementById("filterCount");

    if (!grid) return;

    const BASE_PATH = "/assets/data/insights/insights-page1.json";
    const CATEGORY_BASE = "/assets/data/insights/categories/category-";
    const USE_NDJSON = true; // prefer streaming when CDN allows

    const TRANSITIONS = {
        fadeOutMs: 240,
        swapDelayMs: 80,
        fadeInMs: 340,
    };

    const state = {
        currentCategory: "all",
        nextPagePath: BASE_PATH,
        totalItems: 0,
        totalPages: 0,
        perPage: 12,
        loadedPages: new Set(),
        transitioning: false,
    };

    const GRID_PHASES = ["cards-exit", "cards-enter", "cards-active"];

    function delay(ms) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }

    function nextFrame() {
        return new Promise((resolve) => requestAnimationFrame(() => resolve()));
    }

    function setGridPhase(phase) {
        grid.classList.remove(...GRID_PHASES);
        if (phase) grid.classList.add(phase);
    }

    function setControlsDisabled(disabled) {
        filterButtons.forEach((btn) => {
            btn.disabled = disabled;
            btn.setAttribute("aria-disabled", String(disabled));
        });
        if (categoryDropdown) categoryDropdown.disabled = disabled;
        if (clearFilterBtn) clearFilterBtn.disabled = disabled;
        if (loadMoreBtn) loadMoreBtn.disabled = disabled;
    }

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

    function renderCard(item) {
        const el = document.createElement("div");
        el.className = "insight-card";
        el.innerHTML = `
      <div class="insight-card-image-wrapper">
        <a href="${item.url}">
          <img src="${item.hero_image || "/assets/images/blog/cards/coming.webp"}" alt="${escapeHtml(item.title || "Placeholder Title")}" class="insight-card-image">
        </a>
        ${item.date ? `<span class="insight-tag insight-date">${formatDate(item.date)}</span>` : ""}
      </div>
      <div class="insight-card-content">
        <a class="insight-card-title" href="${item.url}">
          <h3 class="insight-card-title h7-size">${escapeHtml(item.title || "")}</h3>
          <p class="insight-card-excerpt">
              ${escapeHtml(item.excerpt || "")}
          </p>
        </a>
        <div class="insight-card-footer">
          <div class="insight-card-tags">
            ${renderTags(item.categories)}
          </div>
          ${item.series && item.part ? `<span class="insight-card-series">${escapeHtml(String(item.series)).toUpperCase()} • P${escapeHtml(String(item.part))}</span>` : ""}
        </div>
      </div>
    `;
        return el;
    }

    function renderTags(categories) {
        const cats = Array.isArray(categories)
            ? categories.slice(0, 2)
            : categories
              ? [categories]
              : [];
        const frag = document.createDocumentFragment();

        cats.forEach((cat) => {
            const slug = slugify(cat);
            const tag = document.createElement("button");
            tag.className = "insight-card-tag";
            tag.setAttribute("data-tag-category", slug);
            tag.textContent = `${cat}`;
            frag.appendChild(tag);
        });

        // Attach event handlers to the tags
        attachTagHandlers(frag);

        const container = document.createElement("div");
        container.appendChild(frag);
        return container.innerHTML;
    }

    function escapeHtml(str) {
        return String(str)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }

    function slugify(str) {
        return String(str)
            .trim()
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-+|-+$/g, "");
    }

    function formatDate(str) {
        return new Date(str).toLocaleDateString("en-GB", {
            day: "numeric",
            month: "long",
            year: "numeric",
        });
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
        itemsShown.textContent = `Showing ${renderedCount} of ${total} insights`;
    }
    
    function updateFilterUI() {
        const isFiltered = state.currentCategory !== "all";
        
        // Update clear filter button visibility
        if (clearFilterBtn) {
            clearFilterBtn.style.display = isFiltered ? "flex" : "none";
        }
        
        // Update top filter count
        if (filterCount) {
            const renderedCount = grid.querySelectorAll(".insight-card").length;
            if (isFiltered) {
                const categoryName = state.currentCategory
                    .split("-")
                    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
                    .join(" ");
                filterCount.textContent = `Showing ${renderedCount} insights in ${categoryName}`;
            } else {
                filterCount.textContent = `Showing ${renderedCount} insights`;
            }
        }
    }

    function toggleLoadMore(visible) {
        if (!loadMoreBtn) return;
        loadMoreBtn.style.display = visible ? "block" : "none";
    }

    function attachTagHandlers(scope) {
        const tags = scope.querySelectorAll(".insight-card-tag");
        tags.forEach((tag) => {
            tag.addEventListener("click", (e) => {
                e.preventDefault();
                const slug = tag.getAttribute("data-tag-category");
                runFilterTransition(slug);
                window.location.hash = "filter"; // Navigate to #filter
            });
        });
    }

    function clearGrid() {
        grid.innerHTML = "";
    }

    function appendItems(items) {
        const frag = document.createDocumentFragment();
        items.forEach((item) => frag.appendChild(renderCard(item)));
        attachTagHandlers(frag);
        grid.appendChild(frag);
    }

    async function loadPage(url, { reset = false } = {}) {
        try {
            const { meta, items } = await fetchManifest(url);
            if (reset) clearGrid();
            appendItems(items);
            updateMeta(meta);
            const renderedCount = grid.querySelectorAll(".insight-card").length;
            updateCounters(renderedCount, meta.total_items);
            updateFilterUI();
            toggleLoadMore(Boolean(meta.next_page_path));
            state.loadedPages.add(url);
        } catch (err) {
            console.error(err);
            toggleLoadMore(false);
        }
    }

    function buildPath(pageNum, categorySlug) {
        if (categorySlug && categorySlug !== "all") {
            return `${CATEGORY_BASE}${categorySlug}-page${pageNum}.json`;
        }
        return `/assets/data/insights/insights-page${pageNum}.json`;
    }

    async function swapFilterData(categorySlug) {
        state.currentCategory = categorySlug || "all";
        state.loadedPages.clear();
        const path = buildPath(1, state.currentCategory);
        await loadPage(path, { reset: true });
    }

    async function runFilterTransition(categorySlug) {
        if (state.transitioning) return;
        state.transitioning = true;
        setControlsDisabled(true);

        setGridPhase("cards-exit");
        await delay(TRANSITIONS.fadeOutMs);

        setGridPhase("cards-enter");
        await swapFilterData(categorySlug);
        await nextFrame();
        await delay(TRANSITIONS.swapDelayMs);

        setGridPhase("cards-active");
        await delay(TRANSITIONS.fadeInMs);

        setControlsDisabled(false);
        state.transitioning = false;
    }

    async function handleLoadMore() {
        if (state.transitioning) return;
        if (!state.nextPagePath) {
            toggleLoadMore(false);
            return;
        }
        // Avoid duplicate fetches if user double-clicks
        if (state.loadedPages.has(state.nextPagePath)) return;
        await loadPage(state.nextPagePath, { reset: false });
    }

    function bindFilters() {
        filterButtons.forEach((btn) => {
            btn.addEventListener("click", () => {
                filterButtons.forEach((b) => b.classList.remove("active"));
                btn.classList.add("active");
                const cat = btn.getAttribute("data-category");
                if (categoryDropdown) categoryDropdown.value = cat;
                runFilterTransition(cat);
            });
        });

        if (categoryDropdown) {
            categoryDropdown.addEventListener("change", () => {
                const cat = categoryDropdown.value;
                filterButtons.forEach((b) => b.classList.remove("active"));
                const match = filterButtons.find(
                    (b) => b.getAttribute("data-category") === cat,
                );
                if (match) match.classList.add("active");
                runFilterTransition(cat);
            });
        }
        
        if (clearFilterBtn) {
            clearFilterBtn.addEventListener("click", () => {
                filterButtons.forEach((b) => b.classList.remove("active"));
                const allBtn = filterButtons.find((b) => b.getAttribute("data-category") === "all");
                if (allBtn) allBtn.classList.add("active");
                if (categoryDropdown) categoryDropdown.value = "all";
                runFilterTransition("all");
            });
        }
    }

    function bindLoadMore() {
        if (!loadMoreBtn) return;
        loadMoreBtn.addEventListener("click", handleLoadMore);
    }

    function setupInitialState() {
        const renderedCount = grid.querySelectorAll(".insight-card").length;
        const totalItems = Number(grid.dataset.totalItems) || renderedCount;
        const perPage = Number(grid.dataset.perPage) || state.perPage;
        const nextPage = grid.dataset.nextPage || null;

        state.currentCategory = "all";
        state.totalItems = totalItems;
        state.perPage = perPage;
        state.totalPages = perPage ? Math.ceil(totalItems / perPage) : 0;
        state.nextPagePath = nextPage || null;

        if (nextPage) state.loadedPages.add(BASE_PATH);

        updateCounters(renderedCount, totalItems);
        updateFilterUI();
        toggleLoadMore(Boolean(nextPage));
        attachTagHandlers(grid);
        setGridPhase("cards-active");
    }

    async function init() {
        bindFilters();
        bindLoadMore();
        setupInitialState();
    }

    document.addEventListener("DOMContentLoaded", init);
})();
