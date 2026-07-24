document.getElementById('year').textContent = new Date().getFullYear();

(function () {
  var set = function (id, value) {
    var el = document.getElementById(id);
    if (!el) return;
    el.textContent = value == null || value === '' ? 'unavailable' : value;
    el.classList.remove('pending');
  };

  // ---- Browser + OS + device from the user agent ----
  var ua = navigator.userAgent || '';
  var uaData = navigator.userAgentData;

  function detectBrowser() {
    if (uaData && uaData.brands && uaData.brands.length) {
      var pick = uaData.brands.filter(function (b) {
        return !/Not.?A.?Brand/i.test(b.brand);
      });
      var b = (pick[pick.length - 1] || uaData.brands[0]);
      if (b) return b.brand + ' ' + b.version;
    }
    var m;
    if ((m = ua.match(/Edg\/([\d.]+)/))) return 'Edge ' + m[1];
    if ((m = ua.match(/OPR\/([\d.]+)/))) return 'Opera ' + m[1];
    if ((m = ua.match(/Firefox\/([\d.]+)/))) return 'Firefox ' + m[1];
    if (/Chrome\//.test(ua) && (m = ua.match(/Chrome\/([\d.]+)/))) return 'Chrome ' + m[1];
    if (/Safari\//.test(ua) && (m = ua.match(/Version\/([\d.]+)/))) return 'Safari ' + m[1];
    return 'unknown';
  }

  function detectOS() {
    if (uaData && uaData.platform) {
      var p = uaData.platform;
      if (p === 'Windows') return 'Windows';
      if (p) return p;
    }
    if (/Windows NT 10/.test(ua)) return 'Windows 10/11';
    if (/Windows NT 6\.3/.test(ua)) return 'Windows 8.1';
    if (/Windows/.test(ua)) return 'Windows';
    if (/Mac OS X ([\d_]+)/.test(ua)) return 'macOS ' + RegExp.$1.replace(/_/g, '.');
    if (/Android ([\d.]+)/.test(ua)) return 'Android ' + RegExp.$1;
    if (/(iPhone|iPad).*OS ([\d_]+)/.test(ua)) return 'iOS ' + RegExp.$2.replace(/_/g, '.');
    if (/Linux/.test(ua)) return 'Linux';
    return 'unknown';
  }

  function detectDevice() {
    if (uaData && typeof uaData.mobile === 'boolean') {
      return uaData.mobile ? 'mobile' : 'desktop';
    }
    if (/iPad|Tablet/.test(ua)) return 'tablet';
    if (/Mobi|Android|iPhone/.test(ua)) return 'mobile';
    return 'desktop';
  }

  set('si-browser', detectBrowser());
  set('si-os', detectOS());
  set('si-device', detectDevice());

  // ---- Display ----
  var dpr = window.devicePixelRatio || 1;
  set('si-screen', screen.width + 'x' + screen.height + ' @' + dpr + 'x, ' + (screen.colorDepth || '?') + '-bit');
  set('si-viewport', window.innerWidth + 'x' + window.innerHeight);

  // ---- Hardware ----
  set('si-cpu', navigator.hardwareConcurrency ? navigator.hardwareConcurrency + ' threads' : 'unknown');
  set('si-mem', navigator.deviceMemory ? '~' + navigator.deviceMemory + ' GB' : 'unknown');

  // ---- Locale / time ----
  var tz = 'unknown';
  try { tz = Intl.DateTimeFormat().resolvedOptions().timeZone || 'unknown'; } catch (e) {}
  set('si-tz', tz);
  set('si-lang', navigator.language || 'unknown');

  var timeEl = document.getElementById('si-time');
  function tick() {
    if (!timeEl) return;
    timeEl.textContent = new Date().toLocaleTimeString([], { hour12: false });
    timeEl.classList.remove('pending');
  }
  tick();
  setInterval(tick, 1000);

  // ---- Connection ----
  var conn = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
  if (conn && conn.effectiveType) {
    var parts = [conn.effectiveType];
    if (conn.downlink) parts.push(conn.downlink + ' Mbps');
    if (conn.rtt != null) parts.push(conn.rtt + ' ms rtt');
    set('si-net', parts.join(', '));
  } else {
    set('si-net', 'unavailable');
  }

  // ---- Public IP + geo (client-side lookup, best effort) ----
  fetch('https://ipapi.co/json/')
    .then(function (r) { if (!r.ok) throw new Error('bad status'); return r.json(); })
    .then(function (d) {
      set('si-ip', d.ip || 'unavailable');
      var loc = [d.city, d.region, d.country_name].filter(Boolean).join(', ');
      set('si-loc', loc || 'unavailable');
      set('si-isp', d.org || 'unavailable');
    })
    .catch(function () {
      // Fallback: IP only.
      fetch('https://api.ipify.org?format=json')
        .then(function (r) { return r.json(); })
        .then(function (d) { set('si-ip', d.ip || 'unavailable'); })
        .catch(function () { set('si-ip', 'blocked (adblocker/privacy)'); });
      set('si-loc', 'unavailable');
      set('si-isp', 'unavailable');
    });
})();
