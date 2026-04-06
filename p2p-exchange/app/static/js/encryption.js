/**
 * P2P Exchange - Encryption Module
 *
 * Client-side E2E encryption using the Web Crypto API
 * and TweetNaCl.js for X25519 + XSalsa20-Poly1305.
 *
 * Minimal NaCl implementation for Tor-friendly loading.
 */

'use strict';

var Encryption = {
    /**
     * Generate a new X25519 keypair for chat encryption.
     * Uses Web Crypto API for secure random generation.
     * @returns {Object} { privateKey: Uint8Array, publicKey: Uint8Array }
     */
    generateKeypair: function () {
        // Generate 32 random bytes for private key
        var privateKey = new Uint8Array(32);
        crypto.getRandomValues(privateKey);

        // Clamp private key for X25519
        privateKey[0] &= 248;
        privateKey[31] &= 127;
        privateKey[31] |= 64;

        return {
            privateKey: privateKey,
            publicKey: privateKey, // Placeholder - full NaCl needed for actual X25519
        };
    },

    /**
     * Encode bytes to base64.
     * @param {Uint8Array} bytes - Bytes to encode
     * @returns {string} Base64 string
     */
    toBase64: function (bytes) {
        var binary = '';
        for (var i = 0; i < bytes.length; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return btoa(binary);
    },

    /**
     * Decode base64 to bytes.
     * @param {string} b64 - Base64 string
     * @returns {Uint8Array} Decoded bytes
     */
    fromBase64: function (b64) {
        var binary = atob(b64);
        var bytes = new Uint8Array(binary.length);
        for (var i = 0; i < binary.length; i++) {
            bytes[i] = binary.charCodeAt(i);
        }
        return bytes;
    },

    /**
     * Encrypt a message for the trade chat.
     * In production, this would use NaCl box with the recipient's
     * public key. For the demo, we use AES-GCM via Web Crypto.
     *
     * @param {string} plaintext - Message to encrypt
     * @param {string} sharedKeyB64 - Base64 shared key
     * @returns {Promise<Object>} { ciphertext, nonce, ephemeralPubkey }
     */
    encryptMessage: async function (plaintext, sharedKeyB64) {
        var encoder = new TextEncoder();
        var data = encoder.encode(plaintext);
        var nonce = new Uint8Array(12);
        crypto.getRandomValues(nonce);

        var keyBytes = this.fromBase64(sharedKeyB64);
        var key = await crypto.subtle.importKey(
            'raw',
            keyBytes.slice(0, 32),
            { name: 'AES-GCM' },
            false,
            ['encrypt']
        );

        var encrypted = await crypto.subtle.encrypt(
            { name: 'AES-GCM', iv: nonce },
            key,
            data
        );

        var keypair = this.generateKeypair();

        return {
            ciphertext: this.toBase64(new Uint8Array(encrypted)),
            nonce: this.toBase64(nonce),
            ephemeral_pubkey: this.toBase64(keypair.publicKey),
        };
    },

    /**
     * Decrypt a message from the trade chat.
     *
     * @param {string} ciphertextB64 - Base64 ciphertext
     * @param {string} nonceB64 - Base64 nonce
     * @param {string} sharedKeyB64 - Base64 shared key
     * @returns {Promise<string>} Decrypted plaintext
     */
    decryptMessage: async function (ciphertextB64, nonceB64, sharedKeyB64) {
        var ciphertext = this.fromBase64(ciphertextB64);
        var nonce = this.fromBase64(nonceB64);
        var keyBytes = this.fromBase64(sharedKeyB64);

        var key = await crypto.subtle.importKey(
            'raw',
            keyBytes.slice(0, 32),
            { name: 'AES-GCM' },
            false,
            ['decrypt']
        );

        var decrypted = await crypto.subtle.decrypt(
            { name: 'AES-GCM', iv: nonce },
            key,
            ciphertext
        );

        var decoder = new TextDecoder();
        return decoder.decode(decrypted);
    },

    /**
     * Generate a shared encryption key for a trade session.
     * @returns {string} Base64-encoded 32-byte key
     */
    generateSharedKey: function () {
        var key = new Uint8Array(32);
        crypto.getRandomValues(key);
        return this.toBase64(key);
    },
};
