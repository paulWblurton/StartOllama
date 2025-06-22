<#
GenerateModelDashboard.ps1 — Jaguar Edition with Scrollable, Multi‑Column Navigation,
  Section Headers, and System Requirements at the Top
---------------------------------------------------------------------------------------
How It Works:
1. Fetches the Ollama library page (with a 15‑second timeout).
2. Uses regex to extract model blocks and builds objects (ID, Title, Description).
3. Optionally filters models via a user-provided filter.
4. Builds an HTML dashboard that includes:
   • A top navigation index (wrapped in a scrollable, multi‑column container) listing all model links.
   • A system requirements table at the top using standard ASCII punctuation.
   • Detailed sections for each model (each starting with an H2 header) including title, description, optional classification, default command link, any variants, and a “Back to top” link.
5. Saves the final HTML as "models_catalog.html" in your TEMP folder.
#>

# Set the library URL and fetch page content.
chcp 65001 >nul
$libraryUrl = "https://ollama.com/library"
try {
    Write-Host "Fetching library page..." -ForegroundColor Cyan
    $html = Invoke-WebRequest -Uri $libraryUrl -TimeoutSec 15 -UseBasicParsing
} catch {
    Write-Host "❌ Error fetching library page: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
$pageContent = $html.Content

# Use regex to extract each model block.
$pattern = '<li[^>]*x-test-model[^>]*>(.*?)</li>'
$modelsMatches = [regex]::Matches($pageContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
$models = @()
foreach ($m in $modelsMatches) {
    $liContent = $m.Groups[1].Value
    $anchorMatch = [regex]::Match($liContent, '<a\s+href\s*=\s*"(/library/([a-z0-9\-]+))"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (!$anchorMatch.Success) { continue }
    $modelID = $anchorMatch.Groups[2].Value
    $titleMatch = [regex]::Match($liContent, 'x-test-model-title[^>]+title\s*=\s*"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $modelTitle = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $modelID }
    $descMatch = [regex]::Match($liContent, '<p[^>]*>(.*?)</p>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $modelDesc = if ($descMatch.Success) { ([regex]::Replace($descMatch.Groups[1].Value, '<.*?>','')).Trim() } else { '' }
    $models += [PSCustomObject]@{
         ID          = $modelID
         Title       = $modelTitle
         Description = $modelDesc
    }
}

if ($models.Count -eq 0) { 
    Write-Host "❌ No models found." -ForegroundColor Red
    exit 1
}

# Optional filtering.
$filterString = Read-Host "Enter a filter string for models (optional, e.g., 'qwen', 'llama', 'mistral'; press Enter for all)"
if (-not [string]::IsNullOrWhiteSpace($filterString)) {
    Write-Host "Filtering models using '$filterString'..." -ForegroundColor Cyan
    $models = $models | Where-Object { $_.ID -match $filterString -or $_.Title -match $filterString -or $_.Description -match $filterString }
    if ($models.Count -eq 0) {
        Write-Host "No models match the filter '$filterString'." -ForegroundColor Yellow
        exit 1
    }
}
$models = $models | Sort-Object Title
if (-not [string]::IsNullOrWhiteSpace($filterString)) {
    $filterNotice = "Models filtered by: '$filterString'"
} else {
    $filterNotice = "No filter applied; displaying all models."
}

# Build a top navigation index wrapped in a scrollable, multi-column container.
$indexList = "<nav id='topNav'><ul>"
foreach ($m in $models) {
    $indexList += "<li><a href='#$($m.ID)'>$($m.Title)</a></li>"
}
$indexList += "</ul></nav>"

$outFile = Join-Path $env:TEMP "models_catalog.html"

# Build HTML header with external Normalize.css and custom styles.
$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset='UTF-8'>
  <title>Ollama Model Catalog</title>
  <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css'>
  <style>
    body { 
      font-family: Arial, sans-serif; 
      margin: 0; 
      padding: 0;
      background-color: #f9f9f9;
      scroll-behavior: smooth;
    }
    .content {
      margin: 20px;
      padding: 0 20px;
    }
    h1 { color: #333; }
    h2 { color: #2a2a2a; border-bottom: 1px solid #ccc; padding-bottom: 5px; }
    p { line-height: 1.5em; }
    /* Scrollable, Multi-Column Navigation */
    nav#topNav {
      background: #007acc;
      padding: 10px;
      overflow-y: auto;
      max-height: 150px;
    }
    nav#topNav ul {
      list-style: none;
      margin: 0;
      padding: 0;
      column-count: 3;
      column-gap: 15px;
    }
    nav#topNav li {
      margin-bottom: 5px;
    }
    nav#topNav a {
      color: #fff;
      text-decoration: none;
      font-weight: bold;
    }
    table { 
      border-collapse: collapse; 
      width: 100%; 
      margin: 20px 0; 
    }
    table, th, td { border: 1px solid #ccc; }
    th, td { padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
    a { text-decoration: none; color: #007acc; }
    a:hover { text-decoration: underline; }
    .model-section { 
      background-color: #fff; 
      margin-bottom: 40px; 
      padding: 15px; 
      box-shadow: 0 0 5px rgba(0,0,0,0.1); 
    }
    .back-to-top {
       display: block;
       text-align: right;
       margin-top: 10px;
    }
  </style>
</head>
<body>
  <div class='content'>
    <a id='top'></a>
    <h1>Ollama Model Catalog</h1>
    <p>Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    <p>$filterNotice</p>
    <!-- Place system requirements table at the very top -->
    <h3>System Requirements for Running LLMs</h3>
    <table>
      <thead>
        <tr>
          <th>Component</th>
          <th>Small LLMs (e.g., TinyLlama, GPT-2 Small)</th>
          <th>Medium LLMs (e.g., 3B-7B models)</th>
          <th>Beast LLMs (30B-70B+ models)</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>CPU</td>
          <td>4-core Intel i5 / AMD Ryzen 5</td>
          <td>6-8 core (e.g., Intel i7 11th Gen / AMD Ryzen 7)</td>
          <td>32+ core (e.g., Intel Xeon / AMD Threadripper)</td>
        </tr>
        <tr>
          <td>Memory (RAM)</td>
          <td>8-16 GB (some models can run on as little as 4 GB)</td>
          <td>32 GB recommended (16 GB min with swap; 64 GB ideal)</td>
          <td>128-256 GB ECC</td>
        </tr>
        <tr>
          <td>GPU</td>
          <td>Optional – 2-4 GB VRAM (e.g., GTX 1050 Ti)</td>
          <td>NVIDIA RTX 3060 (12GB VRAM recommended; 8GB min)</td>
          <td>2-4× NVIDIA RTX 4090 (24GB each) or A100/H100</td>
        </tr>
        <tr>
          <td>Storage</td>
          <td>SSD with 10-20 GB free</td>
          <td>NVMe SSD with at least 100 GB free</td>
          <td>2-4 TB high-speed NVMe SSD</td>
        </tr>
        <tr>
          <td>OS</td>
          <td>Windows, macOS, or Linux (Ubuntu preferred)</td>
          <td>Windows 11, macOS (M1/M2 supported), or Linux (Ubuntu recommended)</td>
          <td>Linux (Ubuntu preferred for best CUDA/cuDNN support)</td>
        </tr>
      </tbody>
    </table>
    $indexList
"@ | Out-File -Encoding UTF8 $outFile

# Define a Classification lookup dictionary (extend as needed).
$classificationMapping = @{
   "alfred"    = "Small LLMs"
   "athene-v2" = "Medium LLMs"
   # Add additional mappings here.
}

# Append each model's detailed section.
foreach ($model in $models) {
    $detailUrl = "https://ollama.com/library/$($model.ID)"
    try {
        $detailResponse = Invoke-WebRequest -Uri $detailUrl -TimeoutSec 10 -UseBasicParsing
        $detailContent = $detailResponse.Content

        $cmdRegex = '<input[^>]+name="command"[^>]+value="([^"]+)"'
        $cmdMatch = [regex]::Match($detailContent, $cmdRegex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $defaultCommand = if ($cmdMatch.Success) { $cmdMatch.Groups[1].Value } else { "ollama run $($model.ID)" }
        $defaultCmdLink = "cmd://" + ($defaultCommand -replace " ", "%20" -replace ":", "%3A")

        # Collect any variants.
        $variants = @()
        $ulRegex = '<ul[^>]+role="list"[^>]*>(.*?)</ul>'
        $ulMatch = [regex]::Match($detailContent, $ulRegex, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($ulMatch.Success) {
            $ulContent = $ulMatch.Groups[1].Value
            $liRegex = '<li[^>]*>(.*?)</li>'
            $liMatches = [regex]::Matches($ulContent, $liRegex, [System.Text.RegularExpressions.RegexOptions]::Singleline)
            foreach ($li in $liMatches) {
                $variantLine = ([regex]::Replace($li.Groups[1].Value, '<.*?>','')).Trim()
                if ($variantLine -ne "") { $variants += $variantLine }
            }
        }
        $parsedVariants = @()
        foreach ($line in $variants) {
            $variantRegex = '^(?<name>\S+)\s+(?<size>\S+)\s+(?<context>\S+)\s+(?<input>.+)$'
            $mVariant = [regex]::Match($line, $variantRegex)
            if ($mVariant.Success) {
                $parsedVariants += [PSCustomObject]@{
                    Variant = $mVariant.Groups["name"].Value
                    Size    = $mVariant.Groups["size"].Value
                    Context = $mVariant.Groups["context"].Value
                    Input   = $mVariant.Groups["input"].Value
                }
            }
            else {
                $parsedVariants += [PSCustomObject]@{
                    Variant = $line
                    Size    = ""
                    Context = ""
                    Input   = ""
                }
            }
        }

        Add-Content -Encoding UTF8 -Path $outFile -Value "<div class='model-section'>"
        Add-Content -Encoding UTF8 -Path $outFile -Value "<h2 id='$($model.ID)'>Model: $($model.Title)</h2>"
        Add-Content -Encoding UTF8 -Path $outFile -Value "<p><strong>Description:</strong> $($model.Description)</p>"
        
        # Add Classification if available.
        $modelIdLower = $model.ID.ToLower()
        if ($classificationMapping.ContainsKey($modelIdLower)) {
            $classification = $classificationMapping[$modelIdLower]
            Add-Content -Encoding UTF8 -Path $outFile -Value "<p><strong>Classification:</strong> $classification</p>"
        }
        
        Add-Content -Encoding UTF8 -Path $outFile -Value "<p><strong>Default Command:</strong> <a href='$defaultCmdLink'>$defaultCommand</a></p>"
        if ($parsedVariants.Count -gt 0) {
            Add-Content -Encoding UTF8 -Path $outFile -Value "<table>"
            Add-Content -Encoding UTF8 -Path $outFile -Value "<tr><th>Variant</th><th>Size</th><th>Context</th><th>Input</th><th>Launch</th></tr>"
            foreach ($v in $parsedVariants) {
                $variantCommand = "ollama run $($v.Variant)"
                $variantLink = "cmd://" + ($variantCommand -replace " ", "%20" -replace ":", "%3A")
                $row = "<tr><td>$($v.Variant)</td><td>$($v.Size)</td><td>$($v.Context)</td><td>$($v.Input)</td><td><a href='$variantLink'>Run</a></td></tr>"
                Add-Content -Encoding UTF8 -Path $outFile -Value $row
            }
            Add-Content -Encoding UTF8 -Path $outFile -Value "</table>"
        }
        Add-Content -Encoding UTF8 -Path $outFile -Value "<p><a href='#top' class='back-to-top'>Back to top</a></p>"
        Add-Content -Encoding UTF8 -Path $outFile -Value "<p><a href='$detailUrl' target='_blank'>View on Ollama</a></p>"
        Add-Content -Encoding UTF8 -Path $outFile -Value "</div>"
    }
    catch {
        Write-Host "⚠️ Failed to retrieve details for $($model.ID): $($_.Exception.Message)" -ForegroundColor Yellow
        Add-Content -Encoding UTF8 -Path $outFile -Value "<div class='model-section'>"
        Add-Content -Encoding UTF8 -Path $outFile -Value "<h2>$($model.Title)</h2>"
        Add-Content -Encoding UTF8 -Path $outFile -Value "<p><strong>Error:</strong> Failed to retrieve details for this model.</p>"
        Add-Content -Encoding UTF8 -Path $outFile -Value "<p><a href='#top' class='back-to-top'>Back to top</a></p>"
        Add-Content -Encoding UTF8 -Path $outFile -Value "</div>"
    }
}

@"
  </div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
  <script>
    // Smooth scroll "Back to top" animation
    $('.back-to-top').click(function(e) {
        e.preventDefault();
        $('html, body').animate({scrollTop: 0}, 500);
    });
  </script>
</body>
</html>
"@ | Out-File -Encoding UTF8 -Append -FilePath $outFile

Write-Host "Dashboard generated: $outFile" -ForegroundColor Green
