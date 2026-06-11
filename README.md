# USER MANUAL ACTEEVAZ
ACTEEVAZ merupakan aplikasi yang membantu pencatatan dan pengelolaan aktiva tetap bagi perusahaan. Aplikasi ini terinspirasi dari software ACCURATE versi 5. Source code ini memodifikasi modul "Aktiva Tetap" dari software ACCURATE versi 5. Aplikasi ini disusun menggunakan R Studio dan R Shiny untuk membuatnya menjadi website interaktif. 

Panduan Instalasi ACTEEVAZ:
1. Buka file Source-Code-ACTEEVAZ_FIX.R pada repository Source-Code-ACTEEVAZ
2. Klik tombol berlogo "Donwload" untuk mengunduh raw file dari source code.
3. Buka file pada R Studio
4. Klik "Run App" di sisi kanan R Script. Anda akan diarahkan ke Dashboard Acteevaz di R Shiny.
5. Apabila Anda ingin menjalankan di browser, klik "Open in Browser" di sisi kiri atas R Shiny.

5 HALAMAN UTAMA dalam aplikasi Acteevaz:
1. Acteevaz Analytics Dashboard
Halaman ini merupakan dasbor analitik yang menampilkan data total nilai aktiva tetap milik perusahaan secara real-time.
Terdapat dua tab pada halaman ini:
a. Tab "Grafik & Analisis"
b. Tab "Ringkasan"
Anda dapat mencetak salah satu tab ke dalam bentuk PDF.
Untuk saat ini, pencetakan menggunakan Printer hanya dimungkinkan melalui browser, bukan pada R Shiny.

2. Fiscal Fixed Asset Type
Memuat klasifikasi aktiva tetap beserta ketentuan perhitungan depresiasinya menurut UU PPh Nomor 17 Tahun 2020 Pasal 11
Anda dapat menambahkan, mengedit, menghapus, me-refresh, melakukan pencarian, mencetak, serta mengunduh dalam format Excel (.xlsx) atau CSV (.csv).

3. Fixed Asset Type
Memuat klasifikasi aktiva tetap menurut kebijakan perusahaan.
Anda dapat menambahkan, mengedit, menghapus, me-refresh, melakukan pencarian, mencetak, serta mengunduh dalam format Excel (.xlsx) atau CSV (.csv).

3. List of Fixed Asset
Mencatat aktiva tetap menurut UU kebijakan perusahaan.
Anda dapat menambahkan, mengedit, menghapus, me-refresh, mencetak, serta mengunduh dalam format Excel (.xlsx) atau CSV (.csv).

4. New Fixed Asset Form.
Anda dapat mencatat aktiva tetap baru yang dimiliki oleh perusahaan, melihat simulasi depresiasi dan perubahan nilai buku antar periode, menghapusbukukan aktiva tetap melalui menu "Dispose", serta melakukan revaluasi melalui menu "Revaluation".
Anda dapat mencetak formulir yang sedang Anda input melalui browser.


