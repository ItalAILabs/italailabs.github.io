class ValuesCarousel {
  constructor() {
    this.grid = document.getElementById('valuesGrid');
    this.prevBtn = document.getElementById('prevBtn');
    this.nextBtn = document.getElementById('nextBtn');
    this.cards = Array.from(document.querySelectorAll('.value-card'));
    this.currentIndex = 0;
    
    this.init();
  }
  
  init() {
    this.updateCardsPerView();
    this.updateButtons();
    
    this.prevBtn.addEventListener('click', () => this.prev());
    this.nextBtn.addEventListener('click', () => this.next());
    
    window.addEventListener('resize', () => {
      this.updateCardsPerView();
      this.updatePosition();
      this.updateButtons();
    });
  }
  
  updateCardsPerView() {
    const width = window.innerWidth;
    if (width <= 768) {
      this.cardsPerView = 1;
    } else if (width <= 1024) {
      this.cardsPerView = 2;
    } else {
      this.cardsPerView = 3;
    }
  }
  
  get maxIndex() {
    return Math.max(0, this.cards.length - this.cardsPerView);
  }
  
  prev() {
    if (this.currentIndex > 0) {
      this.currentIndex--;
      this.updatePosition();
      this.updateButtons();
    }
  }
  
  next() {
    if (this.currentIndex < this.maxIndex) {
      this.currentIndex++;
      this.updatePosition();
      this.updateButtons();
    }
  }
  
  updatePosition() {
    const cardWidth = this.cards[0].offsetWidth;
    const gap = 16; // 1rem
    const offset = -(this.currentIndex * (cardWidth + gap));
    this.grid.style.transform = `translateX(${offset}px)`;
  }
  
  updateButtons() {
    this.prevBtn.disabled = this.currentIndex === 0;
    this.nextBtn.disabled = this.currentIndex >= this.maxIndex;
  }
}

// Initialize carousel when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  new ValuesCarousel();
});