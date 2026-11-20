# Remove Ads as a non-consumable IAP via StoreKit 2, with mandatory restore

> Status: arah Remove Ads sekali beli dan StoreKit 2 disetujui; alur restore masih draf. Klaim bahwa Apple menyukai opsi ini bukan bukti atau jaminan kelulusan review. Lihat [Menetapkan Kadens Iklan dan pengalaman Remove Ads](https://github.com/benih-dev/offplay/issues/24).

Remove Ads is a single non-consumable StoreKit 2 in-app purchase. Buying it disables all ads. A restore option is required in Settings so a user who re-installs the app can recover the purchase without paying twice.

Reason: Apple favours apps that offer an IAP to remove ads, and re-install recovery is a real user path. StoreKit 2 keeps receipt and restore handling minimal in modern Swift.
