---
---
// ^ Tells Jekyll this has front matter and should be processed
// Minimal JS to hide loading screen when page is ready
(function() {
    // Jekyll will inject debug flag - set loading_debug: true in _config.yml to enable
    const DEBUG = {{ site.loading_debug | default: false }};
    
    function log() {
        if (DEBUG) console.log.apply(console, arguments);
    }
    
    function warn() {
        if (DEBUG) console.warn.apply(console, arguments);
    }
    
    function error() {
        if (DEBUG) console.error.apply(console, arguments);
    }
    
    log('[Loading] Script started');
    log('[Loading] Document ready state:', document.readyState);
    
    // Check if already loaded (in case script runs late)
    if (document.readyState === 'complete') {
        log('[Loading] Document already complete, hiding immediately');
        const loadingScreen = document.getElementById('loading-screen');
        if (loadingScreen) {
            loadingScreen.classList.add('loaded');
            setTimeout(() => {
                loadingScreen.remove();
            }, 600);
        }
    }
    
    // Listen for DOMContentLoaded
    document.addEventListener('DOMContentLoaded', function() {
        log('[Loading] DOMContentLoaded fired');
    });
    
    // Listen for load event
    window.addEventListener('load', function() {
        log('[Loading] Window load event fired');
        log('[Loading] All resources loaded at:', new Date().toISOString());
        
        const loadingScreen = document.getElementById('loading-screen');
        if (loadingScreen) {
            log('[Loading] Loading screen found, adding loaded class');
            loadingScreen.classList.add('loaded');
            // Remove from DOM after transition
            setTimeout(() => {
                log('[Loading] Removing loading screen from DOM');
                loadingScreen.remove();
            }, 600);
        } else {
            error('[Loading] Loading screen element not found!');
        }
    });
    
    // Log any resource errors (only in debug mode)
    if (DEBUG) {
        window.addEventListener('error', function(e) {
            if (e.target.tagName) {
                error('[Loading] Resource failed to load:', e.target.tagName, e.target.src || e.target.href);
            }
        }, true);
    }
    
    // Timeout fallback - force hide after 5 seconds
    setTimeout(function() {
        if (document.readyState !== 'complete') {
            warn('[Loading] Timeout reached, document still not complete');
            warn('[Loading] Ready state:', document.readyState);
        }
        const loadingScreen = document.getElementById('loading-screen');
        if (loadingScreen && !loadingScreen.classList.contains('loaded')) {
            warn('[Loading] Force hiding loading screen after 5s timeout');
            loadingScreen.classList.add('loaded');
            setTimeout(() => {
                loadingScreen.remove();
            }, 600);
        }
    }, 5000);
})();