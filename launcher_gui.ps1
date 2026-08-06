# ═══════════════════════════════════════════════════════════════
# Llama.cpp Elite Orchestrator — RTX 5080 Blackwell
# GUI Unificada: Modelo + Settings en una sola ventana
# ═══════════════════════════════════════════════════════════════
param(
    [switch]$Test,
    [switch]$Headless,
    [switch]$Status,
    [switch]$WaitReady,
    [int]$Port = 5050,
    [int]$TimeoutSec = 180,
    [string]$ModelPath = "",
    [string]$Ctx = "131072",
    [string]$Ngl = "99",
    [string]$Np = "1",
    [string]$Ub = "Default",
    [string]$Kv = "q4_0",
    [string]$KvD = "default",
    [string]$HermesCfg = "",
    [string]$Mtp = "auto",
    [string]$Temp = "0.4",
    [string]$TopP = "0.95",
    [string]$TopK = "20",
    [string]$MinP = "0.0",
    [string]$PresenceP = "0.0",
    [string]$RepeatP = "1.0",
    [switch]$Lan,
    [switch]$Tavily
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$CONFIG_PATH = Join-Path $PSScriptRoot "config_server.json"
$LAUNCH_STATE = Join-Path $PSScriptRoot "launch_state.json"
$DEFAULT_MODEL_ROOT = "$env:USERPROFILE\.lmstudio\models"
$DEFAULT_HERMES_CFG = "$env:USERPROFILE\.hermes\config.yaml"

# ── Detección automática de Tavily API Key ──
$TAVILY_KEY_FOUND = ($null -ne $env:TAVILY_API_KEY -and $env:TAVILY_API_KEY.Trim() -ne "")
$TAVILY_KEY_SHORT = if ($TAVILY_KEY_FOUND) { "..." + $env:TAVILY_API_KEY.Substring([Math]::Max(0, $env:TAVILY_API_KEY.Length - 6)) } else { "NO ENCONTRADA" }



# ── Cargar Configuración ──
$EXPOSE_LAN = $false
if (Test-Path $CONFIG_PATH) {
    try {
        $config = Get-Content $CONFIG_PATH | ConvertFrom-Json
        $MODEL_ROOT = $config.ModelRoot
        $HERMES_CFG = $config.HermesConfig
        if ($config.ExposeLan -eq $true) { $EXPOSE_LAN = $true }
    }
    catch {
        $MODEL_ROOT = $DEFAULT_MODEL_ROOT
        $HERMES_CFG = $DEFAULT_HERMES_CFG
    }
}
else {
    $MODEL_ROOT = $DEFAULT_MODEL_ROOT
    $HERMES_CFG = $DEFAULT_HERMES_CFG
}

if (-not $MODEL_ROOT) { $MODEL_ROOT = $DEFAULT_MODEL_ROOT }
if (-not $HERMES_CFG) { $HERMES_CFG = $DEFAULT_HERMES_CFG }

$RESULT_FILE = "$env:TEMP\llama_launch.txt"

# ── Funciones Core ──
function Get-GGUFModels {
    param([string]$path)
    if (-not (Test-Path $path)) { return @() }
    return @(Get-ChildItem -Path $path -Filter "*.gguf" -Recurse | Where-Object { $_.Name -notmatch "mmproj" })
}

# ── Detección de MTP por metadata del modelo (nombre de archivo o carpeta) ──
function Get-MtpCapable {
    param([string]$fullName)
    $fileName = Split-Path $fullName -Leaf
    $dirName = Split-Path (Split-Path $fullName -Parent) -Leaf
    return (($fileName -match "MTP") -or ($dirName -match "MTP"))
}

# ── Formulario (Elite Design) ──
$form = New-Object Windows.Forms.Form
$form.Text = "Llama.cpp Elite Orchestrator - RTX 5080 Blackwell"
$form.ClientSize = New-Object Drawing.Size(960, 940)
$form.StartPosition = "CenterScreen"
$form.BackColor = [Drawing.Color]::FromArgb(25, 25, 25)
$form.ForeColor = [Drawing.Color]::White
$form.Font = New-Object Drawing.Font("Segoe UI", 10)
$form.FormBorderStyle = "Sizable"

# ── Cabecera: Rutas ──
$lblPath = New-Object Windows.Forms.Label
$lblPath.Text = "Carpeta Modelos:"; $lblPath.Location = New-Object Drawing.Point(20, 15); $lblPath.AutoSize = $true; $form.Controls.Add($lblPath)

$txtPath = New-Object Windows.Forms.TextBox
$txtPath.Text = $MODEL_ROOT; $txtPath.Location = New-Object Drawing.Point(160, 13); $txtPath.Size = New-Object Drawing.Size(690, 28)
$txtPath.BackColor = [Drawing.Color]::FromArgb(50, 50, 50); $txtPath.ForeColor = [Drawing.Color]::LimeGreen; $form.Controls.Add($txtPath)

$btnBrowse = New-Object Windows.Forms.Button
$btnBrowse.Text = "FOLDER"; $btnBrowse.Location = New-Object Drawing.Point(860, 12); $btnBrowse.Size = New-Object Drawing.Size(80, 30); $btnBrowse.BackColor = [Drawing.Color]::FromArgb(70, 70, 70); $form.Controls.Add($btnBrowse)

$lblHermes = New-Object Windows.Forms.Label
$lblHermes.Text = "Hermes Config:"; $lblHermes.Location = New-Object Drawing.Point(20, 55); $lblHermes.AutoSize = $true; $form.Controls.Add($lblHermes)

$txtHermes = New-Object Windows.Forms.TextBox
$txtHermes.Text = $HERMES_CFG; $txtHermes.Location = New-Object Drawing.Point(160, 53); $txtHermes.Size = New-Object Drawing.Size(690, 28)
$txtHermes.BackColor = [Drawing.Color]::FromArgb(50, 50, 50); $txtHermes.ForeColor = [Drawing.Color]::DeepSkyBlue; $form.Controls.Add($txtHermes)

$btnHermes = New-Object Windows.Forms.Button
$btnHermes.Text = "CONFIG"; $btnHermes.Location = New-Object Drawing.Point(860, 52); $btnHermes.Size = New-Object Drawing.Size(80, 30); $btnHermes.BackColor = [Drawing.Color]::FromArgb(70, 70, 70); $form.Controls.Add($btnHermes)

# ── Buscador Veloce ──
$lblS = New-Object Windows.Forms.Label
$lblS.Text = "Buscador:"; $lblS.Location = New-Object Drawing.Point(20, 95); $lblS.AutoSize = $true; $form.Controls.Add($lblS)

$txtS = New-Object Windows.Forms.TextBox
$txtS.Location = New-Object Drawing.Point(160, 93); $txtS.Size = New-Object Drawing.Size(780, 28)
$txtS.BackColor = [Drawing.Color]::FromArgb(45, 45, 45); $txtS.ForeColor = [Drawing.Color]::White; $form.Controls.Add($txtS)

# ── DataGridView (Elite Table Style) ──
$dgv = New-Object Windows.Forms.DataGridView
$dgv.Location = New-Object Drawing.Point(20, 135); $dgv.Size = New-Object Drawing.Size(920, 250)
$dgv.Anchor = "Top,Left,Right,Bottom"
$dgv.BackgroundColor = [Drawing.Color]::FromArgb(35, 35, 35); $dgv.BorderStyle = "None"
$dgv.CellBorderStyle = "SingleHorizontal"; $dgv.GridColor = [Drawing.Color]::FromArgb(60, 60, 60)
$dgv.ColumnHeadersDefaultCellStyle.BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
$dgv.ColumnHeadersDefaultCellStyle.ForeColor = [Drawing.Color]::LimeGreen
$dgv.ColumnHeadersDefaultCellStyle.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$dgv.EnableHeadersVisualStyles = $false
$dgv.DefaultCellStyle.BackColor = [Drawing.Color]::FromArgb(40, 40, 40)
$dgv.DefaultCellStyle.ForeColor = [Drawing.Color]::White
$dgv.DefaultCellStyle.SelectionBackColor = [Drawing.Color]::FromArgb(0, 180, 0)
$dgv.DefaultCellStyle.SelectionForeColor = [Drawing.Color]::Black
$dgv.RowTemplate.Height = 32; $dgv.RowHeadersVisible = $false; $dgv.AllowUserToAddRows = $false; $dgv.ReadOnly = $true
$dgv.SelectionMode = "FullRowSelect"; $dgv.MultiSelect = $false
$dgv.ColumnCount = 5; $dgv.Columns[0].Name = "Modelo"; $dgv.Columns[0].Width = 350; $dgv.Columns[1].Name = "GB"; $dgv.Columns[1].Width = 70; $dgv.Columns[2].Name = "Origen"; $dgv.Columns[2].Width = 240; $dgv.Columns[3].Name = "MTP"; $dgv.Columns[3].Width = 50; $dgv.Columns[4].Visible = $false
$form.Controls.Add($dgv)

function Update-Grid {
    $currentModel = if ($dgv.SelectedRows.Count -gt 0) { $dgv.SelectedRows[0].Cells[4].Value } else { "" }
    $dgv.Rows.Clear()
    $models = Get-GGUFModels $txtPath.Text
    foreach ($m in $models) {
        if ($m.Name -like "*$($txtS.Text)*") {
            $origen = $m.Directory.Parent.Name + "/" + $m.Directory.Name
            $mtp = Get-MtpCapable $m.FullName
            $mtpStr = if ($mtp) { "SI" } else { "NO" }
            $idx = $dgv.Rows.Add($m.Name, [math]::round($m.Length / 1GB, 2), $origen, $mtpStr, $m.FullName)
            if ($m.FullName -eq $currentModel) { $dgv.Rows[$idx].Selected = $true }
        }
    }
    if ($dgv.SelectedRows.Count -eq 0 -and $dgv.Rows.Count -gt 0) { $dgv.Rows[0].Selected = $true }
}
Update-Grid

# ── Eventos Selectores ──
$btnBrowse.Add_Click({ $fbd = New-Object Windows.Forms.FolderBrowserDialog; if ($fbd.ShowDialog() -eq "OK") { $txtPath.Text = $fbd.SelectedPath; Update-Grid } })
$btnHermes.Add_Click({ $ofd = New-Object Windows.Forms.OpenFileDialog; $ofd.Filter = "YAML|*.yaml"; if ($ofd.ShowDialog() -eq "OK") { $txtHermes.Text = $ofd.FileName } })
$txtPath.Add_TextChanged({ Update-Grid })
$txtS.Add_TextChanged({ Update-Grid })

# ── Panel de Settings (Premium Original) ──
$pnl = New-Object Windows.Forms.GroupBox
$pnl.Text = "  Optimizacion de Inferencia Blackwell RTX 5080  "
$pnl.ForeColor = [Drawing.Color]::LimeGreen
$pnl.Location = New-Object Drawing.Point(20, 415); $pnl.Size = New-Object Drawing.Size(920, 420); $pnl.Anchor = "Bottom,Left,Right"
$form.Controls.Add($pnl)

# Panel interior con scroll (GroupBox no es scrollable en .NET Framework)
$pnlInner = New-Object Windows.Forms.Panel
$pnlInner.Location = New-Object Drawing.Point(12, 22); $pnlInner.Size = New-Object Drawing.Size(896, 385); $pnlInner.Anchor = "Top,Left,Right,Bottom"
$pnlInner.AutoScroll = $true
$pnlInner.AutoScrollMinSize = New-Object Drawing.Size(0, 385)
$pnl.Controls.Add($pnlInner)

function New-Setting {
    param($title, $x, $items, $def, $tip)
    $lbl = New-Object Windows.Forms.Label; $lbl.Text = $title; $lbl.Location = New-Object Drawing.Point($x, 30); $lbl.Width = 200; $lbl.ForeColor = "White"; $pnlInner.Controls.Add($lbl)
    $cb = New-Object Windows.Forms.ComboBox; $cb.Location = New-Object Drawing.Point($x, 55); $cb.Width = 200; $cb.DropDownStyle = "DropDownList"; $cb.BackColor = [Drawing.Color]::FromArgb(50, 50, 50); $cb.ForeColor = [Drawing.Color]::White; $cb.FlatStyle = "Flat"
    foreach ($i in $items) { $cb.Items.Add($i) | Out-Null }; $cb.SelectedIndex = $def; $pnlInner.Controls.Add($cb)
    $tipLbl = New-Object Windows.Forms.Label; $tipLbl.Text = $tip; $tipLbl.ForeColor = [Drawing.Color]::Gray; $tipLbl.Location = New-Object Drawing.Point($x, 85); $tipLbl.Size = New-Object Drawing.Size(210, 40); $tipLbl.Font = New-Object Drawing.Font("Segoe UI", 8); $pnlInner.Controls.Add($tipLbl)
    return $cb
}

$cCtx = New-Setting "Contexto (Tokens)" 15 @("32768 (32K)", "65536 (64K)", "131072 (128K)", "262144 (256K)") 2 "Memoria del modelo"
$cGpu = New-Setting "GPU Layers (-ngl)" 240 @("99 - Max FPS", "60 - Balanced", "40 - Safe") 0 "Capas en VRAM"
$cPar = New-Setting "Parallel Slots (-np)" 465 @("1 - Solo Yo", "2 - Con Hermes", "4 - Multi") 0 "Sesiones simultaneas"
$cBat = New-Setting "uBatch Size" 690 @("Default", "1024", "2048", "4096") 0 "Velocidad Blackwell"

# ── KV Cache selector (Q4_0 / F16; f4 no soportado por el binario v488) ──
$lblKv = New-Object Windows.Forms.Label
$lblKv.Text = "KV Cache Type:"; $lblKv.Location = New-Object Drawing.Point(15, 130); $lblKv.AutoSize = $true; $lblKv.ForeColor = [Drawing.Color]::LightGoldenrodYellow
$pnlInner.Controls.Add($lblKv)

$cKv = New-Object Windows.Forms.ComboBox
$cKv.Location = New-Object Drawing.Point(160, 128); $cKv.Width = 200; $cKv.DropDownStyle = "DropDownList"
$cKv.BackColor = [Drawing.Color]::FromArgb(50, 50, 50); $cKv.ForeColor = [Drawing.Color]::LightGoldenrodYellow; $cKv.FlatStyle = "Flat"
@("q4_0 (Recomendado)", "f16 (Máx. Calidad)") | ForEach-Object { $cKv.Items.Add($_) | Out-Null }
$cKv.SelectedIndex = 0
$pnlInner.Controls.Add($cKv)

$lblKvTip = New-Object Windows.Forms.Label
$lblKvTip.Text = "q4_0: -60% VRAM vs f16 (sin perdida perceptible)"; $lblKvTip.ForeColor = [Drawing.Color]::Gray
$lblKvTip.Location = New-Object Drawing.Point(370, 128); $lblKvTip.Size = New-Object Drawing.Size(280, 26); $lblKvTip.Font = New-Object Drawing.Font("Segoe UI", 8)
$pnlInner.Controls.Add($lblKvTip)

# ── KV Cache Draft selector (MTP: cache separado del contexto draft) ──
$lblKvD = New-Object Windows.Forms.Label
$lblKvD.Text = "KV Draft (MTP):"; $lblKvD.Location = New-Object Drawing.Point(15, 170); $lblKvD.AutoSize = $true; $lblKvD.ForeColor = [Drawing.Color]::LightGoldenrodYellow
$pnlInner.Controls.Add($lblKvD)

$cKvD = New-Object Windows.Forms.ComboBox
$cKvD.Location = New-Object Drawing.Point(160, 168); $cKvD.Width = 200; $cKvD.DropDownStyle = "DropDownList"
$cKvD.BackColor = [Drawing.Color]::FromArgb(50, 50, 50); $cKvD.ForeColor = [Drawing.Color]::LightGoldenrodYellow; $cKvD.FlatStyle = "Flat"
@("Default (sin setear)", "q4_0", "f16", "q8_0", "bf16") | ForEach-Object { $cKvD.Items.Add($_) | Out-Null }
$cKvD.SelectedIndex = 0
$pnlInner.Controls.Add($cKvD)

$lblKvDTip = New-Object Windows.Forms.Label
$lblKvDTip.Text = "KV del contexto draft MTP. Default = f16 del motor. q4_0: -75% VRAM, probado."
$lblKvDTip.ForeColor = [Drawing.Color]::Gray
$lblKvDTip.Location = New-Object Drawing.Point(370, 168); $lblKvDTip.Size = New-Object Drawing.Size(520, 30); $lblKvDTip.Font = New-Object Drawing.Font("Segoe UI", 8)
$pnlInner.Controls.Add($lblKvDTip)

# ── MTP toggle (auto-detectado por metadata del modelo, override manual) ──
$chkMtp = New-Object Windows.Forms.CheckBox
$chkMtp.Text = "MTP (draft-mtp n=2)"; $chkMtp.Checked = $true
$chkMtp.Location = New-Object Drawing.Point(15, 205); $chkMtp.AutoSize = $true
$chkMtp.ForeColor = [Drawing.Color]::LimeGreen
$chkMtp.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold); $pnlInner.Controls.Add($chkMtp)

$lblMtpTip = New-Object Windows.Forms.Label
$lblMtpTip.Text = "Auto-detectado por el nombre del modelo (MTP en archivo o carpeta)."
$lblMtpTip.ForeColor = [Drawing.Color]::Gray
$lblMtpTip.Location = New-Object Drawing.Point(200, 205); $lblMtpTip.Size = New-Object Drawing.Size(400, 20); $lblMtpTip.Font = New-Object Drawing.Font("Segoe UI", 8)
$pnlInner.Controls.Add($lblMtpTip)

# Al seleccionar un modelo en la grilla, auto-setear el toggle segun metadata
$dgv.Add_SelectionChanged({
        if ($dgv.SelectedRows.Count -gt 0) {
            $selPath = $dgv.SelectedRows[0].Cells[4].Value
            if ($selPath) { $chkMtp.Checked = Get-MtpCapable $selPath }
        }
    })

# Sincronizar estado inicial: Update-Grid ya selecciono la fila 0 antes de registrar el handler
if ($dgv.SelectedRows.Count -gt 0) {
    $selPath = $dgv.SelectedRows[0].Cells[4].Value
    if ($selPath) { $chkMtp.Checked = Get-MtpCapable $selPath }
}

# ── Opción LAN y Tavily ──
$chkLan = New-Object Windows.Forms.CheckBox
$chkLan.Text = "EXPONER SERVIDOR EN RED LOCAL (LAN)"; $chkLan.Checked = $EXPOSE_LAN
$chkLan.Location = New-Object Drawing.Point(15, 240); $chkLan.AutoSize = $true; $chkLan.ForeColor = [Drawing.Color]::DeepSkyBlue
$chkLan.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold); $pnlInner.Controls.Add($chkLan)

$chkTavily = New-Object Windows.Forms.CheckBox
$chkTavily.Text = "TAVILY WEB SEARCH (MCP)"; $chkTavily.Checked = $TAVILY_KEY_FOUND
$chkTavily.Location = New-Object Drawing.Point(350, 240); $chkTavily.AutoSize = $true
$chkTavily.ForeColor = if ($TAVILY_KEY_FOUND) { [Drawing.Color]::Cyan } else { [Drawing.Color]::DarkGray }
$chkTavily.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold); $pnlInner.Controls.Add($chkTavily)

$lblTavilyKey = New-Object Windows.Forms.Label
$lblTavilyKey.Text = if ($TAVILY_KEY_FOUND) { "API KEY: $TAVILY_KEY_SHORT" } else { "Sin TAVILY_API_KEY en entorno" }
$lblTavilyKey.ForeColor = if ($TAVILY_KEY_FOUND) { [Drawing.Color]::LimeGreen } else { [Drawing.Color]::OrangeRed }
$lblTavilyKey.Location = New-Object Drawing.Point(350, 257); $lblTavilyKey.AutoSize = $true
$lblTavilyKey.Font = New-Object Drawing.Font("Segoe UI", 8); $pnlInner.Controls.Add($lblTavilyKey)

# ── Sampling (todos seteables, defaults = config sagrada testeada) ──
$lblSampling = New-Object Windows.Forms.Label
$lblSampling.Text = "SAMPLING (defaults = config ultra testeada Qwen; ajustar por modelo si hace falta)"; $lblSampling.Location = New-Object Drawing.Point(15, 285); $lblSampling.AutoSize = $true; $lblSampling.ForeColor = [Drawing.Color]::LimeGreen; $lblSampling.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pnlInner.Controls.Add($lblSampling)

function New-Slider {
    param($title, $x, $y, $min, $max, $val, $step, $format)
    $lbl = New-Object Windows.Forms.Label; $lbl.Text = $title; $lbl.Location = New-Object Drawing.Point($x, $y); $lbl.Width = 130; $lbl.ForeColor = "White"; $pnlInner.Controls.Add($lbl)
    $lblVal = New-Object Windows.Forms.Label; $lblVal.Text = $val.ToString($format); $lblVal.Location = New-Object Drawing.Point(($x + 135), $y); $lblVal.Width = 50; $lblVal.ForeColor = [Drawing.Color]::LimeGreen; $pnlInner.Controls.Add($lblVal)
    $tb = New-Object Windows.Forms.TrackBar; $tb.Location = New-Object Drawing.Point(($x + 190), ($y - 4)); $tb.Width = 180; $tb.Minimum = [int]($min / $step); $tb.Maximum = [int]($max / $step); $tb.TickFrequency = [Math]::Max(1, [int]((($max - $min) / $step) / 10)); $tb.Value = [int]($val / $step); $pnlInner.Controls.Add($tb)
    $tb.Add_Scroll({ $lblVal.Text = ($tb.Value * $step).ToString($format) })
    return @{ Track = $tb; Step = $step; Format = $format }
}

$sTemp = New-Slider "Temperature" 15 315 0.0 2.0 0.4 0.1 "0.0"
$sTopP = New-Slider "Top P" 15 355 0.5 1.0 0.95 0.01 "0.00"
$sTopK = New-Slider "Top K" 465 315 1 200 20 1 "0"
$sMinP = New-Slider "Min P" 465 355 0.0 1.0 0.0 0.01 "0.00"
$sPresence = New-Slider "Presence Penalty" 15 395 0.0 2.0 0.0 0.1 "0.0"
$sRepeat = New-Slider "Repeat Penalty" 465 395 1.0 2.0 1.0 0.05 "0.00"

# ── Botón Lanzar (Maximum Impact) ──
$btn = New-Object Windows.Forms.Button
$btn.Text = "LANZAR LABORATORIO BLACKWELL"
$btn.Location = New-Object Drawing.Point(250, 850); $btn.Size = New-Object Drawing.Size(460, 60); $btn.Anchor = "Bottom"
$btn.BackColor = [Drawing.Color]::LimeGreen; $btn.ForeColor = [Drawing.Color]::Black; $btn.FlatStyle = "Flat"
$btn.Font = New-Object Drawing.Font("Segoe UI", 16, [Drawing.FontStyle]::Bold); $btn.Cursor = [Windows.Forms.Cursors]::Hand

$btn.Add_Click({
        if ($dgv.SelectedRows.Count -eq 0) { return }
        $conf = @{ ModelRoot = $txtPath.Text; HermesConfig = $txtHermes.Text; ExposeLan = $chkLan.Checked }
        $conf | ConvertTo-Json | Out-File $CONFIG_PATH -Force
        $modelPath = $dgv.SelectedRows[0].Cells[4].Value
        $ctx = $cCtx.SelectedItem.Split(" ")[0]; $ngl = $cGpu.SelectedItem.Split(" ")[0]; $np = $cPar.SelectedItem.Split(" ")[0]; $ub = $cBat.SelectedItem.Split(" ")[0]
        $kvRaw = $cKv.SelectedItem.Split(" ")[0]  # e.g. "q4_0", "f16"
        $kvDRaw = if ($cKvD.SelectedIndex -eq 0) { "default" } else { $cKvD.SelectedItem }
        $mtpVal = if ($chkMtp.Checked) { "1" }else { "0" }
        $lan = if ($chkLan.Checked) { "1" }else { "0" }
        $tavily = if ($chkTavily.Checked) { "1" }else { "0" }
        $tempVal = ($sTemp.Track.Value * $sTemp.Step).ToString($sTemp.Format)
        $topPVal = ($sTopP.Track.Value * $sTopP.Step).ToString($sTopP.Format)
        $topKVal = ($sTopK.Track.Value * $sTopK.Step).ToString($sTopK.Format)
        $minPVal = ($sMinP.Track.Value * $sMinP.Step).ToString($sMinP.Format)
        $presenceVal = ($sPresence.Track.Value * $sPresence.Step).ToString($sPresence.Format)
        $repeatVal = ($sRepeat.Track.Value * $sRepeat.Step).ToString($sRepeat.Format)
        $state = @{
            mode    = "gui"
            config  = @{
                modelPath  = $modelPath
                ctx        = $ctx
                ngl        = $ngl
                np         = $np
                ub         = $ub
                kv         = $kvRaw
                kvD        = $kvDRaw
                mtp        = $mtpVal
                temp       = $tempVal
                topP       = $topPVal
                topK       = $topKVal
                minP       = $minPVal
                presenceP  = $presenceVal
                repeatP    = $repeatVal
                hermesCfg  = $txtHermes.Text
                lan        = $lan
                tavily     = $tavily
            }
            updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        $state | ConvertTo-Json | Out-File $LAUNCH_STATE -Force -Encoding utf8
        $form.DialogResult = [Windows.Forms.DialogResult]::OK; $form.Close()
    })
$form.Controls.Add($btn)

# ── Modo Headless (CLI/API: simula el dashboard sin abrir GUI) ──
if ($Headless) {
    if ($Status) {
        if (Test-Path $LAUNCH_STATE) {
            $s = Get-Content $LAUNCH_STATE -Raw | ConvertFrom-Json
            "MODE: $($s.mode)"
            "CONFIG: $($s.config.modelPath) | ctx=$($s.config.ctx) ngl=$($s.config.ngl) np=$($s.config.np) ub=$($s.config.ub) kv=$($s.config.kv) kvd=$($s.config.kvD) mtp=$($s.config.mtp) temp=$($s.config.temp) topP=$($s.config.topP) topK=$($s.config.topK) minP=$($s.config.minP) presence=$($s.config.presenceP) repeat=$($s.config.repeatP) lan=$($s.config.lan) tavily=$($s.config.tavily)"
            "UPDATED: $($s.updated)"
        } else {
            "MODE: none (no launch_state.json)"
        }
        $portOpen = Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue -InformationLevel Quiet
        "SERVER: $portOpen ($Port)"
        exit 0
    }
    if ($WaitReady) {
        $deadline = (Get-Date).AddSeconds($TimeoutSec)
        while ((Get-Date) -lt $deadline) {
            if (Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue -InformationLevel Quiet) {
                "READY: server respondiendo en 127.0.0.1:$Port"
                exit 0
            }
            Start-Sleep -Seconds 2
        }
        "TIMEOUT: server no respondio en $TimeoutSec segundos"
        exit 1
    }
    if (-not $ModelPath) { Write-Error "Headless requiere -ModelPath (o -Status / -WaitReady)"; exit 1 }
    if (-not (Test-Path $ModelPath)) { Write-Error "Modelo no encontrado: $ModelPath"; exit 1 }
    if (-not $HermesCfg) { $HermesCfg = $HERMES_CFG }
    $mtpVal = $Mtp
    if ($mtpVal -eq "auto") { $mtpVal = if (Get-MtpCapable $ModelPath) { "1" } else { "0" } }
    $lanVal = if ($Lan) { "1" } else { "0" }
    $tavilyVal = if ($Tavily) { "1" } else { "0" }
    $state = @{
        mode    = "headless"
        config  = @{
            modelPath  = $ModelPath
            ctx        = $Ctx
            ngl        = $Ngl
            np         = $Np
            ub         = $Ub
            kv         = $Kv
            kvD        = $KvD
            mtp        = $mtpVal
            temp       = $Temp
            topP       = $TopP
            topK       = $TopK
            minP       = $MinP
            presenceP  = $PresenceP
            repeatP    = $RepeatP
            hermesCfg  = $HermesCfg
            lan        = $lanVal
            tavily     = $tavilyVal
        }
        updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $state | ConvertTo-Json | Out-File $LAUNCH_STATE -Force -Encoding utf8
    "HEADLESS OK: config escrita en launch_state.json"
    "MODO: el bat saltara la GUI y lanzara con esta config"
    exit 0
}

# ── Modo Test ──
if ($Test) {
    if ($dgv.Rows.Count -eq 0) { Write-Error "No modelos"; exit 1 }
    $lanStr = if ($EXPOSE_LAN) { "1" }else { "0" }
    $testPath = $dgv.Rows[0].Cells[4].Value
    $state = @{
        mode    = "test"
        config  = @{
            modelPath  = $testPath
            ctx        = "131072"
            ngl        = "99"
            np         = "1"
            ub         = "Default"
            kv         = "q4_0"
            kvD        = "default"
            mtp        = if (Get-MtpCapable $testPath) { "1" } else { "0" }
            temp       = "0.4"
            topP       = "0.95"
            topK       = "20"
            minP       = "0.0"
            presenceP  = "0.0"
            repeatP    = "1.0"
            hermesCfg  = $HERMES_CFG
            lan        = $lanStr
            tavily     = "0"
        }
        updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $state | ConvertTo-Json | Out-File $LAUNCH_STATE -Force -Encoding utf8
    exit 0
}

$form.ShowDialog() | Out-Null
