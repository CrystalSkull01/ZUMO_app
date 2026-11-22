/* Zumo app prototype player — screens exported from the Figma file (figma-screens.js)
   Autoplays a tour of the main screens; pauses while the visitor interacts, then resumes. */
(function () {
  var D = window.ZUMO_SCREENS, app = document.getElementById('app');
  if (!D || !app) return;
  var phone = app.parentNode;
  var TOUR = ['11:2', '11:3', '122:291', '132:414', '234:421', '234:496', '234:558', '234:174', '234:733', '215:3', '234:878'];
  var DWELL = { '11:2': 2200, '11:3': 3200 }, DEFAULT_DWELL = 3400, IDLE_RESUME = 10000;
  var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  var current = null, currentId = null, timer = null, autoTimer = null, resumeTimer = null, paused = reduce, hovering = false, userPaused = false;

  function show(id, instant, auto) {
    var s = D.screens[id]; if (!s) return;
    clearTimeout(timer);
    currentId = id;
    var el = document.createElement('div');
    el.className = 'fz-screen';
    el.innerHTML = s.svg;
    var hot = s.hot.slice().sort(function (a, b) { return b.w * b.h - a.w * a.h; });
    var delay = null;
    hot.forEach(function (h) {
      if (h.ev === 'AFTER_TIMEOUT') { if (delay === null || h.t < delay.t) delay = h; return; }
      if (h.w * h.h >= s.w * s.h * 0.9) return;
      var b = document.createElement('button');
      b.type = 'button'; b.className = 'fz-hot'; b.setAttribute('aria-label', h.name);
      b.style.cssText = 'left:' + (h.x / s.w * 100) + '%;top:' + (h.y / s.h * 100) + '%;width:' + (h.w / s.w * 100) + '%;height:' + (h.h / s.h * 100) + '%';
      b.addEventListener('click', function () { userAction(); show(h.to); });
      el.appendChild(b);
    });
    if (!instant) el.style.opacity = '0';
    app.appendChild(el);
    var old = current; current = el;
    requestAnimationFrame(function () { requestAnimationFrame(function () { el.style.opacity = '1'; }); });
    setTimeout(function () { if (old && old.parentNode) old.parentNode.removeChild(old); }, instant ? 0 : 520);
    // Figma's own timer (e.g. splash) only runs when the tour is not driving
    if (delay && paused) timer = setTimeout(function () { show(delay.to); }, Math.max(delay.t, 0.5) * 1000);
  }

  function schedule() {
    clearTimeout(autoTimer);
    if (paused) return;
    autoTimer = setTimeout(function () {
      if (paused) return;
      var i = TOUR.indexOf(currentId);
      show(TOUR[(i + 1) % TOUR.length], false, true);
      schedule();
    }, DWELL[currentId] || DEFAULT_DWELL);
  }

  function pause() { paused = true; clearTimeout(autoTimer); clearTimeout(timer); clearTimeout(resumeTimer); }
  function resume() {
    if (reduce || hovering || userPaused) return;
    paused = false;
    if (TOUR.indexOf(currentId) === -1) show('122:291');
    schedule();
  }
  function userAction() { pause(); resumeTimer = setTimeout(resume, IDLE_RESUME); }

  phone.addEventListener('mouseenter', function () { hovering = true; pause(); });
  phone.addEventListener('mouseleave', function () { hovering = false, userPaused = false; resumeTimer = setTimeout(resume, 2500); });
  document.addEventListener('visibilitychange', function () { if (document.hidden) pause(); else { resumeTimer = setTimeout(resume, 800); } });

  var ctl = document.createElement('button');
  ctl.type = 'button'; ctl.className = 'proto-ctl';
  var ICON_PAUSE = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5v14M16 5v14" stroke="currentColor" stroke-width="3" stroke-linecap="round"/></svg>';
  var ICON_PLAY = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5.5v13l11-6.5z" fill="currentColor"/></svg>';
  function label() { ctl.innerHTML = (userPaused || reduce ? ICON_PLAY + '<span>Play tour</span>' : ICON_PAUSE + '<span>Pause tour</span>'); ctl.setAttribute('aria-pressed', userPaused ? 'true' : 'false'); }
  ctl.addEventListener('click', function () {
    userPaused = !userPaused;
    if (userPaused) pause(); else { reduce = false; hovering = false; clearTimeout(resumeTimer); resume(); }
    label();
  });
  label();
  (phone.parentNode).appendChild(ctl);

  show(D.start, true);
  if (!reduce) { paused = false; schedule(); }
  else { paused = true; setTimeout(function () { show('11:3'); }, 1500); }
})();
