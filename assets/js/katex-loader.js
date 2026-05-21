(function() {
  var katexRoot = document.querySelector('.kdmath, .math-block');
  if (!katexRoot) return;

  var cssHref = 'https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css';
  var jsHref = 'https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js';
  var autoRenderHref = 'https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js';

  function whenIdle(fn) {
    if ('requestIdleCallback' in window) {
      return requestIdleCallback(fn, { timeout: 2000 });
    }
    return setTimeout(fn, 200);
  }

  function loadCSS(href) {
    return new Promise(function(resolve, reject) {
      var link = document.createElement('link');
      link.rel = 'preload';
      link.as = 'style';
      link.href = href;
      link.onload = function() {
        link.rel = 'stylesheet';
        resolve();
      };
      link.onerror = reject;
      document.head.appendChild(link);
    });
  }

  function loadScript(src) {
    return new Promise(function(resolve, reject) {
      var script = document.createElement('script');
      script.src = src;
      script.defer = true;
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
  }

  function renderMath() {
    if (!window.renderMathInElement) return;
    window.renderMathInElement(document.body, {
      delimiters: [
        { left: '$$', right: '$$', display: true },
        { left: '$', right: '$', display: false }
      ],
      throwOnError: false,
      ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code']
    });
  }

  whenIdle(function() {
    loadCSS(cssHref)
      .then(function() { return loadScript(jsHref); })
      .then(function() { return loadScript(autoRenderHref); })
      .then(renderMath)
      .catch(function(err) {
        console.error('KaTeX failed to load', err);
      });
  });
})();