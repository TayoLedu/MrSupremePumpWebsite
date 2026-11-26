// Home page only: the before/after picker and the consultation form.
(function () {
  // --- Before & after client picker ---------------------------------------
  var before = document.getElementById('ba-before');
  var after = document.getElementById('ba-after');
  var clients = document.querySelectorAll('.client');

  if (before && after && clients.length) {
    var swap = function (img, src, alt) {
      img.classList.add('is-loading');
      img.onload = function () { img.classList.remove('is-loading'); };
      img.src = src;
      img.alt = alt;
    };

    clients.forEach(function (btn) {
      btn.addEventListener('click', function () {
        clients.forEach(function (b) {
          b.classList.remove('is-active');
          b.setAttribute('aria-selected', 'false');
        });
        btn.classList.add('is-active');
        btn.setAttribute('aria-selected', 'true');
        var name = btn.dataset.name;
        swap(before, btn.dataset.before, name + ' before');
        swap(after, btn.dataset.after, name + ' after');
      });
      // Preload so switching is instant
      [btn.dataset.before, btn.dataset.after].forEach(function (src) {
        var i = new Image();
        i.src = src;
      });
    });
  }

  // --- "Enquire" links pre-select the service in the form ------------------
  var select = document.getElementById('service');
  if (select) {
    document.querySelectorAll('[data-service]').forEach(function (a) {
      a.addEventListener('click', function () { select.value = a.dataset.service; });
    });
  }

  // --- Contact form: post to Netlify Forms without leaving the page --------
  var form = document.querySelector('form[name="consultation"]');
  if (!form) return;
  var status = form.querySelector('.form-status');

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    var btn = form.querySelector('button[type="submit"]');
    btn.disabled = true;
    status.className = 'form-status full';
    status.textContent = 'Sending…';
    fetch('/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams(new FormData(form)).toString()
    }).then(function (res) {
      if (!res.ok) throw new Error(res.status);
      form.reset();
      status.classList.add('ok');
      status.textContent = 'Message sent! I’ll get back to you within 24 hours.';
    }).catch(function () {
      status.classList.add('err');
      status.textContent = 'Something went wrong. Please try again or message me on Instagram.';
    }).finally(function () { btn.disabled = false; });
  });
})();
