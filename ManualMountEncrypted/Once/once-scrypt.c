/* 同事电脑上解开一次性密钥。口令只从标准输入读，不进参数。
   只依赖 libc，方便做成静态程序，对方不必安装 python。 */
#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

enum { BODY = 256, DKLEN = 32 + BODY };

static void wipe(void *ptr, size_t n) {
    volatile uint8_t *p = ptr;
    while (n--) {
        *p++ = 0;
    }
}

static void die(const char *msg) {
    fprintf(stderr, "%s\n", msg);
    exit(1);
}

static uint32_t rotr(uint32_t x, uint32_t n) {
    return (x >> n) | (x << (32 - n));
}

static uint32_t load_be32(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) | ((uint32_t)p[2] << 8) | p[3];
}

static void store_be32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v >> 24);
    p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >> 8);
    p[3] = (uint8_t)v;
}

static void sha256(const uint8_t *msg, size_t len, uint8_t out[32]) {
    static const uint32_t k[64] = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2};
    uint32_t h[8] = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                     0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};
    size_t total = ((len + 1 + 8 + 63) / 64) * 64;
    uint8_t *buf = calloc(1, total);
    if (!buf) {
        die("内存不够，解不开。");
    }
    memcpy(buf, msg, len);
    buf[len] = 0x80;
    uint64_t bits = (uint64_t)len * 8;
    for (int i = 0; i < 8; i++) {
        buf[total - 1 - i] = (uint8_t)(bits >> (8 * i));
    }
    for (size_t off = 0; off < total; off += 64) {
        uint32_t w[64];
        for (int i = 0; i < 16; i++) {
            w[i] = load_be32(buf + off + (size_t)i * 4);
        }
        for (int i = 16; i < 64; i++) {
            uint32_t s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
            uint32_t s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16] + s0 + w[i - 7] + s1;
        }
        uint32_t a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
        for (int i = 0; i < 64; i++) {
            uint32_t S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
            uint32_t ch = (e & f) ^ ((~e) & g);
            uint32_t t1 = hh + S1 + ch + k[i] + w[i];
            uint32_t S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
            uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
            uint32_t t2 = S0 + maj;
            hh = g;
            g = f;
            f = e;
            e = d + t1;
            d = c;
            c = b;
            b = a;
            a = t1 + t2;
        }
        h[0] += a;
        h[1] += b;
        h[2] += c;
        h[3] += d;
        h[4] += e;
        h[5] += f;
        h[6] += g;
        h[7] += hh;
    }
    wipe(buf, total);
    free(buf);
    for (int i = 0; i < 8; i++) {
        store_be32(out + (size_t)i * 4, h[i]);
    }
}

static void hmac_sha256(const uint8_t *key, size_t keylen, const uint8_t *msg, size_t msglen, uint8_t out[32]) {
    uint8_t k[64];
    memset(k, 0, sizeof k);
    if (keylen > 64) {
        sha256(key, keylen, k);
    } else {
        memcpy(k, key, keylen);
    }
    uint8_t pad[64];
    uint8_t *inner_msg = malloc(64 + msglen);
    if (!inner_msg) {
        die("内存不够，解不开。");
    }
    for (int i = 0; i < 64; i++) {
        pad[i] = k[i] ^ 0x36;
    }
    memcpy(inner_msg, pad, 64);
    memcpy(inner_msg + 64, msg, msglen);
    uint8_t inner[32];
    sha256(inner_msg, 64 + msglen, inner);
    wipe(inner_msg, 64 + msglen);
    free(inner_msg);
    for (int i = 0; i < 64; i++) {
        pad[i] = k[i] ^ 0x5c;
    }
    uint8_t outer[96];
    memcpy(outer, pad, 64);
    memcpy(outer + 64, inner, 32);
    sha256(outer, 96, out);
    wipe(k, sizeof k);
    wipe(pad, sizeof pad);
    wipe(inner, sizeof inner);
    wipe(outer, sizeof outer);
}

static uint32_t rotl(uint32_t x, uint32_t n) {
    return (x << n) | (x >> (32 - n));
}

static void salsa20_8(uint8_t block[64]) {
    uint32_t b[16], x[16];
    for (int i = 0; i < 16; i++) {
        b[i] = (uint32_t)block[i * 4] | ((uint32_t)block[i * 4 + 1] << 8) |
               ((uint32_t)block[i * 4 + 2] << 16) | ((uint32_t)block[i * 4 + 3] << 24);
        x[i] = b[i];
    }
    for (int round = 0; round < 4; round++) {
        x[4] ^= rotl(x[0] + x[12], 7);
        x[8] ^= rotl(x[4] + x[0], 9);
        x[12] ^= rotl(x[8] + x[4], 13);
        x[0] ^= rotl(x[12] + x[8], 18);
        x[9] ^= rotl(x[5] + x[1], 7);
        x[13] ^= rotl(x[9] + x[5], 9);
        x[1] ^= rotl(x[13] + x[9], 13);
        x[5] ^= rotl(x[1] + x[13], 18);
        x[14] ^= rotl(x[10] + x[6], 7);
        x[2] ^= rotl(x[14] + x[10], 9);
        x[6] ^= rotl(x[2] + x[14], 13);
        x[10] ^= rotl(x[6] + x[2], 18);
        x[3] ^= rotl(x[15] + x[11], 7);
        x[7] ^= rotl(x[3] + x[15], 9);
        x[11] ^= rotl(x[7] + x[3], 13);
        x[15] ^= rotl(x[11] + x[7], 18);
        x[1] ^= rotl(x[0] + x[3], 7);
        x[2] ^= rotl(x[1] + x[0], 9);
        x[3] ^= rotl(x[2] + x[1], 13);
        x[0] ^= rotl(x[3] + x[2], 18);
        x[6] ^= rotl(x[5] + x[4], 7);
        x[7] ^= rotl(x[6] + x[5], 9);
        x[4] ^= rotl(x[7] + x[6], 13);
        x[5] ^= rotl(x[4] + x[7], 18);
        x[11] ^= rotl(x[10] + x[9], 7);
        x[8] ^= rotl(x[11] + x[10], 9);
        x[9] ^= rotl(x[8] + x[11], 13);
        x[10] ^= rotl(x[9] + x[8], 18);
        x[12] ^= rotl(x[15] + x[14], 7);
        x[13] ^= rotl(x[12] + x[15], 9);
        x[14] ^= rotl(x[13] + x[12], 13);
        x[15] ^= rotl(x[14] + x[13], 18);
    }
    for (int i = 0; i < 16; i++) {
        uint32_t v = b[i] + x[i];
        block[i * 4] = (uint8_t)v;
        block[i * 4 + 1] = (uint8_t)(v >> 8);
        block[i * 4 + 2] = (uint8_t)(v >> 16);
        block[i * 4 + 3] = (uint8_t)(v >> 24);
    }
}

static void blockmix(uint8_t *block, uint8_t *out, size_t r) {
    uint8_t x[64];
    memcpy(x, block + (2 * r - 1) * 64, 64);
    for (size_t i = 0; i < 2 * r; i++) {
        for (int k = 0; k < 64; k++) {
            x[k] ^= block[i * 64 + (size_t)k];
        }
        salsa20_8(x);
        memcpy(out + i * 64, x, 64);
    }
    for (size_t i = 0; i < r; i++) {
        memcpy(block + i * 64, out + (i * 2) * 64, 64);
    }
    for (size_t i = 0; i < r; i++) {
        memcpy(block + (i + r) * 64, out + (i * 2 + 1) * 64, 64);
    }
    wipe(x, sizeof x);
}

static void smix(uint8_t *block, size_t r, uint64_t n, uint8_t *v) {
    size_t blen = 128 * r;
    uint8_t *x = malloc(blen);
    uint8_t *y = malloc(blen);
    if (!x || !y) {
        die("内存不够，解不开。");
    }
    memcpy(x, block, blen);
    for (uint64_t i = 0; i < n; i++) {
        memcpy(v + i * blen, x, blen);
        blockmix(x, y, r);
    }
    for (uint64_t i = 0; i < n; i++) {
        uint8_t *last = x + (2 * r - 1) * 64;
        uint64_t j = 0;
        for (int k = 0; k < 8; k++) {
            j |= (uint64_t)last[k] << (8 * k);
        }
        j &= n - 1;
        uint8_t *src = v + j * blen;
        for (size_t k = 0; k < blen; k++) {
            x[k] ^= src[k];
        }
        blockmix(x, y, r);
    }
    memcpy(block, x, blen);
    wipe(x, blen);
    wipe(y, blen);
    free(x);
    free(y);
}

static void pbkdf2_once(const uint8_t *pass, size_t passlen, const uint8_t *salt, size_t saltlen,
                        uint8_t *out, size_t dklen) {
    uint8_t *msg = malloc(saltlen + 4);
    if (!msg) {
        die("内存不够，解不开。");
    }
    memcpy(msg, salt, saltlen);
    size_t done = 0;
    uint32_t counter = 1;
    while (done < dklen) {
        msg[saltlen] = (uint8_t)(counter >> 24);
        msg[saltlen + 1] = (uint8_t)(counter >> 16);
        msg[saltlen + 2] = (uint8_t)(counter >> 8);
        msg[saltlen + 3] = (uint8_t)counter;
        uint8_t block[32];
        hmac_sha256(pass, passlen, msg, saltlen + 4, block);
        size_t take = dklen - done;
        if (take > 32) {
            take = 32;
        }
        memcpy(out + done, block, take);
        wipe(block, sizeof block);
        done += take;
        counter++;
    }
    wipe(msg, saltlen + 4);
    free(msg);
}

static void scrypt_dk(const uint8_t *pass, size_t passlen, const uint8_t *salt, size_t saltlen, uint64_t n,
                      uint32_t r, uint32_t p, uint8_t *out, size_t dklen) {
    if (r == 0 || r > 16 || p == 0 || p > 16 || n < 2 || n > (1u << 20) || (n & (n - 1)) != 0) {
        die("密钥文件损坏。");
    }
    size_t blen = 128 * (size_t)r;
    if (blen > (256ull * 1024 * 1024) / n) {
        die("内存不够，解不开。");
    }
    size_t buflen = blen * p;
    uint8_t *b = malloc(buflen);
    uint8_t *v = malloc(blen * (size_t)n);
    if (!b || !v) {
        die("内存不够，解不开。");
    }
    pbkdf2_once(pass, passlen, salt, saltlen, b, buflen);
    for (uint32_t i = 0; i < p; i++) {
        smix(b + (size_t)i * blen, r, n, v);
    }
    pbkdf2_once(pass, passlen, b, buflen, out, dklen);
    wipe(b, buflen);
    wipe(v, blen * (size_t)n);
    free(b);
    free(v);
}

static int b64val(int c) {
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}

static size_t b64decode(const char *text, uint8_t *out, size_t outcap) {
    size_t len = strlen(text);
    if (len == 0 || (len % 4) != 0) {
        die("密钥文件损坏。");
    }
    size_t o = 0;
    for (size_t i = 0; i < len; i += 4) {
        int pad = 0;
        int v[4];
        for (int k = 0; k < 4; k++) {
            if (text[i + (size_t)k] == '=') {
                v[k] = 0;
                pad++;
            } else {
                if (pad) {
                    die("密钥文件损坏。");
                }
                v[k] = b64val((unsigned char)text[i + (size_t)k]);
                if (v[k] < 0) {
                    die("密钥文件损坏。");
                }
            }
        }
        if (pad > 2) {
            die("密钥文件损坏。");
        }
        uint32_t triple = ((uint32_t)v[0] << 18) | ((uint32_t)v[1] << 12) | ((uint32_t)v[2] << 6) | (uint32_t)v[3];
        uint8_t decoded[3];
        decoded[0] = (uint8_t)(triple >> 16);
        decoded[1] = (uint8_t)(triple >> 8);
        decoded[2] = (uint8_t)triple;
        size_t keep = (size_t)(3 - pad);
        if (o + keep > outcap) {
            die("密钥文件损坏。");
        }
        memcpy(out + o, decoded, keep);
        o += keep;
    }
    return o;
}

static int hexval(int c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static size_t hexdecode(const char *text, uint8_t *out, size_t outcap) {
    size_t len = strlen(text);
    if ((len % 2) != 0 || len / 2 > outcap) {
        die("参数不对。");
    }
    for (size_t i = 0; i < len; i += 2) {
        int hi = hexval((unsigned char)text[i]);
        int lo = hexval((unsigned char)text[i + 1]);
        if (hi < 0 || lo < 0) {
            die("参数不对。");
        }
        out[i / 2] = (uint8_t)((hi << 4) | lo);
    }
    return len / 2;
}

static char *field_get(char *text, const char *key);

static void copy_field(const char *raw, size_t nread, const char *key, char *dest, size_t destlen) {
    char *buf = malloc(nread + 1);
    if (!buf) {
        die("内存不够，解不开。");
    }
    memcpy(buf, raw, nread + 1);
    char *val = field_get(buf, key);
    if (!val || strlen(val) >= destlen) {
        free(buf);
        die(val ? "密钥文件损坏。" : "密钥文件缺字段。");
    }
    memcpy(dest, val, strlen(val) + 1);
    free(buf);
}

static char *field_get(char *text, const char *key) {
    size_t klen = strlen(key);
    char *save = NULL;
    for (char *line = strtok_r(text, "\n", &save); line; line = strtok_r(NULL, "\n", &save)) {
        if (line[0] == '\0' || strcmp(line, "ONCEKEY2") == 0) {
            continue;
        }
        char *eq = strchr(line, '=');
        if (!eq) {
            die("密钥文件损坏。");
        }
        if ((size_t)(eq - line) == klen && strncmp(line, key, klen) == 0) {
            return eq + 1;
        }
    }
    return NULL;
}

static void open_key(const char *path, long now, const uint8_t *temp, size_t templen) {
    FILE *fp = fopen(path, "r");
    if (!fp) {
        die("读不了 U 盘上的密钥文件。");
    }
    char raw[4096];
    size_t nread = fread(raw, 1, sizeof raw - 1, fp);
    if (!feof(fp)) {
        fclose(fp);
        die("密钥文件损坏。");
    }
    fclose(fp);
    raw[nread] = '\0';
    if (strncmp(raw, "ONCEKEY2\n", 9) != 0) {
        die("不是这次的密钥文件。");
    }
    char kind_buf[16], n_buf[32], r_buf[32], p_buf[32], exp_buf[32];
    char salt_text[256], ct_text[512], mac_text[128];
    copy_field(raw, nread, "kind", kind_buf, sizeof kind_buf);
    copy_field(raw, nread, "n", n_buf, sizeof n_buf);
    copy_field(raw, nread, "r", r_buf, sizeof r_buf);
    copy_field(raw, nread, "p", p_buf, sizeof p_buf);
    copy_field(raw, nread, "salt", salt_text, sizeof salt_text);
    copy_field(raw, nread, "ct", ct_text, sizeof ct_text);
    copy_field(raw, nread, "mac", mac_text, sizeof mac_text);
    copy_field(raw, nread, "expires", exp_buf, sizeof exp_buf);
    uint64_t n = strtoull(n_buf, NULL, 10);
    uint32_t r = (uint32_t)strtoul(r_buf, NULL, 10);
    uint32_t p = (uint32_t)strtoul(p_buf, NULL, 10);
    long expires = strtol(exp_buf, NULL, 10);
    long wall = (long)time(NULL);
    long effective = wall;
    if (now > effective) {
        effective = now;
    }
    if (expires <= effective) {
        die("密钥文件已过期。");
    }
    uint8_t pass[1024];
    size_t passlen = 0;
    if (strcmp(kind_buf, "pin") == 0 || strcmp(kind_buf, "token") == 0) {
        for (size_t i = 0; i < templen; i++) {
            if (temp[i] == ' ' || temp[i] == '-') {
                continue;
            }
            if (passlen >= sizeof pass) {
                die("临时口令不对。");
            }
            pass[passlen++] = temp[i];
        }
    } else {
        if (templen > sizeof pass) {
            die("临时口令不对。");
        }
        memcpy(pass, temp, templen);
        passlen = templen;
    }
    if (passlen == 0) {
        die("临时口令是空的。");
    }
    uint8_t salt[128], ct[BODY], mac[32];
    size_t saltlen = b64decode(salt_text, salt, sizeof salt);
    size_t ctlen = b64decode(ct_text, ct, sizeof ct);
    size_t maclen = b64decode(mac_text, mac, sizeof mac);
    if (ctlen != BODY || maclen != 32 || saltlen == 0) {
        die("密钥文件损坏。");
    }
    uint8_t dk[DKLEN];
    scrypt_dk(pass, passlen, salt, saltlen, n, r, p, dk, DKLEN);
    size_t explen = strlen(exp_buf);
    uint8_t *msg = malloc(saltlen + BODY + explen);
    if (!msg) {
        die("内存不够，解不开。");
    }
    memcpy(msg, salt, saltlen);
    memcpy(msg + saltlen, ct, BODY);
    memcpy(msg + saltlen + BODY, exp_buf, explen);
    uint8_t expect[32];
    hmac_sha256(dk, 32, msg, saltlen + BODY + explen, expect);
    wipe(msg, saltlen + BODY + explen);
    free(msg);
    unsigned diff = 0;
    for (int i = 0; i < 32; i++) {
        diff |= (unsigned)(expect[i] ^ mac[i]);
    }
    if (diff != 0) {
        wipe(pass, sizeof pass);
        wipe(dk, sizeof dk);
        die("临时口令不对。");
    }
    wall = (long)time(NULL);
    effective = wall;
    if (now > effective) {
        effective = now;
    }
    if (expires <= effective) {
        wipe(pass, sizeof pass);
        wipe(dk, sizeof dk);
        die("密钥文件已过期。");
    }
    uint8_t body[BODY];
    for (int i = 0; i < BODY; i++) {
        body[i] = ct[i] ^ dk[32 + i];
    }
    unsigned ln = ((unsigned)body[0] << 8) | body[1];
    if (ln < 1 || ln > BODY - 2) {
        die("临时口令不对。");
    }
    for (unsigned i = 2 + ln; i < BODY; i++) {
        if (body[i] != 0) {
            die("临时口令不对。");
        }
    }
    for (unsigned i = 0; i < ln; i++) {
        if (body[2 + i] == '\n' || body[2 + i] == '\0') {
            die("临时口令不对。");
        }
    }
    fwrite(body + 2, 1, ln, stdout);
    wipe(pass, sizeof pass);
    wipe(dk, sizeof dk);
    wipe(body, sizeof body);
}

static void raw_dk(int argc, char **argv, const uint8_t *pass, size_t passlen) {
    if (argc != 7) {
        exit(2);
    }
    uint8_t salt[128];
    size_t saltlen = hexdecode(argv[2], salt, sizeof salt);
    uint64_t n = strtoull(argv[3], NULL, 10);
    uint32_t r = (uint32_t)strtoul(argv[4], NULL, 10);
    uint32_t p = (uint32_t)strtoul(argv[5], NULL, 10);
    size_t dklen = (size_t)strtoul(argv[6], NULL, 10);
    if (dklen == 0 || dklen > 1024) {
        die("参数不对。");
    }
    uint8_t *out = malloc(dklen);
    if (!out) {
        die("内存不够，解不开。");
    }
    scrypt_dk(pass, passlen, salt, saltlen, n, r, p, out, dklen);
    fwrite(out, 1, dklen, stdout);
    wipe(out, dklen);
    free(out);
    wipe((void *)pass, passlen);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        return 2;
    }
    uint8_t temp[1024];
    size_t templen = 0;
    while (templen < sizeof temp) {
        size_t got = fread(temp + templen, 1, sizeof temp - templen, stdin);
        if (got == 0) {
            break;
        }
        templen += got;
    }
    if (!feof(stdin)) {
        die("临时口令不对。");
    }
    if (strcmp(argv[1], "raw") == 0) {
        raw_dk(argc, argv, temp, templen);
        return 0;
    }
    if (argc != 3) {
        return 2;
    }
    char *end = NULL;
    long now = strtol(argv[2], &end, 10);
    if (!end || *end != '\0') {
        die("读不到时间。");
    }
    open_key(argv[1], now, temp, templen);
    return 0;
}
