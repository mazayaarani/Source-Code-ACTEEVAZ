pkgs <- c("shiny", "shinydashboard", "DT", "shinyjs", "shinyWidgets", "plotly", "scales", "writexl")
new_pkgs <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(new_pkgs) > 0) install.packages(new_pkgs)
lapply(pkgs, library, character.only = TRUE)

#1. DATA REAKTIF GLOBAL (in-memory data store)

#A. Fiscal Fixed Asset Type (UU No. 17 Tahun 2002 — PPh Pasal 11)
#Kelompok Bukan Bangunan: Golongan 1-4
#Kelompok Bangunan: Permanen & Semi Permanen
fiscal_type_data_init <- data.frame(
  fiscal_type_code    = c("FT-G1", "FT-G2", "FT-G3", "FT-G4", "FT-BP", "FT-BS"),
  fiscal_type_name    = c(
    "Golongan 1 (Bukan Bangunan)",
    "Golongan 2 (Bukan Bangunan)",
    "Golongan 3 (Bukan Bangunan)",
    "Golongan 4 (Bukan Bangunan)",
    "Bangunan Permanen",
    "Bangunan Semi Permanen"
  ),
  kategori            = c(
    "Bukan Bangunan", "Bukan Bangunan", "Bukan Bangunan", "Bukan Bangunan",
    "Bangunan", "Bangunan"
  ),
  umur_ekonomis       = c("1 – 4 Tahun", "4 – 8 Tahun", "8 – 16 Tahun",
                          "16 – 20 Tahun", "1 – 10 Tahun", "10 – 20 Tahun"),
  tarif_garis_lurus   = c(25.00, 12.50, 6.25, 5.00, 10.00, 5.00),
  tarif_saldo_menurun = c(50.00, 25.00, 12.50, 10.00, NA, NA),
  stringsAsFactors    = FALSE
)

#B. Fixed Asset Type
fa_type_data_init <- data.frame(
  type_code      = c("AT-KD", "AT-BG", "AT-INV"),
  type_name      = c("Kendaraan", "Bangunan", "Inventaris"),
  asset_account  = c("1.1.5.01", "1.1.5.02", "1.1.5.03"),
  accum_dep_acc  = c("1.1.5.11", "1.1.5.12", "1.1.5.13"),
  dep_exp_acc    = c("6.1.1.01", "6.1.1.02", "6.1.1.03"),
  stringsAsFactors = FALSE
)

#C. Fixed Asset List
fa_list_data_init <- data.frame(
  asset_code      = c("AT-001", "AT-002", "AT-003"),
  asset_desc      = c("Toyota Avanza 2020", "Gedung Kantor Pusat", "Laptop Dell XPS"),
  asset_type      = c("Kendaraan", "Bangunan", "Inventaris"),
  asset_account   = c("1.1.5.01", "1.1.5.02", "1.1.5.03"),
  asset_cost      = c(250000000, 2000000000, 25000000),
  acquisition_date = as.Date(c("2020-01-15", "2015-06-01", "2022-03-10")),
  usage_date      = as.Date(c("2020-02-01", "2015-07-01", "2022-03-15")),
  estimated_life  = c(8, 20, 4),
  dep_rate        = c(12.5, 5.0, 25.0),
  dep_method      = c("Straight Line", "Straight Line", "Double Declining"),
  department      = c("Marketing", "Umum", "IT"),
  intangible      = c("No", "No", "No"),
  fiscal          = c("Yes", "No", "Yes"),
  status          = c("Proceeded", "Proceeded", "Proceeded"),
  salvage_value   = c(10000000, 500000000, 0),
  notes           = c("", "", ""),
  stringsAsFactors = FALSE
)

#2. UI

ui <- dashboardPage(
  skin = "blue",
  
  #Header
  dashboardHeader(
    title = tags$span(
      tags$b(
        style = "font-family:'Segoe UI',sans-serif; font-size:20px; font-weight:900; color:#FFFFFF; letter-spacing:.06em;",
        "Acteevaz"
      ),
      tags$span(
        style = "font-size:10px; color:rgba(255,255,255,0.65); margin-left:7px; font-weight:400; letter-spacing:.08em; vertical-align:middle;",
        "Fixed Asset"
      )
    )
  ),
  
  #Sidebar
  dashboardSidebar(
    sidebarMenu(
      id = "sidebar_menu",
      menuItem("📊 Dashboard",         tabName = "dashboard",    icon = icon("chart-line")),
      tags$li(class = "header", style = "padding:8px 15px 3px; font-size:10px; color:#aaa; text-transform:uppercase; letter-spacing:.08em;", "Master Data"),
      menuItem("Fiscal Fixed Asset Type",  tabName = "fiscal_type",  icon = icon("percent")),
      menuItem("Fixed Asset Type", tabName = "fa_type",     icon = icon("layer-group")),
      menuItem("List of Fixed Asset",       tabName = "fa_list",     icon = icon("list")),
      menuItem("New Fixed Asset Form",      tabName = "new_fa",      icon = icon("file-invoice-dollar"))
    ),
    tags$div(
      style = "position:absolute; bottom:10px; padding:10px; font-size:11px; color:#aaa;",
      "© 2026 Acteevaz · Ref: UU No.17/2002 PPh Ps.11"
    )
  ),
  
  #Body
  dashboardBody(
    useShinyjs(),
    #Print-to-PDF JavaScript
    tags$script(HTML("
      function printSection(section) {
        // Tandai body dengan class section yang akan dicetak
        document.body.classList.add('print-' + section);
        // Paksa tab yang tepat aktif secara visual sebelum print
        window.print();
        // Bersihkan class setelah dialog print tertutup
        setTimeout(function() {
          document.body.classList.remove('print-' + section);
        }, 1000);
      }
    ")),
    tags$head(tags$style(HTML("
      /* ── Global ── */
      body { font-family: 'Segoe UI', sans-serif; font-size: 13px; }
      .content-wrapper, .right-side { background-color: #f4f6f9; }

      /* ── Header title overrides (shinydashboard) ── */
      .main-header .logo {
        font-size: 16px !important;
        font-weight: 900 !important;
        letter-spacing: .05em !important;
        background-color: #367fa9 !important;
        width: 220px !important;
      }
      .main-header .navbar { margin-left: 220px !important; }
      .main-sidebar, .left-side { padding-top: 50px; width: 220px !important; }
      .content-wrapper, .main-footer { margin-left: 220px !important; }
      .main-header .logo b { color: #FFFFFF !important; }

      /* ── Box styling ── */
      .box { border-top: 3px solid #3c8dbc; border-radius: 6px; }
      .box.box-success { border-top-color: #00a65a; }
      .box.box-warning { border-top-color: #f39c12; }
      .box.box-danger  { border-top-color: #dd4b39; }

      /* ── Toolbar buttons ── */
      .btn-toolbar-custom { margin-bottom: 12px; }
      .btn-toolbar-custom .btn { margin-right: 4px; font-size: 12px; }

      /* ── Print Button ── */
      .print-btn {
        background: #6c757d; color: #fff; border: none;
        border-radius: 4px; padding: 5px 12px; font-size: 12px;
        font-weight: 600; cursor: pointer; display: inline-flex;
        align-items: center; gap: 6px;
      }
      .print-btn:hover { background: #5a6268; color:#fff; }

      /* Elemen print-only: tersembunyi di layar, tampil saat print */
      .print-only { display: none; }

      /* ════════════════════════════════════════════════════════
         PRINT MEDIA QUERY — Print to PDF
         ════════════════════════════════════════════════════════ */
      @media print {
        /* Sembunyikan semua chrome Shiny/shinydashboard */
        .main-header, .main-sidebar, .control-sidebar,
        .control-sidebar-bg, .sidebar-toggle,
        .print-btn, .slicer-bar, .kpi-icon,
        .chart-card-footer, .db-tab-panel .nav-tabs,
        .db-header-badge { display: none !important; }

        /* Reset layout */
        .content-wrapper, .main-footer { margin-left: 0 !important; padding: 0 !important; }
        .db-canvas { padding: 6px !important; background: #fff !important; }

        /* DB Header */
        .db-header {
          background: #1a2533 !important;
          -webkit-print-color-adjust: exact; print-color-adjust: exact;
          border-radius: 6px !important; margin-bottom: 12px !important;
          padding: 10px 16px !important;
        }
        .db-header-title  { font-size: 14px !important; }
        .db-header-sub    { font-size: 10px !important; }

        /* KPI cards */
        .kpi-row  { gap: 8px !important; margin-bottom: 12px !important; }
        .kpi-card { min-width: 80px !important; padding: 8px 10px !important;
                    -webkit-print-color-adjust: exact; print-color-adjust: exact; }
        .kpi-card.green, .kpi-card.orange,
        .kpi-card.purple, .kpi-card.red {
          -webkit-print-color-adjust: exact; print-color-adjust: exact; }
        .kpi-value { font-size: 14px !important; }
        .kpi-label { font-size: 9px !important; }
        .kpi-unit  { font-size: 9px !important; }

        /* Hanya tab aktif yang tampil */
        .tab-content > .tab-pane:not(.active) { display: none !important; }
        .tab-content > .active { display: block !important; }

        /* Chart cards */
        .chart-card { box-shadow: none !important; border: 1px solid #ddd !important;
                      page-break-inside: avoid; margin-bottom: 10px !important; }
        .chart-card-header {
          -webkit-print-color-adjust: exact; print-color-adjust: exact;
          padding: 8px 12px !important;
        }
        .chart-card-title { color: #fff !important; }

        /* Ring cards */
        .ring-card { box-shadow: none !important; border: 1px solid #ddd !important;
                     page-break-inside: avoid; margin-bottom: 10px !important; }
        .ring-card-header {
          -webkit-print-color-adjust: exact; print-color-adjust: exact;
          padding: 8px 12px !important;
        }
        .ring-card-header h4 { font-size: 12px !important; }

        /* Print-only elements muncul saat print */
        .print-only { display: block !important; }

        /* Plotly: paksa full width */
        .js-plotly-plot, .plotly { width: 100% !important; }

        /* Page size */
        @page { margin: 12mm; }
        @page :first { margin-top: 6mm; }
      }

      /* ── Export Dropdown ── */
      .export-dd .dropdown-toggle {
        background: #17a2b8; color: #fff; border: none;
        font-size: 12px; font-weight: 600; border-radius: 4px;
        padding: 4px 10px; cursor: pointer;
      }
      .export-dd .dropdown-toggle:hover { background: #138496; }
      .export-dd .dropdown-menu {
        min-width: 180px; border-radius: 6px;
        box-shadow: 0 4px 16px rgba(0,0,0,.15);
        border: 1px solid #e0e0e0; padding: 4px 0;
      }
      .export-dd .dropdown-menu li a {
        padding: 8px 16px; font-size: 12px; color: #333;
        display: flex; align-items: center; gap: 8px;
        text-decoration: none !important;
      }
      .export-dd .dropdown-menu li a:hover {
        background: #f0f9ff; color: #17a2b8;
      }
      .export-dd .dropdown-divider { margin: 4px 0; border-top: 1px solid #eee; }
      /* downloadLink inside dropdown: remove default Shiny styling */
      .export-dd .dropdown-menu a.shiny-download-link {
        color: #333 !important; background: transparent !important;
        padding: 8px 16px; display: flex; align-items: center; gap: 8px;
      }
      .export-dd .dropdown-menu a.shiny-download-link:hover {
        background: #f0f9ff !important; color: #17a2b8 !important;
      }

      /* ── Filter panel ── */
      .filter-panel { background:#fff; border:1px solid #ddd; border-radius:6px;
                      padding:14px; margin-bottom:12px; }
      .filter-panel h5 { margin-top:0; color:#3c8dbc; font-weight:bold; }

      /* ── DataTable ── */
      .dataTables_wrapper .dataTables_filter input { border:1px solid #ccc;
        border-radius:4px; padding:4px 8px; }
      table.dataTable thead th { background-color: #3c8dbc; color: #fff;
        border-bottom: none !important; }
      table.dataTable tbody tr:hover { background-color: #eaf4fb !important; }

      /* ── Form sections ── */
      .form-section-title { font-weight:bold; color:#3c8dbc; font-size:13px;
        border-bottom:2px solid #3c8dbc; padding-bottom:4px; margin-bottom:12px; }
      .form-note { font-size:11px; color:#888; margin-top:2px; }

      /* ── Status badges ── */
      .badge-proceeded { background:#00a65a; color:#fff; padding:2px 8px; border-radius:10px; }
      .badge-disposed  { background:#dd4b39; color:#fff; padding:2px 8px; border-radius:10px; }

      /* ── Numeric right-align ── */
      .dt-right { text-align: right !important; }

      /* ════════════════════════════════════════════════════════
         DASHBOARD — Power BI Style
         ════════════════════════════════════════════════════════ */

      /* Canvas background */
      .db-canvas { background: #f0f2f5; padding: 18px; }

      /* Header bar */
      .db-header {
        background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
        border-radius: 10px; padding: 18px 24px; margin-bottom: 20px;
        display: flex; align-items: center; justify-content: space-between;
        box-shadow: 0 4px 20px rgba(0,0,0,.25);
      }
      .db-header-title { color: #fff; font-size: 18px; font-weight: 700;
        letter-spacing: .03em; margin: 0; }
      .db-header-sub   { color: #a8c5e0; font-size: 12px; margin: 3px 0 0; }
      .db-header-badge { background: rgba(255,255,255,.12); border: 1px solid rgba(255,255,255,.2);
        border-radius: 20px; padding: 4px 14px; color: #fff; font-size: 11px; }

      /* KPI cards */
      .kpi-row { display: flex; gap: 14px; margin-bottom: 20px; flex-wrap: wrap; }
      .kpi-card {
        flex: 1; min-width: 160px; background: #fff; border-radius: 10px;
        padding: 16px 20px; box-shadow: 0 2px 10px rgba(0,0,0,.07);
        border-left: 4px solid #3c8dbc; position: relative; overflow: hidden;
        transition: box-shadow .2s;
      }
      .kpi-card:hover { box-shadow: 0 6px 24px rgba(0,0,0,.13); }
      .kpi-card::after {
        content: ''; position: absolute; right: -18px; top: -18px;
        width: 70px; height: 70px; border-radius: 50%;
        background: rgba(60,141,188,.08);
      }
      .kpi-card.green  { border-left-color: #00a65a; }
      .kpi-card.green::after  { background: rgba(0,166,90,.08); }
      .kpi-card.orange { border-left-color: #f39c12; }
      .kpi-card.orange::after { background: rgba(243,156,18,.08); }
      .kpi-card.red    { border-left-color: #e74c3c; }
      .kpi-card.red::after    { background: rgba(231,76,60,.08); }
      .kpi-card.purple { border-left-color: #8e44ad; }
      .kpi-card.purple::after { background: rgba(142,68,173,.08); }

      .kpi-label { font-size: 11px; color: #888; font-weight: 600;
        text-transform: uppercase; letter-spacing: .06em; margin-bottom: 6px; }
      .kpi-value { font-size: 22px; font-weight: 700; color: #1a2533;
        line-height: 1.1; }
      .kpi-unit  { font-size: 11px; color: #aaa; margin-top: 4px; }
      .kpi-icon  { position: absolute; right: 16px; bottom: 14px;
        font-size: 26px; opacity: .13; }

      /* Chart cards */
      .chart-card {
        background: #fff; border-radius: 10px; padding: 0;
        box-shadow: 0 2px 10px rgba(0,0,0,.07); overflow: hidden;
        margin-bottom: 18px;
      }
      .chart-card-header {
        padding: 13px 18px 11px; border-bottom: 1px solid #f0f0f0;
        display: flex; align-items: center; justify-content: space-between;
      }
      .chart-card-title {
        font-size: 13px; font-weight: 700; color: #1a2533; margin: 0;
        display: flex; align-items: center; gap: 7px;
      }
      .chart-card-title .dot {
        width: 8px; height: 8px; border-radius: 50%;
        display: inline-block; flex-shrink: 0;
      }
      .chart-card-body { padding: 6px 4px 4px; }
      .chart-card-footer {
        padding: 8px 18px; background: #fafbfc; border-top: 1px solid #f0f0f0;
        font-size: 11px; color: #aaa;
      }

      /* Slicer bar */
      .slicer-bar {
        background: #fff; border-radius: 10px; padding: 10px 18px;
        box-shadow: 0 2px 8px rgba(0,0,0,.06); margin-bottom: 18px;
        display: flex; align-items: center; gap: 16px; flex-wrap: wrap;
      }
      .slicer-bar label { font-size: 11px; font-weight: 700; color: #555;
        text-transform: uppercase; letter-spacing: .05em; margin: 0; }
      .slicer-bar .form-group { margin: 0; }
      .slicer-bar .selectize-input { font-size: 12px; min-height: 30px;
        border-radius: 6px; border-color: #ddd; }

      .ring-card {
        background: #fff; border-radius: 10px; overflow: hidden;
        box-shadow: 0 2px 10px rgba(0,0,0,.08); margin-bottom: 18px;
      }
      .ring-card-header {
        display: flex; align-items: center; gap: 10px;
        padding: 13px 18px; color: #fff;
      }
      .ring-card-header h4 {
        margin: 0; font-size: 14px; font-weight: 700;
        letter-spacing: .02em; color: #fff;
      }
      .ring-tipe-header   { background: linear-gradient(135deg,#1e3a5f,#2563EB); }
      .ring-metode-header { background: linear-gradient(135deg,#92400e,#f59e0b); }
      .ring-dept-header   { background: linear-gradient(135deg,#0e7490,#06b6d4); }
      .ring-card-body { padding: 0; }

      /* Ringkasan DT overrides */
      .ring-card table.dataTable thead th {
        background-color: #f8fafc !important;
        color: #374151 !important;
        font-weight: 700 !important;
        font-size: 12px !important;
        border-bottom: 2px solid #e5e7eb !important;
        padding: 10px 14px !important;
      }
      .ring-card table.dataTable tbody td {
        padding: 9px 14px !important;
        font-size: 13px !important;
        border-bottom: 1px solid #f3f4f6 !important;
        vertical-align: middle !important;
      }
      .ring-card table.dataTable tbody tr:hover td {
        background-color: #f0f9ff !important;
      }
      .ring-card .dataTables_wrapper { padding: 0 !important; }
      .ring-card .dataTables_info,
      .ring-card .dataTables_paginate { padding: 8px 14px !important; font-size: 11px; }
      .td-nilai  { font-weight: 700; color: #1e3a5f; font-variant-numeric: tabular-nums; }
      .td-jumlah { font-weight: 600; color: #374151; text-align: right; }
      /* Tab panel styling */
      .db-tab-panel .nav-tabs { border-bottom: 2px solid #e5e7eb; margin-bottom: 0; }
      .db-tab-panel .nav-tabs > li > a {
        font-size: 13px; font-weight: 600; color: #6b7280;
        border: none; border-bottom: 3px solid transparent;
        padding: 10px 20px; border-radius: 0; margin-right: 4px;
      }
      .db-tab-panel .nav-tabs > li.active > a,
      .db-tab-panel .nav-tabs > li.active > a:hover {
        color: #2563EB; border-bottom: 3px solid #2563EB;
        background: transparent; border-top: none;
        border-left: none; border-right: none;
      }
      .db-tab-panel .nav-tabs > li > a:hover { color: #2563EB; background: #f0f9ff; }
      .db-tab-panel .tab-content { padding-top: 16px; }
    ")))
    ,
    
    tabItems(
      tabItem(tabName = "dashboard",
              div(class = "db-canvas",
                  
                  #Header Bar
                  div(class = "db-header",
                      div(
                        tags$p(class = "db-header-title",
                               tags$span("📊", style="margin-right:8px;"),
                               "Acteevaz Analytics Dashboard"),
                        tags$p(class = "db-header-sub",
                               "Real-time dari data aktif")
                      ),
                      div(
                        span(class = "db-header-badge", "🟢 Live Data"),
                        span(style = "color:#a8c5e0; font-size:11px; margin-left:12px;",
                             textOutput("db_last_update", inline = TRUE))
                      )
                  ),
                  
                  #Tab Panel: Grafik & Analisis | Ringkasan
                  div(class = "db-tab-panel",
                      tabsetPanel(
                        id = "db_main_tabs", type = "tabs",
                        
                        #Tab 1: Grafik & Analisis
                        tabPanel(
                          title = tags$span("📈 Grafik & Analisis"),
                          value = "grafik",
                          br(),
                          #Print button (Grafik)
                          div(style = "text-align:right; margin-bottom:8px;",
                              tags$button(
                                class = "print-btn",
                                onclick = "printSection('grafik')",
                                tags$span("🖨"), " Print PDF"
                              ),
                              tags$span(
                                style = "font-size:10px; color:#999; margin-left:8px;",
                                "Landscape A4 — cetak/simpan via dialog browser"
                              )
                          ),
                          #Slicer Bar
                          div(class = "slicer-bar",
                              tags$label("Filter:"),
                              div(style = "min-width:160px;",
                                  selectInput("db_slicer_type",   NULL,
                                              choices = c("Semua Tipe" = "All", "Kendaraan", "Bangunan", "Inventaris"),
                                              width = "100%")
                              ),
                              div(style = "min-width:160px;",
                                  selectInput("db_slicer_dept",   NULL,
                                              choices = c("Semua Dept" = "All"),
                                              width = "100%")
                              ),
                              div(style = "min-width:160px;",
                                  selectInput("db_slicer_fiscal", NULL,
                                              choices = c("Semua Fiscal" = "All", "Fiscal = Yes" = "Yes", "Fiscal = No" = "No"),
                                              width = "100%")
                              ),
                              div(style = "min-width:160px;",
                                  selectInput("db_slicer_status", NULL,
                                              choices = c("Semua Status" = "All", "Proceeded", "Disposed"),
                                              width = "100%")
                              ),
                              actionButton("db_reset_slicer", "↺ Reset",
                                           class = "btn btn-default btn-sm",
                                           style = "margin-left:auto; font-size:11px;")
                          ),
                          
                          #KPI Cards Row
                          div(class = "kpi-row",
                              div(class = "kpi-card",
                                  div(class = "kpi-label", "Total Aktiva"),
                                  div(class = "kpi-value", textOutput("kpi_total_aset", inline = TRUE)),
                                  div(class = "kpi-unit", "unit aktiva tetap"),
                                  div(class = "kpi-icon", "🏭")
                              ),
                              div(class = "kpi-card green",
                                  div(class = "kpi-label", "Total Nilai Perolehan"),
                                  div(class = "kpi-value", textOutput("kpi_total_nilai", inline = TRUE)),
                                  div(class = "kpi-unit", "Rupiah"),
                                  div(class = "kpi-icon", "💰")
                              ),
                              div(class = "kpi-card orange",
                                  div(class = "kpi-label", "Rata-rata Nilai Aset"),
                                  div(class = "kpi-value", textOutput("kpi_avg_nilai", inline = TRUE)),
                                  div(class = "kpi-unit", "per unit"),
                                  div(class = "kpi-icon", "📐")
                              ),
                              div(class = "kpi-card purple",
                                  div(class = "kpi-label", "Total Nilai Penyusutan"),
                                  div(class = "kpi-value", textOutput("kpi_total_salv", inline = TRUE)),
                                  div(class = "kpi-unit", "Nilai Sisa (Salvage)"),
                                  div(class = "kpi-icon", "📉")
                              ),
                              div(class = "kpi-card red",
                                  div(class = "kpi-label", "Fiscal Asset"),
                                  div(class = "kpi-value", textOutput("kpi_fiscal_count", inline = TRUE)),
                                  div(class = "kpi-unit", "aktiva tercatat pajak"),
                                  div(class = "kpi-icon", "🧾")
                              )
                          ),
                          
                          # \u2500\u2500 Baris 1: Nilai Perolehan per Kategori (kiri) + Komposisi (kanan) \u2500\u2500
                          fluidRow(
                            # Kotak 1 \u2014 Bar chart horizontal
                            column(width = 7,
                                   div(class = "chart-card", style = "margin-bottom:0;",
                                       div(class = "chart-card-header",
                                           style = "background:linear-gradient(135deg,#1e3a5f,#2563EB); border-radius:8px 8px 0 0;",
                                           tags$p(class = "chart-card-title", style = "color:#fff;",
                                                  span(class = "dot", style = "background:#60CDFF;"),
                                                  "Nilai Perolehan per Kategori"
                                           ),
                                           selectInput("db_bar_sort", NULL,
                                                       choices = c("Nilai \u2193" = "desc", "Nilai \u2191" = "asc", "Nama A-Z" = "name"),
                                                       width = "130px")
                                       ),
                                       div(class = "chart-card-body",
                                           plotlyOutput("chart_nilai_kategori", height = "320px")
                                       ),
                                       div(class = "chart-card-footer",
                                           "Hover pada batang untuk melihat detail nilai. Klik legenda untuk filter.")
                                   )
                            ),
                            # Kotak 2 \u2014 Pie / Donut chart
                            column(width = 5,
                                   div(class = "chart-card", style = "margin-bottom:0;",
                                       div(class = "chart-card-header",
                                           style = "background:linear-gradient(135deg,#0e7490,#06b6d4); border-radius:8px 8px 0 0;",
                                           tags$p(class = "chart-card-title", style = "color:#fff;",
                                                  span(class = "dot", style = "background:#A5F3FC;"),
                                                  "Komposisi Jumlah Aset"
                                           ),
                                           selectInput("db_pie_metric", NULL,
                                                       choices = c("Jumlah Unit" = "count", "Nilai Perolehan" = "value"),
                                                       width = "150px")
                                       ),
                                       div(class = "chart-card-body",
                                           plotlyOutput("chart_komposisi", height = "320px")
                                       ),
                                       div(class = "chart-card-footer",
                                           "Klik segmen untuk isolasi. Double-klik untuk reset tampilan.")
                                   )
                            )
                          ),
                          
                          tags$div(style = "height:16px;"),
                          
                          # \u2500\u2500 Baris 2: Distribusi per Departemen (full width) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
                          fluidRow(
                            column(width = 12,
                                   div(class = "chart-card",
                                       div(class = "chart-card-header",
                                           style = "background:linear-gradient(135deg,#92400e,#f59e0b); border-radius:8px 8px 0 0;",
                                           tags$p(class = "chart-card-title", style = "color:#fff;",
                                                  span(class = "dot", style = "background:#FDE68A;"),
                                                  "Distribusi Nilai Aset per Departemen"
                                           ),
                                           selectInput("db_dept_view", NULL,
                                                       choices = c("Bar Horizontal" = "hbar", "Treemap" = "treemap",
                                                                   "Waterfall" = "waterfall"),
                                                       selected = "hbar",
                                                       width = "170px")
                                       ),
                                       div(class = "chart-card-body",
                                           plotlyOutput("chart_dept_dist", height = "360px")
                                       ),
                                       div(class = "chart-card-footer",
                                           "Panjang bar proporsional terhadap nilai perolehan per departemen. Hover untuk detail.")
                                   )
                            )
                          )
                          
                          
                        ),
                        
                        #Tab 2: Ringkasan
                        tabPanel(
                          title = tags$span("📋 Ringkasan"),
                          value = "ringkasan",
                          br(),
                          #Print button (Ringkasan)
                          div(style = "text-align:right; margin-bottom:8px;",
                              tags$button(
                                class = "print-btn",
                                onclick = "printSection('ringkasan')",
                                tags$span("🖨"), " Print PDF"
                              ),
                              tags$span(
                                style = "font-size:10px; color:#999; margin-left:8px;",
                                "Portrait A4 — cetak/simpan via dialog browser"
                              )
                          ),
                          #Print-only title (hanya tampil saat cetak)
                          div(class = "print-only",
                              style = "margin-bottom:12px; border-bottom:2px solid #2563EB; padding-bottom:6px;",
                              tags$h4(style = "margin:0; color:#1a2533; font-size:14px;",
                                      "📋 Ringkasan Aktiva Tetap — Acteevaz"),
                              tags$p(style = "margin:2px 0 0; font-size:10px; color:#666;",
                                     paste0("Dicetak: ", format(Sys.Date(), "%d %B %Y"),
                                            "  ·  Ref: UU No.17/2002 PPh Pasal 11"))
                          ),
                          
                          # Baris 1: Ringkasan per Tipe Aset (kiri) + per Metode (kanan)
                          fluidRow(
                            column(width = 7,
                                   div(class = "ring-card",
                                       div(class = "ring-card-header ring-tipe-header",
                                           tags$span("🏷️", style = "font-size:18px;"),
                                           tags$h4("Ringkasan per Tipe Aset")
                                       ),
                                       div(class = "ring-card-body",
                                           DTOutput("ring_tipe")
                                       )
                                   )
                            ),
                            column(width = 5,
                                   div(class = "ring-card",
                                       div(class = "ring-card-header ring-metode-header",
                                           tags$span("⚙️", style = "font-size:18px;"),
                                           tags$h4("Ringkasan per Metode Penyusutan")
                                       ),
                                       div(class = "ring-card-body",
                                           DTOutput("ring_metode")
                                       )
                                   )
                            )
                          ),
                          
                          # Baris 2: Ringkasan per Departemen (full width)
                          fluidRow(
                            column(width = 12,
                                   div(class = "ring-card",
                                       div(class = "ring-card-header ring-dept-header",
                                           tags$span("🏢", style = "font-size:18px;"),
                                           tags$h4("Ringkasan per Departemen")
                                       ),
                                       div(class = "ring-card-body",
                                           DTOutput("ring_dept")
                                       )
                                   )
                            )
                          )
                          
                        ) # tabPanel ringkasan
                      ) # tabsetPanel
                  ), # db-tab-panel
                  
              ) # db-canvas
      ), # tabItem dashboard
      
      # TAB A: FISCAL FIXED ASSET TYPE
      tabItem(tabName = "fiscal_type",
              fluidRow(
                box(width = 12,
                    title = tagList(
                      "Daftar Tipe Aktiva Tetap Pajak (Fiscal Fixed Asset Type)",
                      tags$small(
                        style = "margin-left:12px; font-weight:400; font-size:11px; color:#d4edff;",
                        "📋 Berdasarkan UU No. 17 Tahun 2002 — PPh Pasal 11"
                      )
                    ),
                    status = "primary", solidHeader = TRUE,
                    # Info banner
                    div(style = paste0(
                      "background:linear-gradient(135deg,#e8f4fd,#d1ecf1);",
                      "border:1px solid #bee5eb; border-radius:6px; padding:10px 14px;",
                      "margin-bottom:12px; font-size:12px; color:#0c5460;"
                    ),
                    tags$b("ℹ Ketentuan Penggolongan Aktiva Tetap menurut Pajak:"),
                    tags$ul(style="margin:6px 0 0 0; padding-left:18px;",
                            tags$li("Bukan Bangunan: Golongan 1 (s/d 4 Th), Golongan 2 (4–8 Th), Golongan 3 (8–16 Th), Golongan 4 (16–20 Th)"),
                            tags$li("Bangunan Permanen: umur 1–10 Th, Tarif GL 10% (Saldo Menurun tidak berlaku untuk bangunan)"),
                            tags$li("Bangunan Semi Permanen: umur 10–20 Th, Tarif GL 5%")
                    )
                    ),
                    div(class = "btn-toolbar-custom",
                        actionButton("fft_new",    "⊕ New",    class = "btn btn-success btn-sm"),
                        actionButton("fft_edit",   "✎ Edit",   class = "btn btn-warning btn-sm"),
                        actionButton("fft_delete", "✕ Delete", class = "btn btn-danger btn-sm"),
                        actionButton("fft_refresh","↺ Refresh", class = "btn btn-default btn-sm"),
                        actionButton("fft_print",  "⎙ Print",  class = "btn btn-info btn-sm"),
                        # ── Export Dropdown ──
                        tags$div(class = "btn-group export-dd", style = "margin-right:4px;",
                                 tags$button(class = "btn btn-sm dropdown-toggle",
                                             style = "background:#17a2b8;color:#fff;border:none;font-size:12px;",
                                             `data-toggle` = "dropdown", `aria-expanded` = "false",
                                             "⬇ Export ", tags$span(class = "caret")
                                 ),
                                 tags$ul(class = "dropdown-menu dropdown-menu-right",
                                         tags$li(downloadLink("fft_excel",
                                                              tags$span("📊 Export Excel (.xlsx)"))),
                                         tags$li(tags$hr(class = "dropdown-divider")),
                                         tags$li(downloadLink("fft_csv",
                                                              tags$span("📄 Export CSV (.csv)")))
                                 )
                        )
                    ),
                    DTOutput("fft_table")
                )
              ),
              
              # Modal untuk New / Edit
              conditionalPanel("false",
                               div(id = "fft_modal_trigger")
              )
      ),
      
      # TAB B: FIXED ASSET TYPE
      tabItem(tabName = "fa_type",
              fluidRow(
                box(width = 12, title = "Daftar Tipe Aktiva Tetap (Fixed Asset Type)",
                    status = "primary", solidHeader = TRUE,
                    div(class = "btn-toolbar-custom",
                        actionButton("fat_new",    "⊕ New",     class = "btn btn-success btn-sm"),
                        actionButton("fat_edit",   "✎ Edit",    class = "btn btn-warning btn-sm"),
                        actionButton("fat_delete", "✕ Delete",  class = "btn btn-danger btn-sm"),
                        actionButton("fat_refresh","↺ Refresh", class = "btn btn-default btn-sm"),
                        actionButton("fat_print",  "⎙ Print",   class = "btn btn-info btn-sm"),
                        # ── Export Dropdown ──
                        tags$div(class = "btn-group export-dd", style = "margin-right:4px;",
                                 tags$button(class = "btn btn-sm dropdown-toggle",
                                             style = "background:#17a2b8;color:#fff;border:none;font-size:12px;",
                                             `data-toggle` = "dropdown", `aria-expanded` = "false",
                                             "⬇ Export ", tags$span(class = "caret")
                                 ),
                                 tags$ul(class = "dropdown-menu dropdown-menu-right",
                                         tags$li(downloadLink("fat_excel",
                                                              tags$span("📊 Export Excel (.xlsx)"))),
                                         tags$li(tags$hr(class = "dropdown-divider")),
                                         tags$li(downloadLink("fat_csv",
                                                              tags$span("📄 Export CSV (.csv)")))
                                 )
                        )
                    ),
                    DTOutput("fat_table")
                )
              )
      ),
      
      # TAB C: LIST OF FIXED ASSET
      tabItem(tabName = "fa_list",
              fluidRow(
                #Filter Panel
                column(width = 3,
                       div(class = "filter-panel",
                           h5("🔍 Filter"),
                           selectInput("flt_type",   "Asset Type:", choices = c("All", "Kendaraan", "Bangunan", "Inventaris")),
                           selectInput("flt_method", "Dep. Method:",
                                       choices = c("All", "Non Depreciable", "Straight Line",
                                                   "Sum Of Year Digit", "Double Declining")),
                           selectInput("flt_intangible", "Intangible:", choices = c("All", "Yes", "No")),
                           selectInput("flt_fiscal",    "Fiscal:",    choices = c("All", "Yes", "No")),
                           selectInput("flt_status",    "Status:",    choices = c("All", "Proceeded", "Disposed")),
                           hr(),
                           dateRangeInput("flt_usage_date", "Usage Date:", start = NULL, end = NULL),
                           dateRangeInput("flt_acq_date",   "Acquisition Date:", start = NULL, end = NULL),
                           actionButton("flt_apply",   "Terapkan Filter", class = "btn btn-primary btn-sm btn-block"),
                           actionButton("flt_reset",   "Reset",           class = "btn btn-default btn-sm btn-block")
                       )
                ),
                #Tabel + Tombol
                column(width = 9,
                       box(width = NULL, title = "Daftar Aktiva Tetap (Fixed Asset List)",
                           status = "primary", solidHeader = TRUE,
                           div(class = "btn-toolbar-custom",
                               actionButton("fal_new",    "⊕ New",    class = "btn btn-success btn-sm"),
                               actionButton("fal_edit",   "✎ Edit",   class = "btn btn-warning btn-sm"),
                               actionButton("fal_delete", "✕ Delete", class = "btn btn-danger btn-sm"),
                               actionButton("fal_refresh","↺ Refresh", class = "btn btn-default btn-sm"),
                               # ── Export Dropdown ──
                               tags$div(class = "btn-group export-dd", style = "margin-right:4px;",
                                        tags$button(class = "btn btn-sm dropdown-toggle",
                                                    style = "background:#17a2b8;color:#fff;border:none;font-size:12px;",
                                                    `data-toggle` = "dropdown", `aria-expanded` = "false",
                                                    "⬇ Export ", tags$span(class = "caret")
                                        ),
                                        tags$ul(class = "dropdown-menu dropdown-menu-right",
                                                tags$li(downloadLink("fal_excel",
                                                                     tags$span("📊 Export Excel (.xlsx)"))),
                                                tags$li(tags$hr(class = "dropdown-divider")),
                                                tags$li(downloadLink("fal_csv",
                                                                     tags$span("📄 Export CSV (.csv)")))
                                        )
                               )
                           ),
                           div(style = "margin-bottom:8px;",
                               textInput("fal_find_code", NULL, placeholder = "Cari Asset Code...",
                                         width = "200px") |>
                                 tagAppendAttributes(style = "display:inline-block;"),
                               textInput("fal_find_desc", NULL, placeholder = "Cari Description...",
                                         width = "220px") |>
                                 tagAppendAttributes(style = "display:inline-block; margin-left:6px;")
                           ),
                           DTOutput("fal_table")
                       )
                )
              )
      ),
      
      # TAB D: NEW FIXED ASSET FORM
      tabItem(tabName = "new_fa",
              fluidRow(
                box(width = 12, title = "Formulir Aktiva Tetap Baru (New Fixed Asset)",
                    status = "success", solidHeader = TRUE,
                    
                    #Toolbar Form
                    div(class = "btn-toolbar-custom",
                        actionButton("nfa_prev",       "◀ Previous",       class = "btn btn-default btn-sm"),
                        actionButton("nfa_next",       "▶ Next",           class = "btn btn-default btn-sm"),
                        actionButton("nfa_preview",    "👁 Preview",        class = "btn btn-info btn-sm"),
                        actionButton("nfa_print",      "⎙ Print",          class = "btn btn-info btn-sm"),
                        actionButton("nfa_dispose",    "📤 Dispose",        class = "btn btn-warning btn-sm"),
                        actionButton("nfa_revaluation","♻ Revaluation",    class = "btn btn-warning btn-sm")
                    ),
                    hr(),
                    
                    #Header Form
                    div(class = "form-section-title", "📋 Data Identitas Aktiva Tetap"),
                    fluidRow(
                      column(4, textInput("nfa_code", "Asset Code *", placeholder = "Contoh: AT-004")),
                      column(4, selectInput("nfa_type", "Asset Type *",
                                            choices = c("", "Kendaraan", "Bangunan", "Inventaris"))),
                      column(4, textInput("nfa_dept", "Department",
                                          placeholder = "Contoh: Marketing"))
                    ),
                    fluidRow(
                      column(8, textInput("nfa_desc", "Asset Description *",
                                          placeholder = "Nama / keterangan aktiva tetap")),
                      column(4, numericInput("nfa_qty", "Quantity *", value = 1, min = 1))
                    ),
                    fluidRow(
                      column(4, dateInput("nfa_acq_date", "Acquisition Date *",
                                          value = Sys.Date(), language = "id")),
                      column(4, dateInput("nfa_usage_date", "Usage Date *",
                                          value = Sys.Date(), language = "id")),
                      column(4, tags$p(class = "form-note",
                                       "Tanggal perolehan (acquisition) = tanggal pembelian.",
                                       br(), "Tanggal usage = tanggal mulai digunakan."))
                    ),
                    hr(),
                    
                    #Tab Panel General & Expenditure
                    tabsetPanel(id = "nfa_tabs", type = "tabs",
                                
                                #Tab General
                                tabPanel("📄 General",
                                         br(),
                                         div(class = "form-section-title", "⚙ Parameter Penyusutan"),
                                         fluidRow(
                                           column(3, numericInput("nfa_life", "Estimated Life (Tahun) *",
                                                                  value = 4, min = 1, step = 1)),
                                           column(4, selectInput("nfa_dep_method", "Depreciation Method *",
                                                                 choices = c(
                                                                   "Non Depreciable",
                                                                   "Straight Line Method",
                                                                   "Sum Of Year Digit Method",
                                                                   "Double Declining Method"
                                                                 ))),
                                           column(5,
                                                  tags$p(class = "form-note",
                                                         strong("Straight Line"), ": (Nilai - Salvage) / Umur", br(),
                                                         strong("Sum of Year Digit"), ": Sisa Umur / Jumlah Tahun × (Nilai - Salvage)", br(),
                                                         strong("Double Declining"), ": 2/Umur × Nilai Buku"))
                                         ),
                                         div(class = "form-section-title", "🏦 Akun-Akun"),
                                         fluidRow(
                                           column(4, textInput("nfa_asset_acc",  "Asset Account *",
                                                               placeholder = "Misal: 1.1.5.01")),
                                           column(4, textInput("nfa_accum_acc",  "Accumulated Dep. Account",
                                                               placeholder = "Misal: 1.1.5.11")),
                                           column(4, textInput("nfa_dep_exp_acc","Depreciation Expense Account",
                                                               placeholder = "Misal: 6.1.1.01"))
                                         ),
                                         fluidRow(
                                           column(6,
                                                  checkboxInput("nfa_intangible",   "🔲 Intangible Asset", value = FALSE),
                                                  tags$p(class = "form-note", "Centang jika Aktiva Tidak Berwujud (Hak Cipta, Royalti, Goodwill).")
                                           ),
                                           column(6,
                                                  checkboxInput("nfa_fiscal_fa",    "🔲 Fiscal Fixed Asset", value = FALSE),
                                                  tags$p(class = "form-note", "Centang untuk menghitung penyusutan berdasarkan ketentuan pajak.")
                                           )
                                         ),
                                         # Tampil jika Fiscal dicentang
                                         conditionalPanel("input.nfa_fiscal_fa == true",
                                                          div(style = "background:#fff3cd; padding:12px; border-radius:6px; border:1px solid #ffc107;",
                                                              strong("⚠ Fiscal Fixed Asset diaktifkan"),
                                                              br(),
                                                              fluidRow(
                                                                column(4, selectInput("nfa_fiscal_type",  "Fiscal Type",
                                                                                      choices = c(
                                                                                        "Golongan 1 – Bukan Bangunan (1–4 Th, GL: 25%, SM: 50%)",
                                                                                        "Golongan 2 – Bukan Bangunan (4–8 Th, GL: 12.5%, SM: 25%)",
                                                                                        "Golongan 3 – Bukan Bangunan (8–16 Th, GL: 6.25%, SM: 12.5%)",
                                                                                        "Golongan 4 – Bukan Bangunan (16–20 Th, GL: 5%, SM: 10%)",
                                                                                        "Bangunan Permanen (1–10 Th, GL: 10%)",
                                                                                        "Bangunan Semi Permanen (10–20 Th, GL: 5%)"
                                                                                      ))),
                                                                column(4, textInput("nfa_fiscal_acc", "Fiscal Asset Account",
                                                                                    placeholder = "Akun Pajak")),
                                                                column(4, textInput("nfa_fiscal_dep_acc", "Fiscal Dep. Account",
                                                                                    placeholder = "Akun Penyusutan Pajak"))
                                                              )
                                                          )
                                         )
                                ),
                                
                                #Tab Expenditure
                                tabPanel("💰 Expenditure",
                                         br(),
                                         div(class = "form-section-title", "📊 Nilai Perolehan Aktiva Tetap"),
                                         fluidRow(
                                           column(4, textInput("nfa_exp_acc",  "Account No *",
                                                               placeholder = "Pilih/Ketik Nomor Akun")),
                                           column(4, textInput("nfa_exp_desc", "Description",
                                                               placeholder = "Otomatis dari nama akun")),
                                           column(4, numericInput("nfa_exp_amount", "Amount (Rp) *",
                                                                  value = 0, min = 0, step = 1000000))
                                         ),
                                         actionButton("nfa_add_exp", "⊕ Tambah Baris", class = "btn btn-success btn-sm"),
                                         br(), br(),
                                         DTOutput("nfa_exp_table"),
                                         hr(),
                                         fluidRow(
                                           column(3, tags$div(class = "info-box bg-green",
                                                              tags$span(class = "info-box-icon", icon("dollar-sign")),
                                                              tags$div(class = "info-box-content",
                                                                       tags$span(class = "info-box-text", "Assets Cost"),
                                                                       tags$span(class = "info-box-number", textOutput("nfa_total_cost"))
                                                              )
                                           )),
                                           column(3, numericInput("nfa_salvage", "Salvage Value (Rp)",
                                                                  value = 0, min = 0, step = 1000000)),
                                           column(6, tags$p(class = "form-note",
                                                            "Salvage Value hanya berlaku untuk metode",
                                                            strong("Straight Line"), "dan", strong("Sum of Year Digit."),
                                                            br(), "Formula penyusutan: (Asset Cost – Salvage Value) × Rate"))
                                         )
                                ),
                                
                                #Tab Notes
                                tabPanel("📝 Notes",
                                         br(),
                                         div(class = "form-section-title", "Catatan Tambahan"),
                                         textAreaInput("nfa_notes", NULL,
                                                       rows = 5, width = "100%",
                                                       placeholder = "Isi catatan atau keterangan tambahan mengenai aktiva tetap ini...")
                                ),
                                
                                #Tab Kalkulator Penyusutan
                                tabPanel("🧮 Kalkulasi Depresiasi",
                                         br(),
                                         div(class = "form-section-title", "Simulasi Penyusutan"),
                                         actionButton("nfa_calc", "Hitung Penyusutan", class = "btn btn-primary"),
                                         br(), br(),
                                         DTOutput("nfa_dep_schedule"),
                                         tags$p(class = "form-note",
                                                "* Tabel di atas adalah simulasi. Jurnal otomatis dibuat saat Period End di ACCURATE.")
                                )
                    ),
                    hr(),
                    
                    #Tombol Simpan
                    div(style = "text-align:right; margin-top:10px;",
                        actionButton("nfa_save_new",   "💾 Save & New",   class = "btn btn-primary"),
                        tags$span("  "),
                        actionButton("nfa_save_close", "✔ Save & Close",  class = "btn btn-success")
                    )
                )
              )
      ) # tabItem new_fa
    ) # tabItems
  ) # dashboardBody
) # dashboardPage

#Helper: hitung accumulated depreciation sederhana per aset
# Output ini dipakai untuk menambahkan kolom Accumulated Depreciation di List of Fixed Asset.
calc_accum_dep <- function(df, as_of = Sys.Date()) {
  if (nrow(df) == 0) return(numeric(0))
  mapply(function(cost, salvage, life, method, usage_date) {
    cost <- as.numeric(cost)
    salvage <- as.numeric(salvage)
    life <- as.numeric(life)
    
    if (is.na(cost) || is.na(salvage) || is.na(life) || life <= 0) return(0)
    if (is.na(usage_date)) return(0)
    if (method == "Non Depreciable") return(0)
    
    elapsed_years <- floor(as.numeric(as_of - as.Date(usage_date)) / 365)
    elapsed_years <- max(0, min(elapsed_years, life))
    
    depreciable_base <- max(cost - salvage, 0)
    if (elapsed_years <= 0 || depreciable_base <= 0) return(0)
    
    if (method == "Straight Line") {
      accum <- depreciable_base / life * elapsed_years
      
    } else if (method == "Double Declining") {
      book_value <- cost
      accum <- 0
      for (year in seq_len(elapsed_years)) {
        dep <- book_value * (2 / life)
        dep <- min(dep, max(book_value - salvage, 0))
        accum <- accum + dep
        book_value <- book_value - dep
      }
      
    } else if (method == "Sum Of Year Digit") {
      syd_denominator <- life * (life + 1) / 2
      accum <- 0
      for (year in seq_len(elapsed_years)) {
        dep <- ((life - year + 1) / syd_denominator) * depreciable_base
        accum <- accum + dep
      }
      
    } else {
      accum <- depreciable_base / life * elapsed_years
    }
    
    round(min(accum, depreciable_base), 0)
  },
  df$asset_cost,
  df$salvage_value,
  df$estimated_life,
  df$dep_method,
  df$usage_date)
}

#Helper: hitung book value per aset
# Book Value = Asset Cost - Accumulated Depreciation
calc_book_value <- function(df, as_of = Sys.Date()) {
  if (nrow(df) == 0) return(numeric(0))
  round(df$asset_cost - calc_accum_dep(df, as_of), 0)
}

#3. SERVER

server <- function(input, output, session) {
  
  #Reaktif Data Store
  rv <- reactiveValues(
    fiscal_types  = fiscal_type_data_init,
    fa_types      = fa_type_data_init,
    fa_list       = fa_list_data_init,
    fa_list_disp  = fa_list_data_init,   # tampilan (setelah filter)
    exp_rows      = data.frame(
      account = character(), date = character(),
      description = character(), amount = numeric(),
      stringsAsFactors = FALSE
    ),
    editing_fft   = NULL,
    editing_fat   = NULL,
    editing_fal   = NULL,
    current_nfa   = 1L    # indeks record FA yang sedang dilihat di form D
  )

  # MODUL A: FISCAL FIXED ASSET TYPE
  # Render Tabel — Fiscal Fixed Asset Type (6 Golongan, UU No.17/2002 PPh Ps.11)
  output$fft_table <- renderDT({
    df <- rv$fiscal_types
    
    # Kolom Tarif Saldo Menurun: tampilkan "—" untuk Bangunan (NA), angka untuk lainnya
    sm_display <- vapply(df$tarif_saldo_menurun, function(x) {
      if (is.na(x)) "—" else paste0(x, " %")
    }, character(1))
    
    # Nama kolom TANPA karakter khusus (%, ()) agar formatStyle tidak gagal di JS/CSS
    display_df <- data.frame(
      Kode              = df$fiscal_type_code,
      Nama_Golongan     = df$fiscal_type_name,
      Kategori          = df$kategori,
      Umur_Ekonomis     = df$umur_ekonomis,
      Tarif_GL_pct      = paste0(df$tarif_garis_lurus, " %"),
      Tarif_SM_pct      = sm_display,
      stringsAsFactors  = FALSE
    )
    
    datatable(
      display_df,
      selection  = "single",
      rownames   = FALSE,
      # Ganti nama header jadi ramah (dengan % dan simbol) via colnames
      colnames   = c(
        "Kode", "Nama Golongan", "Kategori", "Umur Ekonomis",
        "Tarif Garis Lurus", "Tarif Saldo Menurun"
      ),
      options = list(
        pageLength = 10,
        searching  = TRUE,
        dom        = "Bfrtip",
        language   = list(
          search      = "Cari:",
          lengthMenu  = "Tampilkan _MENU_ data",
          info        = "Menampilkan _START_ s/d _END_ dari _TOTAL_ data"
        ),
        columnDefs = list(
          # Center: Kategori(2), Umur(3), Tarif GL(4), Tarif SM(5) — 0-based
          list(className = "dt-center", targets = c(2, 3, 4, 5)),
          list(width = "90px",  targets = 0),
          list(width = "110px", targets = c(4, 5))
        )
      )
    ) %>%
      # formatStyle pakai nama internal (tanpa %) agar tidak ada CSS-selector error
      formatStyle(
        "Kategori",
        backgroundColor = styleEqual(
          c("Bukan Bangunan", "Bangunan"),
          c("#e8f5e9",        "#e3f2fd")
        ),
        color = styleEqual(
          c("Bukan Bangunan", "Bangunan"),
          c("#2e7d32",        "#1565c0")
        ),
        fontWeight = "bold"
      ) %>%
      formatStyle(
        "Tarif_GL_pct",
        fontWeight = "bold",
        color      = "#1a5276",
        backgroundColor = "#EBF5FB"
      ) %>%
      formatStyle(
        "Tarif_SM_pct",
        fontWeight = "bold",
        color      = styleEqual(
          c("—"),
          c("#aaa"),
          default = "#7d3c98"
        ),
        backgroundColor = styleEqual(
          c("—"),
          c("#f9f9f9"),
          default = "#F5EEF8"
        )
      )
  })
  
  # Tombol New → Modal
  observeEvent(input$fft_new, {
    rv$editing_fft <- NULL
    showModal(modalDialog(
      title = "New Fiscal Fixed Asset Type",
      size = "m", easyClose = FALSE,
      tags$p(style = "font-size:11px; color:#888; margin-bottom:10px;",
             "Ref: UU No. 17 Tahun 2002 — Pajak Penghasilan Pasal 11"),
      fluidRow(
        column(5, textInput("fft_m_code", "Kode *", placeholder = "Misal: FT-G5")),
        column(7, selectInput("fft_m_cat", "Kategori *",
                              choices = c("Bukan Bangunan", "Bangunan")))
      ),
      textInput("fft_m_name", "Nama Golongan *",
                placeholder = "Misal: Golongan 5 (Bukan Bangunan)"),
      textInput("fft_m_umur", "Umur Ekonomis *",
                placeholder = "Misal: 20 – 30 Tahun"),
      fluidRow(
        column(6,
               numericInput("fft_m_gl", "Tarif Garis Lurus (%)*",
                            value = 5, min = 0, max = 100, step = 0.25),
               tags$p(class = "form-note", "Berlaku untuk semua kategori aktiva.")
        ),
        column(6,
               numericInput("fft_m_sm", "Tarif Saldo Menurun (%)",
                            value = NA, min = 0, max = 100, step = 0.25),
               tags$p(class = "form-note",
                      "Isi 0 atau kosongkan jika tidak berlaku (misal: Bangunan).")
        )
      ),
      footer = tagList(
        modalButton("Batal"),
        actionButton("fft_m_save", "Simpan", class = "btn btn-primary")
      )
    ))
  })
  
  # Tombol Edit → Modal (isi data terpilih)
  observeEvent(input$fft_edit, {
    sel <- input$fft_table_rows_selected
    if (is.null(sel)) {
      showNotification("Pilih satu baris terlebih dahulu.", type = "warning"); return()
    }
    rv$editing_fft <- sel
    row <- rv$fiscal_types[sel, ]
    showModal(modalDialog(
      title = "Edit Fiscal Fixed Asset Type",
      size = "m", easyClose = FALSE,
      tags$p(style = "font-size:11px; color:#888; margin-bottom:10px;",
             "Ref: UU No. 17 Tahun 2002 — Pajak Penghasilan Pasal 11"),
      fluidRow(
        column(5, textInput("fft_m_code", "Kode *", value = row$fiscal_type_code)),
        column(7, selectInput("fft_m_cat", "Kategori *",
                              choices  = c("Bukan Bangunan", "Bangunan"),
                              selected = row$kategori))
      ),
      textInput("fft_m_name", "Nama Golongan *", value = row$fiscal_type_name),
      textInput("fft_m_umur", "Umur Ekonomis *", value = row$umur_ekonomis),
      fluidRow(
        column(6,
               numericInput("fft_m_gl", "Tarif Garis Lurus (%)*",
                            value = row$tarif_garis_lurus, min = 0, max = 100, step = 0.25)
        ),
        column(6,
               numericInput("fft_m_sm", "Tarif Saldo Menurun (%)",
                            value = ifelse(is.na(row$tarif_saldo_menurun), NA_real_,
                                           row$tarif_saldo_menurun),
                            min = 0, max = 100, step = 0.25)
        )
      ),
      footer = tagList(
        modalButton("Batal"),
        actionButton("fft_m_save", "Simpan", class = "btn btn-primary")
      )
    ))
  })
  
  # Simpan Modal (New/Edit)
  observeEvent(input$fft_m_save, {
    req(input$fft_m_code, input$fft_m_name, input$fft_m_umur)
    sm_val <- if (is.null(input$fft_m_sm) || is.na(input$fft_m_sm) ||
                  input$fft_m_sm == 0) NA_real_ else input$fft_m_sm
    # Bangunan tidak menggunakan Saldo Menurun
    if (!is.null(input$fft_m_cat) && input$fft_m_cat == "Bangunan") sm_val <- NA_real_
    new_row <- data.frame(
      fiscal_type_code    = trimws(input$fft_m_code),
      fiscal_type_name    = trimws(input$fft_m_name),
      kategori            = input$fft_m_cat,
      umur_ekonomis       = trimws(input$fft_m_umur),
      tarif_garis_lurus   = input$fft_m_gl,
      tarif_saldo_menurun = sm_val,
      stringsAsFactors    = FALSE
    )
    if (is.null(rv$editing_fft)) {
      if (new_row$fiscal_type_code %in% rv$fiscal_types$fiscal_type_code) {
        showNotification("Kode sudah ada. Gunakan kode lain.", type = "error"); return()
      }
      rv$fiscal_types <- rbind(rv$fiscal_types, new_row)
      showNotification("Data berhasil disimpan.", type = "message")
    } else {
      rv$fiscal_types[rv$editing_fft, ] <- new_row
      showNotification("Data berhasil diperbarui.", type = "message")
    }
    removeModal()
  })
  
  # Tombol Delete
  observeEvent(input$fft_delete, {
    sel <- input$fft_table_rows_selected
    if (is.null(sel)) {
      showNotification("Pilih satu baris terlebih dahulu.", type = "warning"); return()
    }
    showModal(modalDialog(
      title = "Konfirmasi Hapus",
      paste0("Yakin ingin menghapus tipe: ",
             rv$fiscal_types$fiscal_type_name[sel], "?"),
      footer = tagList(
        modalButton("Batal"),
        actionButton("fft_delete_confirm", "Hapus", class = "btn btn-danger")
      )
    ))
  })
  observeEvent(input$fft_delete_confirm, {
    sel <- input$fft_table_rows_selected
    rv$fiscal_types <- rv$fiscal_types[-sel, ]
    removeModal()
    showNotification("Data berhasil dihapus.", type = "message")
  })
  
  # Refresh & Print
  observeEvent(input$fft_refresh, showNotification("Data diperbarui.", type = "message"))
  observeEvent(input$fft_print,   showNotification("Fitur cetak: gunakan Ctrl+P di browser.", type = "message"))
  
  # MODUL B: FIXED ASSET TYPE
  
  output$fat_table <- renderDT({
    df <- rv$fa_types
    names(df) <- c("Kode", "Nama Tipe", "Asset Account", "Accum. Dep. Account", "Dep. Expense Account")
    datatable(df, selection = "single", rownames = FALSE,
              options = list(pageLength = 10,
                             language = list(search = "Cari:", info = "Data _START_-_END_ dari _TOTAL_")))
  })
  
  observeEvent(input$fat_new, {
    rv$editing_fat <- NULL
    showModal(modalDialog(
      title = "New Fixed Asset Type", size = "m", easyClose = FALSE,
      textInput("fat_m_code", "Kode Tipe *", placeholder = "Misal: AT-PN"),
      textInput("fat_m_name", "Nama Tipe *", placeholder = "Misal: Peralatan"),
      hr(),
      div(class = "form-section-title", "Akun-Akun (Chart of Account)"),
      textInput("fat_m_asset_acc",  "Asset Account *",                placeholder = "Misal: 1.1.5.04"),
      textInput("fat_m_accum_acc",  "Accumulated Dep. Account",        placeholder = "Misal: 1.1.5.14"),
      textInput("fat_m_dep_exp_acc","Depreciation Expense Account",    placeholder = "Misal: 6.1.1.04"),
      footer = tagList(
        modalButton("Batal"),
        actionButton("fat_m_save", "Simpan", class = "btn btn-primary")
      )
    ))
  })
  
  observeEvent(input$fat_edit, {
    sel <- input$fat_table_rows_selected
    if (is.null(sel)) {
      showNotification("Pilih satu baris.", type = "warning"); return()
    }
    rv$editing_fat <- sel
    row <- rv$fa_types[sel, ]
    showModal(modalDialog(
      title = "Edit Fixed Asset Type", size = "m", easyClose = FALSE,
      textInput("fat_m_code", "Kode Tipe *", value = row$type_code),
      textInput("fat_m_name", "Nama Tipe *", value = row$type_name),
      hr(),
      div(class = "form-section-title", "Akun-Akun"),
      textInput("fat_m_asset_acc",  "Asset Account *",               value = row$asset_account),
      textInput("fat_m_accum_acc",  "Accumulated Dep. Account",       value = row$accum_dep_acc),
      textInput("fat_m_dep_exp_acc","Depreciation Expense Account",   value = row$dep_exp_acc),
      footer = tagList(
        modalButton("Batal"),
        actionButton("fat_m_save", "Simpan", class = "btn btn-primary")
      )
    ))
  })
  
  observeEvent(input$fat_m_save, {
    req(input$fat_m_code, input$fat_m_name, input$fat_m_asset_acc)
    new_row <- data.frame(
      type_code     = trimws(input$fat_m_code),
      type_name     = trimws(input$fat_m_name),
      asset_account = trimws(input$fat_m_asset_acc),
      accum_dep_acc = trimws(input$fat_m_accum_acc),
      dep_exp_acc   = trimws(input$fat_m_dep_exp_acc),
      stringsAsFactors = FALSE
    )
    if (is.null(rv$editing_fat)) {
      if (new_row$type_code %in% rv$fa_types$type_code) {
        showNotification("Kode sudah ada.", type = "error"); return()
      }
      rv$fa_types <- rbind(rv$fa_types, new_row)
    } else {
      rv$fa_types[rv$editing_fat, ] <- new_row
    }
    removeModal()
    showNotification("Data berhasil disimpan.", type = "message")
  })
  
  observeEvent(input$fat_delete, {
    sel <- input$fat_table_rows_selected
    if (is.null(sel)) { showNotification("Pilih satu baris.", type = "warning"); return() }
    showModal(modalDialog(
      title = "Konfirmasi Hapus",
      paste0("Yakin hapus tipe: ", rv$fa_types$type_name[sel], "?"),
      footer = tagList(
        modalButton("Batal"),
        actionButton("fat_delete_confirm", "Hapus", class = "btn btn-danger")
      )
    ))
  })
  observeEvent(input$fat_delete_confirm, {
    sel <- input$fat_table_rows_selected
    rv$fa_types <- rv$fa_types[-sel, ]
    removeModal()
    showNotification("Data berhasil dihapus.", type = "message")
  })
  
  observeEvent(input$fat_refresh, showNotification("Data diperbarui.", type = "message"))
  observeEvent(input$fat_print,   showNotification("Gunakan Ctrl+P untuk cetak.", type = "message"))

  # MODUL C: LIST OF FIXED ASSET
  # Filter
  observeEvent(input$flt_apply, {
    df <- rv$fa_list
    if (input$flt_type != "All")
      df <- df[df$asset_type == input$flt_type, ]
    if (input$flt_method != "All") {
      method_map <- c(
        "Non Depreciable"  = "Non Depreciable",
        "Straight Line"    = "Straight Line",
        "Sum Of Year Digit"= "Sum Of Year Digit",
        "Double Declining" = "Double Declining"
      )
      df <- df[df$dep_method == input$flt_method, ]
    }
    if (input$flt_intangible != "All") df <- df[df$intangible == input$flt_intangible, ]
    if (input$flt_fiscal      != "All") df <- df[df$fiscal      == input$flt_fiscal, ]
    if (input$flt_status      != "All") df <- df[df$status      == input$flt_status, ]
    
    if (!is.null(input$flt_usage_date[1]) && !is.na(input$flt_usage_date[1]))
      df <- df[df$usage_date >= input$flt_usage_date[1], ]
    if (!is.null(input$flt_usage_date[2]) && !is.na(input$flt_usage_date[2]))
      df <- df[df$usage_date <= input$flt_usage_date[2], ]
    if (!is.null(input$flt_acq_date[1]) && !is.na(input$flt_acq_date[1]))
      df <- df[df$acquisition_date >= input$flt_acq_date[1], ]
    if (!is.null(input$flt_acq_date[2]) && !is.na(input$flt_acq_date[2]))
      df <- df[df$acquisition_date <= input$flt_acq_date[2], ]
    
    rv$fa_list_disp <- df
    showNotification(paste(nrow(df), "data ditemukan."), type = "message")
  })
  
  observeEvent(input$flt_reset, {
    rv$fa_list_disp <- rv$fa_list
    updateSelectInput(session, "flt_type",       selected = "All")
    updateSelectInput(session, "flt_method",     selected = "All")
    updateSelectInput(session, "flt_intangible", selected = "All")
    updateSelectInput(session, "flt_fiscal",     selected = "All")
    updateSelectInput(session, "flt_status",     selected = "All")
    updateDateRangeInput(session, "flt_usage_date", start = NA, end = NA)
    updateDateRangeInput(session, "flt_acq_date",   start = NA, end = NA)
  })
  
  # Pencarian cepat (find)
  fa_filtered <- reactive({
    df <- rv$fa_list_disp
    if (nchar(trimws(input$fal_find_code)) > 0)
      df <- df[grepl(input$fal_find_code, df$asset_code, ignore.case = TRUE), ]
    if (nchar(trimws(input$fal_find_desc)) > 0)
      df <- df[grepl(input$fal_find_desc, df$asset_desc, ignore.case = TRUE), ]
    df
  })
  
  # Render Tabel
  output$fal_table <- renderDT({
    df <- fa_filtered()
    display_df <- data.frame(
      "Asset Code"     = df$asset_code,
      "Description"    = df$asset_desc,
      "Asset Type"     = df$asset_type,
      "Asset Account"  = df$asset_account,
      "Asset Cost (Rp)"= format(df$asset_cost, big.mark = ".", scientific = FALSE),
      "Salvage Value (Rp)" = format(df$salvage_value, big.mark = ".", scientific = FALSE),
      "Accum. Depreciation (Rp)" = format(calc_accum_dep(df), big.mark = ".", scientific = FALSE),
      "Book Value (Rp)" = format(calc_book_value(df), big.mark = ".", scientific = FALSE),
      "Usage Date"     = format(df$usage_date, "%d/%m/%Y"),
      "Acq. Date"      = format(df$acquisition_date, "%d/%m/%Y"),
      "Est. Life (Th)" = df$estimated_life,
      "Dep. Rate (%)"  = df$dep_rate,
      "Dep. Method"    = df$dep_method,
      "Department"     = df$department,
      "Intangible"     = df$intangible,
      "Fiscal"         = df$fiscal,
      "Status"         = df$status,
      check.names = FALSE
    )
    datatable(display_df, selection = "single", rownames = FALSE,
              options = list(pageLength = 10, scrollX = TRUE,
                             language = list(search = "Cari:", info = "Data _START_-_END_ dari _TOTAL_")))
  })
  
  # Tombol New FA → pindah ke Tab D
  observeEvent(input$fal_new, {
    updateTabItems(session, "sidebar_menu", "new_fa")
  })
  
  # Tombol Edit FA (buka modal ringkas)
  observeEvent(input$fal_edit, {
    sel <- input$fal_table_rows_selected
    if (is.null(sel)) { showNotification("Pilih satu baris.", type = "warning"); return() }
    df <- fa_filtered()
    row <- df[sel, ]
    showModal(modalDialog(
      title = paste("Edit Fixed Asset:", row$asset_code),
      size = "l", easyClose = FALSE,
      fluidRow(
        column(6, textInput("fal_edit_code", "Asset Code", value = row$asset_code)),
        column(6, textInput("fal_edit_desc", "Description", value = row$asset_desc))
      ),
      fluidRow(
        column(6, selectInput("fal_edit_type", "Asset Type", selected = row$asset_type,
                              choices = c("Kendaraan", "Bangunan", "Inventaris"))),
        column(6, textInput("fal_edit_dept", "Department", value = row$department))
      ),
      fluidRow(
        column(6, numericInput("fal_edit_cost", "Asset Cost (Rp)", value = row$asset_cost, min = 0)),
        column(6, numericInput("fal_edit_salvage", "Salvage Value (Rp)", value = row$salvage_value, min = 0))
      ),
      fluidRow(
        column(6, textInput("fal_edit_acc", "Asset Account", value = row$asset_account)),
        column(6, selectInput("fal_edit_method", "Dep. Method", selected = row$dep_method,
                              choices = c("Non Depreciable", "Straight Line",
                                          "Sum Of Year Digit", "Double Declining")))
      ),
      fluidRow(
        column(4, numericInput("fal_edit_life", "Estimated Life (Th)", value = row$estimated_life, min = 1)),
        column(4, selectInput("fal_edit_fiscal", "Fiscal", selected = row$fiscal,
                              choices = c("Yes", "No"))),
        column(4, selectInput("fal_edit_intangible", "Intangible", selected = row$intangible,
                              choices = c("Yes", "No")))
      ),
      textAreaInput("fal_edit_notes", "Notes", value = row$notes, rows = 2),
      footer = tagList(
        modalButton("Batal"),
        actionButton("fal_edit_save", "Simpan", class = "btn btn-primary")
      )
    ))
  })
  
  observeEvent(input$fal_edit_save, {
    sel <- input$fal_table_rows_selected
    df  <- fa_filtered()
    code_to_edit <- df$asset_code[sel]
    idx <- which(rv$fa_list$asset_code == code_to_edit)
    rv$fa_list$asset_code[idx]   <- input$fal_edit_code
    rv$fa_list$asset_desc[idx]   <- input$fal_edit_desc
    rv$fa_list$asset_type[idx]   <- input$fal_edit_type
    rv$fa_list$department[idx]   <- input$fal_edit_dept
    rv$fa_list$asset_cost[idx]   <- input$fal_edit_cost
    rv$fa_list$salvage_value[idx]<- input$fal_edit_salvage
    rv$fa_list$asset_account[idx]<- input$fal_edit_acc
    rv$fa_list$dep_method[idx]   <- input$fal_edit_method
    rv$fa_list$estimated_life[idx]<- input$fal_edit_life
    rv$fa_list$fiscal[idx]       <- input$fal_edit_fiscal
    rv$fa_list$intangible[idx]   <- input$fal_edit_intangible
    rv$fa_list$notes[idx]        <- input$fal_edit_notes
    rv$fa_list_disp              <- rv$fa_list
    removeModal()
    showNotification("Data berhasil diperbarui.", type = "message")
  })
  
  # Hapus FA
  observeEvent(input$fal_delete, {
    sel <- input$fal_table_rows_selected
    if (is.null(sel)) { showNotification("Pilih satu baris.", type = "warning"); return() }
    df  <- fa_filtered()
    code <- df$asset_code[sel]
    showModal(modalDialog(
      title = "Konfirmasi Hapus",
      paste0("Yakin hapus aktiva tetap: ", code, " - ", df$asset_desc[sel], "?"),
      footer = tagList(
        modalButton("Batal"),
        actionButton("fal_delete_confirm", "Hapus", class = "btn btn-danger")
      )
    ))
  })
  observeEvent(input$fal_delete_confirm, {
    sel  <- input$fal_table_rows_selected
    df   <- fa_filtered()
    code <- df$asset_code[sel]
    rv$fa_list      <- rv$fa_list[rv$fa_list$asset_code != code, ]
    rv$fa_list_disp <- rv$fa_list
    removeModal()
    showNotification("Data berhasil dihapus.", type = "message")
  })
  
  observeEvent(input$fal_refresh, {
    rv$fa_list_disp <- rv$fa_list
    showNotification("Data diperbarui.", type = "message")
  })
  
  # MODUL D: NEW FIXED ASSET FORM
  
  # Sembunyikan Accum Dep saat Intangible
  observe({
    toggle("nfa_accum_acc", condition = !isTRUE(input$nfa_intangible))
  })
  
  # Tambah Baris Expenditure
  observeEvent(input$nfa_add_exp, {
    req(input$nfa_exp_acc, input$nfa_exp_amount)
    new_exp <- data.frame(
      account     = input$nfa_exp_acc,
      date        = as.character(input$nfa_acq_date),
      description = input$nfa_exp_desc,
      amount      = input$nfa_exp_amount,
      stringsAsFactors = FALSE
    )
    rv$exp_rows <- rbind(rv$exp_rows, new_exp)
    updateTextInput(session, "nfa_exp_acc",  value = "")
    updateTextInput(session, "nfa_exp_desc", value = "")
    updateNumericInput(session, "nfa_exp_amount", value = 0)
  })
  
  output$nfa_exp_table <- renderDT({
    df <- rv$exp_rows
    if (nrow(df) == 0) return(data.frame(
      Account = character(), Tanggal = character(),
      Deskripsi = character(), `Amount (Rp)` = numeric(), check.names = FALSE
    ))
    df$amount <- format(df$amount, big.mark = ".", scientific = FALSE)
    names(df) <- c("Account No", "Tanggal", "Deskripsi", "Amount (Rp)")
    datatable(df, rownames = FALSE, selection = "none",
              options = list(dom = "t", pageLength = 10))
  })
  
  output$nfa_total_cost <- renderText({
    total <- sum(rv$exp_rows$amount, na.rm = TRUE)
    format(total, big.mark = ".", scientific = FALSE, nsmall = 0)
  })
  
  # Kalkulasi Penyusutan
  observeEvent(input$nfa_calc, {
    cost    <- sum(rv$exp_rows$amount, na.rm = TRUE)
    salvage <- input$nfa_salvage
    life    <- input$nfa_life
    method  <- input$nfa_dep_method
    
    if (cost <= 0 || life <= 0) {
      showNotification("Isi Amount dan Estimated Life terlebih dahulu.", type = "warning")
      return()
    }
    
    dep_schedule <- lapply(seq_len(life), function(y) {
      book_beg <- if (method == "Double Declining Method") {
        cost * (1 - 2/life)^(y-1)
      } else {
        cost - (y-1) * (cost - salvage) / life
      }
      dep_amount <- switch(method,
                           "Straight Line Method"    = (cost - salvage) / life,
                           "Sum Of Year Digit Method"= (life - y + 1) / (life * (life + 1) / 2) * (cost - salvage),
                           "Double Declining Method" = book_beg * (2/life),
                           0  # Non Depreciable
      )
      book_end <- book_beg - dep_amount
      data.frame(
        Tahun          = y,
        `Nilai Awal (Rp)` = format(round(book_beg), big.mark = ".", scientific = FALSE),
        `Penyusutan (Rp)` = format(round(dep_amount), big.mark = ".", scientific = FALSE),
        `Nilai Buku (Rp)` = format(round(book_end), big.mark = ".", scientific = FALSE),
        check.names = FALSE
      )
    })
    dep_df <- do.call(rbind, dep_schedule)
    
    output$nfa_dep_schedule <- renderDT({
      datatable(dep_df, rownames = FALSE, selection = "none",
                options = list(dom = "t", pageLength = 25))
    })
  })
  
  #Navigasi Prev / Next
  observeEvent(input$nfa_prev, {
    if (rv$current_nfa > 1) {
      rv$current_nfa <- rv$current_nfa - 1
      load_fa_to_form(rv$current_nfa)
    } else {
      showNotification("Sudah di record pertama.", type = "message")
    }
  })
  observeEvent(input$nfa_next, {
    if (rv$current_nfa < nrow(rv$fa_list)) {
      rv$current_nfa <- rv$current_nfa + 1
      load_fa_to_form(rv$current_nfa)
    } else {
      showNotification("Sudah di record terakhir.", type = "message")
    }
  })
  
  # Helper: isi form dari data FA yang ada
  load_fa_to_form <- function(idx) {
    row <- rv$fa_list[idx, ]
    updateTextInput(session,   "nfa_code",      value = row$asset_code)
    updateSelectInput(session, "nfa_type",       selected = row$asset_type)
    updateTextInput(session,   "nfa_desc",       value = row$asset_desc)
    updateNumericInput(session,"nfa_qty",        value = 1)
    updateTextInput(session,   "nfa_dept",       value = row$department)
    updateDateInput(session,   "nfa_acq_date",   value = row$acquisition_date)
    updateDateInput(session,   "nfa_usage_date", value = row$usage_date)
    updateNumericInput(session,"nfa_life",        value = row$estimated_life)
    updateSelectInput(session, "nfa_dep_method",  selected = row$dep_method)
    updateTextInput(session,   "nfa_asset_acc",  value = row$asset_account)
    updateNumericInput(session,"nfa_salvage",    value = row$salvage_value)
    rv$exp_rows <- data.frame(
      account = row$asset_account, date = as.character(row$acquisition_date),
      description = row$asset_desc, amount = row$asset_cost,
      stringsAsFactors = FALSE
    )
  }
  
  # Dispose & Revaluation (placeholder)
  observeEvent(input$nfa_dispose, {
    showModal(modalDialog(
      title = "Disposal Fixed Asset", size = "m",
      p("Form Disposal Fixed Asset akan memindahkan aktiva ke status 'Disposed'",
        "dan membuat jurnal pelepasan aktiva secara otomatis."),
      textInput("disp_account", "Disposal Account", placeholder = "Akun Penerimaan/Kerugian"),
      numericInput("disp_amount", "Nilai Disposal (Rp)", value = 0, min = 0),
      dateInput("disp_date", "Tanggal Disposal", value = Sys.Date()),
      textAreaInput("disp_notes", "Catatan", rows = 2),
      footer = tagList(
        modalButton("Batal"),
        actionButton("disp_save", "Dispose", class = "btn btn-warning")
      )
    ))
  })
  observeEvent(input$disp_save, {
    removeModal()
    showNotification("Aktiva berhasil di-dispose.", type = "message")
  })
  
  observeEvent(input$nfa_revaluation, {
    showModal(modalDialog(
      title = "Revaluation Fixed Asset", size = "m",
      p("Form Revaluation digunakan untuk mencatat penilaian kembali aktiva tetap."),
      numericInput("reval_new_value", "Nilai Baru Aktiva (Rp)", value = 0, min = 0),
      dateInput("reval_date", "Tanggal Revaluasi", value = Sys.Date()),
      textInput("reval_account", "Akun Selisih Revaluasi", placeholder = "Misal: 3.1.4.01"),
      textAreaInput("reval_notes", "Catatan", rows = 2),
      footer = tagList(
        modalButton("Batal"),
        actionButton("reval_save", "Simpan Revaluasi", class = "btn btn-primary")
      )
    ))
  })
  observeEvent(input$reval_save, {
    removeModal()
    showNotification("Revaluasi berhasil disimpan.", type = "message")
  })
  
  #Save & New
  observeEvent(input$nfa_save_new, {
    if (!validate_nfa_form(input)) return()
    save_fa_form(input, rv)
    # Reset form
    updateTextInput(session,   "nfa_code",       value = "")
    updateSelectInput(session, "nfa_type",        selected = "")
    updateTextInput(session,   "nfa_desc",        value = "")
    updateTextInput(session,   "nfa_dept",        value = "")
    updateNumericInput(session,"nfa_qty",          value = 1)
    updateDateInput(session,   "nfa_acq_date",    value = Sys.Date())
    updateDateInput(session,   "nfa_usage_date",  value = Sys.Date())
    updateNumericInput(session,"nfa_life",         value = 4)
    updateTextInput(session,   "nfa_asset_acc",   value = "")
    updateTextInput(session,   "nfa_accum_acc",   value = "")
    updateTextInput(session,   "nfa_dep_exp_acc", value = "")
    updateNumericInput(session,"nfa_salvage",      value = 0)
    updateTextAreaInput(session,"nfa_notes",       value = "")
    updateCheckboxInput(session,"nfa_intangible",  value = FALSE)
    updateCheckboxInput(session,"nfa_fiscal_fa",   value = FALSE)
    rv$exp_rows <- data.frame(account=character(), date=character(),
                              description=character(), amount=numeric(),
                              stringsAsFactors = FALSE)
    showNotification("Data tersimpan. Formulir baru siap diisi.", type = "message")
  })
  
  #Save & Close
  observeEvent(input$nfa_save_close, {
    if (!validate_nfa_form(input)) return()
    save_fa_form(input, rv)
    showNotification("Data berhasil disimpan.", type = "message")
    updateTabItems(session, "sidebar_menu", "fa_list")
  })
  
  # HALAMAN DASHBOARD — Power BI Style
  PBI_PALETTE <- c(
    "Kendaraan"  = "#2563EB",
    "Bangunan"   = "#7C3AED",
    "Inventaris" = "#059669",
    "IT"         = "#D97706",
    "Marketing"  = "#DC2626",
    "Umum"       = "#0891B2",
    "Finance"    = "#7C3AED",
    "HR"         = "#BE185D",
    "Operations" = "#065F46",
    "Other"      = "#6B7280"
  )
  
  #Reactive: Update Dept slicer choices from live data
  observe({
    depts <- c("Semua Dept" = "All", sort(unique(rv$fa_list$department)))
    updateSelectInput(session, "db_slicer_dept", choices = depts)
  })
  
  #Reactive: data terfilter untuk dashboard
  db_data <- reactive({
    df <- rv$fa_list
    if (!is.null(input$db_slicer_type)   && input$db_slicer_type   != "All")
      df <- df[df$asset_type  == input$db_slicer_type, ]
    if (!is.null(input$db_slicer_dept)   && input$db_slicer_dept   != "All")
      df <- df[df$department  == input$db_slicer_dept, ]
    if (!is.null(input$db_slicer_fiscal) && input$db_slicer_fiscal != "All")
      df <- df[df$fiscal      == input$db_slicer_fiscal, ]
    if (!is.null(input$db_slicer_status) && input$db_slicer_status != "All")
      df <- df[df$status      == input$db_slicer_status, ]
    df
  })
  
  # Reset slicer
  observeEvent(input$db_reset_slicer, {
    updateSelectInput(session, "db_slicer_type",   selected = "All")
    updateSelectInput(session, "db_slicer_dept",   selected = "All")
    updateSelectInput(session, "db_slicer_fiscal", selected = "All")
    updateSelectInput(session, "db_slicer_status", selected = "All")
  })
  
  #Timestamp
  output$db_last_update <- renderText({
    db_data()  # trigger reactivity
    paste("Diperbarui:", format(Sys.time(), "%d/%m/%Y %H:%M"))
  })
  
  #Helpers format rupiah
  fmt_rp <- function(x) {
    if (x >= 1e12) paste0("Rp ", round(x/1e12, 2), " T")
    else if (x >= 1e9) paste0("Rp ", round(x/1e9, 2), " M")
    else if (x >= 1e6) paste0("Rp ", round(x/1e6, 1), " Jt")
    else paste0("Rp ", format(round(x), big.mark = ".", scientific = FALSE))
  }
  
  #KPI Cards
  output$kpi_total_aset   <- renderText({ nrow(db_data()) })
  output$kpi_total_nilai  <- renderText({
    fmt_rp(sum(db_data()$asset_cost, na.rm = TRUE))
  })
  output$kpi_avg_nilai    <- renderText({
    df <- db_data()
    if (nrow(df) == 0) return("—")
    fmt_rp(mean(df$asset_cost, na.rm = TRUE))
  })
  output$kpi_total_salv   <- renderText({
    fmt_rp(sum(db_data()$salvage_value, na.rm = TRUE))
  })
  output$kpi_fiscal_count <- renderText({
    sum(db_data()$fiscal == "Yes", na.rm = TRUE)
  })
  
  #Chart 1: Nilai Perolehan per Kategori (Bar)
  output$chart_nilai_kategori <- renderPlotly({
    df <- db_data()
    if (nrow(df) == 0) return(plot_ly() %>% layout(title = "Tidak ada data"))
    
    agg <- aggregate(asset_cost ~ asset_type, data = df, FUN = sum)
    agg$label_rp <- sapply(agg$asset_cost, fmt_rp)
    
    # Sort
    agg <- switch(req(input$db_bar_sort),
                  "desc" = agg[order(-agg$asset_cost), ],
                  "asc"  = agg[order(agg$asset_cost), ],
                  "name" = agg[order(agg$asset_type), ],
                  agg
    )
    agg$asset_type <- factor(agg$asset_type, levels = agg$asset_type)
    
    bar_colors <- ifelse(agg$asset_type %in% names(PBI_PALETTE),
                         PBI_PALETTE[as.character(agg$asset_type)], "#6B7280")
    
    plot_ly(agg, x = ~asset_type, y = ~asset_cost, type = "bar",
            marker = list(color = bar_colors,
                          line = list(color = "rgba(255,255,255,.4)", width = 1.5)),
            text = ~paste0("<b>", asset_type, "</b><br>",
                           label_rp, "<br>",
                           scales::percent(asset_cost / sum(agg$asset_cost), accuracy = .1)),
            hovertemplate = "%{text}<extra></extra>") %>%
      layout(
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)",
        margin = list(l = 50, r = 20, t = 20, b = 50),
        xaxis = list(title = "", tickfont = list(size = 11), zeroline = FALSE,
                     showgrid = FALSE),
        yaxis = list(title = "Nilai (Rp)", tickfont = list(size = 10),
                     tickformat = "~s", showgrid = TRUE,
                     gridcolor = "rgba(0,0,0,.06)"),
        bargap = 0.35
      ) %>%
      add_annotations(
        x = agg$asset_type, y = agg$asset_cost,
        text = agg$label_rp, showarrow = FALSE,
        yanchor = "bottom", yshift = 5,
        font = list(size = 10, color = "#333", family = "Segoe UI")
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  #Chart 2: Komposisi Aset (Donut / Pie)
  output$chart_komposisi <- renderPlotly({
    df <- db_data()
    if (nrow(df) == 0) return(plot_ly() %>% layout(title = "Tidak ada data"))
    
    metric <- req(input$db_pie_metric)
    if (metric == "count") {
      agg <- as.data.frame(table(df$asset_type))
      names(agg) <- c("asset_type", "val")
      hover_suffix <- " unit"
    } else {
      agg <- aggregate(asset_cost ~ asset_type, data = df, FUN = sum)
      names(agg) <- c("asset_type", "val")
      hover_suffix <- ""
    }
    
    pie_colors <- ifelse(agg$asset_type %in% names(PBI_PALETTE),
                         PBI_PALETTE[as.character(agg$asset_type)], "#6B7280")
    
    custom_text <- if (metric == "count") {
      paste0(agg$asset_type, ": ", agg$val, " unit")
    } else {
      paste0(agg$asset_type, "<br>", sapply(agg$val, fmt_rp))
    }
    
    plot_ly(agg, labels = ~asset_type, values = ~val, type = "pie",
            hole = 0.54,
            marker = list(colors = pie_colors,
                          line = list(color = "#fff", width = 2)),
            textinfo = "label+percent",
            textfont = list(size = 11),
            hovertemplate = paste0("%{label}<br>",
                                   if (metric == "count") "%{value} unit" else "%{text}",
                                   "<br>%{percent}<extra></extra>"),
            text = ~sapply(val, fmt_rp),
            pull = 0.03) %>%
      layout(
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)",
        margin = list(l = 10, r = 10, t = 10, b = 10),
        showlegend = TRUE,
        legend = list(orientation = "v", x = 1, y = 0.5,
                      font = list(size = 11)),
        annotations = list(list(
          text = paste0("<b>", nrow(df), "</b><br>Aset"),
          x = 0.5, y = 0.5, showarrow = FALSE, xref = "paper", yref = "paper",
          font = list(size = 14, color = "#1a2533")
        ))
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  #Chart 3: Distribusi per Departemen (Treemap / HBar / Waterfall)
  output$chart_dept_dist <- renderPlotly({
    df <- db_data()
    if (nrow(df) == 0) return(plot_ly() %>% layout(title = "Tidak ada data"))
    
    agg <- aggregate(asset_cost ~ department, data = df, FUN = sum)
    agg$count <- as.integer(table(df$department)[agg$department])
    agg$label_rp <- sapply(agg$asset_cost, fmt_rp)
    
    dept_colors <- sapply(agg$department, function(d) {
      if (d %in% names(PBI_PALETTE)) PBI_PALETTE[d] else "#6B7280"
    })
    
    view <- req(input$db_dept_view)
    
    if (view == "treemap") {
      plot_ly(
        type = "treemap",
        labels = agg$department,
        parents = rep("", nrow(agg)),
        values = agg$asset_cost,
        text = agg$label_rp,
        hovertemplate = paste0(
          "<b>%{label}</b><br>Nilai: %{text}<br>",
          "Proporsi: %{percentRoot:.1%}<extra></extra>"),
        marker = list(colors = dept_colors,
                      line = list(color = "#fff", width = 2)),
        textinfo = "label+text+percent root",
        textfont = list(size = 12)
      ) %>%
        layout(paper_bgcolor = "rgba(0,0,0,0)",
               margin = list(l = 5, r = 5, t = 5, b = 5)) %>%
        config(displayModeBar = FALSE)
      
    } else if (view == "hbar") {
      agg_s <- agg[order(agg$asset_cost), ]
      agg_s$department <- factor(agg_s$department, levels = agg_s$department)
      hcolors <- sapply(as.character(agg_s$department), function(d) {
        if (d %in% names(PBI_PALETTE)) PBI_PALETTE[d] else "#6B7280"
      })
      
      plot_ly(agg_s, x = ~asset_cost, y = ~department, type = "bar",
              orientation = "h",
              marker = list(color = hcolors),
              text = ~label_rp, textposition = "outside",
              hovertemplate = "<b>%{y}</b><br>%{text}<extra></extra>") %>%
        layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          margin = list(l = 80, r = 60, t = 10, b = 40),
          xaxis = list(title = "Nilai (Rp)", showgrid = TRUE,
                       gridcolor = "rgba(0,0,0,.06)", tickformat = "~s",
                       tickfont = list(size = 10)),
          yaxis = list(title = "", tickfont = list(size = 11)),
          bargap = 0.3
        ) %>%
        config(displayModeBar = FALSE)
      
    } else { # waterfall
      agg_s <- agg[order(-agg$asset_cost), ]
      cumvals <- cumsum(agg_s$asset_cost)
      prevvals <- c(0, cumvals[-length(cumvals)])
      
      plot_ly(
        type = "waterfall", orientation = "v",
        x = agg_s$department,
        y = agg_s$asset_cost,
        measure = rep("relative", nrow(agg_s)),
        text = agg_s$label_rp,
        textposition = "outside",
        connector = list(line = list(color = "#ccc", width = 1)),
        increasing  = list(marker = list(color = "#059669")),
        decreasing  = list(marker = list(color = "#DC2626")),
        hovertemplate = "<b>%{x}</b><br>%{text}<extra></extra>"
      ) %>%
        layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          margin = list(l = 50, r = 20, t = 20, b = 50),
          xaxis = list(title = "", showgrid = FALSE, tickfont = list(size = 11)),
          yaxis = list(title = "Nilai (Rp)", tickformat = "~s",
                       gridcolor = "rgba(0,0,0,.06)", tickfont = list(size = 10)),
          showlegend = FALSE
        ) %>%
        config(displayModeBar = FALSE)
    }
  })
  
  # TAB RINGKASAN — 3 tabel agregat (reaktif terhadap slicer)
  
  #Helper: format Rupiah Indonesia (dot sebagai pemisah ribuan)
  fmt_idr <- function(x) {
    paste0("Rp ", formatC(round(x), format = "f", digits = 0, big.mark = ".",
                          decimal.mark = ","))
  }
  
  #Helper: buat DT ringkasan standar
  make_ring_dt <- function(df, col_label) {
    names(df) <- c(col_label, "Jumlah", "Total Nilai")
    datatable(
      df,
      rownames  = FALSE,
      selection = "none",
      options   = list(
        dom         = "t",        # hanya tabel, tanpa search/pagination
        pageLength  = 50,
        ordering    = TRUE,
        scrollX     = FALSE,
        language    = list(info = ""),
        columnDefs  = list(
          list(className = "dt-left",   targets = 0),
          list(className = "dt-right td-jumlah", targets = 1),
          list(className = "dt-right td-nilai",  targets = 2)
        )
      )
    )
  }
  
  #1. Ringkasan per Tipe Aset
  output$ring_tipe <- renderDT({
    df <- db_data()
    if (nrow(df) == 0) {
      return(make_ring_dt(
        data.frame(Tipe = character(), Jumlah = integer(), Nilai = character()),
        "Tipe Aset"
      ))
    }
    agg <- do.call(rbind, lapply(
      split(df, df$asset_type), function(g) {
        data.frame(
          asset_type  = g$asset_type[1],
          jumlah      = nrow(g),
          total_nilai = fmt_idr(sum(g$asset_cost, na.rm = TRUE)),
          stringsAsFactors = FALSE
        )
      }
    ))
    # Urutkan dari nilai terbesar
    agg <- agg[order(
      as.numeric(gsub("[^0-9]", "", agg$total_nilai)), decreasing = TRUE
    ), ]
    make_ring_dt(agg, "Tipe Aset")
  })
  
  #2. Ringkasan per Metode Penyusutan
  output$ring_metode <- renderDT({
    df <- db_data()
    if (nrow(df) == 0) {
      return(make_ring_dt(
        data.frame(Metode = character(), Jumlah = integer(), Nilai = character()),
        "Metode Penyusutan"
      ))
    }
    agg <- do.call(rbind, lapply(
      split(df, df$dep_method), function(g) {
        data.frame(
          dep_method  = g$dep_method[1],
          jumlah      = nrow(g),
          total_nilai = fmt_idr(sum(g$asset_cost, na.rm = TRUE)),
          stringsAsFactors = FALSE
        )
      }
    ))
    agg <- agg[order(
      as.numeric(gsub("[^0-9]", "", agg$total_nilai)), decreasing = TRUE
    ), ]
    make_ring_dt(agg, "Metode Penyusutan")
  })
  
  #3. Ringkasan per Departemen
  output$ring_dept <- renderDT({
    df <- db_data()
    if (nrow(df) == 0) {
      return(make_ring_dt(
        data.frame(Dept = character(), Jumlah = integer(), Nilai = character()),
        "Departemen"
      ))
    }
    agg <- do.call(rbind, lapply(
      split(df, df$department), function(g) {
        data.frame(
          department  = g$department[1],
          jumlah      = nrow(g),
          total_nilai = fmt_idr(sum(g$asset_cost, na.rm = TRUE)),
          stringsAsFactors = FALSE
        )
      }
    ))
    # Urutkan: terbesar di atas
    agg <- agg[order(
      as.numeric(gsub("[^0-9]", "", agg$total_nilai)), decreasing = TRUE
    ), ]
    make_ring_dt(agg, "Departemen")
  })
 
  # EXPORT — Excel & CSV untuk Tab A, B, C
  
  #Helper: siapkan data display untuk masing-masing tab
  
  export_fft <- reactive({
    df <- rv$fiscal_types
    data.frame(
      "Kode"                    = df$fiscal_type_code,
      "Nama Golongan"           = df$fiscal_type_name,
      "Kategori"                = df$kategori,
      "Umur Ekonomis"           = df$umur_ekonomis,
      "Tarif Garis Lurus (%)"   = df$tarif_garis_lurus,
      "Tarif Saldo Menurun (%)" = ifelse(is.na(df$tarif_saldo_menurun),
                                         "-", as.character(df$tarif_saldo_menurun)),
      check.names = FALSE, stringsAsFactors = FALSE
    )
  })
  
  export_fat <- reactive({
    df <- rv$fa_types
    data.frame(
      "Kode Tipe"                    = df$type_code,
      "Nama Tipe"                    = df$type_name,
      "Asset Account"                = df$asset_account,
      "Accumulated Dep. Account"     = df$accum_dep_acc,
      "Depreciation Expense Account" = df$dep_exp_acc,
      check.names = FALSE, stringsAsFactors = FALSE
    )
  })
  
  export_fal <- reactive({
    df <- fa_filtered()
    data.frame(
      "Asset Code"       = df$asset_code,
      "Description"      = df$asset_desc,
      "Asset Type"       = df$asset_type,
      "Asset Account"    = df$asset_account,
      "Asset Cost (Rp)"  = df$asset_cost,
      "Acquisition Date" = format(df$acquisition_date, "%d/%m/%Y"),
      "Usage Date"       = format(df$usage_date,       "%d/%m/%Y"),
      "Est. Life (Th)"   = df$estimated_life,
      "Dep. Rate (%)"    = df$dep_rate,
      "Dep. Method"      = df$dep_method,
      "Department"       = df$department,
      "Intangible"       = df$intangible,
      "Fiscal"           = df$fiscal,
      "Status"                    = df$status,
      "Salvage Value"             = df$salvage_value,
      "Accumulated Depreciation"  = calc_accum_dep(df),
      "Book Value"                = calc_book_value(df),
      "Notes"                     = df$notes,
      check.names = FALSE, stringsAsFactors = FALSE
    )
  })
  
  #TAB A: Fiscal Fixed Asset Type
  output$fft_excel <- downloadHandler(
    filename = function() paste0("Fiscal_FA_Type_", Sys.Date(), ".xlsx"),
    content  = function(file) writexl::write_xlsx(export_fft(), file)
  )
  output$fft_csv <- downloadHandler(
    filename = function() paste0("Fiscal_FA_Type_", Sys.Date(), ".csv"),
    content  = function(file) {
      write.csv(export_fft(), file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )
  
  #TAB B: Fixed Asset Type
  output$fat_excel <- downloadHandler(
    filename = function() paste0("FA_Type_", Sys.Date(), ".xlsx"),
    content  = function(file) writexl::write_xlsx(export_fat(), file)
  )
  output$fat_csv <- downloadHandler(
    filename = function() paste0("FA_Type_", Sys.Date(), ".csv"),
    content  = function(file) {
      write.csv(export_fat(), file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )
  
  #TAB C: Fixed Asset List
  output$fal_excel <- downloadHandler(
    filename = function() paste0("FA_List_", Sys.Date(), ".xlsx"),
    content  = function(file) writexl::write_xlsx(export_fal(), file)
  )
  output$fal_csv <- downloadHandler(
    filename = function() paste0("FA_List_", Sys.Date(), ".csv"),
    content  = function(file) {
      write.csv(export_fal(), file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )
  
} # server

#4. FUNGSI BANTU

validate_nfa_form <- function(input) {
  if (nchar(trimws(input$nfa_code)) == 0) {
    showNotification("Asset Code wajib diisi.", type = "error"); return(FALSE)
  }
  if (input$nfa_type == "") {
    showNotification("Asset Type wajib dipilih.", type = "error"); return(FALSE)
  }
  if (nchar(trimws(input$nfa_desc)) == 0) {
    showNotification("Asset Description wajib diisi.", type = "error"); return(FALSE)
  }
  if (input$nfa_life < 1) {
    showNotification("Estimated Life minimal 1 tahun.", type = "error"); return(FALSE)
  }
  if (nchar(trimws(input$nfa_asset_acc)) == 0) {
    showNotification("Asset Account wajib diisi.", type = "error"); return(FALSE)
  }
  TRUE
}

save_fa_form <- function(input, rv) {
  total_cost <- sum(rv$exp_rows$amount, na.rm = TRUE)
  dep_rate <- switch(input$nfa_dep_method,
                     "Straight Line Method"    = round(100 / input$nfa_life, 2),
                     "Sum Of Year Digit Method"= round(100 / input$nfa_life, 2),
                     "Double Declining Method" = round(200 / input$nfa_life, 2),
                     0
  )
  new_row <- data.frame(
    asset_code       = trimws(input$nfa_code),
    asset_desc       = trimws(input$nfa_desc),
    asset_type       = input$nfa_type,
    asset_account    = input$nfa_asset_acc,
    asset_cost       = total_cost,
    acquisition_date = input$nfa_acq_date,
    usage_date       = input$nfa_usage_date,
    estimated_life   = input$nfa_life,
    dep_rate         = dep_rate,
    dep_method       = gsub(" Method", "", input$nfa_dep_method),
    department       = input$nfa_dept,
    intangible       = ifelse(input$nfa_intangible, "Yes", "No"),
    fiscal           = ifelse(input$nfa_fiscal_fa,  "Yes", "No"),
    status           = "Proceeded",
    salvage_value    = input$nfa_salvage,
    notes            = input$nfa_notes,
    stringsAsFactors = FALSE
  )
  # Hindari duplikat kode
  if (new_row$asset_code %in% rv$fa_list$asset_code) {
    idx <- which(rv$fa_list$asset_code == new_row$asset_code)
    rv$fa_list[idx, ] <- new_row
  } else {
    rv$fa_list <- rbind(rv$fa_list, new_row)
  }
  rv$fa_list_disp <- rv$fa_list
}

#5. JALANKAN APLIKASI 
shinyApp(ui = ui, server = server)
