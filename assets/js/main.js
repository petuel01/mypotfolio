// Mobile Navbar Toggle (Tailwind version)
const navToggle = document.getElementById('nav-toggle');
const navMenu = document.getElementById('nav-menu');
const navClose = document.getElementById('nav-close');
if (navToggle && navMenu) {
  navToggle.onclick = () => navMenu.classList.toggle('hidden');
}
if (navClose && navMenu) {
  navClose.onclick = () => navMenu.classList.add('hidden');
}
if (navMenu) {
  navMenu.querySelectorAll('a').forEach(link => {
    link.onclick = () => navMenu.classList.add('hidden');
  });
}
// Typing Effect
const typingText = document.getElementById('typing-text');
if (typingText) {
  const roles = [
    'I am a Software Engineer, Developer, Graphic Designer, and Tech Problem Solver'
  ];
  let i = 0, j = 0, isDeleting = false;
  function type() {
    typingText.textContent = roles[i].substring(0, j);
    if (!isDeleting && j < roles[i].length) {
      j++;
      setTimeout(type, 40);
    } else if (isDeleting && j > 0) {
      j--;
      setTimeout(type, 20);
    } else {
      setTimeout(() => { isDeleting = !isDeleting; type(); }, 1200);
    }
  }
  type();
}
// ScrollReveal Animations
if (window.ScrollReveal) {
  ScrollReveal().reveal('.container, .skills-grid, .projects-grid, .services-list, .tutorials-grid', {
    distance: '40px', duration: 900, easing: 'ease', origin: 'bottom', interval: 100
  });
}
// GSAP Animations
if (window.gsap) {
  gsap.from('.hero-content', { opacity: 0, y: 60, duration: 1.2 });
}
// Form Validation
const contactForm = document.getElementById('contact-form');
if (contactForm) {
  contactForm.onsubmit = function(e) {
    const name = this.name.value.trim();
    const email = this.email.value.trim();
    const subject = this.subject.value.trim();
    const message = this.message.value.trim();
    if (!name || !email || !subject || !message) {
      alert('Please fill in all fields.');
      e.preventDefault();
    } else if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      alert('Please enter a valid email address.');
      e.preventDefault();
    }
  };
}
// Carousel for Projects
const carouselTrack = document.getElementById('carousel-track');
const prevBtn = document.getElementById('carousel-prev');
const nextBtn = document.getElementById('carousel-next');
if (carouselTrack && prevBtn && nextBtn) {
  prevBtn.onclick = () => {
    carouselTrack.scrollBy({ left: -340, behavior: 'smooth' });
  };
  nextBtn.onclick = () => {
    carouselTrack.scrollBy({ left: 340, behavior: 'smooth' });
  };
}
