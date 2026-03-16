// api.js — Shared API wrapper with auto-refresh (cookie-based auth)
const API_BASE = '';

/**
 * Escape HTML special characters to prevent XSS.
 * @param {string} str
 * @returns {string}
 */
export function escapeHtml(str) {
  if (str == null) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export async function apiFetch(path, options = {}) {
  const headers = { ...options.headers };

  let res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
    credentials: 'same-origin',
  });

  // Try refresh if token expired
  if (res.status === 401) {
    const refreshRes = await fetch(`${API_BASE}/api/auth/refresh`, {
      method: 'POST',
      credentials: 'same-origin',
    });

    if (refreshRes.ok) {
      res = await fetch(`${API_BASE}${path}`, {
        ...options,
        headers,
        credentials: 'same-origin',
      });
    } else {
      window.location.href = '/login';
    }
  }

  return res;
}
