# Monetization with AdMob, ads shown only online and failing silently offline

> Status: AdMob disetujui. Rincian perilaku SDK, privasi, dan Kadens Iklan masih draf; klaim pembayaran iklan di bawah belum diverifikasi. Lihat [Memeriksa batas AdMob, privasi, dan Remove Ads](https://github.com/benih-dev/offplay/issues/21).

Ads use AdMob. Interstitial ads are shown only while the device is online per the Kadens Iklan; offline, ad requests fail silently and never block or gate a Judul. Remove Ads disables all ads.

Reason: an offline-first product must never depend on ad availability, matching the Bermain offline definition. Cached pre-loaded interstitials are treated as a bonus while online, not a revenue guarantee offline, because impressions may not record or pay out reliably without a connection.
