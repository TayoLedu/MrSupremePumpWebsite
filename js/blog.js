// Blog page: reads blog-data.json (written by the CMS at /admin) and renders
// a post index plus the selected post.
(function () {
  var indexEl = document.getElementById('post-index');
  var postEl = document.getElementById('post');
  if (!indexEl || !postEl) return;

  var posts = [];

  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  function formatDate(value) {
    var d = new Date(value);
    if (isNaN(d)) return escapeHtml(value);
    return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
  }

  function show(i) {
    var post = posts[i];
    if (!post) return;

    var cover = post.image
      ? '<img class="blog-cover" src="' + escapeHtml(post.image) + '" alt="">'
      : '';

    postEl.innerHTML =
      cover +
      '<h3>' + escapeHtml(post.title) + '</h3>' +
      '<p class="blog-date">' + formatDate(post.date) + '</p>' +
      '<div class="blog-body">' + marked.parse(post.body || '') + '</div>';

    indexEl.querySelectorAll('.blog-link').forEach(function (el, n) {
      el.classList.toggle('is-active', n === i);
      el.setAttribute('aria-current', n === i ? 'true' : 'false');
    });

    if (window.innerWidth <= 820) {
      postEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  fetch('blog-data.json')
    .then(function (res) {
      if (!res.ok) throw new Error(res.status);
      return res.json();
    })
    .then(function (data) {
      // Newest first, and drop anything without a title.
      posts = (data.posts || []).filter(function (p) { return p && p.title; }).reverse();

      if (!posts.length) {
        indexEl.innerHTML = '<p class="blog-empty">No posts yet.</p>';
        postEl.innerHTML = '<p class="blog-empty">Check back soon for the first post.</p>';
        return;
      }

      indexEl.innerHTML = posts.map(function (post, i) {
        return '<button type="button" class="blog-link" data-i="' + i + '">' +
               '<strong>' + escapeHtml(post.title) + '</strong>' +
               '<span>' + formatDate(post.date) + '</span></button>';
      }).join('');

      indexEl.addEventListener('click', function (e) {
        var btn = e.target.closest('.blog-link');
        if (btn) show(Number(btn.dataset.i));
      });

      show(0);
    })
    .catch(function (err) {
      console.error('Could not load blog posts:', err);
      indexEl.innerHTML = '<p class="blog-empty">Could not load the post list.</p>';
      postEl.innerHTML = '<p class="blog-empty">Please refresh the page or try again later.</p>';
    });
})();
