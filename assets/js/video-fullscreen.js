/**
 * Video fullscreen toggle — uses the Fullscreen API on the card
 * container (.in-action-item / .project-card-media) so that the
 * expand/exit button inside it remains visible.
 *
 * When fullscreen, object-fit switches from cover → contain so the
 * full video frame is visible.
 */
(function () {
    var FULLSCREEN_SVG =
        '<svg viewBox="0 0 24 24"><path d="M8 3H5a2 2 0 00-2 2v3m18 0V5a2 2 0 00-2-2h-3m0 18h3a2 2 0 002-2v-3M3 16v3a2 2 0 002 2h3"/></svg>';
    var EXIT_SVG =
        '<svg viewBox="0 0 24 24"><path d="M8 3v3a2 2 0 01-2 2H3m18 0h-3a2 2 0 01-2-2V3m0 18v-3a2 2 0 012-2h3M3 16h3a2 2 0 012 2v3"/></svg>';

    /* Track which container we fullscreened so we can clean up
       after exit, even though getFullscreenElement() is null by then. */
    var lastContainer = null;

    /* ── helpers ──────────────────────────────────────────────── */
    function getFullscreenElement() {
        return (
            document.fullscreenElement ||
            document.webkitFullscreenElement ||
            document.mozFullScreenElement ||
            document.msFullscreenElement
        );
    }

    function isFullscreen() {
        return !!getFullscreenElement();
    }

    function requestFullscreen(el) {
        if (el.requestFullscreen) return el.requestFullscreen();
        if (el.webkitRequestFullscreen) return el.webkitRequestFullscreen();
        if (el.mozRequestFullScreen) return el.mozRequestFullScreen();
        if (el.msRequestFullscreen) return el.msRequestFullscreen();
    }

    function exitFullscreen() {
        if (document.exitFullscreen) return document.exitFullscreen();
        if (document.webkitExitFullscreen) return document.webkitExitFullscreen();
        if (document.mozCancelFullScreen) return document.mozCancelFullScreen();
        if (document.msExitFullscreen) return document.msExitFullscreen();
    }

    /* iOS Safari can only fullscreen <video> elements, not arbitrary
       containers. This fallback uses webkitEnterFullscreen() on the
       video when the container-level API silently fails. */
    function tryFallbackFullscreen(item) {
        var video = item.querySelector("video");
        if (video && video.webkitEnterFullscreen) {
            try {
                video.webkitEnterFullscreen();
            } catch (_) {
                /* no-op — nothing we can do */
            }
        }
    }

    /* ── button icon sync ────────────────────────────────────── */
    function syncAllButtons() {
        var fs = isFullscreen();
        var btns = document.querySelectorAll(".video-fullscreen-btn");
        for (var i = 0; i < btns.length; i++) {
            btns[i].innerHTML = fs ? EXIT_SVG : FULLSCREEN_SVG;
        }
    }

    /* ── object-fit management ───────────────────────────────── */
    function setVideoObjectFit(mode) {
        if (!lastContainer) return;
        var video = lastContainer.querySelector("video");
        if (video) video.style.objectFit = mode;
    }

    /* ── click handler (event delegation) ────────────────────── */
    document.addEventListener(
        "click",
        function (e) {
            var btn = e.target.closest(".video-fullscreen-btn");
            if (!btn) return;

            var item = btn.closest(".in-action-item, .project-card-media");
            if (!item) return;

            if (isFullscreen()) {
                exitFullscreen();
            } else {
                lastContainer = item;
                var result = requestFullscreen(item);
                if (result && typeof result.then === "function") {
                    result
                        .then(function () {
                            if (!isFullscreen()) {
                                tryFallbackFullscreen(item);
                            }
                        })
                        .catch(function () {
                            tryFallbackFullscreen(item);
                        });
                } else {
                    setTimeout(function () {
                        if (!isFullscreen()) {
                            tryFallbackFullscreen(item);
                        }
                    }, 150);
                }
            }
        },
        false
    );

    /* ── fullscreen change listener ──────────────────────────── */
    function onFullscreenChange() {
        syncAllButtons();
        if (isFullscreen()) {
            setVideoObjectFit("contain");
        } else {
            setVideoObjectFit("cover");
            lastContainer = null;
        }
    }

    document.addEventListener("fullscreenchange", onFullscreenChange, false);
    document.addEventListener("webkitfullscreenchange", onFullscreenChange, false);
    document.addEventListener("mozfullscreenchange", onFullscreenChange, false);
    document.addEventListener("MSFullscreenChange", onFullscreenChange, false);

    /* ── Escape key ──────────────────────────────────────────── */
    document.addEventListener(
        "keydown",
        function (e) {
            if (e.key === "Escape" && isFullscreen()) {
                exitFullscreen();
            }
        },
        false
    );
})();
