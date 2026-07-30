# ═══════════════════════════════════════════════════════════════
# Llama.cpp Elite Orchestrator — RTX 5080 Blackwell
# GUI Unificada: Modelo + Settings en una sola ventana
# ═══════════════════════════════════════════════════════════════
param(
    [switch]$Test
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$CONFIG_PATH = Join-Path $PSScriptRoot "config_server.json"
$DEFAULT_MODEL_ROOT = "$env:USERPROFILE\.lmstudio\models"
$DEFAULT_HERMES_CFG = "$env:USERPROFILE\.hermes\config.yaml"



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

# ── Formulario (Elite Design) ──
$form = New-Object Windows.Forms.Form
$form.Text = "Llama.cpp Elite Orchestrator - RTX 5080 Blackwell"
$form.ClientSize = New-Object Drawing.Size(960, 860)
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
$dgv.Location = New-Object Drawing.Point(20, 135); $dgv.Size = New-Object Drawing.Size(920, 330)
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
$dgv.ColumnCount = 4; $dgv.Columns[0].Name = "Modelo"; $dgv.Columns[0].Width = 380; $dgv.Columns[1].Name = "GB"; $dgv.Columns[1].Width = 70; $dgv.Columns[2].Name = "Origen"; $dgv.Columns[2].Width = 250; $dgv.Columns[3].Visible = $false
$form.Controls.Add($dgv)

function Update-Grid {
    $currentModel = if ($dgv.SelectedRows.Count -gt 0) { $dgv.SelectedRows[0].Cells[3].Value } else { "" }
    $dgv.Rows.Clear()
    $models = Get-GGUFModels $txtPath.Text
    foreach ($m in $models) {
        if ($m.Name -like "*$($txtS.Text)*") {
            $origen = $m.Directory.Parent.Name + "/" + $m.Directory.Name
            $idx = $dgv.Rows.Add($m.Name, [math]::round($m.Length / 1GB, 2), $origen, $m.FullName)
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
$pnl.Location = New-Object Drawing.Point(20, 480); $pnl.Size = New-Object Drawing.Size(920, 210); $pnl.Anchor = "Bottom,Left,Right"
$form.Controls.Add($pnl)

function New-Setting {
    param($title, $x, $items, $def, $tip)
    $lbl = New-Object Windows.Forms.Label; $lbl.Text = $title; $lbl.Location = New-Object Drawing.Point($x, 30); $lbl.Width = 200; $lbl.ForeColor = "White"; $pnl.Controls.Add($lbl)
    $cb = New-Object Windows.Forms.ComboBox; $cb.Location = New-Object Drawing.Point($x, 55); $cb.Width = 200; $cb.DropDownStyle = "DropDownList"; $cb.BackColor = [Drawing.Color]::FromArgb(50, 50, 50); $cb.ForeColor = [Drawing.Color]::White; $cb.FlatStyle = "Flat"
    foreach ($i in $items) { $cb.Items.Add($i) | Out-Null }; $cb.SelectedIndex = $def; $pnl.Controls.Add($cb)
    $tipLbl = New-Object Windows.Forms.Label; $tipLbl.Text = $tip; $tipLbl.ForeColor = [Drawing.Color]::Gray; $tipLbl.Location = New-Object Drawing.Point($x, 85); $tipLbl.Size = New-Object Drawing.Size(210, 80); $tipLbl.Font = New-Object Drawing.Font("Segoe UI", 8); $pnl.Controls.Add($tipLbl)
    return $cb
}

$cCtx = New-Setting "Contexto (Tokens)" 15 @("32768 (32K)", "65536 (64K)", "131072 (128K)", "262144 (256K)") 2 "Memoria del modelo"
$cGpu = New-Setting "GPU Layers (-ngl)" 240 @("99 - Max FPS", "60 - Balanced", "40 - Safe") 0 "Capas en VRAM"
$cPar = New-Setting "Parallel Slots (-np)" 465 @("1 - Solo Yo", "2 - Con Hermes", "4 - Multi") 0 "Sesiones simultaneas"
$cBat = New-Setting "uBatch Size" 690 @("Default", "1024", "2048", "4096") 0 "Velocidad Blackwell"

# ── KV Cache selector (nuevo: Q4_0 / FP4 nativo Blackwell) ──
$lblKv = New-Object Windows.Forms.Label
$lblKv.Text = "KV Cache Type:"; $lblKv.Location = New-Object Drawing.Point(20, 145); $lblKv.AutoSize = $true; $lblKv.ForeColor = [Drawing.Color]::LightGoldenrodYellow
$pnl.Controls.Add($lblKv)

$cKv = New-Object Windows.Forms.ComboBox
$cKv.Location = New-Object Drawing.Point(160, 143); $cKv.Width = 200; $cKv.DropDownStyle = "DropDownList"
$cKv.BackColor = [Drawing.Color]::FromArgb(50, 50, 50); $cKv.ForeColor = [Drawing.Color]::LightGoldenrodYellow; $cKv.FlatStyle = "Flat"
@("q4_0 (Recomendado)", "f4 (Blackwell FP4 nativo)", "f16 (Máx. Calidad)") | ForEach-Object { $cKv.Items.Add($_) | Out-Null }
$cKv.SelectedIndex = 0
$pnl.Controls.Add($cKv)

$lblKvTip = New-Object Windows.Forms.Label
$lblKvTip.Text = "q4_0: -60% VRAM vs f16`nf4: -75% VRAM (Tensor Cores FP4)"; $lblKvTip.ForeColor = [Drawing.Color]::Gray
$lblKvTip.Location = New-Object Drawing.Point(370, 143); $lblKvTip.Size = New-Object Drawing.Size(280, 40); $lblKvTip.Font = New-Object Drawing.Font("Segoe UI", 8)
$pnl.Controls.Add($lblKvTip)


# ── Opción LAN y Tavily ──
$chkLan = New-Object Windows.Forms.CheckBox
$chkLan.Text = "EXPONER SERVIDOR EN RED LOCAL (LAN)"; $chkLan.Checked = $EXPOSE_LAN
$chkLan.Location = New-Object Drawing.Point(20, 175); $chkLan.AutoSize = $true; $chkLan.ForeColor = [Drawing.Color]::DeepSkyBlue
$chkLan.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold); $pnl.Controls.Add($chkLan)

$chkTavily = New-Object Windows.Forms.CheckBox
$chkTavily.Text = "TAVILY WEB SEARCH (MCP)"; $chkTavily.Checked = $false
$chkTavily.Location = New-Object Drawing.Point(350, 175); $chkTavily.AutoSize = $true; $chkTavily.ForeColor = [Drawing.Color]::Cyan
$chkTavily.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold); $pnl.Controls.Add($chkTavily)

# ── Botón Lanzar (Maximum Impact) ──
$btn = New-Object Windows.Forms.Button
$btn.Text = "LANZAR LABORATORIO BLACKWELL"
$btn.Location = New-Object Drawing.Point(250, 715); $btn.Size = New-Object Drawing.Size(460, 80); $btn.Anchor = "Bottom"
$btn.BackColor = [Drawing.Color]::LimeGreen; $btn.ForeColor = [Drawing.Color]::Black; $btn.FlatStyle = "Flat"
$btn.Font = New-Object Drawing.Font("Segoe UI", 16, [Drawing.FontStyle]::Bold); $btn.Cursor = [Windows.Forms.Cursors]::Hand

$btn.Add_Click({
        if ($dgv.SelectedRows.Count -eq 0) { return }
        $conf = @{ ModelRoot = $txtPath.Text; HermesConfig = $txtHermes.Text; ExposeLan = $chkLan.Checked }
        $conf | ConvertTo-Json | Out-File $CONFIG_PATH -Force
        $modelPath = $dgv.SelectedRows[0].Cells[3].Value
        $ctx = $cCtx.SelectedItem.Split(" ")[0]; $ngl = $cGpu.SelectedItem.Split(" ")[0]; $np = $cPar.SelectedItem.Split(" ")[0]; $ub = $cBat.SelectedItem.Split(" ")[0]
        $kvRaw = $cKv.SelectedItem.Split(" ")[0]  # e.g. "q4_0", "f4", "f16"
        $lan = if ($chkLan.Checked) { "1" }else { "0" }
        $tavily = if ($chkTavily.Checked) { "1" }else { "0" }
        $line = "$modelPath|$ctx|$ngl|$np|$ub|$($txtHermes.Text)|$lan|$tavily|$kvRaw"
        [System.IO.File]::WriteAllText($RESULT_FILE, $line)
        $form.DialogResult = [Windows.Forms.DialogResult]::OK; $form.Close()
    })
$form.Controls.Add($btn)

# ── Modo Test ──
if ($Test) {
    if ($dgv.Rows.Count -eq 0) { Write-Error "No modelos"; exit 1 }
    $lanStr = if ($EXPOSE_LAN) { "1" }else { "0" }
    $line = "$($dgv.Rows[0].Cells[3].Value)|131072|99|1|Default|$HERMES_CFG|$lanStr|0|q4_0"
    [System.IO.File]::WriteAllText($RESULT_FILE, $line)
    exit 0
}

$form.ShowDialog() | Out-Null
