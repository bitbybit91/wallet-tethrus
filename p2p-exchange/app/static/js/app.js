/**
 * P2P Exchange - Main Application JavaScript
 *
 * Core API client and session management.
 * No external dependencies - vanilla JS only (Tor-friendly).
 */

'use strict';

const App = {
    /** Base URL for API requests */
    apiBase: '/api',

    /** Current user session data */
    session: null,

    /**
     * Initialize the application.
     * Restores session from localStorage if available.
     */
    init: function () {
        this.session = this.loadSession();
        this.updateUI();

        if (this.session) {
            this.verifySession();
        }
    },

    /**
     * Make an authenticated API request.
     * @param {string} path - API endpoint path
     * @param {Object} options - Fetch options
     * @returns {Promise<Object>} Response JSON
     */
    api: async function (path, options) {
        options = options || {};
        var headers = options.headers || {};
        headers['Content-Type'] = 'application/json';

        if (this.session && this.session.session_token) {
            headers['Authorization'] = 'Bearer ' + this.session.session_token;
        }

        options.headers = headers;

        try {
            var response = await fetch(this.apiBase + path, options);
            var data = await response.json();

            if (response.status === 401) {
                this.clearSession();
                this.updateUI();
            }

            return data;
        } catch (err) {
            console.error('API request failed:', err);
            return { success: false, error: 'Network error' };
        }
    },

    /**
     * Create a new anonymous session.
     */
    createSession: async function () {
        var data = await this.api('/auth/session', { method: 'POST' });

        if (data.success) {
            this.session = data.user;
            this.saveSession();
            this.updateUI();
            App.showAlert('Session created! You are: ' + data.user.nickname, 'success');
        } else {
            App.showAlert('Failed to create session: ' + data.error, 'error');
        }
    },

    /**
     * Verify the current session token is still valid.
     */
    verifySession: async function () {
        if (!this.session) return;

        var data = await this.api('/auth/session/verify', {
            method: 'POST',
            body: JSON.stringify({ session_token: this.session.session_token }),
        });

        if (data.success) {
            this.session = data.user;
            this.saveSession();
        } else {
            this.clearSession();
        }
        this.updateUI();
    },

    /**
     * Generate a new BIP39 mnemonic for persistent identity.
     */
    generateMnemonic: async function () {
        var data = await this.api('/auth/mnemonic/generate', { method: 'POST' });

        if (data.success) {
            return data;
        }
        App.showAlert('Failed to generate mnemonic: ' + data.error, 'error');
        return null;
    },

    /**
     * Restore identity from a BIP39 mnemonic phrase.
     * @param {string} mnemonic - 12-word phrase
     */
    restoreFromMnemonic: async function (mnemonic) {
        var data = await this.api('/auth/mnemonic/restore', {
            method: 'POST',
            body: JSON.stringify({ mnemonic: mnemonic }),
        });

        if (data.success) {
            this.session = data.user;
            this.saveSession();
            this.updateUI();
            App.showAlert('Identity restored: ' + data.user.nickname, 'success');
        } else {
            App.showAlert('Restore failed: ' + data.error, 'error');
        }
    },

    /**
     * Save session data to localStorage.
     */
    saveSession: function () {
        if (this.session) {
            localStorage.setItem('p2p_session', JSON.stringify(this.session));
        }
    },

    /**
     * Load session data from localStorage.
     * @returns {Object|null}
     */
    loadSession: function () {
        try {
            var data = localStorage.getItem('p2p_session');
            return data ? JSON.parse(data) : null;
        } catch (e) {
            return null;
        }
    },

    /**
     * Clear the current session.
     */
    clearSession: function () {
        this.session = null;
        localStorage.removeItem('p2p_session');
        this.updateUI();
    },

    /**
     * Update the UI based on authentication state.
     */
    updateUI: function () {
        var userInfo = document.getElementById('user-info');
        var authActions = document.getElementById('auth-actions');
        var loggedInNav = document.querySelectorAll('.auth-required');

        if (this.session) {
            if (userInfo) {
                userInfo.innerHTML =
                    '<span class="user-nickname">' +
                    this.escapeHtml(this.session.nickname) +
                    '</span>' +
                    '<span>Score: ' + (this.session.trust_score || 0) + '</span>' +
                    '<button class="btn btn-sm" onclick="App.clearSession()">Logout</button>';
                userInfo.style.display = 'flex';
            }
            if (authActions) authActions.style.display = 'none';
            loggedInNav.forEach(function (el) {
                el.style.display = '';
            });
        } else {
            if (userInfo) userInfo.style.display = 'none';
            if (authActions) authActions.style.display = '';
            loggedInNav.forEach(function (el) {
                el.style.display = 'none';
            });
        }
    },

    /**
     * Show a temporary alert message.
     * @param {string} message - Alert text
     * @param {string} type - Alert type (success, error, warning, info)
     */
    showAlert: function (message, type) {
        type = type || 'info';
        var container = document.getElementById('alert-container');
        if (!container) return;

        var alert = document.createElement('div');
        alert.className = 'alert alert-' + type;
        alert.textContent = message;
        container.appendChild(alert);

        setTimeout(function () {
            alert.remove();
        }, 5000);
    },

    /**
     * Escape HTML to prevent XSS.
     * @param {string} str - Raw string
     * @returns {string} Escaped string
     */
    escapeHtml: function (str) {
        var div = document.createElement('div');
        div.appendChild(document.createTextNode(str));
        return div.innerHTML;
    },

    /**
     * Format a Unix timestamp to a readable date string.
     * @param {number} timestamp - Unix timestamp
     * @returns {string} Formatted date
     */
    formatDate: function (timestamp) {
        if (!timestamp) return 'N/A';
        return new Date(timestamp * 1000).toLocaleString();
    },

    /**
     * Format a number with commas and fixed decimals.
     * @param {number} num - Number to format
     * @param {number} decimals - Decimal places
     * @returns {string} Formatted number
     */
    formatNumber: function (num, decimals) {
        decimals = decimals !== undefined ? decimals : 2;
        return Number(num).toLocaleString(undefined, {
            minimumFractionDigits: decimals,
            maximumFractionDigits: decimals,
        });
    },

    /**
     * Get trust badge HTML based on score.
     * @param {number} score - Trust score
     * @returns {string} Badge HTML
     */
    getTrustBadge: function (score) {
        var level, cls;
        if (score >= 70) {
            level = 'High';
            cls = 'trust-high';
        } else if (score >= 40) {
            level = 'Medium';
            cls = 'trust-medium';
        } else {
            level = 'Low';
            cls = 'trust-low';
        }
        return (
            '<span class="trust-badge ' + cls + '">' +
            '&#9733; ' + score + ' ' + level +
            '</span>'
        );
    },
};

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function () {
    App.init();
});
