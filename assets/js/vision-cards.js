document.addEventListener("DOMContentLoaded", () => {
  const sections = Array.from(document.querySelectorAll(".vision-card"));
  
  function updateCoverProgress() {
    sections.forEach((section, index) => {
      const nextSection = sections[index + 1];
      if (!nextSection) return;

      const sectionRect = section.getBoundingClientRect();
      const nextRect = nextSection.getBoundingClientRect();

      // Skip sections offscreen
      if (sectionRect.bottom < 0 || sectionRect.top > window.innerHeight) return;

      const overlap = Math.max(0, sectionRect.bottom - nextRect.top);
      const progress = Math.min(overlap / sectionRect.height, 1);

      section.style.setProperty("--cover-progress", progress.toFixed(3));
    });
  }

  let ticking = false;
  window.addEventListener("scroll", () => {
    if (!ticking) {
      window.requestAnimationFrame(() => {
        updateCoverProgress();
        ticking = false;
      });
      ticking = true;
    }
  });

  // Initial update
  updateCoverProgress();
});