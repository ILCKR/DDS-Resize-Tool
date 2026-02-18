# Отступ для выравнивания текста в консоли / Indent for console text alignment
$indent = "      "

# Отображает ASCII-заголовок и очищает экран / Displays ASCII header and clears the screen
function Show-Header {
    Clear-Host
    Write-Host "`n`n`n      _      _____ _  _________  '  ____"
    Write-Host "      | |    / ____| |/ /  __ \ \ / / ___|"
    Write-Host "      | |   | |    | ' /| |__) \ V /\___ \"
    Write-Host "      | |   | |    |  < |  _  / > <  ___) |"
    Write-Host "      | |___| |____| . \| | \ \/ ^ \|____/"
    Write-Host "      |______\_____|_|\_\_|  \_\_/ \_\    "
    Write-Host "            DDS RESIZE TOOL v2.1 MT`n"
}

# Выводит цветной статус-блок с центрированным текстом / Displays a colored status block with centered text
function Show-Status {
    param(
        [string]$text,
        [string]$color
    )
    $w = 40
    $p = [math]::Max(0, [math]::Floor(($w - $text.Length - 2) / 2))
    Write-Host "${indent}****************************************" -ForegroundColor $color
    Write-Host "${indent}*$(" " * $p)$text$(" " * ($w - $text.Length - 2 - $p))*" -ForegroundColor $color
    Write-Host "${indent}****************************************`n" -ForegroundColor $color
}

# Определяем путь скрипта и ожидаемый путь к texconv.exe / Define script path and expected texconv.exe path
$scriptPath = $PSScriptRoot
$tc = Join-Path $scriptPath "texconv.exe"

# Запрашиваем texconv.exe, пока он не будет найден / Prompt for texconv.exe until found
while (-not (Test-Path $tc)) {
    Show-Header
    Show-Status "TEXCONV NOT FOUND" "Red"
    $tc = (Read-Host "      Drag texconv.exe here").Trim().Trim('"').Trim("'")
}

# Основной бесконечный цикл обработки папок / Main infinite loop for folder processing
while ($true) {

    # Запрос папки с DDS-файлами / Request folder with DDS files
    Show-Header
    Show-Status "READY" "Green"
    $inputDir = (Read-Host "      Drag FOLDER here").Trim().Trim('"').Trim("'")
    if (-not (Test-Path $inputDir)) { continue }

    # Поиск всех DDS файлов рекурсивно / Recursive search for all DDS files
    $files = Get-ChildItem $inputDir -Filter *.dds -Recurse
    if ($files.Count -eq 0) { continue }

    # Запрос коэффициента уменьшения / Request downscale ratio
    $ratio = 0
    while ($ratio -notin @(2, 4, 8, 16)) {
        Write-Host "${indent}Multiplier (2, 4, 8, 16): " -NoNewline
        $val = Read-Host
        if ($val -match "^\d+$") { $ratio = [int]$val }
    }

    # Создание выходной папки / Create output folder
    $outputBase = Join-Path (Split-Path $inputDir -Parent) "$((Split-Path $inputDir -Leaf))-resized"
    if (!(Test-Path $outputBase)) {
        New-Item $outputBase -ItemType Directory -Force | Out-Null
    }

    # Инициализация счётчиков и UI / Initialize counters and UI
    Show-Header
    Show-Status "PROCESSING..." "Yellow"
    $bc1 = 0; $bc3 = 0; $skip = 0; $done = 0; $total = $files.Count
    $startTop = [Console]::CursorTop
    Push-Location $outputBase

    # Параллельная обработка DDS файлов / Parallel processing of DDS files
    $files | ForEach-Object -Parallel {

        # Подготовка путей / Prepare paths
        $f = $_
        $relPath = $f.DirectoryName.Replace($using:inputDir, "").TrimStart("\")
        $target = if ($relPath) { Join-Path $using:outputBase $relPath } else { $using:outputBase }
        if (!(Test-Path $target)) {
            New-Item $target -ItemType Directory -Force | Out-Null
        }
        Set-Location $target

        # Получение информации о текстуре / Get texture information
        $rawInfo = & $using:tc -nologo "$($f.FullName)"
        $info = $rawInfo | Select-String "(\d+)x(\d+)"

        if ($info -match "(\d+)x(\d+)") {

            # Вычисление нового размера / Calculate new size
            $w = [int]($matches[1] / $using:ratio)
            $h = [int]($matches[2] / $using:ratio)

            # Пропуск слишком маленьких текстур / Skip textures that are too small
            if ($w -lt 4 -or $h -lt 4) {
                Write-Output "SKIP:$($f.Name)"
            }
            else {
                # Определение формата сжатия / Determine compression format
                $hasAlpha = $rawInfo | Select-String "alpha: (?!none)"
                $isBC1 = $rawInfo | Select-String "BC1_UNORM|DXT1"

                $fmt =
                    if ($f.Name -match "_bump#?\.dds$") { "BC3_UNORM" }
                    elseif ($isBC1) { "BC1_UNORM" }
                    elseif ($hasAlpha) { "BC3_UNORM" }
                    else { "BC1_UNORM" }

                # Конвертация и ресайз / Conversion and resize
                & $using:tc -nologo -if FANT -f $fmt -m 0 -w $w -h $h -y -o "$target" "$($f.FullName)" | Out-Null
                Write-Output $fmt
            }
        }

    } -ThrottleLimit 12 | ForEach-Object {

        # Обновление статистики и прогресса / Update statistics and progress
        if ($_ -eq "BC1_UNORM") { $bc1++ }
        elseif ($_ -eq "BC3_UNORM") { $bc3++ }
        elseif ($_ -like "SKIP:*") {
            $skip++
            $name = $_.Replace("SKIP:", "")
            Get-ChildItem $outputBase -Filter $name -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
        }

        $done++
        [Console]::SetCursorPosition(0, $startTop)
        $pct = [math]::Round(($done / $total) * 100)
        Write-Host "${indent}Progress: $($pct.ToString().PadLeft(3))% ($done/$total)"
        Write-Host "${indent}BC1: $bc1 | BC3: $bc3 | Skip: $skip"
    }

    Pop-Location

    # Очистка пустых папок / Clean up empty folders
    Get-ChildItem $outputBase -Recurse |
        Where { $_.PSIsContainer -and (Get-ChildItem $_.FullName -Recurse).Count -eq 0 } |
        Remove-Item -Recurse -Force

    # Финальный отчёт / Final report
    explorer $outputBase
    Show-Header
    Show-Status "DONE" "Green"
    Write-Host "${indent}Files Processed : $total"
    Write-Host "${indent}BC1 Compressed  : $bc1"
    Write-Host "${indent}BC3 Compressed  : $bc3"
    Write-Host "${indent}Skipped (Small) : $skip"
    [System.Console]::Beep(440, 500)

    Write-Host "`n${indent}Press Enter for next folder..."
    Read-Host | Out-Null
}