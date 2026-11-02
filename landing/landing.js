// Progressive enhancement for the landing page; no application/database writes.
(() => {
  // Native touch stays untouched; wheel smoothing is disabled for Reduced Motion.
  const scrollMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  let smoothScroll;
  const configureScroll = () => {
    smoothScroll?.destroy();
    smoothScroll = undefined;
    if (!scrollMotion.matches && window.Lenis) {
      smoothScroll = new window.Lenis({
        autoRaf: true, lerp: 0.1, smoothWheel: true, syncTouch: false,
        anchors: true, allowNestedScroll: true,
        prevent: () => document.body.style.overflow === 'hidden',
      });
    }
  };
  configureScroll();
  scrollMotion.addEventListener('change', configureScroll);
  const menu = document.getElementById('mobileMenuDrawer');
  const menuButton = document.getElementById('mobileMenuBtn');
  window.toggleMobileMenu = (forceState) => {
    const open = typeof forceState === 'boolean' ? forceState : menu.hidden;
    menu.hidden = !open;
    menuButton.setAttribute('aria-expanded', String(open));
    menuButton.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  };
  window.matchMedia('(min-width: 761px)').addEventListener('change', event => {
    if (event.matches) window.toggleMobileMenu(false);
  });

  const modal = document.getElementById('downloadModal');
  const modalPanel = modal.firstElementChild;
  let returnFocus;
  const background = [...document.querySelectorAll('header, main, footer')];
  window.openDownloadModal = (event) => {
    event?.preventDefault();
    window.toggleMobileMenu(false);
    returnFocus = document.activeElement;
    modal.classList.remove('hidden');
    background.forEach(element => { element.inert = true; });
    document.body.style.overflow = 'hidden';
    modal.querySelector('[aria-label="Close modal"]').focus();
  };
  window.closeDownloadModal = () => {
    if (modal.classList.contains('hidden')) return;
    modal.classList.add('hidden');
    background.forEach(element => { element.inert = false; });
    document.body.style.overflow = '';
    returnFocus?.focus();
  };
  modalPanel.addEventListener('keydown', event => {
    if (event.key !== 'Tab') return;
    const controls = [...modalPanel.querySelectorAll('a[href], button:not([disabled]), input:not([disabled])')];
    const first = controls[0];
    const last = controls[controls.length - 1];
    if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
    else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
  });
  // Keep download anchors from scrolling the underlying page as the dialog opens.
  document.querySelectorAll('a[onclick*="openDownloadModal"]').forEach(link => {
    link.removeAttribute('onclick');
    link.addEventListener('click', window.openDownloadModal);
  });
  document.querySelectorAll('.material-symbols-outlined').forEach(icon => icon.setAttribute('aria-hidden', 'true'));
  // Decorative hardware chrome, separate from the real app screenshots.
  document.querySelectorAll('.hero-phone, .gallery-screen, .story-phone, .story-mobile-device').forEach(phone => {
    const bar = document.createElement('span');
    bar.className = 'phone-status-bar';
    bar.setAttribute('aria-hidden', 'true');
    bar.innerHTML = '<span class="phone-time">9:41</span><span class="phone-status-icons"><svg viewBox="0 0 16 12"><rect x="0" y="8" width="3" height="4" rx=".7"/><rect x="4" y="5" width="3" height="7" rx=".7"/><rect x="8" y="2" width="3" height="10" rx=".7"/><rect x="12" width="3" height="12" rx=".7"/></svg><svg viewBox="0 0 16 12" fill="none"><path d="M1 3.5a11 11 0 0 1 14 0M3.5 6a7 7 0 0 1 9 0M6 8.5a3 3 0 0 1 4 0" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="8" cy="11" r="1" fill="currentColor"/></svg><span class="phone-battery">100</span></span>';
    phone.prepend(bar);
  });

})();

// Scroll-driven product narrative; native scrolling and reduced-motion fallback.
(() => {
  const hero = document.querySelector('.depth-hero');
  const chapters = [...document.querySelectorAll('[data-story-step]')];
  const screens = [...document.querySelectorAll('[data-story-screen]')];
  const phone = document.querySelector('.story-phone');
  const caption = document.querySelector('[data-story-caption]');
  if (!hero || !chapters.length || !phone) return;
  const reduce = matchMedia('(prefers-reduced-motion: reduce)');
  const desktop = matchMedia('(min-width: 761px)');
  const captions = ['Discover opportunities that fit your profile.', 'Prepare and review your application.', 'Your submission, saved with a receipt.', 'Follow your application’s recorded progress.'];
  const story = document.querySelector('.student-story');
  let queued = false;
  let active = -1;
  function paint() {
    queued = false;
    if (reduce.matches || !desktop.matches) {
      hero.style.removeProperty('--hero-progress');
      phone.style.removeProperty('transform');
      story.removeAttribute('data-active-step');
      active = -1;
      return;
    }
    const bounds = hero.getBoundingClientRect();
    const progress = Math.max(0, Math.min(1, -bounds.top / Math.max(1, bounds.height * .65)));
    hero.style.setProperty('--hero-progress', progress.toFixed(3));
    let next = 0;
    chapters.forEach((chapter, index) => { if (chapter.getBoundingClientRect().top < innerHeight * .56) next = index; });
    if (next === active) return;
    active = next;
    story.dataset.activeStep = String(active);
    chapters.forEach((chapter, index) => chapter.classList.toggle('is-active', index === active));
    screens.forEach((screen, index) => { screen.classList.toggle('is-active', index === active); screen.setAttribute('aria-hidden', String(index !== active)); });
    caption.textContent = captions[active];
    phone.style.transform = `rotateY(${[-8, 8, -6, 6][active]}deg) rotateZ(${[-3, 3, -2, 2][active]}deg)`;
  }
  function requestPaint() { if (!queued) { queued = true; requestAnimationFrame(paint); } }
  addEventListener('scroll', requestPaint, { passive: true });
  addEventListener('resize', requestPaint, { passive: true });
  reduce.addEventListener('change', requestPaint);
  desktop.addEventListener('change', requestPaint);
  paint();
})();

// Audience-specific concept films share the same accessible player.
(() => {
  const film = document.getElementById('providerFilm');
  const buttons = [...document.querySelectorAll('[data-provider]')];
  if (!film) return;
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  let visible = false;
  function syncFilm() {
    if (!film.hidden && visible && !document.hidden && !reducedMotion.matches) {
      film.muted = true;
      film.play().catch(() => {}); // Native controls remain available if autoplay is blocked.
    } else film.pause();
  }
  buttons.forEach(button => button.addEventListener('click', () => {
    if (button.getAttribute('aria-pressed') === 'true') return;
    const individual = button.dataset.provider === 'individual';
    const section = document.getElementById('provider-portal-section');
    const panels = [...section.querySelectorAll('.provider-copy, .provider-film')];
    const previous = panels.map(panel => panel.getBoundingClientRect());
    panels.forEach(panel => panel.getAnimations().forEach(animation => animation.cancel()));
    section.classList.toggle('is-organization', !individual);
    if (!reducedMotion.matches && innerWidth > 1000) {
      panels.forEach((panel, index) => {
        const next = panel.getBoundingClientRect();
        const x = previous[index].left - next.left;
        const y = previous[index].top - next.top;
        if (Math.abs(x) + Math.abs(y) > 1) panel.animate([
          {transform:`translate(${x}px, ${y}px)`},
          {transform:'translate(0, 0)'}
        ], {duration:900, easing:'cubic-bezier(.16,1,.3,1)'});
      });
    }
    buttons.forEach(item => item.setAttribute('aria-pressed', String(item === button)));
    film.pause();
    const source = individual ? 'assets/provider-concept-v2.mp4' : 'assets/org-provider-concept.mp4';
    if (film.querySelector('source').getAttribute('src') !== source) {
      film.querySelector('source').src = source;
      film.poster = individual ? 'assets/provider-poster.png' : 'assets/org-provider-poster.png';
      film.querySelector('track').src = individual ? 'assets/provider-concept-v2.vtt' : 'assets/org-provider-concept.vtt';
      film.setAttribute('aria-label', individual ? 'Individual provider concept: scholarship setup, applicant review, application approval' : 'Organization workspace concept: scholarship programs, team review, application decisions');
      if (!reducedMotion.matches) film.style.opacity = '0';
      film.load();
    }
    document.querySelector('[data-provider-heading]').textContent = individual ? 'A scholarship with a personal purpose.' : 'A shared workspace for a bigger purpose.';
    document.querySelector('[data-provider-description]').textContent = individual ? 'Turn your wish to help into an opportunity. Set the support you can offer, review students’ stories and documents, and give applicants a clear next step.' : 'Bring your scholarship team together. Organize programs, review applications, and keep decisions and student updates in one shared workspace.';
    document.querySelector('[data-provider-caption]').textContent = individual ? 'Individual provider preview · Concept UI · Fictional demonstration data' : 'Organization workspace preview · Concept UI · Fictional demonstration data';
    if (!reducedMotion.matches) {
      const description = section.querySelector('.provider-description');
      description.getAnimations().forEach(animation => animation.cancel());
      description.animate([{opacity:0, transform:'translateY(14px)', filter:'blur(2px)'}, {opacity:1, transform:'translateY(0)', filter:'blur(0)'}], {duration:750, delay:100, fill:'backwards', easing:'cubic-bezier(.22,1,.36,1)'});
      section.querySelectorAll('#providerTitle .reveal-word').forEach((word, index) => {
        word.getAnimations().forEach(animation => animation.cancel());
        word.animate([{opacity:0, transform:'translateY(14px)'}, {opacity:1, transform:'translateY(0)'}], {duration:650, delay:index*45, fill:'backwards', easing:'cubic-bezier(.22,1,.36,1)'});
      });
    }
    syncFilm();
  }));
  film.addEventListener('loadeddata', () => {
    film.style.removeProperty('opacity');
    if (!reducedMotion.matches) film.animate([{opacity:0, filter:'blur(2px)'}, {opacity:1, filter:'blur(0)'}], {duration:700, easing:'cubic-bezier(.22,1,.36,1)'});
    syncFilm();
  });
  film.addEventListener('error', () => film.style.removeProperty('opacity'));
  new IntersectionObserver(entries => { visible = entries[0].isIntersecting; syncFilm(); }, {threshold:.2}).observe(film);
  reducedMotion.addEventListener('change', syncFilm);
  document.addEventListener('visibilitychange', syncFilm);
})();

// Progressive word reveals keep the full heading available to assistive technology.
(() => {
  const reduce = matchMedia('(prefers-reduced-motion: reduce)');
  const titles = [...document.querySelectorAll('#heroTitle, #journeyTitle, .story-chapter h3, #nextChapterTitle, #providerTitle')];
  const entries = titles.map(title => {
    const label = title.innerText.replace(/\s+/g, ' ').trim();
    const visual = document.createElement('span');
    visual.setAttribute('aria-hidden', 'true');
    while (title.firstChild) visual.append(title.firstChild);
    const walker = document.createTreeWalker(visual, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    const words = [];
    nodes.forEach(node => {
      const fragment = document.createDocumentFragment();
      node.textContent.split(/(\s+)/).filter(Boolean).forEach(part => {
        if (/^\s+$/.test(part)) fragment.append(document.createTextNode(part));
        else {
          const word = document.createElement('span');
          word.className = 'reveal-word';
          word.textContent = part;
          word.style.setProperty('--word-index', words.length);
          words.push(word);
          fragment.append(word);
        }
      });
      node.replaceWith(fragment);
    });
    title.append(visual);
    title.setAttribute('aria-label', label);
    title.classList.add('reveal-title');
    return { title, words };
  });
  const hero = document.getElementById('heroTitle');
  document.querySelectorAll('.hero-copy > .landing-eyebrow, .hero-description, .hero-actions, .hero-footnote, .depth-stage').forEach((element, index) => {
    element.classList.add('entrance-piece');
    element.style.setProperty('--entrance-delay', `${.12 + index * .12}s`);
  });
  const blocks = [...document.querySelectorAll('.story-intro > p, .story-chapter > p, .story-chapter > ul, .chapter-label, .provider-description, .provider-next')];
  blocks.forEach(block => block.classList.add('content-build'));
  const reveal = element => element.classList.add('build-visible');
  const targets = [...entries.filter(entry => entry.title !== hero).map(entry => entry.title), ...blocks];
  if (!('IntersectionObserver' in window) || reduce.matches) targets.forEach(reveal);
  else {
    const observer = new IntersectionObserver(observations => {
      observations.forEach(observation => {
        if (!observation.isIntersecting) return;
        reveal(observation.target);
        observer.unobserve(observation.target);
      });
    }, {threshold:.08, rootMargin:'0px 0px -9% 0px'});
    targets.forEach(target => observer.observe(target));
    reduce.addEventListener('change', event => {
      if (event.matches) { targets.forEach(reveal); observer.disconnect(); }
    });
  }
})();

// The journey shortcuts enter as a group, staggered in reading order.
(() => {
  const strip = document.querySelector('.journey-strip');
  if (!strip || !('IntersectionObserver' in window)) return;
  strip.classList.add('journey-motion-ready');
  const observer = new IntersectionObserver(entries => {
    if (!entries[0].isIntersecting) return;
    strip.classList.add('journey-visible');
    observer.disconnect();
  }, {threshold:.2, rootMargin:'0px 0px -24px 0px'});
  observer.observe(strip);
})();
