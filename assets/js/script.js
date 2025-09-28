
// Centralized UI script: menu, theme, active link, accessibility
document.addEventListener('DOMContentLoaded', () => {
  // Menu toggling (support old and new IDs)
  const menuBtn = document.getElementById('menuBtn') || document.getElementById('nav-toggle');
  const mobileMenu = document.getElementById('mobileMenu') || document.getElementById('nav-menu');
  const navClose = document.getElementById('nav-close');
  if (menuBtn && mobileMenu) {
    // create close button inside mobileMenu if it doesn't exist
    let closeBtn = mobileMenu.querySelector('#mobileClose');
    if (!closeBtn) {
      closeBtn = document.createElement('button');
      closeBtn.id = 'mobileClose';
      closeBtn.setAttribute('aria-label', 'Close menu');
      closeBtn.className = 'mobile-close';
      closeBtn.innerHTML = '&times;';
      // place at the top of the mobile menu
      mobileMenu.insertBefore(closeBtn, mobileMenu.firstChild);
    }

    function showMobileMenu(show) {
      const isOpen = !!show;
      if (isOpen) {
        mobileMenu.classList.remove('hidden');
        mobileMenu.classList.add('open');
        if (menuBtn.hasAttribute('aria-expanded')) menuBtn.setAttribute('aria-expanded', 'true');
      } else {
        mobileMenu.classList.add('hidden');
        mobileMenu.classList.remove('open');
        if (menuBtn.hasAttribute('aria-expanded')) menuBtn.setAttribute('aria-expanded', 'false');
      }
    }

    menuBtn.addEventListener('click', () => {
      const currentlyOpen = !mobileMenu.classList.contains('hidden');
      showMobileMenu(!currentlyOpen);
    });

    // close handler for X
    closeBtn.addEventListener('click', () => showMobileMenu(false));
  }
  if (navClose && mobileMenu) {
    navClose.addEventListener('click', () => mobileMenu.classList.add('hidden'));
  }
  if (mobileMenu) {
    mobileMenu.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        mobileMenu.classList.add('hidden');
        if (menuBtn && menuBtn.hasAttribute('aria-expanded')) menuBtn.setAttribute('aria-expanded', 'false');
      });
    });
  }
  // close on Escape
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && mobileMenu && !mobileMenu.classList.contains('hidden')) {
      mobileMenu.classList.add('hidden');
      if (menuBtn && menuBtn.hasAttribute('aria-expanded')) menuBtn.setAttribute('aria-expanded', 'false');
    }
  });

  // Fade-in on scroll animation (Intersection Observer)
  const fadeEls = document.querySelectorAll('.js-fade, .js-fade-up, .js-fade-in');
  if ('IntersectionObserver' in window && fadeEls.length) {
    const observer = new IntersectionObserver((entries, obs) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('opacity-100', 'translate-y-0');
          obs.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15 });
    fadeEls.forEach(el => {
      el.classList.add('opacity-0', 'translate-y-8', 'transition-all', 'duration-700');
      observer.observe(el);
    });
  }

  // Active link highlighting: resolve links to absolute URLs and compare pathnames and hashes
  (function markActiveLinks() {
    const links = Array.from(document.querySelectorAll('a[data-nav], nav a'));
    const currentUrl = new URL(location.href);
    const currentFile = (currentUrl.pathname.split('/').pop() || 'index.html').toLowerCase();

    links.forEach(link => {
      try {
        const raw = link.getAttribute('data-nav') || link.getAttribute('href') || '';
        if (!raw) {
          link.classList.remove('active-link');
          link.removeAttribute('aria-current');
          return;
        }

        // Resolve against current location so relative paths are handled correctly
        const resolved = new URL(raw, currentUrl);
        const linkFile = (resolved.pathname.split('/').pop() || 'index.html').toLowerCase();

        // If this is a fragment-only link (href starts with '#')
        if (raw.startsWith('#')) {
          // Only consider in-page fragments when on index (home) or when pathname matches
          if (linkFile === currentFile) {
            // If hash matches current hash or common home anchors, mark active
            const hash = resolved.hash || '#';
            const currentHash = currentUrl.hash || '#';
            const treatHome = ['#', '#home', '#top'].includes(hash.toLowerCase());
            if (hash.toLowerCase() === currentHash.toLowerCase() || (treatHome && (currentHash === '#' || currentHash === '' || currentFile === 'index.html'))) {
              link.classList.add('active-link');
              link.setAttribute('aria-current', 'page');
              return;
            }
          }
          link.classList.remove('active-link');
          link.removeAttribute('aria-current');
          return;
        }

        // For normal links, compare the filename portion
        if (linkFile === currentFile) {
          link.classList.add('active-link');
          link.setAttribute('aria-current', 'page');
        } else {
          link.classList.remove('active-link');
          link.removeAttribute('aria-current');
        }
      } catch (err) {
        // ignore invalid URLs
        link.classList.remove('active-link');
        link.removeAttribute('aria-current');
      }
    });
  })();

  // Theme toggle (dark purple)
  const themeBtn = document.getElementById('themeBtn');
  const themeIcon = document.getElementById('themeIcon');
  function applyTheme(theme) {
    if (theme === 'dark') {
      document.documentElement.setAttribute('data-theme', 'dark');
      // theme variables in CSS handle background/text colors (uses #1e232b for dark)
      themeIcon && themeIcon.classList.remove('fa-moon'); themeIcon && themeIcon.classList.add('fa-sun');
    } else {
      document.documentElement.setAttribute('data-theme', 'light');
      // theme variables in CSS handle background/text colors for light
      themeIcon && themeIcon.classList.remove('fa-sun'); themeIcon && themeIcon.classList.add('fa-moon');
    }
    localStorage.setItem('theme', theme);
  }
  if (themeBtn) {
    const saved = localStorage.getItem('theme') || (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    applyTheme(saved);
    themeBtn.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
      applyTheme(current === 'dark' ? 'light' : 'dark');
    });
  }

  // Optional: smooth-scroll for same-page anchors
  document.querySelectorAll('a[href^="#"]').forEach(link => {
    link.addEventListener('click', function(e) {
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth' });
      }
    });
  });

  // CV download: safer cross-browser download (fetch blob then force a download)
  const cvLink = document.getElementById('cvDownload');
  if (cvLink) {
    cvLink.addEventListener('click', async (e) => {
      // If user explicitly used modifier keys, let native behavior happen (open in new tab)
      if (e.ctrlKey || e.metaKey || e.shiftKey || e.altKey) return;
      e.preventDefault();
      const cvPath = cvLink.getAttribute('data-cv') || cvLink.getAttribute('href');
      try {
        const resp = await fetch(cvPath, { cache: 'no-store' });
        if (!resp.ok) throw new Error('Network response not ok');
        const blob = await resp.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        // prefer filename from link download attribute or fallback to RESUME.pdf
        const suggested = cvLink.getAttribute('download') || 'RESUME.pdf';
        a.download = suggested;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
      } catch (err) {
        // If fetch fails, fallback to normal navigation which may trigger browser download
        window.location.href = cvPath;
      }
    });
  }

});
